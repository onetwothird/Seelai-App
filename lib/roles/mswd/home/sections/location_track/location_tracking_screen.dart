// File: lib/roles/mswd/home/sections/location_track/location_tracking_screen.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

// App Imports
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/widgets/map_marker_helper.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  GoogleMapController? _mapController;
  bool _isMapReady = false;
  bool _isLoading = true;
  
  StreamSubscription? _locationsStream;
  StreamSubscription<Position>? _myPositionStream; 
  Position? _myPosition;

  Map<String, Map<String, dynamic>> _userLocations = {};
  final Map<String, Map<String, dynamic>> _userProfiles = {};
  
  String _selectedFilter = 'all';
  bool _showOnlyActive = false;
  String? _selectedUserId;
  
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};
  
  final Map<String, BitmapDescriptor> _markerCache = {};
  final Map<String, String> _markerStateCache = {}; 
  
  bool _isRouting = false;
  
  Timer? _refreshTimer;
  Timer? _uiUpdateTimer;

  final double bottomContentOffset = 130.0; 
  
  @override
  void initState() {
    super.initState();
    _startTrackingMyLocation(); 
    _startLocationTracking();
    
    _uiUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _locationsStream?.cancel();
    _myPositionStream?.cancel();
    _refreshTimer?.cancel();
    _uiUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ==================== DATA LOGIC ====================

  Future<void> _startTrackingMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      _myPosition = await Geolocator.getCurrentPosition();
      if (mounted && _isMapReady) await _updateMapMarkers();

      // ✅ 1. Push Initial Location to Firebase
      final currentUserId = databaseService.currentUserId;
      if (currentUserId != null && _myPosition != null) {
        mswdLocationTrackingService.updateMswdLocation(
          adminId: currentUserId,
          latitude: _myPosition!.latitude,
          longitude: _myPosition!.longitude,
          accuracy: _myPosition!.accuracy,
        );
      }

      // ✅ 2. Listen to Live Location and sync to Firebase
      _myPositionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((Position position) {
        if (mounted) {
          setState(() => _myPosition = position);
          if (_isMapReady) _updateMapMarkers();
          
          if (currentUserId != null) {
            mswdLocationTrackingService.updateMswdLocation(
              adminId: currentUserId,
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
            );
          }
        }
      });
    } catch (e) {
      debugPrint('Error tracking MSWD location: $e');
    }
  }

  Future<void> _startLocationTracking() async {
    _locationsStream = mswdLocationTrackingService
        .streamAllUserLocations()
        .listen((locationsData) async {
      if (!mounted) return;

      Map<String, Map<String, dynamic>> newLocations = {};
      await _processUserLocations(locationsData['patients'] ?? [], 'partially_sighted', newLocations);
      await _processUserLocations(locationsData['caretakers'] ?? [], 'caretaker', newLocations);
      await _processUserLocations(locationsData['mswd'] ?? [], 'admin', newLocations); // ✅ Support Other Admins!

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
      Set<Marker> newMarkers = {};
      final currentUserId = databaseService.currentUserId;

      // 1. Add YOUR Own Marker (Drawn instantly locally so it never lags)
      if (_myPosition != null && currentUserId != null) {
        final myImgUrl = widget.userData['profileImageUrl'] as String?;
        final myName = widget.userData['name'] ?? 'You';

        String myStateKey = "${currentUserId}_$myImgUrl";

        if (!_markerCache.containsKey(currentUserId) || _markerStateCache[currentUserId] != myStateKey) {
          final myMarkerBytes = await MapMarkerHelper.createProfileMarker(
            imageUrl: myImgUrl, name: myName, borderColor: primary, 
            size: 35.0, isOffline: false, 
          );
          
          if (myMarkerBytes != null) {
            _markerCache[currentUserId] = BitmapDescriptor.bytes(myMarkerBytes);
            _markerStateCache[currentUserId] = myStateKey;
          }
        }

        if (_markerCache.containsKey(currentUserId)) {
          newMarkers.add(Marker(
            markerId: MarkerId(currentUserId),
            position: LatLng(_myPosition!.latitude, _myPosition!.longitude),
            icon: _markerCache[currentUserId]!,
            zIndexInt: 3,
          ));
        }
      }

      // 2. Add Everyone Else's Markers
      final filteredList = _userLocations.entries.where((entry) {
        if (entry.key == currentUserId) return false; // ✅ SKIP drawing yourself twice!

        final userType = entry.value['userType'] ?? '';
        final isActive = mswdLocationTrackingService.isLocationRecent(entry.value);
        if (_showOnlyActive && !isActive) return false;
        if (_selectedFilter == 'patients' && userType != 'partially_sighted') return false;
        if (_selectedFilter == 'caretakers' && userType != 'caretaker') return false;
        return true;
      }).toList();

      for (var entry in filteredList) {
        final userId = entry.key;
        final location = entry.value;
        final lat = location['latitude'] as double?;
        final lng = location['longitude'] as double?;
        final profile = _userProfiles[userId];
        final currentImgUrl = profile?['profileImageUrl'] as String?;
        final name = profile?['name'] ?? 'User';

        if (lat == null || lng == null) continue;

        final isActive = mswdLocationTrackingService.isLocationRecent(location);
        final userType = location['userType'] ?? '';
        final isSelected = _selectedUserId == userId;
        
        Color ringColor = userType == 'partially_sighted' ? Colors.redAccent : Colors.blueAccent;
        if (userType == 'mswd' || userType == 'admin') ringColor = primary; // Other Admins
        if (!isActive) ringColor = Colors.grey;

        String stateKey = "${userId}_${isActive}_${isSelected}_$currentImgUrl";

        if (!_markerCache.containsKey(userId) || _markerStateCache[userId] != stateKey) {
          final markerBytes = await MapMarkerHelper.createProfileMarker(
            imageUrl: currentImgUrl, name: name, borderColor: ringColor,
            size: isSelected ? 35.0 : 35.0, isOffline: !isActive,
          );
          
          if (markerBytes != null) {
            _markerCache[userId] = BitmapDescriptor.bytes(markerBytes);
            _markerStateCache[userId] = stateKey;
          }
        }

        if (_markerCache.containsKey(userId)) {
          newMarkers.add(Marker(
            markerId: MarkerId(userId),
            position: LatLng(lat, lng),
            icon: _markerCache[userId]!,
            zIndexInt: isSelected ? 2 : 1, 
            onTap: () => _selectUser(userId),
          ));
        }
      }

      if (mounted) {
        setState(() {
          _markers = newMarkers;
          _circles = {};
        });
      }

    } catch (e) {
      debugPrint('Marker Update Error: $e');
    }
  }

  // ==================== ROUTING LOGIC ====================

 Future<void> _drawRouteToUser(LatLng targetPoint) async {
    setState(() => _isRouting = true);
    
    try {
      _myPosition ??= await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      LatLng myLocation = LatLng(_myPosition!.latitude, _myPosition!.longitude);

      // 1. Fetch API Key from .env
      String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

      // 2. Initialize PolylinePoints
      PolylinePoints polylinePoints = PolylinePoints(apiKey: apiKey);
      List<LatLng> polylineCoordinates = [];

      // 3. Create the request using RoutesApiRequest
      RoutesApiRequest request = RoutesApiRequest(
        origin: PointLatLng(myLocation.latitude, myLocation.longitude),
        destination: PointLatLng(targetPoint.latitude, targetPoint.longitude),
        travelMode: TravelMode.driving, 
      );

      // 4. Fetch the route using the V2 endpoint
      RoutesApiResponse response = await polylinePoints.getRouteBetweenCoordinatesV2(
        request: request,
      );

      // 5. Convert and extract points
      PolylineResult result = polylinePoints.convertToLegacyResult(response);

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        debugPrint("Error fetching route: ${result.errorMessage}");
        // Fallback to straight line if API fails
        polylineCoordinates = [myLocation, targetPoint];
      }

      // 6. Draw the route on the map
      if (mounted) {
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylineCoordinates, // <-- Using decoded road points
              color: primary,    // Kept your original styling
              width: 5,
              geodesic: true,
            )
          };
          _isRouting = false;
        });
      }

      // 7. Frame the route on the camera
      double minLat = myLocation.latitude < targetPoint.latitude ? myLocation.latitude : targetPoint.latitude;
      double maxLat = myLocation.latitude > targetPoint.latitude ? myLocation.latitude : targetPoint.latitude;
      double minLng = myLocation.longitude < targetPoint.longitude ? myLocation.longitude : targetPoint.longitude;
      double maxLng = myLocation.longitude > targetPoint.longitude ? myLocation.longitude : targetPoint.longitude;
      
      await _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 80.0
      ));

    } catch (e) {
      debugPrint('Routing Error: $e');
      if (mounted) {
        setState(() => _isRouting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to calculate route. Please ensure your location is enabled.')),
        );
      }
    }
  }

  // ==================== INTERACTION ====================

  Future<void> _selectUser(String userId) async {
    setState(() {
      _selectedUserId = userId;
      _polylines.clear(); 
    });
    
    await _updateMapMarkers(); 
    
    final location = _userLocations[userId];
    if (location != null) {
      final targetLat = location['latitude'] as double;
      final targetLng = location['longitude'] as double;

      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(targetLat, targetLng), 17.0
      ));

      if (_myPosition != null && mounted) {
        Geolocator.distanceBetween(
          _myPosition!.latitude, _myPosition!.longitude, 
          targetLat, targetLng
        );

        setState(() {
        });
      }
    }
  }

  void _clearSelection() async {
    widget.onRestoreMenu?.call(); 

    setState(() {
      _selectedUserId = null;
      _polylines.clear();
    });
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

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: 16,
            bottom: _selectedUserId != null 
                ? bottomContentOffset + 240 
                : bottomContentOffset + 160, 
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

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(14.4167, 120.9833), 
        zoom: 12.0,

      ),
      onMapCreated: (controller) {
        _mapController = controller;
        setState(() => _isMapReady = true);
        _updateMapMarkers();
      },
      markers: _markers,
      circles: _circles,
      polylines: _polylines,
      myLocationEnabled: false, 
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onCameraMoveStarted: () => widget.onScroll?.call(true),
      onTap: (_) => _clearSelection(),
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
    final currentUserId = databaseService.currentUserId;
    
    final usersList = _userLocations.values.where((loc) {
       if (loc['userId'] == currentUserId) return false; // ✅ Hide yourself from the carousel

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

    // 1. Calculate Real-Time Distance and Time dynamically
    String distanceText = '...';
    String timeText = '...';

    if (_myPosition != null) {
      double distanceMeters = Geolocator.distanceBetween(
        _myPosition!.latitude, _myPosition!.longitude, 
        location['latitude'] as double, location['longitude'] as double
      );
      
      double distanceKm = distanceMeters / 1000;
      double timeInMinutes = (distanceKm / 30) * 60; // Assumes driving at ~30km/h

      // Format to look exactly like the Caretaker screen
      distanceText = distanceKm < 1 ? '${distanceMeters.toStringAsFixed(0)} m' : '${distanceKm.toStringAsFixed(2)} km';
      timeText = timeInMinutes < 1 ? 'Less than 1 min' : '${timeInMinutes.round()} min';
    }

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
                    // 2. Replace Accuracy with Distance/Time Row
                    Row(
                      children: [
                        Icon(Icons.directions_car, size: 14, color: theme.subtextColor),
                        const SizedBox(width: 4),
                        Text(
                          '$distanceText • $timeText',
                          style: caption.copyWith(color: Colors.blueAccent, fontWeight: FontWeight.bold),
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
                  onPressed: () async {
                    final phone = profile['contactNumber'] ?? profile['phone'] ?? '';
                    if (phone.isNotEmpty) {
                      final Uri url = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch phone dialer.')));
                      }
                    } else {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No contact number available for this user.')));
                    }
                  },
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
                    _drawRouteToUser(LatLng(lat, lng));
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
    if (_markers.isEmpty && _myPosition == null) return;
    
    if (_selectedUserId != null) {
      final loc = _userLocations[_selectedUserId];
      if (loc != null) {
        await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(loc['latitude'], loc['longitude']), 17.0
        ));
      }
    } else {
      double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
      for (var marker in _markers) {
        if (marker.position.latitude < minLat) minLat = marker.position.latitude;
        if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
        if (marker.position.longitude < minLng) minLng = marker.position.longitude;
        if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
      }
      
      if (_markers.length == 1 && _myPosition != null) {
         await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(_myPosition!.latitude, _myPosition!.longitude), 15.0
        ));
      } else {
        await _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 50.0
        ));
      }
    }
  }
}