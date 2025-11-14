// File: lib/roles/visually_impaired/widgets/location_map_widget.dart
// ignore_for_file: prefer_final_fields, deprecated_member_use


import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/services/location_tracking_service.dart';
import 'dart:async';

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
  bool _isLocationEnabled = false;
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  double _currentZoom = 15.0;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _requestLocationPermission();
  }

  void _initializeMap() {
    _mapController = MapController(
      initPosition: GeoPoint(
        latitude: 14.4167, // Default Philippines center
        longitude: 120.9833,
      ),
      areaLimit: BoundingBox.world(),
    );
  }

  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _isLocationEnabled = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _isLocationEnabled = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _isLocationEnabled = false;
        });
        return;
      }

      // Permission granted, start tracking
      await _startLocationTracking();
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      setState(() {
        _isLoading = false;
        _isLocationEnabled = false;
      });
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      // Get initial position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocationEnabled = true;
          _isLoading = false;
        });

        // Update map to current position
        if (_isMapReady) {
          await _updateMapPosition(position);
        }

        // Update Firebase with current location
        await _updateFirebaseLocation(position);
      }

      // Start listening to position updates
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) async {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });

          if (_isMapReady) {
            await _updateMapPosition(position);
          }

          // Update Firebase
          await _updateFirebaseLocation(position);
        }
      });

      // Also update Firebase every 30 seconds even if position hasn't changed
      _updateTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
        if (_currentPosition != null) {
          await _updateFirebaseLocation(_currentPosition!);
        }
      });
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      if (mounted) {
        setState(() {
          _isLocationEnabled = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateFirebaseLocation(Position position) async {
    try {
      await locationTrackingService.updatePatientLocation(
        patientId: widget.userId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
      );
      debugPrint('✅ Location updated in Firebase for user: ${widget.userId}');
    } catch (e) {
      debugPrint('❌ Error updating location in Firebase: $e');
    }
  }

  Future<void> _updateMapPosition(Position position) async {
    try {
      final geoPoint = GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Update map camera
      await _mapController.moveTo(geoPoint, animate: true);

      // Add/update marker
      await _mapController.changeLocationMarker(
        oldLocation:  geoPoint,
        newLocation: geoPoint,
        markerIcon: MarkerIcon(
          icon: Icon(
            Icons.location_on,
            color: primary,
            size: 48,
          ),
        ),
      );

      // Add circle around user
      await _mapController.drawCircle(
        CircleOSM(
          key: 'user_location',
          centerPoint: geoPoint,
          radius: position.accuracy,
          color: primary.withOpacity(0.2),
          strokeWidth: 2,
        ),
      );
    } catch (e) {
      debugPrint('Error updating map position: $e');
    }
  }

  Future<void> _centerOnMyLocation() async {
    if (_currentPosition != null && _isMapReady) {
      await _updateMapPosition(_currentPosition!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.my_location, color: white, size: 20),
                SizedBox(width: spacingSmall),
                Text('Centered on your location'),
              ],
            ),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareLocationWithCaretaker() async {
    if (_currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location not available'),
            backgroundColor: error,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
          ),
        );
      }
      return;
    }

    // Force update Firebase
    await _updateFirebaseLocation(_currentPosition!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: white, size: 20),
              SizedBox(width: spacingSmall),
              Text('Location shared with caretaker'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _updateTimer?.cancel();
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
              else if (!_isLocationEnabled)
                _buildErrorState()
              else
                _buildMapView(),

              // Location info overlay
              if (_isLocationEnabled && _currentPosition != null)
                _buildLocationInfoOverlay(),

              // Control buttons
              if (_isLocationEnabled)
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
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: widget.theme.cardColor,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(spacingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 64,
                color: error.withOpacity(0.5),
              ),
              SizedBox(height: spacingMedium),
              Text(
                'Location Services Disabled',
                style: bodyBold.copyWith(
                  fontSize: 16,
                  color: widget.theme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacingSmall),
              Text(
                'Please enable location services in your device settings',
                style: body.copyWith(
                  fontSize: 13,
                  color: widget.theme.subtextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacingLarge),
              ElevatedButton.icon(
                onPressed: _requestLocationPermission,
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Retry'),
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
          enableTracking: true,
          unFollowUser: false,
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
      onMapIsReady: (isReady) {
        setState(() {
          _isMapReady = isReady;
        });
        if (isReady && _currentPosition != null) {
          _updateMapPosition(_currentPosition!);
        }
      },
    );
  }

  Widget _buildLocationInfoOverlay() {
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
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade700],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: white,
                size: 20,
              ),
            ),
            SizedBox(width: spacingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Location Tracking Active',
                    style: bodyBold.copyWith(
                      fontSize: 13,
                      color: widget.theme.textColor,
                    ),
                  ),
                  Text(
                    'Your caretaker can see your location',
                    style: caption.copyWith(
                      fontSize: 11,
                      color: widget.theme.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
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
          _buildControlButton(
            icon: Icons.share_location,
            onTap: _shareLocationWithCaretaker,
            tooltip: 'Share location with caretaker',
            color: accent,
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