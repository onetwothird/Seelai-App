// File: lib/roles/mswd/home/sections/location_track/location_tracking_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class TrackContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;

  const TrackContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
  });

  @override
  State<TrackContent> createState() => _TrackContentState();
}

class _TrackContentState extends State<TrackContent> {
  late MapController _mapController;
  bool _isMapReady = false;
  double _currentZoom = 13.0;
  
  // Location data
  List<Map<String, dynamic>> _patientLocations = [];
  List<Map<String, dynamic>> _caretakerLocations = [];
  final Map<String, Map<String, dynamic>> _userDataCache = {};
  
  // Filters
  bool _showPatients = true;
  bool _showCaretakers = true;
  String _filterStatus = 'all'; // all, active, offline
  
  // Selected user
  
  // Stream subscriptions
  StreamSubscription? _locationsSubscription;
  
  // Statistics
  Map<String, dynamic> _stats = {
    'total': 0,
    'active': 0,
    'offline': 0,
    'patients': 0,
    'caretakers': 0,
  };

  bool _isLoadingStats = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initializeMapController();
    _loadInitialData();
    _startLocationStream();
  }

  void _initializeMapController() {
    _mapController = MapController(
      initPosition: GeoPoint(
        latitude: 14.4167, // Philippines center
        longitude: 120.9833,
      ),
      areaLimit: BoundingBox.world(),
    );
  }

  Future<void> _loadInitialData() async {
    await _loadStatistics();
    await _loadUserData();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    
    final stats = await mswdLocationTrackingService.getLocationStatistics();
    
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Get all users
      List<Map<String, dynamic>> allUsers = await adminService.getAllUsers();
      
      for (var user in allUsers) {
        String userId = user['userId'] ?? '';
        if (userId.isNotEmpty) {
          _userDataCache[userId] = user;
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _startLocationStream() {
    _locationsSubscription = mswdLocationTrackingService
        .streamAllUserLocations()
        .listen((locations) {
      if (mounted) {
        setState(() {
          _patientLocations = locations['patients'] ?? [];
          _caretakerLocations = locations['caretakers'] ?? [];
        });
        
        if (_isMapReady) {
          _updateMapMarkers();
        }
        
        _loadStatistics();
      }
    });
  }

  List<Map<String, dynamic>> _getFilteredLocations() {
    List<Map<String, dynamic>> filtered = [];
    
    if (_showPatients) {
      filtered.addAll(_patientLocations);
    }
    
    if (_showCaretakers) {
      filtered.addAll(_caretakerLocations);
    }
    
    if (_filterStatus != 'all') {
      filtered = filtered.where((location) {
        String status = mswdLocationTrackingService.getLocationStatus(location);
        if (_filterStatus == 'active') {
          return status == 'active';
        } else if (_filterStatus == 'offline') {
          return status == 'offline' || status == 'poor_signal';
        }
        return true;
      }).toList();
    }
    
    return filtered;
  }

  Future<void> _updateMapMarkers() async {
    if (!_isMapReady) return;

    try {
      List<Map<String, dynamic>> filtered = _getFilteredLocations();
      
      for (var location in filtered) {
        String userId = location['userId'] ?? '';
        String userType = location['userType'] ?? '';
        double lat = location['latitude'] as double? ?? 0.0;
        double lng = location['longitude'] as double? ?? 0.0;
        
        if (lat == 0.0 || lng == 0.0) continue;
        
        GeoPoint geoPoint = GeoPoint(latitude: lat, longitude: lng);
        
        // Get user data
        Map<String, dynamic>? userData = _userDataCache[userId];
        String name = userData?['name'] ?? 'Unknown';
        String? imageUrl = userData?['profileImageUrl'] as String?;
        
        // Determine marker color based on user type and status
        Color markerColor = userType == 'visually_impaired' ? primary : Colors.blue;
        String status = mswdLocationTrackingService.getLocationStatus(location);
        
        if (status == 'offline') {
          markerColor = grey;
        } else if (status == 'poor_signal') {
          markerColor = Colors.orange;
        }
        
        // Create marker
        final markerBytes = await _createUserMarker(
          imageUrl: imageUrl,
          name: name,
          borderColor: markerColor,
          status: status,
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
        }
      }
    } catch (e) {
      debugPrint('Error updating map markers: $e');
    }
  }

  Future<Uint8List?> _createUserMarker({
    required String? imageUrl,
    required String name,
    required Color borderColor,
    required String status,
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
              Paint(),
            );
          } else {
            _drawDefaultAvatar(canvas, size, name, borderColor);
          }
        } catch (e) {
          _drawDefaultAvatar(canvas, size, name, borderColor);
        }
      } else {
        _drawDefaultAvatar(canvas, size, name, borderColor);
      }

      // Draw colored border
      final coloredBorderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 7, coloredBorderPaint);

      // Draw status indicator if offline or poor signal
      if (status != 'active') {
        final statusColor = status == 'offline' ? Colors.red : Colors.orange;
        final statusPaint = Paint()
          ..color = statusColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(size - 15, 15), 8, statusPaint);
        
        final statusBorderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(size - 15, 15), 8, statusBorderPaint);
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error creating marker: $e');
      return null;
    }
  }

  void _drawDefaultAvatar(Canvas canvas, double size, String name, Color color) {
    final rect = Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2 - 10);
    final gradient = ui.Gradient.linear(
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.bottom),
      [color, color.withOpacity(0.7)],
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

  Future<void> _centerOnUser(Map<String, dynamic> location) async {
    if (!_isMapReady) return;
    
    double lat = location['latitude'] as double? ?? 0.0;
    double lng = location['longitude'] as double? ?? 0.0;
    
    if (lat == 0.0 || lng == 0.0) return;
    
    GeoPoint geoPoint = GeoPoint(latitude: lat, longitude: lng);
    await _mapController.moveTo(geoPoint, animate: true);
    
    setState(() {
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  Future<void> _zoomIn() async {
    if (!_isMapReady || _currentZoom >= 19) return;
    setState(() => _currentZoom += 1);
    await _mapController.setZoom(zoomLevel: _currentZoom);
  }

  Future<void> _zoomOut() async {
    if (!_isMapReady || _currentZoom <= 3) return;
    setState(() => _currentZoom -= 1);
    await _mapController.setZoom(zoomLevel: _currentZoom);
  }

  @override
  void dispose() {
    _locationsSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
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
          _buildStatistics(),
          SizedBox(height: spacingLarge),
          _buildFilters(),
          SizedBox(height: spacingLarge),
          _buildMapContainer(height),
          SizedBox(height: spacingLarge),
          _buildUsersList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
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
          'Monitor all users in real-time',
          style: body.copyWith(
            color: widget.theme.subtextColor,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    if (_isLoadingStats) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primary),
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: _buildStatCard('Total', _stats['total'], primary, Icons.location_on)),
        SizedBox(width: spacingSmall),
        Expanded(child: _buildStatCard('Active', _stats['active'], Colors.green, Icons.check_circle)),
        SizedBox(width: spacingSmall),
        Expanded(child: _buildStatCard('Offline', _stats['offline'], error, Icons.offline_bolt)),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusMedium),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: spacingSmall),
          Text(
            '$value',
            style: h3.copyWith(
              color: widget.theme.textColor,
              fontWeight: FontWeight.bold,
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

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: bodyBold.copyWith(
            color: widget.theme.textColor,
            fontSize: 14,
          ),
        ),
        SizedBox(height: spacingSmall),
        Wrap(
          spacing: spacingSmall,
          runSpacing: spacingSmall,
          children: [
            _buildFilterChip(
              'Patients',
              _showPatients,
              () => setState(() => _showPatients = !_showPatients),
              primary,
            ),
            _buildFilterChip(
              'Caretakers',
              _showCaretakers,
              () => setState(() => _showCaretakers = !_showCaretakers),
              Colors.blue,
            ),
            _buildFilterChip(
              'All Status',
              _filterStatus == 'all',
              () => setState(() => _filterStatus = 'all'),
              grey,
            ),
            _buildFilterChip(
              'Active Only',
              _filterStatus == 'active',
              () => setState(() => _filterStatus = 'active'),
              Colors.green,
            ),
            _buildFilterChip(
              'Offline Only',
              _filterStatus == 'offline',
              () => setState(() => _filterStatus = 'offline'),
              error,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: () {
        onTap();
        if (_isMapReady) {
          _updateMapMarkers();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: spacingMedium, vertical: spacingSmall),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusSmall),
          border: Border.all(
            color: isSelected ? color : widget.theme.subtextColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: caption.copyWith(
            color: isSelected ? color : widget.theme.subtextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMapContainer(double height) {
    return Container(
      height: height * 0.5,
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [BoxShadow(color: primary.withOpacity(0.2), blurRadius: 24, offset: Offset(0, 8))]
            : softShadow,
        border: widget.isDarkMode ? Border.all(color: primary.withOpacity(0.3), width: 2) : null,
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
            staticPoints: [],
            enableRotationByGesture: true,
            showZoomController: false,
            showDefaultInfoWindow: false,
          ),
          onMapIsReady: (isReady) async {
            setState(() => _isMapReady = isReady);
            if (isReady) {
              await Future.delayed(Duration(milliseconds: 300));
              if (mounted) _updateMapMarkers();
            }
          },
        ),
        _buildZoomControls(fullscreen),
        if (!fullscreen) _buildMapActionButtons(),
      ],
    );
  }

  Widget _buildZoomControls(bool fullscreen) {
    return Positioned(
      right: spacingMedium,
      top: fullscreen ? 80 : spacingMedium,
      child: Column(
        children: [
          _buildZoomButton(Icons.add, _zoomIn),
          SizedBox(height: spacingSmall),
          _buildZoomButton(Icons.remove, _zoomOut),
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Icon(icon, color: primary, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildMapActionButtons() {
    return Positioned(
      bottom: spacingMedium,
      right: spacingMedium,
      child: ElevatedButton(
        onPressed: _toggleFullscreen,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          padding: EdgeInsets.all(12),
          shape: CircleBorder(),
        ),
        child: Icon(Icons.fullscreen, color: white),
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
          ElevatedButton.icon(
            onPressed: _toggleFullscreen,
            icon: Icon(Icons.fullscreen_exit, size: 18),
            label: Text('Exit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: grey,
              foregroundColor: white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    List<Map<String, dynamic>> filtered = _getFilteredLocations();
    
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(spacingXLarge),
          child: Text(
            'No users found with current filters',
            style: body.copyWith(color: widget.theme.subtextColor),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Users (${filtered.length})',
          style: bodyBold.copyWith(
            color: widget.theme.textColor,
            fontSize: 16,
          ),
        ),
        SizedBox(height: spacingMedium),
        ...filtered.map((location) => _buildUserCard(location)),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> location) {
    String userId = location['userId'] ?? '';
    String userType = location['userType'] ?? '';
    Map<String, dynamic>? userData = _userDataCache[userId];
    
    String name = userData?['name'] ?? 'Unknown User';
    String? imageUrl = userData?['profileImageUrl'] as String?;
    String status = mswdLocationTrackingService.getLocationStatus(location);
    
    Color statusColor = status == 'active' 
        ? Colors.green 
        : status == 'poor_signal' 
            ? Colors.orange 
            : grey;
    
    Color typeColor = userType == 'visually_impaired' ? primary : Colors.blue;
    
    return Container(
      margin: EdgeInsets.only(bottom: spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusMedium),
        boxShadow: widget.isDarkMode ? [] : softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _centerOnUser(location),
          borderRadius: BorderRadius.circular(radiusMedium),
          child: Padding(
            padding: EdgeInsets.all(spacingMedium),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: imageUrl == null ? LinearGradient(colors: [typeColor, typeColor.withOpacity(0.7)]) : null,
                        image: imageUrl != null 
                            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageUrl == null 
                          ? Center(child: Text(name[0].toUpperCase(), style: TextStyle(color: white, fontSize: 20, fontWeight: FontWeight.bold)))
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: widget.theme.cardColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: bodyBold.copyWith(color: widget.theme.textColor)),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(radiusSmall),
                            ),
                            child: Text(
                              userType == 'visually_impaired' ? 'Patient' : 'Caretaker',
                              style: caption.copyWith(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: spacingSmall),
                          Text(
                            status == 'active' ? 'Active' : status == 'poor_signal' ? 'Poor Signal' : 'Offline',
                            style: caption.copyWith(color: statusColor, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: widget.theme.subtextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}