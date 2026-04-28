import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patient_model.dart';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:ui' as ui;

import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/widgets/map_marker_helper.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patient_location/select_patient.dart';

class RealtimeTrackingScreen extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final LocationService locationService;
  
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
  Map<String, dynamic>? _caretakerFullData; 
  
  bool _isTracking = false;
  String? _caretakerId;
  StreamSubscription? _locationTrackingStream;
  StreamSubscription? _caretakerLocationStream;
  
  Map<String, dynamic>? _currentPatientLocation;
  Map<String, dynamic>? _currentCaretakerLocation;
  
  GoogleMapController? _mapController;
  final FlutterTts _flutterTts = FlutterTts();

  bool _isMapReady = false;
  
  Timer? _pulseTimer;
  bool _isPulseExpanded = false;
  String? _distanceToPatient;
  String? _estimatedTime;
  bool _isLoadingRoute = false;

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};
  bool _isUpdatingMarkers = false;

  final double bottomContentOffset = 100.0;

  @override
  void initState() {
    super.initState();
    _initializeCaretakerId();
    _initTTS();
    _requestLocationPermission();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async => await _flutterTts.speak(text);

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    _startCaretakerLocationTracking();
  }

  Future<void> _startCaretakerLocationTracking() async {
    if (_caretakerId == null) return;
    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
      );
      if (mounted) {
        setState(() {
          _currentCaretakerLocation = {'latitude': initialPosition.latitude, 'longitude': initialPosition.longitude, 'accuracy': initialPosition.accuracy};
        });
        if (_isMapReady) await _updateMapMarkers();
      }
    } catch (_) {}

    _caretakerLocationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 2),
    ).listen((Position position) async {
      final newLocation = {'latitude': position.latitude, 'longitude': position.longitude, 'accuracy': position.accuracy};

      if (_hasCaretakerLocationChanged(newLocation)) {
        setState(() => _currentCaretakerLocation = newLocation);
        await locationTrackingService.updateCaretakerLocation(
          caretakerId: _caretakerId!, latitude: position.latitude, longitude: position.longitude, accuracy: position.accuracy,
        );
        if (_currentPatientLocation != null) _updateDistance();
        if (_isMapReady && _isTracking) {
           await _updateMapMarkers();
           await _drawRoute(); 
        }
      }
    });
  }

  bool _hasCaretakerLocationChanged(Map<String, dynamic> newLocation) {
    if (_currentCaretakerLocation == null) return true;
    double distance = locationTrackingService.calculateDistance(
      lat1: _currentCaretakerLocation!['latitude'] as double, lon1: _currentCaretakerLocation!['longitude'] as double,
      lat2: newLocation['latitude'] as double, lon2: newLocation['longitude'] as double,
    );
    return distance > 1.5; 
  }

  Future<void> _initializeCaretakerId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      setState(() => _caretakerId = user.uid);
      final freshData = await databaseService.getUserDataByRole(user.uid, 'caretaker');
      if (freshData != null && mounted) {
        setState(() => _caretakerFullData = freshData);
        if (_isMapReady) _updateMapMarkers(); 
      }
    }
  }

  @override
  void dispose() {
    _locationTrackingStream?.cancel();
    _caretakerLocationStream?.cancel();
    _pulseTimer?.cancel();
    _mapController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void onPatientSelected(PatientModel patient) async {
    setState(() {
      _selectedPatient = patient;
      _isTracking = true; 
    });
    
    _locationTrackingStream?.cancel();
    _pulseTimer?.cancel();
    
    final patientData = await databaseService.getUserDataByRole(patient.id, 'partially_sighted');
    if (patientData != null && mounted) setState(() => _selectedPatientFullData = patientData);
    
    final location = await locationTrackingService.getPatientLocation(patient.id);
    if (location != null && mounted) {
      setState(() => _currentPatientLocation = location);
      _updateDistance();
      await _updateMapMarkers();
      await _drawRoute(frameRoute: true);
    } else {
      if (mounted) _speak('Location is currently not available for ${patient.name}.');
    }

    _startPulseAnimation();
    
    _locationTrackingStream = locationTrackingService.trackPatientLocation(patient.id).listen((loc) async {
      if (loc != null && mounted) {
        if (_hasPatientLocationChanged(loc)) {
          setState(() => _currentPatientLocation = loc);
          _updateDistance();
          await _updateMapMarkers();
          await _drawRoute(frameRoute: false); // Draw lines without zooming wildly
        }
      }
    });
    _speak('Tracking started for ${patient.name}.');
  }

  void _clearSelection() async {
    widget.onRestoreMenu?.call();
    _locationTrackingStream?.cancel();
    _pulseTimer?.cancel();
    
    setState(() {
      _selectedPatient = null;
      _isTracking = false;
      _currentPatientLocation = null;
      _distanceToPatient = null;
      _estimatedTime = null;
      _isPulseExpanded = false;
      _polylines.clear();
    });
    
    _speak('Tracking stopped.');
    await _updateMapMarkers();
  }

  Future<void> _updateMapMarkers() async {
    if (!_isMapReady || _isUpdatingMarkers) return;
    _isUpdatingMarkers = true;

    try {
      Set<Marker> newMarkers = {};

      if (_currentPatientLocation != null && _selectedPatient != null && _isTracking) {
        final patientLatLng = LatLng(_currentPatientLocation!['latitude'] as double, _currentPatientLocation!['longitude'] as double);
        final patientImageUrl = _selectedPatientFullData?['profileImageUrl'] as String?;
        
        final markerBytes = await MapMarkerHelper.createProfileMarker(
          imageUrl: patientImageUrl, name: _selectedPatient!.name, borderColor: primary, size: 35.0
        );

        if (markerBytes != null) {
          newMarkers.add(Marker(
            markerId: const MarkerId('patient'), position: patientLatLng, icon: BitmapDescriptor.bytes(markerBytes), zIndexInt: 2, 
          ));
          // REMOVED: patient_pulse Circle code from here
        }
      }

      if (_currentCaretakerLocation != null) {
        final caretakerLatLng = LatLng(_currentCaretakerLocation!['latitude'] as double, _currentCaretakerLocation!['longitude'] as double);
        final caretakerImageUrl = _caretakerFullData?['profileImageUrl'] as String? ?? widget.userData['profileImageUrl'] as String?;
            
        final markerBytes = await MapMarkerHelper.createProfileMarker(
          imageUrl: caretakerImageUrl, name: widget.userData['name'] ?? 'You', borderColor: Colors.blueAccent, size: 35.0
        );

        if (markerBytes != null) {
          newMarkers.add(Marker(
            markerId: const MarkerId('caretaker'), position: caretakerLatLng, icon: BitmapDescriptor.bytes(markerBytes), zIndexInt: 1, 
          ));
        }
      }

      if (mounted) {
        setState(() { 
        _markers = newMarkers; 
        _circles = {}; // Ensure circles are cleared
      });
      }
    } finally {
      _isUpdatingMarkers = false;
    }
  }

  bool _hasPatientLocationChanged(Map<String, dynamic> newLocation) {
    if (_currentPatientLocation == null) return true;
    double distance = locationTrackingService.calculateDistance(
      lat1: _currentPatientLocation!['latitude'] as double, lon1: _currentPatientLocation!['longitude'] as double,
      lat2: newLocation['latitude'] as double, lon2: newLocation['longitude'] as double,
    );
    return distance > 1.5; 
  }

  void _updateDistance() {
    if (_currentPatientLocation == null || _currentCaretakerLocation == null) return;
    final distance = locationTrackingService.calculateDistance(
      lat1: _currentCaretakerLocation!['latitude'] as double, lon1: _currentCaretakerLocation!['longitude'] as double,
      lat2: _currentPatientLocation!['latitude'] as double, lon2: _currentPatientLocation!['longitude'] as double,
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

  Future<void> _drawRoute({bool frameRoute = true}) async {
    if (!_isMapReady || _currentPatientLocation == null || _currentCaretakerLocation == null) return;
    if (_isLoadingRoute) return;
    
    setState(() => _isLoadingRoute = true);

    try {
      final start = LatLng(_currentCaretakerLocation!['latitude'] as double, _currentCaretakerLocation!['longitude'] as double);
      final end = LatLng(_currentPatientLocation!['latitude'] as double, _currentPatientLocation!['longitude'] as double);

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [start, end],
            color: primary, width: 6, geodesic: true,
          )
        };
      });

      if (frameRoute) {
        double minLat = start.latitude < end.latitude ? start.latitude : end.latitude;
        double maxLat = start.latitude > end.latitude ? start.latitude : end.latitude;
        double minLng = start.longitude < end.longitude ? start.longitude : end.longitude;
        double maxLng = start.longitude > end.longitude ? start.longitude : end.longitude;
        
        await _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 80.0
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _centerOnPatient() async {
    if (_currentPatientLocation != null && _isMapReady) {
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(_currentPatientLocation!['latitude'] as double, _currentPatientLocation!['longitude'] as double), 17.0
      ));
      _speak('Centered on patient.');
    }
  }

  Future<void> _centerOnCaretaker() async {
    if (_currentCaretakerLocation != null && _isMapReady) {
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(_currentCaretakerLocation!['latitude'] as double, _currentCaretakerLocation!['longitude'] as double), 17.0
      ));
      _speak('Centered on your location.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          Positioned(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16, child: _buildGlassTopBar(theme)),
          Positioned(
            right: 16, bottom: _selectedPatient != null ? 310.0 : 380.0, 
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
          Positioned(
            left: 0, right: 0, bottom: 0, 
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(anim), child: child,
              ),
              child: _selectedPatient != null
                  ? Padding(padding: const EdgeInsets.only(bottom: 140.0), child: _buildDetailCard(theme))
                  : _buildPatientSelectionPanel(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(14.2456, 121.1234), zoom: 17.0,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        setState(() => _isMapReady = true);
      },
      markers: _markers,
      circles: _circles,
      polylines: _polylines,
      myLocationEnabled: false, 
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onCameraMoveStarted: () => widget.onScroll?.call(true),
      onTap: (_) => widget.onRestoreMenu?.call(),
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
            color: widget.isDarkMode ? theme.cardColor.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
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
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isLoadingRoute)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primary)),
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
          child: IconButton(icon: Icon(icon, color: primary), onPressed: onTap),
        ),
      ),
    );
  }

  Widget _buildPatientSelectionPanel(dynamic theme) {
    return Container(
      height: 260.0 + bottomContentOffset, 
      padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: bottomContentOffset),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? theme.cardColor.withOpacity(0.95) : Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: SingleChildScrollView(
        child: SelectPatient(
          isDarkMode: widget.isDarkMode, theme: theme, userData: widget.userData,
          selectedPatient: _selectedPatient, onPatientSelected: onPatientSelected,
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
        color: theme.cardColor, borderRadius: BorderRadius.circular(24),
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
                  shape: BoxShape.circle, color: primary.withValues(alpha: 0.1),
                  image: (imgUrl != null && imgUrl.isNotEmpty) ? DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover) : null,
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
                    Text(_selectedPatient!.name, style: h3.copyWith(color: theme.textColor, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.directions_car, size: 14, color: theme.subtextColor), const SizedBox(width: 4),
                        Text('${_distanceToPatient ?? '...'} • ${_estimatedTime ?? '...'}', style: caption.copyWith(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: _clearSelection, icon: Icon(Icons.close, color: theme.subtextColor), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _drawRoute(frameRoute: true), 
              icon: const Icon(Icons.route, size: 18), label: const Text('Focus on Route'),
              style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
            ),
          ),
        ],
      ),
    );
  }
}