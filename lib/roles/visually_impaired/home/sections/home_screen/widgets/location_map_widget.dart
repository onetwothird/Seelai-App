// File: lib/roles/visually_impaired/home/sections/home_screen/widgets/location_map_widget.dart
// ignore_for_file: prefer_final_fields, deprecated_member_use, empty_catches

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart';
import 'dart:async';
import 'map_marker_helper.dart';

class LocationMapWidget extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final String userId;
  final Map<String, dynamic> userData;

  const LocationMapWidget({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userId,
    required this.userData,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  late MapController _mapController;
  bool _isMapReady = false;
  bool _isLoading = true;
  bool _isTrackingActive = false;
  bool _permissionDenied = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription? _caretakerLocationStream;
  Position? _currentPosition;
  Map<String, dynamic>? _caretakerLocation;
  double _currentZoom = 15.0;
  Timer? _updateTimer;
  Timer? _caretakerCheckTimer;
  bool _showNavigationRoute = false;
  
  static const String _userAccuracyCircleKey = 'user_accuracy_circle';

  // Track last known positions to prevent duplicate updates
  GeoPoint? _lastUserGeoPoint;
  GeoPoint? _lastCaretakerGeoPoint;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocationTracking();
    });
  }

  void _initializeMap() {
    _mapController = MapController(
      initPosition: GeoPoint(
        latitude: 14.4167,
        longitude: 120.9833,
      ),
      areaLimit: BoundingBox.world(),
    );
  }

  Future<void> _initializeLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
        });
        _showSnackBar(
          'Please enable location services in your device settings',
          Icons.location_off,
          Colors.orange,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _permissionDenied = true;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
        });
        _showSnackBar(
          'Location permission permanently denied. Enable in settings.',
          Icons.settings,
          error,
        );
        return;
      }

      await _startLocationTracking();
      
    } catch (e) {
      debugPrint('Error initializing location: $e');
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      // Get initial position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Getting location is taking too long...');
        },
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isTrackingActive = true;
        _isLoading = false;
        _permissionDenied = false;
      });

      await _updateFirebaseLocation(position);
      
      if (_isMapReady) {
        await _updateMapWithBothLocations();
        await _mapController.moveTo(
          GeoPoint(latitude: position.latitude, longitude: position.longitude),
          animate: true,
        );
      }
      
      _startCaretakerLocationListener();
      
      // High-accuracy position stream with distance filter
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5, // Update every 5 meters
          timeLimit: Duration(seconds: 30),
        ),
      ).listen(
        (Position position) async {
          if (!mounted) return;
          
          // Check if position has significantly changed
          if (_hasSignificantChange(_currentPosition, position)) {
            setState(() {
              _currentPosition = position;
            });

            if (_isMapReady) {
              await _updateMapWithBothLocations();
            }

            await _updateFirebaseLocation(position);
          }
        },
        onError: (error) {
          debugPrint('Position stream error: $error');
        },
      );

      // Periodic heartbeat updates
      _updateTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
        if (_currentPosition != null && _isTrackingActive && mounted) {
          await _updateFirebaseLocation(_currentPosition!);
        }
      });

      if (mounted) {
        _showSnackBar(
          'Location tracking active',
          Icons.check_circle,
          Colors.green,
        );
      }
      
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
        });
        _showSnackBar(
          'Could not get your location. Please try again.',
          Icons.error_outline,
          error,
        );
      }
    }
  }

  // Check if position has significantly changed (more than 3 meters)
  bool _hasSignificantChange(Position? oldPos, Position newPos) {
    if (oldPos == null) return true;
    
    double distance = Geolocator.distanceBetween(
      oldPos.latitude,
      oldPos.longitude,
      newPos.latitude,
      newPos.longitude,
    );
    
    return distance > 3.0 || newPos.accuracy < oldPos.accuracy;
  }

  void _startCaretakerLocationListener() {
    final assignedCaretakers = widget.userData['assignedCaretakers'] as Map<dynamic, dynamic>?;
    
    if (assignedCaretakers == null || assignedCaretakers.isEmpty) {
      return;
    }

    final caretakerId = assignedCaretakers.keys.first.toString();

    _caretakerLocationStream = locationTrackingService
        .trackCaretakerLocation(caretakerId)
        .listen((location) async {
      if (location != null && mounted) {
        // Check if caretaker location has significantly changed
        if (_hasCaretakerLocationChanged(location)) {
          setState(() {
            _caretakerLocation = location;
          });

          if (_isMapReady && _currentPosition != null) {
            await _updateMapWithBothLocations();
          }
        }
      }
    });

    _caretakerCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (!mounted) return;
      
      final location = await locationTrackingService.getCaretakerLocation(caretakerId);
      if (location != null && mounted && _hasCaretakerLocationChanged(location)) {
        setState(() {
          _caretakerLocation = location;
        });
        if (_isMapReady && _currentPosition != null) {
          await _updateMapWithBothLocations();
        }
      }
    });
  }

  bool _hasCaretakerLocationChanged(Map<String, dynamic> newLocation) {
    if (_caretakerLocation == null) return true;
    
    final oldLat = _caretakerLocation!['latitude'] as double;
    final oldLng = _caretakerLocation!['longitude'] as double;
    final newLat = newLocation['latitude'] as double;
    final newLng = newLocation['longitude'] as double;
    
    double distance = locationTrackingService.calculateDistance(
      lat1: oldLat,
      lon1: oldLng,
      lat2: newLat,
      lon2: newLng,
    );
    
    return distance > 3.0; // Update if moved more than 3 meters
  }

  Future<void> _updateMapWithBothLocations() async {
    if (!_isMapReady || _currentPosition == null || !mounted) return;

    try {
      final userGeoPoint = GeoPoint(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      // Only update user marker if position has changed significantly
      if (_lastUserGeoPoint == null || 
          _geoPointDistance(_lastUserGeoPoint!, userGeoPoint) > 3.0) {
        
        // Remove existing user marker and circle
        try {
          await _mapController.removeMarker(userGeoPoint);
        } catch (e) {}

        try {
          await _mapController.removeCircle(_userAccuracyCircleKey);
        } catch (e) {}

        // Add user marker
        final userImageUrl = widget.userData['profileImageUrl'] as String?;
        final userName = widget.userData['name'] ?? 'You';
        final userMarkerBytes = await MapMarkerHelper.createProfileMarker(
          imageUrl: userImageUrl,
          name: userName,
          borderColor: primary,
        );
        
        if (userMarkerBytes != null && mounted) {
          await _mapController.addMarker(
            userGeoPoint,
            markerIcon: MarkerIcon(
              iconWidget: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: MemoryImage(userMarkerBytes),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );

          // Add accuracy circle
          await _mapController.drawCircle(
            CircleOSM(
              key: _userAccuracyCircleKey,
              centerPoint: userGeoPoint,
              radius: _currentPosition!.accuracy.clamp(5.0, 100.0),
              color: primary.withOpacity(0.2),
              strokeWidth: 2,
            ),
          );

          _lastUserGeoPoint = userGeoPoint;
        }
      }

      // Update caretaker marker if available and changed
      if (_caretakerLocation != null && mounted) {
        final caretakerGeoPoint = GeoPoint(
          latitude: _caretakerLocation!['latitude'] as double,
          longitude: _caretakerLocation!['longitude'] as double,
        );

        if (_lastCaretakerGeoPoint == null || 
            _geoPointDistance(_lastCaretakerGeoPoint!, caretakerGeoPoint) > 3.0) {
          
          try {
            await _mapController.removeMarker(caretakerGeoPoint);
          } catch (e) {}

          String? caretakerImageUrl;
          final assignedCaretakers = widget.userData['assignedCaretakers'] as Map<dynamic, dynamic>?;
          if (assignedCaretakers != null && assignedCaretakers.isNotEmpty) {
            final firstCaretaker = assignedCaretakers.values.first as Map<dynamic, dynamic>?;
            caretakerImageUrl = firstCaretaker?['profileImageUrl'] as String?;
          }

          final caretakerMarkerBytes = await MapMarkerHelper.createProfileMarker(
            imageUrl: caretakerImageUrl,
            name: 'Caretaker',
            borderColor: Colors.blue,
          );
          
          if (caretakerMarkerBytes != null && mounted) {
            await _mapController.addMarker(
              caretakerGeoPoint,
              markerIcon: MarkerIcon(
                iconWidget: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: MemoryImage(caretakerMarkerBytes),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );

            _lastCaretakerGeoPoint = caretakerGeoPoint;
          }
        }

        // Draw/update route if enabled
        if (_showNavigationRoute && mounted) {
          await _drawNavigationRoute(userGeoPoint, caretakerGeoPoint);
        }
      }
    } catch (e) {
      debugPrint('Error updating map: $e');
    }
  }

  double _geoPointDistance(GeoPoint p1, GeoPoint p2) {
    return locationTrackingService.calculateDistance(
      lat1: p1.latitude,
      lon1: p1.longitude,
      lat2: p2.latitude,
      lon2: p2.longitude,
    );
  }

  Future<void> _drawNavigationRoute(GeoPoint start, GeoPoint end) async {
    try {
      await _mapController.clearAllRoads();
      
      await _mapController.drawRoad(
        start,
        end,
        roadType: RoadType.car,
        roadOption: RoadOption(
          roadWidth: 6.0,
          roadColor: accent,
          roadBorderWidth: 2.0,
          roadBorderColor: Colors.white,
        ),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
    }
  }

  void _toggleNavigationRoute() async {
    setState(() {
      _showNavigationRoute = !_showNavigationRoute;
    });

    if (_showNavigationRoute && _caretakerLocation != null && _currentPosition != null) {
      await _updateMapWithBothLocations();
      
      if (mounted) {
        _showSnackBar(
          'Navigation route shown',
          Icons.directions,
          accent,
        );
      }
    } else {
      await _mapController.clearAllRoads();
      
      if (mounted) {
        _showSnackBar(
          'Navigation route hidden',
          Icons.close,
          grey,
        );
      }
    }
  }

  Future<void> _updateFirebaseLocation(Position position) async {
    try {
      final success = await locationTrackingService.updatePatientLocation(
        patientId: widget.userId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
      );

      if (success) {
        debugPrint('✅ Firebase location updated: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      debugPrint('Error updating Firebase location: $e');
    }
  }

  Future<void> _centerOnMyLocation() async {
    if (_currentPosition != null && _isMapReady) {
      final geoPoint = GeoPoint(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      await _mapController.moveTo(geoPoint, animate: true);
      
      if (mounted) {
        _showSnackBar(
          'Centered on your location',
          Icons.my_location,
          primary,
        );
      }
    }
  }

  Future<void> _forceLocationUpdate() async {
    if (_currentPosition == null) {
      if (mounted) {
        _showSnackBar(
          'Getting current location...',
          Icons.location_searching,
          accent,
        );
      }
      
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        ).timeout(Duration(seconds: 10));
        
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          await _updateMapWithBothLocations();
        }
        await _updateFirebaseLocation(position);
      } catch (e) {
        return;
      }
    } else {
      await _updateFirebaseLocation(_currentPosition!);
    }

    if (mounted) {
      _showSnackBar(
        'Location updated and shared',
        Icons.check_circle,
        Colors.green,
      );
    }
  }

  void _showSnackBar(String message, IconData icon, Color backgroundColor) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: white, size: 20),
            SizedBox(width: spacingSmall),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _caretakerLocationStream?.cancel();
    _updateTimer?.cancel();
    _caretakerCheckTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your current location map',
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: widget.isDarkMode
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.2),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ]
              : softShadow,
          border: widget.isDarkMode
              ? Border.all(color: primary.withOpacity(0.3), width: 2)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radiusLarge),
          child: Stack(
            children: [
              if (_isLoading)
                _buildLoadingState()
              else if (_permissionDenied)
                _buildPermissionDeniedState()
              else
                _buildMapView(),

              if (_isTrackingActive && _currentPosition != null && !_permissionDenied)
                _buildTrackingStatusOverlay(),

              if (!_permissionDenied && !_isLoading)
                _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: widget.theme.cardColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
            SizedBox(height: spacingMedium),
            Text(
              'Getting your location...',
              style: body.copyWith(
                color: widget.theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              'This may take a few moments',
              style: caption.copyWith(
                color: widget.theme.subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState() {
    return Container(
      color: widget.theme.cardColor,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(spacingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: widget.theme.subtextColor,
              ),
              SizedBox(height: spacingMedium),
              Text(
                'Location Access Required',
                style: bodyBold.copyWith(
                  color: widget.theme.textColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacingSmall),
              Text(
                'Please enable location permissions to use this feature',
                style: body.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacingMedium),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                    _permissionDenied = false;
                  });
                  await _initializeLocationTracking();
                },
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: white,
                  padding: EdgeInsets.symmetric(
                    horizontal: spacingLarge,
                    vertical: spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return OSMFlutter(
      controller: _mapController,
      osmOption: OSMOption(
        userTrackingOption: UserTrackingOption(
          enableTracking: false,
          unFollowUser: true,
        ),
        zoomOption: ZoomOption(
          initZoom: _currentZoom,
          minZoomLevel: 3,
          maxZoomLevel: 19,
          stepZoom: 1.0,
        ),
        staticPoints: [],
        enableRotationByGesture: true,
        showZoomController: false,
        showDefaultInfoWindow: false,
      ),
      onMapIsReady: (isReady) async {
        if (!mounted) return;
        
        setState(() {
          _isMapReady = isReady;
        });
        
        if (isReady && _currentPosition != null) {
          await Future.delayed(Duration(milliseconds: 300));
          if (mounted) {
            await _updateMapWithBothLocations();
          }
        }
      },
    );
  }

  Widget _buildTrackingStatusOverlay() {
    return Positioned(
      top: spacingMedium,
      left: spacingMedium,
      right: spacingMedium,
      child: Container(
        padding: EdgeInsets.all(spacingMedium),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.theme.cardColor,
              widget.theme.cardColor.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: spacingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Location Tracking',
                    style: bodyBold.copyWith(
                      fontSize: 13,
                      color: widget.theme.textColor,
                    ),
                  ),
                  Text(
                    _caretakerLocation != null 
                        ? 'Caretaker location visible'
                        : 'Waiting for caretaker location...',
                    style: caption.copyWith(
                      fontSize: 11,
                      color: widget.theme.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      right: spacingMedium,
      bottom: spacingMedium,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.my_location,
            onTap: _centerOnMyLocation,
            tooltip: 'Center on my location',
          ),
          SizedBox(height: spacingSmall),
          if (_caretakerLocation != null)
            _buildControlButton(
              icon: _showNavigationRoute ? Icons.close : Icons.directions,
              onTap: _toggleNavigationRoute,
              tooltip: _showNavigationRoute ? 'Hide route' : 'Show route to caretaker',
              color: _showNavigationRoute ? error : accent,
            ),
          SizedBox(height: spacingSmall),
          _buildControlButton(
            icon: Icons.refresh,
            onTap: _forceLocationUpdate,
            tooltip: 'Update location now',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? color,
  }) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Container(
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                icon,
                color: color ?? primary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}