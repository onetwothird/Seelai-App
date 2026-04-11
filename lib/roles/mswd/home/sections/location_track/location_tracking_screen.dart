// File: lib/roles/mswd/home/sections/location_track/location_tracking_screen.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http; 
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:timeago/timeago.dart' as timeago;

// App Imports
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class MswdLocationTrackingScreen extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final Function(bool isScrollingDown)? onScroll;
  final VoidCallback? onRestoreMenu;

  const MswdLocationTrackingScreen({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    this.onScroll,
    this.onRestoreMenu,
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
  final Map<String, Map<String, dynamic>> _userProfiles = {};
  
  String _selectedFilter = 'all';
  bool _showOnlyActive = false;
  String? _selectedUserId;
  
  // Tracking state
  final Map<String, GeoPoint> _lastRenderedPoints = {};
  final Map<String, String?> _lastRenderedImageUrls = {};
  
  // Routing state
  RoadInfo? _currentRoadInfo;
  bool _isRouting = false;
  
  Timer? _refreshTimer;
  Timer? _uiUpdateTimer;

  // LAYOUT ADJUSTMENT:
  // Lift content 130px from bottom to fully clear the navigation menu
  final double bottomContentOffset = 130.0; 
  
  @override
  void initState() {
    super.initState();
    _initializeMapController();
    _startLocationTracking();
    
    _uiUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
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
      await _processUserLocations(locationsData['patients'] ?? [], 'partially_sighted', newLocations);
      await _processUserLocations(locationsData['caretakers'] ?? [], 'caretaker', newLocations);

      if (mounted) {
        setState(() {
          _userLocations = newLocations;
          _isLoading = false;
        });
        if (_isMapReady) await _updateMapMarkers();
      }
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) => _refreshLocationData());
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
    } catch (e) {
      debugPrint('Error refreshing location data: $e');
    }
  }

  // ==================== MARKER UPDATE LOGIC ====================

  Future<void> _updateMapMarkers() async {
    if (!_isMapReady || !mounted) return;

    try {
      final filteredList = _userLocations.entries.where((entry) {
        final userType = entry.value['userType'] ?? '';
        final isActive = mswdLocationTrackingService.isLocationRecent(entry.value);
        if (_showOnlyActive && !isActive) return false;
        if (_selectedFilter == 'patients' && userType != 'partially_sighted') return false;
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
          
          Color ringColor = userType == 'partially_sighted' ? Colors.redAccent : Colors.blueAccent;
          if (!isActive) ringColor = Colors.grey;

          Uint8List? imageBytes;
          if (currentImgUrl != null && currentImgUrl.isNotEmpty) {
            imageBytes = await _downloadImageBytes(currentImgUrl);
          }

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
            color: Colors.blue.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        );
      }
    }
  }

  // ==================== ROUTING LOGIC ====================

  Future<void> _drawRouteToUser(GeoPoint targetPoint) async {
    setState(() => _isRouting = true);
    
    try {
      GeoPoint? myLocation = await _mapController.myLocation();
      await _mapController.clearAllRoads();

      RoadInfo roadInfo = await _mapController.drawRoad(
        myLocation,
        targetPoint,
        roadType: RoadType.car, 
        roadOption: const RoadOption(
          roadWidth: 10,
          roadColor: Colors.blueAccent,
          zoomInto: true, 
        ),
      );

      if (mounted) {
        setState(() {
          _currentRoadInfo = roadInfo;
          _isRouting = false;
        });
      }
    } catch (e) {
      debugPrint('Routing Error: $e');
      if (mounted) {
        setState(() => _isRouting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to calculate route. Please ensure location is enabled.')),
        );
      }
    }
  }

  // ==================== IMAGE & WIDGET HELPERS ====================

  Future<Uint8List?> _downloadImageBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  Widget _buildAvatarMarkerWidget({
    required Uint8List? imageBytes,
    required String name,
    required Color ringColor,
    required bool isActive,
    required bool isSelected,
  }) {
    final double size = isSelected ? 110.0 : 80.0;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.1),
            boxShadow: const [
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
                    colorFilter: isActive 
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply) 
                        : const ColorFilter.matrix(<double>[
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
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: size * 0.4,
                      ),
                    ),
                  ),
          ),
        ),
        
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
                boxShadow: const [
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
      await _mapController.moveTo(_lastRenderedPoints[userId]!);
    }
  }

  void _clearSelection() async {
    widget.onRestoreMenu?.call(); 

    setState(() {
      _selectedUserId = null;
      _currentRoadInfo = null;
    });
    await _mapController.clearAllRoads();
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

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildGlassTopBar(theme),
          ),

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
                const SizedBox(height: 12),
                _buildGlassButton(
                  icon: Icons.refresh_rounded,
                  onTap: _refreshLocationData,
                  theme: theme,
                ),
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: bottomContentOffset, 
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(anim),
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
              child: const Center(
                child: CircularProgressIndicator(color: primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Listener(
      // This detects when a user drags/swipes their finger across the map
      onPointerMove: (event) {
        // Send a signal to the home screen to hide the menu (true = hide)
        widget.onScroll?.call(true); 
      },
      child: OSMFlutter(
        controller: _mapController,
        osmOption: OSMOption(
          userTrackingOption: const UserTrackingOption(
            enableTracking: true,
            unFollowUser: true,
          ),
          zoomOption: const ZoomOption(
            initZoom: 15.0,
            minZoomLevel: 4,
            maxZoomLevel: 19,
            stepZoom: 1.0,
          ),
          roadConfiguration: const RoadOption(roadColor: Colors.blueGrey),
        ),
        onMapIsReady: (isReady) async {
          if (!mounted) return;
          setState(() => _isMapReady = isReady);
          if (isReady) {
            await Future.delayed(const Duration(milliseconds: 500));
            await _updateMapMarkers();
          }
        },
        onGeoPointClicked: (point) {
          widget.onRestoreMenu?.call(); 

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
      ),
    );
  }

  Widget _buildGlassTopBar(dynamic theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
                ? theme.cardColor.withValues(alpha: 0.8) 
                : Colors.white.withValues(alpha: 0.8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              const Icon(Icons.radar, color: primary),
              const SizedBox(width: 12),
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
                margin: const EdgeInsets.symmetric(horizontal: 8),
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
                    const SizedBox(width: 4),
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
        padding: const EdgeInsets.only(right: 16),
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
            color: widget.isDarkMode ? Colors.black54 : Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
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
       if (_selectedFilter == 'patients' && userType != 'partially_sighted') return false;
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

    if (usersList.isEmpty) return const SizedBox.shrink();

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (widget.onScroll != null) {
          if (notification.direction == ScrollDirection.reverse) {
            widget.onScroll!(true); 
          } else if (notification.direction == ScrollDirection.forward) {
            widget.onScroll!(false); 
          }
        }
        return false; 
      },
      child: Container(
        height: 140,
        padding: const EdgeInsets.only(bottom: 10),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0,4))],
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
                              ? Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 20)) 
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
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
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
    if (_selectedUserId == null) return const SizedBox.shrink();
    
    final location = _userLocations[_selectedUserId];
    final profile = _userProfiles[_selectedUserId];
    if (location == null || profile == null) return const SizedBox.shrink();

    final isActive = mswdLocationTrackingService.isLocationRecent(location);
    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(location['lastUpdateMillis'] ?? 0);
    final accuracy = location['accuracy']?.toStringAsFixed(0) ?? '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 5))],
        border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
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
                  color: primary.withValues(alpha: 0.1)
                ),
                child: (profile['profileImageUrl'] == null || profile['profileImageUrl'].isEmpty)
                  ? Center(child: Text(profile['name']?[0] ?? '?', style: const TextStyle(fontWeight: FontWeight.bold, color: primary)))
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['name'] ?? 'User',
                      style: h3.copyWith(color: theme.textColor, fontSize: 18),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (_currentRoadInfo != null && _currentRoadInfo!.distance != null && _currentRoadInfo!.duration != null)
                      Row(
                        children: [
                          Icon(Icons.directions_car, size: 14, color: theme.subtextColor),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentRoadInfo!.distance!.toStringAsFixed(2)} km • ${(_currentRoadInfo!.duration! / 60).toStringAsFixed(0)} mins',
                            style: caption.copyWith(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: theme.subtextColor),
                          const SizedBox(width: 4),
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
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRouting ? null : () {
                    final lat = location['latitude'] as double;
                    final lng = location['longitude'] as double;
                    _drawRouteToUser(GeoPoint(latitude: lat, longitude: lng));
                  },
                  icon: _isRouting 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.navigation, size: 18),
                  label: Text(_isRouting ? 'Routing...' : 'Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: isActive ? Colors.green : Colors.grey),
                  const SizedBox(width: 6),
                  Builder(
                    builder: (context) {
                      String timeStr = timeago.format(lastUpdate, locale: 'en_short');
                      String displayText = timeStr == 'now' 
                          ? 'Just updated' 
                          : 'Updated $timeStr ago';

                      return Text(
                        displayText, 
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.grey, 
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        )
                      );
                    }
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _centerMapIdeally() async {
    if (_lastRenderedPoints.isEmpty) return;
    
    if (_selectedUserId != null && _lastRenderedPoints.containsKey(_selectedUserId)) {
      await _mapController.moveTo(_lastRenderedPoints[_selectedUserId]!);
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