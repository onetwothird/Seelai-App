// File: lib/roles/mswd/home/sections/location_track/location_tracking_screen.dart
// ignore_for_file: deprecated_member_use, unnecessary_import, prefer_final_fields, empty_catches

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http; // Required for direct image download
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:timeago/timeago.dart' as timeago;

// App Imports
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/mswd/mswd_location_tracking_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/firebase/mswd/mswd_call_service.dart';

class MswdLocationTrackingScreen extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final Function(bool isScrollingDown)? onScroll;

  const MswdLocationTrackingScreen({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    this.onScroll,
  });

  @override
  State<MswdLocationTrackingScreen> createState() => _MswdLocationTrackingScreenState();
}

class _MswdLocationTrackingScreenState extends State<MswdLocationTrackingScreen> with TickerProviderStateMixin {
  late MapController _mapController;
  bool _isMapReady = false;
  bool _isLoading = true;
  
  StreamSubscription? _locationsStream;
  Map<String, Map<String, dynamic>> _userLocations = {};
  Map<String, Map<String, dynamic>> _userProfiles = {};
  
  String _selectedFilter = 'all';
  bool _showOnlyActive = false;
  String? _selectedUserId;
  
  // Tracking state
  Map<String, GeoPoint> _lastRenderedPoints = {};
  Map<String, String?> _lastRenderedImageUrls = {};
  
  Timer? _refreshTimer;
  Timer? _uiUpdateTimer;

  // LAYOUT ADJUSTMENT:
  // Lift content 110px from bottom to clear the navigation menu
  final double bottomContentOffset = 110.0; 
  

  @override
  void initState() {
    super.initState();
    _initializeMapController();
    _startLocationTracking();
    
    _uiUpdateTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _initializeMapController() {
    _mapController = MapController(
      initPosition: GeoPoint(latitude: 14.4167, longitude: 120.9833),
      areaLimit: BoundingBox.world(),
    );
  }

  @override
  void dispose() {
    _locationsStream?.cancel();
    _refreshTimer?.cancel();
    _uiUpdateTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ==================== DATA LOGIC ====================

  Future<void> _startLocationTracking() async {
    _locationsStream = mswdLocationTrackingService
        .streamAllUserLocations()
        .listen((locationsData) async {
      if (!mounted) return;

      Map<String, Map<String, dynamic>> newLocations = {};
      await _processUserLocations(locationsData['patients'] ?? [], 'visually_impaired', newLocations);
      await _processUserLocations(locationsData['caretakers'] ?? [], 'caretaker', newLocations);

      if (mounted) {
        setState(() {
          _userLocations = newLocations;
          _isLoading = false;
        });
        if (_isMapReady) await _updateMapMarkers();
      }
    });

    _refreshTimer = Timer.periodic(Duration(seconds: 45), (_) => _refreshLocationData());
  }

  Future<void> _processUserLocations(
    List<dynamic> rawLocations, 
    String type, 
    Map<String, Map<String, dynamic>> targetMap
  ) async {
    for (var location in rawLocations) {
      String userId = location['userId'];
      targetMap[userId] = location;
      if (!_userProfiles.containsKey(userId)) {
        _fetchUserProfile(userId, type);
      }
    }
  }

  Future<void> _fetchUserProfile(String userId, String userType) async {
    try {
      final userData = await databaseService.getUserDataByRole(userId, userType);
      if (userData != null && mounted) {
        setState(() {
          _userProfiles[userId] = {
            ...userData,
            'userType': userType,
          };
        });
        // Force redraw to show profile image once loaded
        if(_isMapReady) _updateMapMarkers();
      }
    } catch (e) {
      debugPrint('Profile fetch error: $e');
    }
  }

  Future<void> _refreshLocationData() async {
    if (!mounted) return;
    try {
      final allLocations = await mswdLocationTrackingService.getAllUserLocations();
      Map<String, Map<String, dynamic>> newLocations = {};
      for (var loc in allLocations) {
        newLocations[loc['userId']] = loc;
      }
      if (mounted && newLocations.isNotEmpty) {
        setState(() => _userLocations = newLocations);
        if (_isMapReady) await _updateMapMarkers();
      }
    } catch (e) {}
  }

  // ==================== MARKER UPDATE LOGIC ====================

  Future<void> _updateMapMarkers() async {
    if (!_isMapReady || !mounted) return;

    try {
      final filteredList = _userLocations.entries.where((entry) {
        final userType = entry.value['userType'] ?? '';
        final isActive = mswdLocationTrackingService.isLocationRecent(entry.value);
        if (_showOnlyActive && !isActive) return false;
        if (_selectedFilter == 'patients' && userType != 'visually_impaired') return false;
        if (_selectedFilter == 'caretakers' && userType != 'caretaker') return false;
        return true;
      }).toList();

      final activeIds = <String>{};

      for (var entry in filteredList) {
        final userId = entry.key;
        activeIds.add(userId);
        
        final location = entry.value;
        final lat = location['latitude'] as double?;
        final lng = location['longitude'] as double?;
        final profile = _userProfiles[userId];
        final currentImgUrl = profile?['profileImageUrl'] as String?;
        final name = profile?['name'] ?? 'User';

        if (lat == null || lng == null) continue;

        final newGeoPoint = GeoPoint(latitude: lat, longitude: lng);
        bool shouldUpdate = true;

        if (_lastRenderedPoints.containsKey(userId)) {
          double dist = mswdLocationTrackingService.calculateDistance(
            lat1: _lastRenderedPoints[userId]!.latitude,
            lon1: _lastRenderedPoints[userId]!.longitude,
            lat2: lat,
            lon2: lng,
          );

          // Update if moved > 5m OR image URL changed OR selection changed
          bool imageChanged = _lastRenderedImageUrls[userId] != currentImgUrl;
          bool isSelected = _selectedUserId == userId;

          if (dist < 5.0 && !imageChanged && !isSelected) {
            shouldUpdate = false; 
          }
        }

        if (shouldUpdate) {
          if (_lastRenderedPoints.containsKey(userId)) {
            await _mapController.removeMarker(_lastRenderedPoints[userId]!);
          }

          final isActive = mswdLocationTrackingService.isLocationRecent(location);
          final userType = location['userType'] ?? '';
          
          Color ringColor = userType == 'visually_impaired' ? Colors.redAccent : Colors.blueAccent;
          if (!isActive) ringColor = Colors.grey;

          // 1. Download Image Bytes first
          Uint8List? imageBytes;
          if (currentImgUrl != null && currentImgUrl.isNotEmpty) {
            imageBytes = await _downloadImageBytes(currentImgUrl);
          }

          // 2. Build the Marker using standard Widgets
          final markerWidget = _buildAvatarMarkerWidget(
            imageBytes: imageBytes,
            name: name,
            ringColor: ringColor,
            isActive: isActive,
            isSelected: _selectedUserId == userId,
          );

          if (mounted) {
            await _mapController.addMarker(
              newGeoPoint,
              markerIcon: MarkerIcon(iconWidget: markerWidget),
            );
            
            _lastRenderedPoints[userId] = newGeoPoint;
            _lastRenderedImageUrls[userId] = currentImgUrl;
          }
        }
      }

      final idsToRemove = _lastRenderedPoints.keys.where((id) => !activeIds.contains(id)).toList();
      for (var id in idsToRemove) {
        await _mapController.removeMarker(_lastRenderedPoints[id]!);
        _lastRenderedPoints.remove(id);
        _lastRenderedImageUrls.remove(id);
      }
      
      _drawAccuracyCircle();

    } catch (e) {
      debugPrint('Marker Update Error: $e');
    }
  }

  Future<void> _drawAccuracyCircle() async {
    if (_selectedUserId != null && _userLocations.containsKey(_selectedUserId)) {
      final loc = _userLocations[_selectedUserId]!;
      final lat = loc['latitude'] as double;
      final lng = loc['longitude'] as double;
      final accuracy = (loc['accuracy'] as num?)?.toDouble() ?? 50.0;
      
      if (mswdLocationTrackingService.isLocationRecent(loc)) {
        final key = "acc_$_selectedUserId";
        await _mapController.drawCircle(
          CircleOSM(
            key: key,
            centerPoint: GeoPoint(latitude: lat, longitude: lng),
            radius: accuracy, 
            color: Colors.blue.withOpacity(0.2),
            strokeWidth: 1,
          ),
        );
      }
    }
  }

  // ==================== IMAGE & WIDGET HELPERS ====================

  Future<Uint8List?> _downloadImageBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 4));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  // NEW: Builds a marker Widget that looks exactly like the Detail Card profile
  Widget _buildAvatarMarkerWidget({
    required Uint8List? imageBytes,
    required String name,
    required Color ringColor,
    required bool isActive,
    required bool isSelected,
  }) {
    // Determine size based on selection
    final double size = isSelected ? 110.0 : 80.0;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Use the same fallback background color as DetailCard
            color: primary.withOpacity(0.1),
            // Removed the Border.all here as requested
            // Add shadow for visibility on map
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: ClipOval(
            child: imageBytes != null
                ? ColorFiltered(
                    // Apply greyscale filter if not active (offline)
                    colorFilter: isActive 
                        ? ColorFilter.mode(Colors.transparent, BlendMode.multiply) 
                        : ColorFilter.matrix(<double>[
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0,      0,      0,      1, 0,
                          ]),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.cover, 
                    ),
                  )
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        // Match DetailCard text style
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: size * 0.4,
                      ),
                    ),
                  ),
          ),
        ),
        
        // Active Status Indicator (Green Dot)
        if (isActive)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: Colors.greenAccent[700],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4)
                ]
              ),
            ),
          ),
      ],
    );
  }

  // ==================== INTERACTION ====================

  Future<void> _selectUser(String userId) async {
    setState(() => _selectedUserId = userId);
    await _updateMapMarkers(); 
    if (_lastRenderedPoints.containsKey(userId)) {
      await _mapController.goToLocation(_lastRenderedPoints[userId]!);
    }
  }

  void _clearSelection() {
    setState(() => _selectedUserId = null);
    _updateMapMarkers();
  }

  // ==================== UI BUILDER ====================

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),

          // Glass Top Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildGlassTopBar(theme),
          ),

          // Right Side Tools
          Positioned(
            right: 16,
            bottom: bottomContentOffset + 160, 
            child: Column(
              children: [
                _buildGlassButton(
                  icon: Icons.center_focus_strong_rounded,
                  onTap: _centerMapIdeally,
                  theme: theme,
                ),
                SizedBox(height: 12),
                _buildGlassButton(
                  icon: Icons.refresh_rounded,
                  onTap: _refreshLocationData,
                  theme: theme,
                ),
              ],
            ),
          ),

          // User Carousel & Detail Card Container
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomContentOffset, 
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(anim),
                child: child,
              ),
              child: _selectedUserId != null
                  ? _buildDetailCard(theme)
                  : _buildUserCarousel(theme),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: CircularProgressIndicator(color: primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return OSMFlutter(
      controller: _mapController,
      osmOption: OSMOption(
        userTrackingOption: UserTrackingOption(enableTracking: false),
        zoomOption: ZoomOption(
          initZoom: 15.0,
          minZoomLevel: 4,
          maxZoomLevel: 19,
          stepZoom: 1.0,
        ),
        roadConfiguration: RoadOption(roadColor: Colors.blueGrey),
      ),
      onMapIsReady: (isReady) async {
        if (!mounted) return;
        setState(() => _isMapReady = isReady);
        if (isReady) {
          await Future.delayed(Duration(milliseconds: 500));
          await _updateMapMarkers();
        }
      },
      onGeoPointClicked: (point) {
        String? closestId;
        double minD = 10000;
        _lastRenderedPoints.forEach((id, p) {
           double d = mswdLocationTrackingService.calculateDistance(
             lat1: point.latitude, lon1: point.longitude,
             lat2: p.latitude, lon2: p.longitude
           );
           if (d < 150 && d < minD) {
             minD = d;
             closestId = id;
           }
        });
        
        if (closestId != null) {
          _selectUser(closestId!);
        } else {
          _clearSelection();
        }
      },
    );
  }

  Widget _buildGlassTopBar(dynamic theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
                ? theme.cardColor.withOpacity(0.8) 
                : Colors.white.withOpacity(0.8),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              Icon(Icons.radar, color: primary),
              SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterText('All', 'all', theme),
                      _buildFilterText('Patients', 'patients', theme),
                      _buildFilterText('Caretakers', 'caretakers', theme),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1, height: 20, color: theme.subtextColor,
                margin: EdgeInsets.symmetric(horizontal: 8),
              ),
              InkWell(
                onTap: () {
                  setState(() => _showOnlyActive = !_showOnlyActive);
                  _updateMapMarkers();
                },
                child: Row(
                  children: [
                    Icon(
                      _showOnlyActive ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: _showOnlyActive ? Colors.green : theme.subtextColor,
                    ),
                    SizedBox(width: 4),
                    Text('Active', style: TextStyle(
                      fontSize: 12, 
                      color: _showOnlyActive ? Colors.green : theme.subtextColor
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterText(String text, String value, dynamic theme) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _updateMapMarkers();
      },
      child: Padding(
        padding: EdgeInsets.only(right: 16),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primary : theme.subtextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap, required dynamic theme}) {
    return ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.black54 : Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: IconButton(
            icon: Icon(icon, color: widget.isDarkMode ? Colors.white : Colors.black87),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCarousel(dynamic theme) {
    final usersList = _userLocations.values.where((loc) {
       final userType = loc['userType'];
       if (_showOnlyActive && !mswdLocationTrackingService.isLocationRecent(loc)) return false;
       if (_selectedFilter == 'patients' && userType != 'visually_impaired') return false;
       if (_selectedFilter == 'caretakers' && userType != 'caretaker') return false;
       return true;
    }).toList();

    usersList.sort((a, b) {
      bool aActive = mswdLocationTrackingService.isLocationRecent(a);
      bool bActive = mswdLocationTrackingService.isLocationRecent(b);
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;
      return 0;
    });

    if (usersList.isEmpty) return SizedBox.shrink();

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (widget.onScroll != null) {
          if (notification.direction == ScrollDirection.reverse) {
            widget.onScroll!(true); 
          } else if (notification.direction == ScrollDirection.forward) {
            widget.onScroll!(false); 
          }
        }
        return true;
      },
      child: Container(
        height: 140,
        padding: EdgeInsets.only(bottom: 10),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: usersList.length,
          itemBuilder: (context, index) {
            final loc = usersList[index];
            final userId = loc['userId'];
            final profile = _userProfiles[userId];
            final name = profile?['name'] ?? 'Loading...';
            final img = profile?['profileImageUrl'];
            final isActive = mswdLocationTrackingService.isLocationRecent(loc);
  
            return GestureDetector(
              onTap: () => _selectUser(userId),
              child: Container(
                width: 100,
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Color(0xFF1A1F3A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0,4))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: (img != null && img.isNotEmpty) ? NetworkImage(img) : null,
                          child: (img == null || img.isEmpty) 
                              ? Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 20)) 
                              : null,
                        ),
                        if (isActive)
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              width: 16, height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailCard(dynamic theme) {
    if (_selectedUserId == null) return SizedBox.shrink();
    
    final location = _userLocations[_selectedUserId];
    final profile = _userProfiles[_selectedUserId];
    if (location == null || profile == null) return SizedBox.shrink();

    final isActive = mswdLocationTrackingService.isLocationRecent(location);
    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(location['lastUpdateMillis'] ?? 0);
    final accuracy = location['accuracy']?.toStringAsFixed(0) ?? '?';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 5))],
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: (profile['profileImageUrl'] != null && profile['profileImageUrl'].isNotEmpty)
                    ? DecorationImage(image: NetworkImage(profile['profileImageUrl']), fit: BoxFit.cover)
                    : null,
                  color: primary.withOpacity(0.1)
                ),
                child: (profile['profileImageUrl'] == null || profile['profileImageUrl'].isEmpty)
                  ? Center(child: Text(profile['name']?[0] ?? '?', style: TextStyle(fontWeight: FontWeight.bold, color: primary)))
                  : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['name'] ?? 'User',
                      style: h3.copyWith(color: theme.textColor, fontSize: 18),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: theme.subtextColor),
                        SizedBox(width: 4),
                        Text(
                          'Accuracy: ${accuracy}m',
                          style: caption.copyWith(color: theme.subtextColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _clearSelection,
                icon: Icon(Icons.close, color: theme.subtextColor),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => MswdCallService.call(
                    context: context, 
                    user: profile, 
                    isDarkMode: widget.isDarkMode, 
                    theme: theme
                  ),
                  icon: Icon(Icons.call, size: 18),
                  label: Text('Call Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: isActive ? Colors.green : Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      timeago.format(lastUpdate, locale: 'en_short'), 
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.grey, 
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                      )
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _centerMapIdeally() async {
    if (_lastRenderedPoints.isEmpty) return;
    
    if (_selectedUserId != null && _lastRenderedPoints.containsKey(_selectedUserId)) {
      await _mapController.goToLocation(_lastRenderedPoints[_selectedUserId]!);
    } else {
      double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
      for (var p in _lastRenderedPoints.values) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      await _mapController.zoomToBoundingBox(
        BoundingBox(north: maxLat + 0.01, south: minLat - 0.01, east: maxLng + 0.01, west: minLng - 0.01),
      );
    }
  }
}