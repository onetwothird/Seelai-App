import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';

class PatientLocationScreen extends StatefulWidget {
  final bool isDarkMode;
  final LocationService locationService;

  const PatientLocationScreen({
    super.key,
    required this.isDarkMode,
    required this.locationService,
  });

  @override
  State<PatientLocationScreen> createState() => _PatientLocationScreenState();
}

class _PatientLocationScreenState extends State<PatientLocationScreen> {
  Map<String, dynamic>? _currentLocation;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final location = await widget.locationService.getPatientLocation('patient_1');
    setState(() {
      _currentLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? Color(0xFF0A0E27) : backgroundPrimary;
    final textColor = widget.isDarkMode ? white : black;
    final subtextColor = widget.isDarkMode ? Color(0xFFB0B8D4) : grey;
    final cardColor = widget.isDarkMode ? Color(0xFF1A1F3A) : white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Patient Location',
          style: h2.copyWith(color: textColor, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacingLarge),
        child: Column(
          children: [
            // Map placeholder
            Container(
              height: 400,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(radiusLarge),
                boxShadow: widget.isDarkMode
                    ? [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 16)]
                    : softShadow,
                border: widget.isDarkMode
                    ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
                    : null,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      size: 80,
                      color: subtextColor.withOpacity(0.3),
                    ),
                    SizedBox(height: spacingMedium),
                    Text(
                      'Map integration coming soon',
                      style: body.copyWith(color: subtextColor),
                    ),
                    if (_currentLocation != null) ...[
                      SizedBox(height: spacingMedium),
                      Text(
                        'Lat: ${_currentLocation!['latitude']}',
                        style: caption.copyWith(color: subtextColor),
                      ),
                      Text(
                        'Long: ${_currentLocation!['longitude']}',
                        style: caption.copyWith(color: subtextColor),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Track button
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isTracking = !_isTracking;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isTracking
                          ? 'Real-time tracking enabled'
                          : 'Tracking stopped',
                    ),
                    backgroundColor: _isTracking ? Colors.green : grey,
                  ),
                );
              },
              icon: Icon(_isTracking ? Icons.stop_rounded : Icons.my_location_rounded),
              label: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? error : primary,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}