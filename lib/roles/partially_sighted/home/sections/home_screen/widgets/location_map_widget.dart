// File: lib/roles/visually_impaired/home/sections/home_screen/widgets/location_map_widget.dart

import 'dart:ui'; // ADDED: For frosted glass blur effect
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart'; 
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

class _LocationMapWidgetState extends State<LocationMapWidget> with WidgetsBindingObserver {
  late MapController _mapController;
  late FlutterTts _flutterTts; 

  bool _isMapReady = false;
  bool _isLoading = true;
  bool _isTrackingActive = false;
  bool _permissionDenied = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription? _caretakerLocationStream;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  
  Position? _currentPosition;
  Map<String, dynamic>? _caretakerLocation;
  
  final double _currentZoom = 15.0; 
  
  Timer? _updateTimer;
  Timer? _caretakerCheckTimer;
  
  static const String _userAccuracyCircleKey = 'user_accuracy_circle';

  GeoPoint? _lastUserGeoPoint;
  GeoPoint? _lastCaretakerGeoPoint;
  bool _isUpdatingMarkers = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _initializeTts();
    _initializeMap();
    _listenToServiceStatus(); 
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocationTracking();
    });
  }

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flutterTts.stop(); 
    _serviceStatusStream?.cancel();
    _positionStreamSubscription?.cancel();
    _caretakerLocationStream?.cancel();
    _updateTimer?.cancel();
    _caretakerCheckTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isTrackingActive) {
        _initializeLocationTracking();
      }
    }
  }

  void _listenToServiceStatus() {
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.enabled) {
        if (!_isTrackingActive) {
          if (mounted) {
            setState(() {
               _isLoading = true;
               _permissionDenied = false;
            });
          }
          _initializeLocationTracking();
        }
      }
    });
  }

  void _initializeMap() {
    _mapController = MapController(
      initPosition: GeoPoint(
        latitude: 14.3167,
        longitude: 120.7667,
      ),
      areaLimit: BoundingBox.world(),
    );
  }

  Future<void> _initializeLocationTracking() async {
    if (_isTrackingActive) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _permissionDenied = true;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _permissionDenied = true;
            });
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _permissionDenied = true;
          });
        }
        return;
      }

      await _startLocationTracking();
      
    } catch (e) {
      debugPrint('Error initializing location: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
        });
      }
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      ).timeout(
        const Duration(seconds: 15),
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
      
      _caretakerLocationStream?.cancel();
      _caretakerCheckTimer?.cancel();
      _startCaretakerLocationListener();
      
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3, 
        ),
      ).listen(
        (Position position) async {
          if (!mounted) return;
          
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

      _updateTimer?.cancel();
      _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (_currentPosition != null && _isTrackingActive && mounted) {
          await _updateFirebaseLocation(_currentPosition!);
        }
      });
      
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

  bool _hasSignificantChange(Position? oldPos, Position newPos) {
    if (oldPos == null) return true;
    
    double distance = Geolocator.distanceBetween(
      oldPos.latitude,
      oldPos.longitude,
      newPos.latitude,
      newPos.longitude,
    );
    
    return distance > 2.0 || newPos.accuracy < oldPos.accuracy;
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

    _caretakerCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
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
    
    return distance > 3.0; 
  }

  Future<void> _updateMapWithBothLocations() async {
    if (!_isMapReady || _currentPosition == null || !mounted || _isUpdatingMarkers) return;
    
    _isUpdatingMarkers = true;

    try {
      final userGeoPoint = GeoPoint(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      // --- USER MARKER UPDATE ---
      if (_lastUserGeoPoint == null || 
          _geoPointDistance(_lastUserGeoPoint!, userGeoPoint) > 2.0) { 
        
        if (_lastUserGeoPoint != null) {
          try {
            await _mapController.removeMarker(_lastUserGeoPoint!);
          } catch (e) { debugPrint("User marker removal error: $e"); }
        }

        try {
          await _mapController.removeCircle(_userAccuracyCircleKey);
        } catch (e) {
          debugPrint("Accuracy circle removal error: $e");
        }

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

          await _mapController.drawCircle(
            CircleOSM(
              key: _userAccuracyCircleKey,
              centerPoint: userGeoPoint,
              radius: _currentPosition!.accuracy.clamp(5.0, 50.0),
              color: primary.withValues(alpha: 0.2),
              strokeWidth: 2,
            ),
          );

          _lastUserGeoPoint = userGeoPoint;
        }
      }

      // --- CARETAKER MARKER UPDATE ---
      if (_caretakerLocation != null && mounted) {
        final caretakerGeoPoint = GeoPoint(
          latitude: _caretakerLocation!['latitude'] as double,
          longitude: _caretakerLocation!['longitude'] as double,
        );

        if (_lastCaretakerGeoPoint == null || 
            _geoPointDistance(_lastCaretakerGeoPoint!, caretakerGeoPoint) > 3.0) {
          
          if (_lastCaretakerGeoPoint != null) {
            try {
              await _mapController.removeMarker(_lastCaretakerGeoPoint!);
            } catch (e) { debugPrint("Caretaker marker removal error: $e"); }
          }

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
      }
    } catch (e) {
      debugPrint('Error updating map: $e');
    } finally {
      _isUpdatingMarkers = false;
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
        debugPrint('Firebase location updated: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      debugPrint('Error updating Firebase location: $e');
    }
  }

  void _showSnackBar(String message, IconData icon, Color backgroundColor) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: spacingSmall),
            Expanded(
              child: Text(
                message,
                style: bodyBold.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ==========================================
  // INNOVATIVE TTS LOCATION & CONTEXT AWARENESS
  // ==========================================

  Future<void> _centerOnMyLocation() async {
    await _flutterTts.speak('Centering map on your location.');
    
    if (_currentPosition != null && _isMapReady) {
      final geoPoint = GeoPoint(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      await _mapController.moveTo(geoPoint, animate: true);
    }
  }

  Future<void> _announceCurrentLocationAndContext() async {
    if (_currentPosition == null) {
      await _flutterTts.speak('Scanning for GPS signal. Please wait.');
      return;
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      String locationSpeech = "I cannot determine the exact street name.";
      String displayAddress = "Address unknown";

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [];
        
        if (place.street != null && place.street!.isNotEmpty && !place.street!.contains('+')) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }

        if (addressParts.isNotEmpty) {
          displayAddress = addressParts.join(', ');
          locationSpeech = 'You are currently near $displayAddress.';
        } else {
          locationSpeech = 'You are in ${place.locality ?? 'an unknown area'}.';
        }
      }

      String caretakerSpeech = "";
      if (_caretakerLocation != null) {
        double distance = _geoPointDistance(
          GeoPoint(latitude: _currentPosition!.latitude, longitude: _currentPosition!.longitude),
          GeoPoint(latitude: _caretakerLocation!['latitude'], longitude: _caretakerLocation!['longitude']),
        );
        
        String distanceStr = locationTrackingService.formatDistance(distance);
        caretakerSpeech = " Your caretaker is approximately $distanceStr away.";
      } else {
        caretakerSpeech = " Your caretaker's location is currently unavailable.";
      }

      await _flutterTts.speak(locationSpeech + caretakerSpeech);

      if (mounted) {
        _showSnackBar(
          displayAddress,
          Icons.record_voice_over_rounded,
          const Color(0xFFF59E0B), 
        );
      }

    } catch (e) {
      debugPrint('Geocoding error: $e');
      await _flutterTts.speak('Your GPS coordinates are active, but I cannot read the street name right now.');
    }
  }

  // ==========================================
  // BUILD METHODS
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your current location map',
      // REMOVED: All redundant borders, radii, and shadows that were causing the "box-in-a-box" issue.
      // Now it's just a perfectly sized box that flush-fills the parent card.
      child: SizedBox(
        height: 280, // A highly optimized height for maps inside cards
        width: double.infinity,
        child: Stack(
          children: [
            if (_isLoading)
              _buildLoadingState()
            else if (_permissionDenied)
              _buildPermissionDeniedState()
            else
              _buildMapView(),

            if (!_permissionDenied && !_isLoading)
              _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      // Ensure it matches the map's background seamlessly
      color: widget.isDarkMode ? const Color(0xFF1A1F3A) : const Color(0xFFF4F4F5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primary),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: spacingLarge),
            Text(
              'Locating...',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState() {
    return Container(
      color: widget.isDarkMode ? const Color(0xFF1A1F3A) : const Color(0xFFF4F4F5),
      padding: const EdgeInsets.all(spacingLarge),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 42,
              color: widget.theme.subtextColor.withOpacity(0.5),
            ),
            const SizedBox(height: spacingMedium),
            Text(
              'Location Access Denied',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Required to share location with caretaker.',
              style: caption.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: spacingMedium),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                  _permissionDenied = false;
                });
                await _initializeLocationTracking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: Text(
                'Enable',
                style: bodyBold.copyWith(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return OSMFlutter(
      controller: _mapController,
      osmOption: OSMOption(
        userTrackingOption: const UserTrackingOption(
          enableTracking: false,
          unFollowUser: true,
        ),
        zoomOption: ZoomOption(
          initZoom: _currentZoom,
          minZoomLevel: 3,
          maxZoomLevel: 19,
          stepZoom: 1.0,
        ),
        staticPoints: const [],
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
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            await _updateMapWithBothLocations();
          }
        }
      },
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      right: 12,
      bottom: 12,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // Clean shadow to lift the pill off the map
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Beautiful glassmorphic blur
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDarkMode 
                    ? const Color(0xFF1A1F3A).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.9), // Slightly transparent to let blur show through
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isDarkMode 
                      ? Colors.white.withValues(alpha: 0.1) 
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapAction(
                    icon: Icons.my_location_rounded,
                    onTap: _centerOnMyLocation,
                    tooltip: 'Center on my location',
                    color: primary,
                  ),
                  // A very subtle separator line
                  Container(
                    height: 1,
                    width: 36,
                    color: widget.isDarkMode 
                        ? Colors.white.withValues(alpha: 0.1) 
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                  _buildMapAction(
                    // Changed icon to something that feels more like "Read Aloud"
                    icon: Icons.volume_up_rounded, 
                    onTap: _announceCurrentLocationAndContext,
                    tooltip: 'Read current address',
                    color: const Color(0xFF8B5CF6), // A deep, premium purple instead of harsh orange
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapAction({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    required Color color,
  }) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}