// File: lib/roles/mswd/home/sections/location_track/location_tracking_screen.dart
// ignore_for_file: deprecated_member_use, unnecessary_import, prefer_final_fields, empty_catches

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:seelai_app/firebase/mswd/mswd_location_tracking_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class MswdLocationTrackingScreen extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;

  const MswdLocationTrackingScreen({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
  });

  @override
  State<MswdLocationTrackingScreen> createState() => _MswdLocationTrackingScreenState();
}

class _MswdLocationTrackingScreenState extends State<MswdLocationTrackingScreen> {
  late MapController _mapController;
  bool _isMapReady = false;
  bool _isLoading = true;
  double _currentZoom = 12.0;
  
  StreamSubscription? _locationsStream;
  Map<String, Map<String, dynamic>> _userLocations = {};
  Map<String, Map<String, dynamic>> _userProfiles = {};
  
  String _selectedFilter = 'all'; // 'all', 'patients', 'caretakers'
  bool _showOnlyActive = false;
  
  Timer? _refreshTimer;
  
  // Track last known positions to prevent duplicate updates
  Map<String, GeoPoint> _lastGeoPoints = {};

  @override
  void initState() {
    super.initState();
    _initializeMapController();
    _startLocationTracking();
  }

  void _initializeMapController() {
    _mapController = MapController(
      initPosition: GeoPoint(
        latitude: 14.4167,
        longitude: 120.9833,
      ),
      areaLimit: BoundingBox.world(),
    );
  }

  Future<void> _startLocationTracking() async {
    setState(() {
      _isLoading = true;
    });

    // Start real-time location stream
    _locationsStream = mswdLocationTrackingService
        .streamAllUserLocations()
        .listen((locationsData) async {
      if (!mounted) return;

      Map<String, Map<String, dynamic>> newLocations = {};
      
      // Process patients
      for (var location in locationsData['patients'] ?? []) {
        String userId = location['userId'];
        newLocations[userId] = location;
        
        // Fetch profile if not cached
        if (!_userProfiles.containsKey(userId)) {
          await _fetchUserProfile(userId, 'visually_impaired');
        }
      }
      
      // Process caretakers
      for (var location in locationsData['caretakers'] ?? []) {
        String userId = location['userId'];
        newLocations[userId] = location;
        
        // Fetch profile if not cached
        if (!_userProfiles.containsKey(userId)) {
          await _fetchUserProfile(userId, 'caretaker');
        }
      }

      if (mounted) {
        setState(() {
          _userLocations = newLocations;
          _isLoading = false;
        });

        if (_isMapReady) {
          await _updateMapMarkers();
        }
      }
    });

    // Periodic refresh timer to ensure data stays current
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (!mounted) return;
      await _refreshLocationData();
    });
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
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<void> _refreshLocationData() async {
    // This is called periodically to ensure we have the latest data
    // The stream should handle updates, but this is a fallback
    if (!mounted) return;
    
    try {
      final allLocations = await mswdLocationTrackingService.getAllUserLocations();
      
      Map<String, Map<String, dynamic>> newLocations = {};
      for (var location in allLocations) {
        String userId = location['userId'];
        newLocations[userId] = location;
      }

      if (mounted && newLocations.isNotEmpty) {
        setState(() {
          _userLocations = newLocations;
        });

        if (_isMapReady) {
          await _updateMapMarkers();
        }
      }
    } catch (e) {
      debugPrint('Error refreshing location data: $e');
    }
  }

  Future<void> _updateMapMarkers() async {
    if (!_isMapReady || !mounted) return;

    try {
      // Filter locations based on selected filter
      List<MapEntry<String, Map<String, dynamic>>> filteredLocations = 
          _userLocations.entries.where((entry) {
        String userType = entry.value['userType'] ?? '';
        bool isActive = mswdLocationTrackingService.isLocationRecent(entry.value);
        
        // Apply filters
        if (_showOnlyActive && !isActive) return false;
        
        if (_selectedFilter == 'patients' && userType != 'visually_impaired') {
          return false;
        }
        if (_selectedFilter == 'caretakers' && userType != 'caretaker') {
          return false;
        }
        
        return true;
      }).toList();

      // Update markers for each user
      for (var entry in filteredLocations) {
        String userId = entry.key;
        Map<String, dynamic> location = entry.value;
        
        final lat = location['latitude'] as double?;
        final lng = location['longitude'] as double?;
        
        if (lat == null || lng == null) continue;

        final geoPoint = GeoPoint(latitude: lat, longitude: lng);
        
        // Only update if position changed significantly (more than 5 meters)
        if (_lastGeoPoints.containsKey(userId)) {
          double distance = _geoPointDistance(_lastGeoPoints[userId]!, geoPoint);
          if (distance < 5.0) continue; // Skip if moved less than 5 meters
        }

        // Remove old marker
        if (_lastGeoPoints.containsKey(userId)) {
          try {
            await _mapController.removeMarker(_lastGeoPoints[userId]!);
          } catch (e) {}
        }

        // Get user profile
        final profile = _userProfiles[userId];
        final imageUrl = profile?['profileImageUrl'] as String?;
        final name = profile?['name'] ?? 'User';
        final userType = location['userType'] ?? '';
        
        // Determine marker color
        Color borderColor = userType == 'visually_impaired' ? primary : Colors.blue;
        
        // Check if location is recent (active) or stale
        bool isActive = mswdLocationTrackingService.isLocationRecent(location);
        if (!isActive) {
          borderColor = grey; // Grey for offline/stale locations
        }

        // Create marker
        final markerBytes = await _createProfileMarker(
          imageUrl: imageUrl,
          name: name,
          borderColor: borderColor,
          isActive: isActive,
        );

        if (markerBytes != null && mounted) {
          await _mapController.addMarker(
            geoPoint,
            markerIcon: MarkerIcon(
              iconWidget: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: MemoryImage(markerBytes),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );

          // Add accuracy circle for active locations
          if (isActive) {
            final accuracy = location['accuracy'] as double? ?? 20.0;
            await _mapController.drawCircle(
              CircleOSM(
                key: 'accuracy_$userId',
                centerPoint: geoPoint,
                radius: accuracy.clamp(5.0, 100.0),
                color: borderColor.withOpacity(0.15),
                strokeWidth: 1,
              ),
            );
          }

          _lastGeoPoints[userId] = geoPoint;
        }
      }

      // Remove markers for users no longer in filtered list
      List<String> userIdsToRemove = [];
      for (var userId in _lastGeoPoints.keys) {
        if (!filteredLocations.any((entry) => entry.key == userId)) {
          userIdsToRemove.add(userId);
        }
      }

      for (var userId in userIdsToRemove) {
        try {
          await _mapController.removeMarker(_lastGeoPoints[userId]!);
          await _mapController.removeCircle('accuracy_$userId');
          _lastGeoPoints.remove(userId);
        } catch (e) {}
      }

    } catch (e) {
      debugPrint('Error updating map markers: $e');
    }
  }

  double _geoPointDistance(GeoPoint p1, GeoPoint p2) {
    return mswdLocationTrackingService.calculateDistance(
      lat1: p1.latitude,
      lon1: p1.longitude,
      lat2: p2.latitude,
      lon2: p2.longitude,
    );
  }

  Future<Uint8List?> _createProfileMarker({
    required String? imageUrl,
    required String name,
    required Color borderColor,
    required bool isActive,
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
        try {
          final response = await http.get(Uri.parse(imageUrl)).timeout(Duration(seconds: 5));
          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(
              response.bodyBytes,
              targetWidth: size.toInt() - 20,
              targetHeight: size.toInt() - 20,
            );
            final frame = await codec.getNextFrame();
            
            final path = Path()
              ..addOval(Rect.fromCircle(
                center: Offset(size / 2, size / 2),
                radius: size / 2 - 10,
              ));
            canvas.clipPath(path);
            
            canvas.drawImageRect(
              frame.image,
              Rect.fromLTWH(0, 0, frame.image.width.toDouble(), frame.image.height.toDouble()),
              Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2 - 10),
              Paint()..colorFilter = isActive ? null : ColorFilter.mode(
                Colors.grey.withOpacity(0.5),
                BlendMode.saturation,
              ),
            );
          } else {
            _drawDefaultAvatar(canvas, size, name, borderColor, isActive);
          }
        } catch (e) {
          _drawDefaultAvatar(canvas, size, name, borderColor, isActive);
        }
      } else {
        _drawDefaultAvatar(canvas, size, name, borderColor, isActive);
      }

      // Draw colored border
      final coloredBorderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 7, coloredBorderPaint);

      // Draw status indicator
      final statusColor = isActive ? Colors.green : Colors.red;
      final statusPaint = Paint()..color = statusColor;
      canvas.drawCircle(
        Offset(size - 15, size - 15),
        8,
        statusPaint,
      );
      final statusBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        Offset(size - 15, size - 15),
        8,
        statusBorderPaint,
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error creating marker: $e');
      return null;
    }
  }

  void _drawDefaultAvatar(Canvas canvas, double size, String name, Color color, bool isActive) {
    final rect = Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2 - 10);
    final gradient = ui.Gradient.linear(
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.bottom),
      [
        isActive ? color : color.withOpacity(0.5),
        isActive ? color.withOpacity(0.7) : color.withOpacity(0.3),
      ],
    );
    final paint = Paint()..shader = gradient;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 10, paint);

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

  Future<void> _centerOnAllMarkers() async {
    if (!_isMapReady || _lastGeoPoints.isEmpty) return;

    try {
      // Calculate bounds
      double minLat = 90.0, maxLat = -90.0;
      double minLng = 180.0, maxLng = -180.0;

      for (var geoPoint in _lastGeoPoints.values) {
        if (geoPoint.latitude < minLat) minLat = geoPoint.latitude;
        if (geoPoint.latitude > maxLat) maxLat = geoPoint.latitude;
        if (geoPoint.longitude < minLng) minLng = geoPoint.longitude;
        if (geoPoint.longitude > maxLng) maxLng = geoPoint.longitude;
      }

      // Add padding
      double latPadding = (maxLat - minLat) * 0.1;
      double lngPadding = (maxLng - minLng) * 0.1;

      await _mapController.zoomToBoundingBox(
        BoundingBox(
          north: maxLat + latPadding,
          south: minLat - latPadding,
          east: maxLng + lngPadding,
          west: minLng - lngPadding,
        ),
        paddinInPixel: 50,
      );
    } catch (e) {
      debugPrint('Error centering on markers: $e');
    }
  }


  @override
  void dispose() {
    _locationsStream?.cancel();
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
          _buildFilterControls(),
          SizedBox(height: spacingLarge),
          _buildMapContainer(),
          SizedBox(height: spacingLarge),
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Monitoring',
          style: h2.copyWith(
            fontSize: 24,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Real-time tracking of all users',
          style: body.copyWith(
            color: widget.theme.subtextColor,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  'All Users',
                  'all',
                  Icons.people,
                ),
              ),
              SizedBox(width: spacingSmall),
              Expanded(
                child: _buildFilterButton(
                  'Patients',
                  'patients',
                  Icons.accessible,
                ),
              ),
              SizedBox(width: spacingSmall),
              Expanded(
                child: _buildFilterButton(
                  'Caretakers',
                  'caretakers',
                  Icons.medical_services,
                ),
              ),
            ],
          ),
          SizedBox(height: spacingSmall),
          _buildToggleSwitch(),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    
    return Material(
      color: isSelected ? primary : widget.theme.subtextColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(radiusMedium),
      child: InkWell(
        onTap: () async {
          setState(() {
            _selectedFilter = value;
          });
          await _updateMapMarkers();
        },
        borderRadius: BorderRadius.circular(radiusMedium),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? white : widget.theme.textColor,
                size: 24,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: caption.copyWith(
                  color: isSelected ? white : widget.theme.textColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Row(
      children: [
        Icon(
          Icons.filter_list,
          color: widget.theme.subtextColor,
          size: 20,
        ),
        SizedBox(width: spacingSmall),
        Text(
          'Active Users Only',
          style: body.copyWith(
            color: widget.theme.textColor,
            fontSize: 13,
          ),
        ),
        Spacer(),
        Switch(
          value: _showOnlyActive,
          onChanged: (value) async {
            setState(() {
              _showOnlyActive = value;
            });
            await _updateMapMarkers();
          },
          activeColor: primary,
        ),
      ],
    );
  }

  Widget _buildMapContainer() {
    return Container(
      height: 500,
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
            else
              _buildMapView(),
            
            if (!_isLoading)
              _buildMapControls(),
          ],
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
              'Loading locations...',
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
        
        if (isReady) {
          await Future.delayed(Duration(milliseconds: 300));
          if (mounted) {
            await _updateMapMarkers();
            await _centerOnAllMarkers();
          }
        }
      },
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: spacingMedium,
      bottom: spacingMedium,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.center_focus_strong,
            onTap: _centerOnAllMarkers,
            tooltip: 'Center on all users',
          ),
          SizedBox(height: spacingSmall),
          _buildControlButton(
            icon: Icons.refresh,
            onTap: _refreshLocationData,
            tooltip: 'Refresh locations',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
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

  Widget _buildStatistics() {
    final stats = _calculateStatistics();
    
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: bodyBold.copyWith(
              fontSize: 16,
              color: widget.theme.textColor,
            ),
          ),
          SizedBox(height: spacingMedium),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  '${stats['total']}',
                  Icons.people,
                  primary,
                ),
              ),
              SizedBox(width: spacingSmall),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  '${stats['active']}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: spacingSmall),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Patients',
                  '${stats['patients']}',
                  Icons.accessible,
                  primary,
                ),
              ),
              SizedBox(width: spacingSmall),
              Expanded(
                child: _buildStatCard(
                  'Caretakers',
                  '${stats['caretakers']}',
                  Icons.medical_services,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: spacingSmall),
          Text(
            value,
            style: h2.copyWith(
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: caption.copyWith(
              color: widget.theme.subtextColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStatistics() {
    int total = _userLocations.length;
    int active = 0;
    int patients = 0;
    int caretakers = 0;

    for (var location in _userLocations.values) {
      if (mswdLocationTrackingService.isLocationRecent(location)) {
        active++;
      }
      
      String userType = location['userType'] ?? '';
      if (userType == 'visually_impaired') {
        patients++;
      } else if (userType == 'caretaker') {
        caretakers++;
      }
    }

    return {
      'total': total,
      'active': active,
      'patients': patients,
      'caretakers': caretakers,
    };
  }
}