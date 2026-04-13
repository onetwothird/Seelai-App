import 'package:flutter/material.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patient_model.dart';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'dart:async';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// Make sure you have this import path correct
import 'package:seelai_app/roles/caretaker/home/sections/patient_location/select_patient.dart';

class RealtimeTrackingScreen extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final LocationService locationService;
  
  // Callbacks for hiding/showing bottom navigation bar
  final Function(bool isScrollingDown)? onScroll;
  final VoidCallback? onRestoreMenu;

  const RealtimeTrackingScreen({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData, 
    required this.locationService,
    this.onScroll,
    this.onRestoreMenu,
  });

  @override
  State<RealtimeTrackingScreen> createState() => _RealtimeTrackingScreenState();
}

class _RealtimeTrackingScreenState extends State<RealtimeTrackingScreen> with TickerProviderStateMixin {
  PatientModel? _selectedPatient;
  Map<String, dynamic>? _selectedPatientFullData;
  bool _isTracking = false;
  String? _caretakerId;
  StreamSubscription? _locationTrackingStream;
  StreamSubscription? _caretakerLocationStream;
  
  Map<String, dynamic>? _currentPatientLocation;
  Map<String, dynamic>? _currentCaretakerLocation;
  
  late MapController _mapController;
  final FlutterTts _flutterTts = FlutterTts();

  bool _isMapReady = false;
  
  Timer? _pulseTimer;
  bool _isPulseExpanded = false;
  String? _distanceToPatient;
  String? _estimatedTime;
  
  bool _isLoadingRoute = false;

  GeoPoint? _lastPatientGeoPoint;
  GeoPoint? _lastCaretakerGeoPoint;
  bool _isUpdatingMarkers = false;

  final Map<String, Uint8List> _imageCache = {};
  
  // Offset to ensure content stays above the bottom nav bar
  final double bottomContentOffset = 100.0;

  @override
  void initState() {
    super.initState();
    _initializeMapController();
    _initializeCaretakerId();
    _initTTS();
    _requestLocationPermission();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _initializeMapController() {
    _mapController = MapController(
      initPosition: GeoPoint(latitude: 14.2456, longitude: 121.1234),
      areaLimit: BoundingBox.world(),
    );
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _speak('Location services are disabled. Please enable them.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _speak('Location permissions were denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _speak('Location permissions are permanently denied.');
      return;
    }

    _startCaretakerLocationTracking();
  }

  void _startCaretakerLocationTracking() {
    if (_caretakerId == null) return;

    _caretakerLocationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2, 
      ),
    ).listen((Position position) async {
      final newLocation = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };

      if (_hasCaretakerLocationChanged(newLocation)) {
        setState(() {
          _currentCaretakerLocation = newLocation;
        });

        await locationTrackingService.updateCaretakerLocation(
          caretakerId: _caretakerId!,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        );

        if (_currentPatientLocation != null) _updateDistance();
        if (_isMapReady && _isTracking) await _updateMapMarkers();
      }
    });
  }

  bool _hasCaretakerLocationChanged(Map<String, dynamic> newLocation) {
    if (_currentCaretakerLocation == null) return true;
    final oldLat = _currentCaretakerLocation!['latitude'] as double;
    final oldLng = _currentCaretakerLocation!['longitude'] as double;
    final newLat = newLocation['latitude'] as double;
    final newLng = newLocation['longitude'] as double;
    
    double distance = locationTrackingService.calculateDistance(
      lat1: oldLat, lon1: oldLng, lat2: newLat, lon2: newLng,
    );
    return distance > 1.5; 
  }

  Future<void> _initializeCaretakerId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      setState(() => _caretakerId = user.uid);
    }
  }

  @override
  void dispose() {
    _locationTrackingStream?.cancel();
    _caretakerLocationStream?.cancel();
    _pulseTimer?.cancel();
    _mapController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // ==================== AUTO-TRACKING LOGIC ====================

  void onPatientSelected(PatientModel patient) async {
    setState(() {
      _selectedPatient = patient;
      _isTracking = true; // Auto Start Tracking
      _lastPatientGeoPoint = null;
    });
    
    _locationTrackingStream?.cancel();
    _pulseTimer?.cancel();
    
    if (_isMapReady) {
      await _mapController.clearAllRoads();
    }
    
    final patientData = await databaseService.getUserDataByRole(patient.id, 'partially_sighted');
    if (patientData != null && mounted) {
      setState(() => _selectedPatientFullData = patientData);
    }
    
    final location = await locationTrackingService.getPatientLocation(patient.id);
    if (location != null && mounted) {
      setState(() => _currentPatientLocation = location);
      await _updateMapLocation(location);
      _updateDistance();
    } else {
      if (mounted) _speak('Location is currently not available for ${patient.name}.');
    }

    _startPulseAnimation();
    await _drawRoute();
    
    _locationTrackingStream = locationTrackingService
        .trackPatientLocation(patient.id)
        .listen((loc) async {
      if (loc != null && mounted) {
        if (_hasPatientLocationChanged(loc)) {
          setState(() => _currentPatientLocation = loc);
          _updateDistance();
          await _updateMapMarkers();
          
          if (_lastPatientGeoPoint != null) {
            final newPatientGeo = GeoPoint(latitude: loc['latitude'] as double, longitude: loc['longitude'] as double);
            if (_geoPointDistance(_lastPatientGeoPoint!, newPatientGeo) > 5.0) {
              await _drawRoute();
            }
          }
        }
      }
    });
    
    _speak('Tracking started for ${patient.name}.');
  }

  void _clearSelection() async {
    widget.onRestoreMenu?.call();
    _locationTrackingStream?.cancel();
    _pulseTimer?.cancel();
    
    if (_isMapReady) {
      await _mapController.clearAllRoads();
      if (_lastPatientGeoPoint != null) {
        try { await _mapController.removeMarker(_lastPatientGeoPoint!); } catch (_) {}
      }
    }
    
    setState(() {
      _selectedPatient = null;
      _isTracking = false;
      _currentPatientLocation = null;
      _distanceToPatient = null;
      _estimatedTime = null;
      _lastPatientGeoPoint = null;
      _isPulseExpanded = false;
    });
    
    _speak('Tracking stopped.');
    await _updateMapMarkers();
  }

  // ==================== MAP UPDATE LOGIC ====================

  Future<void> _updateMapLocation(Map<String, dynamic> location) async {
    if (!_isMapReady) return;
    final lat = location['latitude'] as double;
    final lng = location['longitude'] as double;
    try {
      await _updateMapMarkers();
      await _mapController.moveTo(GeoPoint(latitude: lat, longitude: lng), animate: true);
    } catch (e) {
      debugPrint('Error updating map location: $e');
    }
  }

  Future<void> _updateMapMarkers() async {
    if (!_isMapReady || _isUpdatingMarkers) return;
    _isUpdatingMarkers = true;

    try {
      // PATIENT MARKER
      if (_currentPatientLocation != null && _selectedPatient != null && _isTracking) {
        final patientGeo = GeoPoint(
          latitude: _currentPatientLocation!['latitude'] as double,
          longitude: _currentPatientLocation!['longitude'] as double,
        );

        bool shouldUpdate = _lastPatientGeoPoint == null || 
            _geoPointDistance(_lastPatientGeoPoint!, patientGeo) > 1.5 || _isTracking; 

        if (shouldUpdate) {
          if (_lastPatientGeoPoint != null) {
            try { await _mapController.removeMarker(_lastPatientGeoPoint!); } catch (_) {}
          }

          final patientImageUrl = _selectedPatientFullData?['profileImageUrl'] as String?;
          Uint8List? imageBytes = await _getImageBytes(patientImageUrl);

          final markerWidget = _buildAvatarMarkerWidget(
            imageBytes: imageBytes,
            name: _selectedPatient!.name,
            ringColor: primary,
            isActive: true,
            isSelected: true,
          );

          if (mounted) {
            await _mapController.addMarker(
              patientGeo,
              markerIcon: MarkerIcon(iconWidget: markerWidget),
            );

            await _mapController.drawCircle(
              CircleOSM(
                key: 'patient_circle',
                centerPoint: patientGeo,
                radius: _isPulseExpanded ? 50.0 : 25.0,
                color: primary.withValues(alpha: 0.2),
                strokeWidth: 2,
              ),
            );

            _lastPatientGeoPoint = patientGeo;
          }
        }
      }

      // CARETAKER MARKER
      if (_currentCaretakerLocation != null) {
        final caretakerGeo = GeoPoint(
          latitude: _currentCaretakerLocation!['latitude'] as double,
          longitude: _currentCaretakerLocation!['longitude'] as double,
        );

        if (_lastCaretakerGeoPoint == null || _geoPointDistance(_lastCaretakerGeoPoint!, caretakerGeo) > 1.5) {
          if (_lastCaretakerGeoPoint != null) {
            try { await _mapController.removeMarker(_lastCaretakerGeoPoint!); } catch (_) {}
          }

          final caretakerImageUrl = widget.userData['profileImageUrl'] as String?;
          Uint8List? careBytes = await _getImageBytes(caretakerImageUrl);

          final markerWidget = _buildAvatarMarkerWidget(
            imageBytes: careBytes,
            name: widget.userData['name'] ?? 'You',
            ringColor: Colors.blueAccent,
            isActive: true,
            isSelected: false,
          );

          if (mounted) {
            await _mapController.addMarker(
              caretakerGeo,
              markerIcon: MarkerIcon(iconWidget: markerWidget),
            );
            _lastCaretakerGeoPoint = caretakerGeo;
          }
        }
      }

    } catch (e) {
      debugPrint('Error updating markers: $e');
    } finally {
      _isUpdatingMarkers = false;
    }
  }

  Future<Uint8List?> _getImageBytes(String? url) async {
    if (url == null || url.isEmpty) return null;
    if (_imageCache.containsKey(url)) return _imageCache[url];
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        _imageCache[url] = response.bodyBytes;
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  Widget _buildAvatarMarkerWidget({
    required Uint8List? imageBytes,
    required String name,
    required Color ringColor,
    required bool isActive,
    required bool isSelected,
  }) {
    final double size = isSelected ? 100.0 : 70.0;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ringColor.withValues(alpha: 0.2),
            border: Border.all(color: ringColor, width: isSelected ? 3 : 2),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: ClipOval(
            child: imageBytes != null
                ? Image.memory(imageBytes, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: ringColor,
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
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.greenAccent[700],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]
              ),
            ),
          ),
      ],
    );
  }

  double _geoPointDistance(GeoPoint p1, GeoPoint p2) {
    return locationTrackingService.calculateDistance(
      lat1: p1.latitude, lon1: p1.longitude, lat2: p2.latitude, lon2: p2.longitude,
    );
  }

  bool _hasPatientLocationChanged(Map<String, dynamic> newLocation) {
    if (_currentPatientLocation == null) return true;
    final oldLat = _currentPatientLocation!['latitude'] as double;
    final oldLng = _currentPatientLocation!['longitude'] as double;
    final newLat = newLocation['latitude'] as double;
    final newLng = newLocation['longitude'] as double;
    
    double distance = locationTrackingService.calculateDistance(
      lat1: oldLat, lon1: oldLng, lat2: newLat, lon2: newLng,
    );
    return distance > 1.5; 
  }

  void _updateDistance() {
    if (_currentPatientLocation == null || _currentCaretakerLocation == null) return;

    final distance = locationTrackingService.calculateDistance(
      lat1: _currentCaretakerLocation!['latitude'] as double,
      lon1: _currentCaretakerLocation!['longitude'] as double,
      lat2: _currentPatientLocation!['latitude'] as double,
      lon2: _currentPatientLocation!['longitude'] as double,
    );

    final timeInMinutes = (distance / 1000) / 5 * 60;

    setState(() {
      _distanceToPatient = locationTrackingService.formatDistance(distance);
      _estimatedTime = timeInMinutes < 1 ? 'Less than 1 min' : '${timeInMinutes.round()} min';
    });
  }

  void _startPulseAnimation() {
    _pulseTimer?.cancel();
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted && _isTracking && _currentPatientLocation != null) {
        setState(() => _isPulseExpanded = !_isPulseExpanded);
        _updateMapMarkers();
      }
    });
  }

  Future<void> _drawRoute() async {
    if (!_isMapReady || _currentPatientLocation == null || _currentCaretakerLocation == null || _isLoadingRoute) return;

    setState(() => _isLoadingRoute = true);

    try {
      final start = GeoPoint(
        latitude: _currentCaretakerLocation!['latitude'] as double,
        longitude: _currentCaretakerLocation!['longitude'] as double,
      );
      final end = GeoPoint(
        latitude: _currentPatientLocation!['latitude'] as double,
        longitude: _currentPatientLocation!['longitude'] as double,
      );

      await _mapController.clearAllRoads();
      await _mapController.drawRoad(
        start, end,
        roadType: RoadType.car,
        roadOption: RoadOption(
          roadWidth: 8.0,
          roadColor: primary,
          zoomInto: true,
        ),
      );
    } catch (e) {
      debugPrint('Error drawing route: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _centerOnPatient() async {
    if (_currentPatientLocation != null && _isMapReady) {
      final geoPoint = GeoPoint(
        latitude: _currentPatientLocation!['latitude'] as double,
        longitude: _currentPatientLocation!['longitude'] as double,
      );
      await _mapController.moveTo(geoPoint, animate: true);
      _speak('Centered on patient.');
    }
  }

  Future<void> _centerOnCaretaker() async {
    if (_currentCaretakerLocation != null && _isMapReady) {
      final geoPoint = GeoPoint(
        latitude: _currentCaretakerLocation!['latitude'] as double,
        longitude: _currentCaretakerLocation!['longitude'] as double,
      );
      await _mapController.moveTo(geoPoint, animate: true);
      _speak('Centered on your location.');
    }
  }

  Future<void> _openGoogleMapsNavigation() async {
    if (_currentPatientLocation == null) {
      _speak('Patient location is currently unavailable.');
      return;
    }
    
    // DEFINE lat AND lng HERE
    final lat = _currentPatientLocation!['latitude'];
    final lng = _currentPatientLocation!['longitude'];
    
    // Inject them into the actual Google Maps URL
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _speak('Could not open navigation app.');
    }
  }

  // ==================== UI BUILDER ====================

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),

          // MSWD Style Glass Top Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildGlassTopBar(theme),
          ),

          // Floating Center Buttons
          Positioned(
            right: 16,
            bottom: _selectedPatient != null ? bottomContentOffset + 180 : bottomContentOffset + 240, 
            child: Column(
              children: [
                if (_selectedPatient != null) ...[
                  _buildGlassButton(icon: Icons.person_pin_circle, onTap: _centerOnPatient, theme: theme),
                  const SizedBox(height: 12),
                ],
                _buildGlassButton(icon: Icons.my_location, onTap: _centerOnCaretaker, theme: theme),
              ],
            ),
          ),

          // Bottom Content Overlay
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
              child: _selectedPatient != null
                  ? _buildDetailCard(theme)
                  : _buildPatientSelectionPanel(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Listener(
      // Passes the drag interaction up to Home Screen to hide the nav bar
      onPointerMove: (event) {
        widget.onScroll?.call(true); 
      },
      child: OSMFlutter(
        controller: _mapController,
        osmOption: const OSMOption(
          userTrackingOption: UserTrackingOption(
            enableTracking: false,
            unFollowUser: true,
          ),
          zoomOption: ZoomOption(
            initZoom: 17.0, 
            minZoomLevel: 3,
            maxZoomLevel: 19,
            stepZoom: 1.0,
          ),
          roadConfiguration: RoadOption(roadColor: primary, roadWidth: 8.0),
          showZoomController: false,
        ),
        onMapIsReady: (isReady) {
          setState(() => _isMapReady = isReady);
        },
        onGeoPointClicked: (point) {
          widget.onRestoreMenu?.call();
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              Icon(_isTracking ? Icons.radar : Icons.map_outlined, color: _isTracking ? Colors.green : primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isTracking ? 'Tracking ${_selectedPatient!.name}' : 'Select Patient to Track',
                  style: h3.copyWith(fontSize: 16, color: theme.textColor, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isLoadingRoute)
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                ),
            ],
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
            icon: Icon(icon, color: primary),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSelectionPanel(dynamic theme) {
    return Container(
      height: 360,
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? theme.cardColor.withOpacity(0.95) : Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: SingleChildScrollView(
        child: SelectPatient(
          isDarkMode: widget.isDarkMode,
          theme: theme,
          userData: widget.userData,
          selectedPatient: _selectedPatient,
          onPatientSelected: onPatientSelected,
        ),
      ),
    );
  }

  Widget _buildDetailCard(dynamic theme) {
    final imgUrl = _selectedPatientFullData?['profileImageUrl'] as String?;

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
                  image: (imgUrl != null && imgUrl.isNotEmpty)
                    ? DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover)
                    : null,
                  color: primary.withValues(alpha: 0.1)
                ),
                child: (imgUrl == null || imgUrl.isEmpty)
                  ? Center(child: Text(_selectedPatient!.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: primary)))
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPatient!.name,
                      style: h3.copyWith(color: theme.textColor, fontSize: 18),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.directions_car, size: 14, color: theme.subtextColor),
                        const SizedBox(width: 4),
                        Text(
                          '${_distanceToPatient ?? '...'} • ${_estimatedTime ?? '...'}',
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openGoogleMapsNavigation,
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('Navigate in Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}