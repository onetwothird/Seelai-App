// File: lib/roles/partially_sighted/home/sections/home_screen/widgets/location_map_widget.dart

import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart'; 
import 'map_marker_helper.dart';

class LocationMapWidget extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final String userId;
  final Map<String, dynamic> userData;
  final bool isFullScreen; 

  const LocationMapWidget({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userId,
    required this.userData,
    this.isFullScreen = false, 
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  late FlutterTts _flutterTts; 

  Map<String, dynamic>? _freshUserData;

  bool _isMapReady = false;
  bool _isLoading = true;
  bool _isTrackingActive = false;
  bool _permissionDenied = false;
  bool _isInitializing = false; 

  Set<Marker> _markers = {};

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  
  Position? _currentPosition;
  
  final double _currentZoom = 17.0; 
  
  Timer? _updateTimer;
  bool _isUpdatingMarkers = false;

  @override
  void initState() {
    super.initState();
    _freshUserData = widget.userData; 
    WidgetsBinding.instance.addObserver(this);
    
    _initializeTts();
    _listenToServiceStatus(); 
    _fetchFreshUserData(); 
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocationTracking();
    });
  }

  Future<void> _fetchFreshUserData() async {
    try {
      final freshData = await databaseService.getUserDataByRole(widget.userId, 'partially_sighted');
      if (freshData != null && mounted) {
        setState(() {
          _freshUserData = freshData;
        });

        if (_isMapReady) {
          _updateMapMarker();
        }
      }
    } catch (e) {
      debugPrint('Error fetching fresh user data: $e');
    }
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
    _updateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isTrackingActive && !_isInitializing) {
        _initializeLocationTracking();
      }
    }
  }

  void _listenToServiceStatus() {
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.enabled) {
        if (!_isTrackingActive && !_isInitializing) {
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

  Future<void> _initializeLocationTracking() async {
    if (_isTrackingActive || _isInitializing) return;
    _isInitializing = true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() { _isLoading = false; _permissionDenied = true; });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() { _isLoading = false; _permissionDenied = true; });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() { _isLoading = false; _permissionDenied = true; });
        return;
      }

      await _startLocationTracking();
    } catch (e) {
      debugPrint('Error initializing location: $e');
      if (mounted) setState(() { _isLoading = false; _permissionDenied = true; });
    } finally {
      _isInitializing = false;
    }
  }

  // ✅ GUARANTEED FAST LOCATION (INDEPENDENT OF CARETAKER)
  Future<void> _startLocationTracking() async {
    _isTrackingActive = true; 

    try {
      // 1. Get Last Known Position immediately for 0-second load time
      Position? startPosition = await Geolocator.getLastKnownPosition();
      
      // 2. If no last known, force a high-accuracy fetch
      if (startPosition == null) {
        try {
          startPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          ).timeout(const Duration(seconds: 3)); 
        } catch (_) {}
      }

      // 3. Show whatever we got instantly!
      if (mounted) {
        setState(() {
          if (startPosition != null) _currentPosition = startPosition;
          _isLoading = false; 
          _permissionDenied = false;
        });

        if (startPosition != null && _isMapReady) {
          await _updateMapMarker();
          await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
             LatLng(startPosition.latitude, startPosition.longitude), _currentZoom
          ));
          _updateFirebaseLocation(startPosition); // Syncs to Firebase in background without blocking UI
        }
      }

      // 4. Start listening to live, high-accuracy GPS in the background
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2, // Reacts to smaller movements now
        ),
      ).listen(
        (Position position) async {
          if (!mounted) return;
          
          // ✅ FIXED: Check if this is the very first time we are getting a location
          bool wasNull = _currentPosition == null; 
          
          setState(() {
            _currentPosition = position;
            _isLoading = false; 
          });

          if (_isMapReady) {
            await _updateMapMarker();
            
            // ✅ FIXED: Animate camera if it's the first time getting a signal
            if (wasNull) {
              await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
                LatLng(position.latitude, position.longitude), _currentZoom
              ));
            }
          }
          _updateFirebaseLocation(position);
        },
        onError: (error) => debugPrint('Position stream error: $error'),
      );

      // 5. Periodically sync with Firebase every 10 seconds
      _updateTimer?.cancel();
      _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (_currentPosition != null && _isTrackingActive && mounted) {
          _updateFirebaseLocation(_currentPosition!);
        }
      });

    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMapMarker() async {
    if (!_isMapReady || _currentPosition == null || !mounted || _isUpdatingMarkers) return;
    _isUpdatingMarkers = true;

    try {
      Set<Marker> newMarkers = {};

      final userLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      
      final String? userImageUrl = _extractImageUrl(_freshUserData ?? widget.userData);
      final String userName = (_freshUserData?['name'] as String?)?.trim() ?? 'You';

      // Marker size exactly 35
      final userMarkerBytes = await MapMarkerHelper.createProfileMarker(
        imageUrl: userImageUrl, name: userName, borderColor: primary, size: 35.0,
      );

      if (userMarkerBytes != null) {
        newMarkers.add(Marker(
          markerId: const MarkerId('user_marker'),
          position: userLatLng,
          icon: BitmapDescriptor.bytes(userMarkerBytes),
          zIndexInt: 2, 
        ));
      }

      if (mounted) {
        setState(() {
          _markers = newMarkers;
        });
      }
    } finally {
      _isUpdatingMarkers = false;
    }
  }

  String? _extractImageUrl(Map<String, dynamic> data) {
    const possibleKeys = ['profileImageUrl', 'profileImage', 'imageUrl', 'photoUrl', 'avatarUrl', 'photo'];
    for (final key in possibleKeys) {
      final val = data[key];
      if (val is String && val.trim().isNotEmpty) return val.trim();
    }
    return null;
  }

  Future<void> _updateFirebaseLocation(Position position) async {
    try {
      await locationTrackingService.updatePatientLocation(
        patientId: widget.userId, latitude: position.latitude, longitude: position.longitude,
        accuracy: position.accuracy, altitude: position.altitude, speed: position.speed, heading: position.heading,
      );
    } catch (_) {}
  }

  Future<void> _centerOnMyLocation() async {
    await _flutterTts.speak('Centering map on your location.');
    if (_currentPosition != null && _mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude), _currentZoom
      ));
    }
  }

  Future<void> _announceCurrentLocationAndContext() async {
    if (_currentPosition == null) {
      await _flutterTts.speak('Scanning for GPS signal. Please wait.');
      return;
    }
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(_currentPosition!.latitude, _currentPosition!.longitude);
      String locationSpeech = "I cannot determine your exact street name.";

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [];
        
        if (place.name != null && place.name!.isNotEmpty && !place.name!.contains('+')) {
          addressParts.add(place.name!);
        } else if (place.street != null && place.street!.isNotEmpty && !place.street!.contains('+')) {
          addressParts.add(place.street!);
        }
        
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);

        if (addressParts.isNotEmpty) {
          locationSpeech = 'You are currently located near ${addressParts.join(', ')}.';
        } else {
          locationSpeech = 'You are in ${place.locality ?? 'an unknown area'}.';
        }
      }

      await _flutterTts.speak(locationSpeech);
      
    } catch (_) {
      await _flutterTts.speak('Your GPS coordinates are active, but I cannot read the street name right now.');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mapStack = Stack(
      children: [
        if (!_permissionDenied) _buildMapView(),
        if (_isLoading) _buildLoadingOverlay()
        else if (_permissionDenied) _buildPermissionDeniedState(),
        if (!_permissionDenied && !_isLoading) _buildControlButtons(),
        
        if (widget.isFullScreen)
          Positioned(top: MediaQuery.of(context).padding.top + 16, left: 16, child: _buildBackButton()),
      ],
    );

    if (widget.isFullScreen) {
      return Scaffold(backgroundColor: widget.isDarkMode ? const Color(0xFF0A0E27) : Colors.white, body: mapStack);
    }

    return Semantics(
      label: 'Your current location map',
      child: Container(
        height: 280, 
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06),
              blurRadius: 20, offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(24), child: mapStack),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1A1F3A).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IconButton(icon: Icon(Icons.arrow_back_rounded, color: widget.theme.textColor), onPressed: () => Navigator.pop(context)),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: widget.isDarkMode ? const Color(0xFF1A1F3A).withValues(alpha: 0.7) : const Color(0xFFF4F4F5).withValues(alpha: 0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40, width: 40, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)), strokeWidth: 3)),
              const SizedBox(height: 16),
              Text('Locating...', style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.textColor, fontSize: 15, letterSpacing: 0.5)),
            ],
          ),
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
            Icon(Icons.location_off_rounded, size: 42, color: widget.theme.subtextColor.withOpacity(0.5)),
            const SizedBox(height: spacingMedium),
            Text('Location Access Denied', style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: spacingMedium),
            ElevatedButton(
              onPressed: () async {
                setState(() { _isLoading = true; _permissionDenied = false; });
                await _initializeLocationTracking();
              },
              style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Enable', style: bodyBold.copyWith(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(14.3167, 120.7667), 
        zoom: 16.0,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        setState(() => _isMapReady = true);
        if (_currentPosition != null) {
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude), _currentZoom
          ));
        }
      },
      markers: _markers,
      myLocationEnabled: false, 
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      right: 12, bottom: widget.isFullScreen ? 24 : 12, 
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), 
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF1A1F3A).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9), 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapAction(icon: Icons.my_location_rounded, onTap: _centerOnMyLocation, tooltip: 'Center on my location', color: primary),
                  _buildDivider(),
                  _buildMapAction(icon: Icons.volume_up_rounded, onTap: _announceCurrentLocationAndContext, tooltip: 'Read current address', color: const Color(0xFF8B5CF6)),
                  _buildDivider(),
                  _buildMapAction(
                    icon: widget.isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, 
                    onTap: () {
                      if (widget.isFullScreen) {
                        Navigator.pop(context); 
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => LocationMapWidget(
                          isDarkMode: widget.isDarkMode, theme: widget.theme, userId: widget.userId, userData: widget.userData, isFullScreen: true, 
                        )));
                      }
                    },
                    tooltip: widget.isFullScreen ? 'Minimize map' : 'Expand map', color: const Color(0xFF8B5CF6), 
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(height: 1, width: 36, color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2));

  Widget _buildMapAction({required IconData icon, required VoidCallback onTap, required String tooltip, required Color color}) {
    return Semantics(
      label: tooltip, button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, splashColor: color.withValues(alpha: 0.1), highlightColor: Colors.transparent,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0), child: Icon(icon, color: color, size: 24)),
        ),
      ),
    );
  }
}