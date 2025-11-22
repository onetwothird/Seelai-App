// File: lib/roles/visually_impaired/services/patient_location_service.dart
// ignore_for_file: deprecated_member_use

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart';

/// Service for visually impaired users to share their location with caretakers
class PatientLocationService {
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _positionStream;
  String? _currentUserId;
  bool _isSharing = false;

  bool get isSharing => _isSharing;

  // ==================== LOCATION SHARING ====================

  /// Start sharing location with caretakers
  Future<bool> startLocationSharing(String userId) async {
    try {
      _currentUserId = userId;

      // Check location permissions
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        debugPrint('❌ Location permission denied');
        return false;
      }

      // Start continuous location updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
          timeLimit: Duration(minutes: 1),
        ),
      ).listen(
        (Position position) {
          _updateLocation(position);
        },
        onError: (error) {
          debugPrint('❌ Location stream error: $error');
        },
      );

      // Also update periodically (every 30 seconds) even if user hasn't moved
      _locationUpdateTimer = Timer.periodic(
        Duration(seconds: 30),
        (_) => _updateCurrentLocation(),
      );

      _isSharing = true;
      debugPrint('✅ Location sharing started for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting location sharing: $e');
      return false;
    }
  }

  /// Stop sharing location
  Future<void> stopLocationSharing() async {
    _positionStream?.cancel();
    _locationUpdateTimer?.cancel();
    _isSharing = false;
    debugPrint('🛑 Location sharing stopped');
  }

  /// Update location in Firebase
  Future<void> _updateLocation(Position position) async {
    if (_currentUserId == null) return;

    try {
      await locationTrackingService.updatePatientLocation(
        patientId: _currentUserId!,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
      );

      debugPrint('📍 Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
    }
  }

  /// Update current location (for periodic updates)
  Future<void> _updateCurrentLocation() async {
    if (_currentUserId == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _updateLocation(position);
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
    }
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Location services are disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Location permissions denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Location permissions permanently denied');
      return false;
    }

    return true;
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) return null;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      return null;
    }
  }

  /// Send emergency location update
  Future<bool> sendEmergencyLocation(String userId) async {
    try {
      Position? position = await getCurrentLocation();
      if (position == null) return false;

      await locationTrackingService.updatePatientLocation(
        patientId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
      );

      debugPrint('🚨 Emergency location sent');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending emergency location: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopLocationSharing();
  }
}

// Singleton instance
final PatientLocationService patientLocationService = PatientLocationService();