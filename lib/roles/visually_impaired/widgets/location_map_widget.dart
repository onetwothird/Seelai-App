// File: lib/roles/visually_impaired/widgets/location_map_widget.dart
// ignore_for_file: prefer_final_fields, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

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
  bool _isTrackingActive = false;
  bool _isInitializing = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription? _caretakerLocationStream;
  Position? _currentPosition;
  Map<String, dynamic>? _caretakerLocation;
  double _currentZoom = 15.0;
  Timer? _updateTimer;
  Timer? _heartbeatTimer;
  Timer? _caretakerCheckTimer;
  bool _showNavigationRoute = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    // Delay the permission request to avoid overwhelming the system
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        _requestLocationPermissionAndStartTracking();
      }
    });
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

  void _startCaretakerLocationListener() {
    // Get assigned caretakers
    final assignedCaretakers = widget.userData['assignedCaretakers'] as Map<dynamic, dynamic>?;
    
    if (assignedCaretakers == null || assignedCaretakers.isEmpty) {
      debugPrint('No assigned caretakers');
      return;
    }

    // Get first caretaker ID
    final caretakerId = assignedCaretakers.keys.first.toString();
    debugPrint('👂 Listening to caretaker location: $caretakerId');

    // Listen to caretaker location updates
    _caretakerLocationStream = locationTrackingService
        .trackCaretakerLocation(caretakerId)
        .listen((location) async {
      if (location != null && mounted) {
        debugPrint('📍 Caretaker location received: ${location['latitude']}, ${location['longitude']}');
        setState(() {
          _caretakerLocation = location;
        });

        if (_isMapReady && _currentPosition != null) {
          await _updateMapWithBothLocations();
        }
      }
    });

    // Periodic check for caretaker location
    _caretakerCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (mounted) {
        final location = await locationTrackingService.getCaretakerLocation(caretakerId);
        if (location != null) {
          debugPrint('🔄 Periodic caretaker location check: ${location['latitude']}, ${location['longitude']}');
          setState(() {
            _caretakerLocation = location;
          });
          if (_isMapReady && _currentPosition != null) {
            await _updateMapWithBothLocations();
          }
        }
      }
    });
  }

  Future<Uint8List?> _getProfileImageMarker(String? imageUrl, String name) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = 120.0;

      // Draw shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(size / 2, size / 2 + 4), size / 2 - 8, shadowPaint);

      // Draw white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 5, borderPaint);

      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Try to load network image
        try {
          final response = await http.get(Uri.parse(imageUrl)).timeout(Duration(seconds: 5));
          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(
              response.bodyBytes,
              targetWidth: size.toInt() - 20,
              targetHeight: size.toInt() - 20,
            );
            final frame = await codec.getNextFrame();
            
            // Clip to circle
            final path = Path()
              ..addOval(Rect.fromCircle(
                center: Offset(size / 2, size / 2),
                radius: size / 2 - 10,
              ));
            canvas.clipPath(path);
            
            // Draw image
            canvas.drawImageRect(
              frame.image,
              Rect.fromLTWH(0, 0, frame.image.width.toDouble(), frame.image.height.toDouble()),
              Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2 - 10),
              Paint(),
            );
          } else {
            _drawDefaultAvatar(canvas, size, name);
          }
        } catch (e) {
          debugPrint('Error loading profile image: $e');
          _drawDefaultAvatar(canvas, size, name);
        }
      } else {
        _drawDefaultAvatar(canvas, size, name);
      }

      // Draw colored border (primary color)
      final coloredBorderPaint = Paint()
        ..color = primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 7, coloredBorderPaint);

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error creating marker: $e');
      return null;
    }
  }

  void _drawDefaultAvatar(Canvas canvas, double size, String name) {
    // Draw gradient background
    final rect = Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2 - 10);
    final gradient = ui.Gradient.linear(
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.bottom),
      [primary, primary.withOpacity(0.7)],
    );
    final paint = Paint()..shader = gradient;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 10, paint);

    // Draw initial
    final textPainter = TextPainter(
      text: TextSpan(
        text: name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size / 2 - textPainter.width / 2,
        size / 2 - textPainter.height / 2,
      ),
    );
  }

  Future<Uint8List?> _getCaretakerMarker(String? imageUrl) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = 120.0;

      // Draw shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(size / 2, size / 2 + 4), size / 2 - 8, shadowPaint);

      // Draw white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 5, borderPaint);

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(imageUrl)).timeout(Duration(seconds: 5));
          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(
              response.bodyBytes,
              targetWidth: size.toInt() - 20,
              targetHeight: size.toInt() - 20,
            );
            final frame = await codec.getNextFrame();
            
            // Clip to circle
            final path = Path()
              ..addOval(Rect.fromCircle(
                center: Offset(size / 2, size / 2),
                radius: size / 2 - 10,
              ));
            canvas.clipPath(path);
            
            // Draw image
            canvas.drawImageRect(
              frame.image,
              Rect.fromLTWH(0, 0, frame.image.width.toDouble(), frame.image.height.toDouble()),
              Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2 - 10),
              Paint(),
            );
          } else {
            _drawCaretakerDefaultAvatar(canvas, size);
          }
        } catch (e) {
          debugPrint('Error loading caretaker image: $e');
          _drawCaretakerDefaultAvatar(canvas, size);
        }
      } else {
        _drawCaretakerDefaultAvatar(canvas, size);
      }

      // Draw blue border for caretaker
      final coloredBorderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 7, coloredBorderPaint);

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error creating caretaker marker: $e');
      return null;
    }
  }

  void _drawCaretakerDefaultAvatar(Canvas canvas, double size) {
    // Draw blue gradient background
    final rect = Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2 - 10);
    final gradient = ui.Gradient.linear(
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.bottom),
      [Colors.blue, Colors.blue.shade700],
    );
    final paint = Paint()..shader = gradient;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 10, paint);

    // Draw caretaker icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: '👤',
        style: TextStyle(fontSize: size * 0.4),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        size / 2 - iconPainter.width / 2,
        size / 2 - iconPainter.height / 2,
      ),
    );
  }

  Future<void> _updateMapWithBothLocations() async {
    if (!_isMapReady || _currentPosition == null) return;

    try {
      // Clear existing markers and roads
      await _mapController.clearAllRoads();

      final userGeoPoint = GeoPoint(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      // Add user marker with profile picture
      final userImageUrl = widget.userData['profileImageUrl'] as String?;
      final userName = widget.userData['name'] ?? 'You';
      final userMarkerBytes = await _getProfileImageMarker(userImageUrl, userName);
      
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
      }

      // Add accuracy circle for user
      if (mounted) {
        await _mapController.drawCircle(
          CircleOSM(
            key: 'user_location',
            centerPoint: userGeoPoint,
            radius: _currentPosition!.accuracy,
            color: primary.withOpacity(0.2),
            strokeWidth: 2,
          ),
        );
      }

      // Add caretaker marker if available
      if (_caretakerLocation != null && mounted) {
        final caretakerGeoPoint = GeoPoint(
          latitude: _caretakerLocation!['latitude'] as double,
          longitude: _caretakerLocation!['longitude'] as double,
        );

        // Get caretaker profile image from assigned caretakers
        String? caretakerImageUrl;
        final assignedCaretakers = widget.userData['assignedCaretakers'] as Map<dynamic, dynamic>?;
        if (assignedCaretakers != null && assignedCaretakers.isNotEmpty) {
          final firstCaretaker = assignedCaretakers.values.first as Map<dynamic, dynamic>?;
          caretakerImageUrl = firstCaretaker?['profileImageUrl'] as String?;
        }

        final caretakerMarkerBytes = await _getCaretakerMarker(caretakerImageUrl);
        
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
        }

        // Draw navigation route if enabled
        if (_showNavigationRoute && mounted) {
          await _drawNavigationRoute(userGeoPoint, caretakerGeoPoint);
        }

        // Calculate and display distance
        final distance = locationTrackingService.calculateDistance(
          lat1: _currentPosition!.latitude,
          lon1: _currentPosition!.longitude,
          lat2: _caretakerLocation!['latitude'] as double,
          lon2: _caretakerLocation!['longitude'] as double,
        );
        
        debugPrint('📏 Distance to caretaker: ${locationTrackingService.formatDistance(distance)}');
      }
    } catch (e) {
      debugPrint('❌ Error updating map with both locations: $e');
    }
  }

  Future<void> _drawNavigationRoute(GeoPoint start, GeoPoint end) async {
    try {
      debugPrint('🗺️ Drawing navigation route...');
      
      final route = await _mapController.drawRoad(
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

      debugPrint('✅ Navigation route drawn successfully');
      debugPrint('📏 Distance: ${route.distance ?? 0}km');
      debugPrint('⏱️ Duration: ${route.duration ?? 0}min');
    } catch (e) {
      debugPrint('❌ Error drawing navigation route: $e');
    }
  }

  void _toggleNavigationRoute() async {
    setState(() {
      _showNavigationRoute = !_showNavigationRoute;
    });

    if (_showNavigationRoute && _caretakerLocation != null && _currentPosition != null) {
      await _updateMapWithBothLocations();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.directions, color: white, size: 20),
                SizedBox(width: spacingSmall),
                Text('Navigation route shown'),
              ],
            ),
            backgroundColor: accent,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _mapController.clearAllRoads();
      await _updateMapWithBothLocations();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.close, color: white, size: 20),
                SizedBox(width: spacingSmall),
                Text('Navigation route hidden'),
              ],
            ),
            backgroundColor: grey,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _requestLocationPermissionAndStartTracking() async {
    if (_isInitializing) {
      debugPrint('⚠️ Already initializing location, skipping...');
      return;
    }

    try {
      _isInitializing = true;
      debugPrint('📍 Checking location services...');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLocationEnabled = false;
            _isInitializing = false;
          });
        }
        _showLocationServicesDialog();
        return;
      }

      debugPrint('✅ Location services enabled, checking permissions...');
      
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('🔍 Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Permission denied, requesting...');
        permission = await Geolocator.requestPermission();
        debugPrint('🔍 Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Permission denied by user');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isLocationEnabled = false;
              _isInitializing = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Permission permanently denied');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLocationEnabled = false;
            _isInitializing = false;
          });
        }
        _showOpenSettingsDialog();
        return;
      }

      debugPrint('✅ Location permission granted! Starting tracking...');
      
      // Add delay before starting tracking to prevent overwhelming the system
      await Future.delayed(Duration(milliseconds: 500));
      
      if (mounted) {
        await _startAutomaticLocationTracking();
      }
    } catch (e) {
      debugPrint('❌ Error in permission flow: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLocationEnabled = false;
          _isInitializing = false;
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _startAutomaticLocationTracking() async {
    try {
      debugPrint('🚀 Starting automatic location tracking for user: ${widget.userId}');

      // Get initial position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );

      debugPrint('✅ Initial position obtained: ${position.latitude}, ${position.longitude}');

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocationEnabled = true;
          _isTrackingActive = true;
          _isLoading = false;
        });

        // Wait for map to be ready before updating
        if (_isMapReady) {
          await _updateMapWithBothLocations();
        }

        // Update Firebase location
        await _updateFirebaseLocation(position);
        
        // Start caretaker location listener after successful location tracking
        _startCaretakerLocationListener();
      }

      // Start position stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 30),
        ),
      ).listen(
        (Position position) async {
          if (mounted) {
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
          debugPrint('❌ Position stream error: $error');
        },
      );

      // Periodic update timer
      _updateTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
        if (_currentPosition != null && _isTrackingActive && mounted) {
          await _updateFirebaseLocation(_currentPosition!);
        }
      });

      // Heartbeat timer
      _heartbeatTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
        if (_isTrackingActive && mounted) {
          debugPrint('💚 Heartbeat - Location tracking still active');
          
          if (_currentPosition != null) {
            await _updateFirebaseLocation(_currentPosition!);
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: spacingSmall),
                Expanded(
                  child: Text('Location tracking active - Caretaker can see your location'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error starting automatic tracking: $e');
      if (mounted) {
        setState(() {
          _isLocationEnabled = false;
          _isTrackingActive = false;
          _isLoading = false;
        });
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
        debugPrint('✅ Firebase location update SUCCESS');
      } else {
        debugPrint('❌ Firebase location update FAILED');
      }
    } catch (e) {
      debugPrint('❌ Exception updating Firebase location: $e');
    }
  }

  void _showLocationServicesDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: error),
            SizedBox(width: spacingSmall),
            Text('Location Disabled'),
          ],
        ),
        content: Text(
          'Please enable location services in your device settings to share your location with your caretaker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: white,
            ),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: error),
            SizedBox(width: spacingSmall),
            Text('Permission Required'),
          ],
        ),
        content: Text(
          'Location permission is permanently denied. Please enable it in app settings to share your location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: white,
            ),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _centerOnMyLocation() async {
    if (_currentPosition != null && _isMapReady) {
      final geoPoint = GeoPoint(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      await _mapController.moveTo(geoPoint, animate: true);
      
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

  Future<void> _forceLocationUpdate() async {
    if (_currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Getting current location...'),
            backgroundColor: accent,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(Duration(seconds: 10));
        
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
        await _updateFirebaseLocation(position);
      } catch (e) {
        debugPrint('Error getting current location: $e');
        return;
      }
    } else {
      await _updateFirebaseLocation(_currentPosition!);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: white, size: 20),
              SizedBox(width: spacingSmall),
              Text('Location updated and shared'),
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
    debugPrint('🛑 Disposing location tracking resources...');
    _positionStreamSubscription?.cancel();
    _caretakerLocationStream?.cancel();
    _updateTimer?.cancel();
    _heartbeatTimer?.cancel();
    _caretakerCheckTimer?.cancel();
    _mapController.dispose();
    debugPrint('✅ Location tracking stopped and resources disposed');
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

              if (_isTrackingActive && _currentPosition != null)
                _buildTrackingStatusOverlay(),

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
                'Location Disabled',
                style: bodyBold.copyWith(
                  fontSize: 16,
                  color: widget.theme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacingSmall),
              Text(
                'Enable location to share with your caretaker',
                style: body.copyWith(
                  fontSize: 13,
                  color: widget.theme.subtextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacingLarge),
              ElevatedButton.icon(
                onPressed: _requestLocationPermissionAndStartTracking,
                icon: Icon(Icons.refresh, size: 18),
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
        debugPrint('🗺️ Map ready status: $isReady');
        if (mounted) {
          setState(() {
            _isMapReady = isReady;
          });
          if (isReady && _currentPosition != null) {
            // Add small delay before updating map to prevent overwhelming
            await Future.delayed(Duration(milliseconds: 300));
            if (mounted) {
              await _updateMapWithBothLocations();
            }
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
                  Row(
                    children: [
                      Text(
                        'Location Tracking',
                        style: bodyBold.copyWith(
                          fontSize: 13,
                          color: widget.theme.textColor,
                        ),
                      ),
                    ],
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