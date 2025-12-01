// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/models/patient_model.dart';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'dart:async';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'select_patient.dart';

class RealtimeTrackingScreen extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final LocationService locationService;

  const RealtimeTrackingScreen({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData, 
    required this.locationService,
  });

  @override
  State<RealtimeTrackingScreen> createState() => _RealtimeTrackingScreenState();
}

class _RealtimeTrackingScreenState extends State<RealtimeTrackingScreen> {
  PatientModel? _selectedPatient;
  Map<String, dynamic>? _selectedPatientFullData;
  bool _isTracking = false;
  bool _isFullscreen = false;
  String? _caretakerId;
  StreamSubscription? _locationTrackingStream;
  StreamSubscription? _caretakerLocationStream;
  
  Map<String, dynamic>? _currentPatientLocation;
  Map<String, dynamic>? _currentCaretakerLocation;
  
  // OSM Map Controller
  late MapController _mapController;
  bool _isMapReady = false;
  double _currentZoom = 15.0;
  
  // Tracking
  Timer? _pulseTimer;
  bool _isPulseExpanded = false;
  String? _distanceToPatient;
  String? _estimatedTime;
  
  // Road/Route
  RoadInfo? _currentRoute;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _initializeMapController();
    _initializeCaretakerId();
    _requestLocationPermission();
  }

  void _initializeMapController() {
    _mapController = MapController(
      initPosition: GeoPoint(
        latitude: 14.2456,
        longitude: 121.1234,
      ),
      areaLimit: BoundingBox.world(),
    );
  }

  Future<Uint8List?> _createProfileMarker({
    required String? imageUrl,
    required String name,
    required Color borderColor,
    double size = 120.0,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

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
          final response = await http.get(Uri.parse(imageUrl));
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
            _drawDefaultMarkerAvatar(canvas, size, name, borderColor);
          }
        } catch (e) {
          debugPrint('Error loading profile image: $e');
          _drawDefaultMarkerAvatar(canvas, size, name, borderColor);
        }
      } else {
        _drawDefaultMarkerAvatar(canvas, size, name, borderColor);
      }

      // Draw colored border
      final coloredBorderPaint = Paint()
        ..color = borderColor
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

  void _drawDefaultMarkerAvatar(Canvas canvas, double size, String name, Color color) {
    // Draw gradient background
    final rect = Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2 - 10);
    final gradient = ui.Gradient.linear(
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.bottom),
      [color, color.withOpacity(0.7)],
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

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar(
        'Location services are disabled. Please enable them.',
        Icons.location_off,
        error,
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar(
          'Location permissions are denied',
          Icons.location_off,
          error,
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
        'Location permissions are permanently denied',
        Icons.location_off,
        error,
      );
      return;
    }

    _startCaretakerLocationTracking();
  }

  void _startCaretakerLocationTracking() {
    if (_caretakerId == null) return;

    _caretakerLocationStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _currentCaretakerLocation = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        };
      });

      locationTrackingService.updateCaretakerLocation(
        caretakerId: _caretakerId!,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      if (_currentPatientLocation != null) {
        _updateDistance();
      }

      if (_isMapReady && _isTracking) {
        _updateMapMarkers();
      }
    });
  }

  Future<void> _initializeCaretakerId() async {
    String? caretakerId = widget.userData['uid'] as String?;
    
    if (caretakerId == null || caretakerId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      caretakerId = user?.uid;
    }
    
    if (caretakerId == null || caretakerId.isEmpty) {
      setState(() {
      });
      return;
    }

    setState(() {
      _caretakerId = caretakerId;
    });

  }

  @override
  void dispose() {
    _locationTrackingStream?.cancel();
    _caretakerLocationStream?.cancel();
    _pulseTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void onPatientSelected(PatientModel patient) async {
    setState(() {
      _selectedPatient = patient;
      _isTracking = false;
      _currentRoute = null;
    });
    
    _locationTrackingStream?.cancel();
    _pulseTimer?.cancel();
    
    if (_isMapReady) {
      await _mapController.clearAllRoads();
    }

    // Load full patient data including profile image
    final patientData = await databaseService.getUserDataByRole(patient.id, 'visually_impaired');
    if (patientData != null && mounted) {
      setState(() {
        _selectedPatientFullData = patientData;
      });
    }
    
    final location = await locationTrackingService.getPatientLocation(patient.id);
    if (location != null && mounted) {
      setState(() {
        _currentPatientLocation = location;
      });
      
      await _updateMapLocation(location);
      _updateDistance();
    } else {
      if (mounted) {
        _showSnackBar(
          'Location not available for ${patient.name}',
          Icons.location_off_rounded,
          error,
        );
      }
    }
  }

  Future<void> _updateMapLocation(Map<String, dynamic> location) async {
    if (!_isMapReady) return;
    
    final lat = location['latitude'] as double;
    final lng = location['longitude'] as double;
    final geoPoint = GeoPoint(latitude: lat, longitude: lng);
    
    try {
      await _updateMapMarkers();
      await _mapController.moveTo(geoPoint, animate: true);
    } catch (e) {
      debugPrint('Error updating map location: $e');
    }
  }

  Future<void> _updateMapMarkers() async {
    if (!_isMapReady) return;

    try {
      await _mapController.clearAllRoads();

      // Add patient marker with profile picture
      if (_currentPatientLocation != null && _selectedPatient != null) {
        final patientGeo = GeoPoint(
          latitude: _currentPatientLocation!['latitude'] as double,
          longitude: _currentPatientLocation!['longitude'] as double,
        );

        // Get patient profile image
        final patientImageUrl = _selectedPatientFullData?['profileImageUrl'] as String?;
        final patientMarkerBytes = await _createProfileMarker(
          imageUrl: patientImageUrl,
          name: _selectedPatient!.name,
          borderColor: primary,
        );

        if (patientMarkerBytes != null) {
          await _mapController.addMarker(
            patientGeo,
            markerIcon: MarkerIcon(
              iconWidget: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: MemoryImage(patientMarkerBytes),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        } else {
          // Fallback to icon marker
          await _mapController.addMarker(
            patientGeo,
            markerIcon: MarkerIcon(
              icon: Icon(
                Icons.person_pin_circle,
                color: primary,
                size: 48,
              ),
            ),
          );
        }

        if (_isTracking) {
          await _mapController.drawCircle(
            CircleOSM(
              key: 'patient_circle',
              centerPoint: patientGeo,
              radius: _isPulseExpanded ? 80.0 : 40.0,
              color: primary.withOpacity(0.2),
              strokeWidth: 2,
            ),
          );
        }
      }

      // Add caretaker marker with profile picture
      if (_currentCaretakerLocation != null) {
        final caretakerGeo = GeoPoint(
          latitude: _currentCaretakerLocation!['latitude'] as double,
          longitude: _currentCaretakerLocation!['longitude'] as double,
        );

        // Get caretaker profile image
        final caretakerImageUrl = widget.userData['profileImageUrl'] as String?;
        final caretakerName = widget.userData['name'] ?? 'You';
        final caretakerMarkerBytes = await _createProfileMarker(
          imageUrl: caretakerImageUrl,
          name: caretakerName,
          borderColor: Colors.blue,
        );

        if (caretakerMarkerBytes != null) {
          await _mapController.addMarker(
            caretakerGeo,
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
        } else {
          // Fallback to icon marker
          await _mapController.addMarker(
            caretakerGeo,
            markerIcon: MarkerIcon(
              icon: Icon(
                Icons.my_location_rounded,
                color: Colors.blue,
                size: 40,
              ),
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('Error updating markers: $e');
    }
  }

  void _updateDistance() {
    if (_currentPatientLocation == null || _currentCaretakerLocation == null) {
      return;
    }

    final distance = locationTrackingService.calculateDistance(
      lat1: _currentCaretakerLocation!['latitude'] as double,
      lon1: _currentCaretakerLocation!['longitude'] as double,
      lat2: _currentPatientLocation!['latitude'] as double,
      lon2: _currentPatientLocation!['longitude'] as double,
    );

    // Estimate time (assuming average walking speed of 5 km/h)
    final timeInMinutes = (distance / 1000) / 5 * 60;

    setState(() {
      _distanceToPatient = locationTrackingService.formatDistance(distance);
      _estimatedTime = timeInMinutes < 1 
          ? 'Less than 1 min'
          : '${timeInMinutes.round()} min';
    });
  }

  void _startPulseAnimation() {
    _pulseTimer?.cancel();
    _pulseTimer = Timer.periodic(Duration(milliseconds: 1500), (timer) {
      if (mounted && _isTracking && _currentPatientLocation != null) {
        setState(() {
          _isPulseExpanded = !_isPulseExpanded;
        });
        _updateMapMarkers();
      }
    });
  }

  void _toggleTracking() async {
    if (_selectedPatient == null) return;
    
    setState(() {
      _isTracking = !_isTracking;
    });
    
    if (_isTracking) {
      _startPulseAnimation();
      await _drawRoute();
      
      _locationTrackingStream = locationTrackingService
          .trackPatientLocation(_selectedPatient!.id)
          .listen((location) async {
        if (location != null && mounted) {
          setState(() {
            _currentPatientLocation = location;
          });
          _updateDistance();
          await _updateMapMarkers();
          
          if (_currentRoute == null || 
              DateTime.now().difference(DateTime.parse(location['timestamp'])).inMinutes > 2) {
            await _drawRoute();
          }
        }
      });
      
      _showSnackBar(
        'Real-time tracking started for ${_selectedPatient?.name}',
        Icons.my_location_rounded,
        Colors.green,
      );
    } else {
      _locationTrackingStream?.cancel();
      _pulseTimer?.cancel();
      
      if (_isMapReady) {
        await _mapController.clearAllRoads();
        await _updateMapMarkers();
      }
      
      _showSnackBar(
        'Tracking stopped',
        Icons.location_off_rounded,
        grey,
      );
    }
  }

  Future<void> _drawRoute() async {
    if (!_isMapReady || 
        _currentPatientLocation == null || 
        _currentCaretakerLocation == null) {
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final start = GeoPoint(
        latitude: _currentCaretakerLocation!['latitude'] as double,
        longitude: _currentCaretakerLocation!['longitude'] as double,
      );

      final end = GeoPoint(
        latitude: _currentPatientLocation!['latitude'] as double,
        longitude: _currentPatientLocation!['longitude'] as double,
      );

      final route = await _mapController.drawRoad(
        start,
        end,
        roadType: RoadType.car,
        roadOption: RoadOption(
          roadWidth: 8.0,
          roadColor: primary,
          roadBorderWidth: 2.0,
          roadBorderColor: Colors.white,
        ),
      );

      setState(() {
        _currentRoute = route;
        _isLoadingRoute = false;
      });

      debugPrint('✅ Route drawn successfully');
    } catch (e) {
      debugPrint('❌ Error drawing route: $e');
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _centerOnPatient() async {
    if (_currentPatientLocation != null && _isMapReady) {
      final geoPoint = GeoPoint(
        latitude: _currentPatientLocation!['latitude'] as double,
        longitude: _currentPatientLocation!['longitude'] as double,
      );
      
      await _mapController.moveTo(geoPoint, animate: true);
      
      _showSnackBar(
        'Centered on patient location',
        Icons.center_focus_strong_rounded,
        accent,
      );
    }
  }

  Future<void> _centerOnCaretaker() async {
    if (_currentCaretakerLocation != null && _isMapReady) {
      final geoPoint = GeoPoint(
        latitude: _currentCaretakerLocation!['latitude'] as double,
        longitude: _currentCaretakerLocation!['longitude'] as double,
      );
      
      await _mapController.moveTo(geoPoint, animate: true);
      
      _showSnackBar(
        'Centered on your location',
        Icons.my_location,
        Colors.blue,
      );
    }
  }

  Future<void> _openGoogleMapsNavigation() async {
    if (_currentPatientLocation == null) {
      _showSnackBar(
        'Patient location not available',
        Icons.error_outline,
        error,
      );
      return;
    }

    final lat = _currentPatientLocation!['latitude'];
    final lng = _currentPatientLocation!['longitude'];
    
    // Google Maps URL for navigation
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar(
        'Could not open navigation',
        Icons.error_outline,
        error,
      );
    }
  }

  Future<void> _zoomIn() async {
    if (!_isMapReady) return;
    if (_currentZoom < 19) {
      setState(() {
        _currentZoom += 1;
      });
      await _mapController.setZoom(zoomLevel: _currentZoom);
    }
  }

  Future<void> _zoomOut() async {
    if (!_isMapReady) return;
    if (_currentZoom > 3) {
      setState(() {
        _currentZoom -= 1;
      });
      await _mapController.setZoom(zoomLevel: _currentZoom);
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  void _showSnackBar(String message, IconData icon, Color backgroundColor) {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: EdgeInsets.only(
          bottom: 80,
          left: spacingMedium,
          right: spacingMedium,
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildProfileAvatar(String? imageUrl, String name, {double size = 40}) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: !hasImage ? primaryGradient : null,
        border: Border.all(color: white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasImage
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        body: Stack(
          children: [
            _buildMapView(fullscreen: true),
            _buildFullscreenControls(),
          ],
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: spacingLarge),
          _buildMapContainer(height),
          SizedBox(height: spacingLarge),
          SelectPatient(
            isDarkMode: widget.isDarkMode,
            theme: widget.theme,
            userData: widget.userData,
            selectedPatient: _selectedPatient,
            onPatientSelected: onPatientSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location Tracking',
                style: h2.copyWith(
                  fontSize: 24,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Monitor patient locations with navigation',
                style: body.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapContainer(double height) {
    return Container(
      height: height * 0.5,
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
        child: _buildMapView(fullscreen: false),
      ),
    );
  }

  Widget _buildMapView({required bool fullscreen}) {
    return Stack(
      children: [
        OSMFlutter(
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
            roadConfiguration: RoadOption(
              roadColor: primary,
              roadWidth: 8.0,
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
            if (isReady && _currentPatientLocation != null) {
              _updateMapMarkers();
            }
          },
        ),
        
        if (_isLoadingRoute)
          Positioned(
            top: fullscreen ? 80 : spacingMedium,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacingMedium,
                  vertical: spacingSmall,
                ),
                decoration: BoxDecoration(
                  color: widget.theme.cardColor,
                  borderRadius: BorderRadius.circular(radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(primary),
                      ),
                    ),
                    SizedBox(width: spacingSmall),
                    Text(
                      'Calculating route...',
                      style: caption.copyWith(
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        if (_selectedPatient != null && !fullscreen)
          _buildPatientInfoOverlay(),
        
        if (_selectedPatient != null)
          fullscreen ? Container() : _buildMapControls(),
        
        _buildZoomControls(fullscreen),
        
        if (_selectedPatient == null && !fullscreen)
          _buildNoPatientMessage(),
      ],
    );
  }

  Widget _buildPatientInfoOverlay() {
    final patientImageUrl = _selectedPatientFullData?['profileImageUrl'] as String?;
    final caretakerImageUrl = widget.userData['profileImageUrl'] as String?;

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
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildProfileAvatar(
                  patientImageUrl,
                  _selectedPatient!.name,
                  size: 45,
                ),
                SizedBox(width: spacingSmall),
                Icon(Icons.arrow_forward, color: widget.theme.subtextColor, size: 20),
                SizedBox(width: spacingSmall),
                _buildProfileAvatar(
                  caretakerImageUrl,
                  widget.userData['name'] ?? 'You',
                  size: 45,
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPatient!.name,
                        style: bodyBold.copyWith(
                          fontSize: 14,
                          color: widget.theme.textColor,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Tracking ${_isTracking ? "Active" : "Paused"}',
                            style: caption.copyWith(
                              fontSize: 12,
                              color: _isTracking ? Colors.green : widget.theme.subtextColor,
                              fontWeight: _isTracking ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_distanceToPatient != null && _estimatedTime != null) ...[
              SizedBox(height: spacingSmall),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacingSmall,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.navigation, size: 14, color: primary),
                    SizedBox(width: 4),
                    Text(
                      '$_distanceToPatient • $_estimatedTime',
                      style: caption.copyWith(
                        fontSize: 12,
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      bottom: spacingMedium,
      left: spacingMedium,
      right: spacingMedium,
      child: Row(
        children: [
          Expanded(
            child: _buildMapActionButton(
              icon: _isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
              label: _isTracking ? 'Stop' : 'Start',
              color: _isTracking ? error : Colors.green,
              onTap: _toggleTracking,
            ),
          ),
          SizedBox(width: spacingSmall),
          Expanded(
            child: _buildMapActionButton(
              icon: Icons.directions_rounded,
              label: 'Navigate',
              color: primary,
              onTap: _openGoogleMapsNavigation,
            ),
          ),
          SizedBox(width: spacingSmall),
          _buildMapActionButton(
            icon: Icons.fullscreen,
            label: '',
            color: accent,
            onTap: _toggleFullscreen,
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls(bool fullscreen) {
    return Positioned(
      right: spacingMedium,
      top: fullscreen ? 80 : spacingMedium + 80,
      child: Column(
        children: [
          _buildZoomButton(Icons.add, _zoomIn),
          SizedBox(height: spacingSmall),
          _buildZoomButton(Icons.remove, _zoomOut),
          SizedBox(height: spacingSmall),
          _buildZoomButton(Icons.my_location, _centerOnCaretaker),
          if (_selectedPatient != null) ...[
            SizedBox(height: spacingSmall),
            _buildZoomButton(Icons.person_pin_circle, _centerOnPatient),
          ],
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return Container(
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
              color: primary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + spacingSmall,
      left: spacingMedium,
      right: spacingMedium,
      child: Row(
        children: [
          _buildMapActionButton(
            icon: Icons.fullscreen_exit,
            label: 'Exit',
            color: grey,
            onTap: _toggleFullscreen,
          ),
          Spacer(),
          if (_selectedPatient != null) ...[
            _buildMapActionButton(
              icon: _isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
              label: _isTracking ? 'Stop' : 'Track',
              color: _isTracking ? error : Colors.green,
              onTap: _toggleTracking,
            ),
            SizedBox(width: spacingSmall),
            _buildMapActionButton(
              icon: Icons.directions_rounded,
              label: 'Navigate',
              color: primary,
              onTap: _openGoogleMapsNavigation,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: white,
          padding: EdgeInsets.symmetric(
            vertical: label.isEmpty ? 12 : 14,
            horizontal: label.isEmpty ? 12 : spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: 0,
        ),
        child: label.isEmpty
            ? Icon(icon, size: 20)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  if (label.isNotEmpty) ...[
                    SizedBox(width: 6),
                    Text(
                      label,
                      style: bodyBold.copyWith(
                        fontSize: 13,
                        color: white,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildNoPatientMessage() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(spacingLarge),
        decoration: BoxDecoration(
          color: widget.theme.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: widget.theme.subtextColor,
            ),
            SizedBox(height: spacingSmall),
            Text(
              'Select a patient to view location',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}