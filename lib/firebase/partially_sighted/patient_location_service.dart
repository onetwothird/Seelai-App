// File: lib/firebase/partially_sighted/patient_location_service.dart
// ignore_for_file: deprecated_member_use

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart';

class PatientLocationService {
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _positionStream;
  String? _currentUserId;
  bool _isSharing = false;
  Position? _lastPosition;

  bool get isSharing => _isSharing;

  // ==================== LOCATION SHARING ====================

  /// Start sharing location with caretakers
  Future<bool> startLocationSharing(String userId) async {
    try {
      _currentUserId = userId;

      // Check location permissions
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        return false;
      }

      // Get initial accurate location
      Position? initialPosition = await _getInitialLocation();
      if (initialPosition != null) {
        _lastPosition = initialPosition;
        await _updateLocation(initialPosition);
      }

      // Start continuous location updates with high accuracy
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation, // Highest accuracy
          distanceFilter: 5, // Update every 5 meters movement
          timeLimit: Duration(seconds: 30), // Timeout for location updates
        ),
      ).listen(
        (Position position) {
          // Only update if position has significantly changed
          if (_lastPosition == null || 
              _hasSignificantChange(_lastPosition!, position)) {
            _lastPosition = position;
            _updateLocation(position);
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('Location stream error: $error');
          }
        },
      );

      // Periodic updates every 15 seconds to ensure continuity
      _locationUpdateTimer = Timer.periodic(
        Duration(seconds: 15),
        (_) => _updateCurrentLocation(),
      );

      _isSharing = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting location sharing: $e');
      }
      return false;
    }
  }

  /// Get initial high-accuracy location
  Future<Position?> _getInitialLocation() async {
    try {
      // Get current position with best accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting initial location: $e');
      }
      return null;
    }
  }

  /// Check if position has changed significantly (more than 3 meters)
  bool _hasSignificantChange(Position oldPos, Position newPos) {
    double distance = Geolocator.distanceBetween(
      oldPos.latitude,
      oldPos.longitude,
      newPos.latitude,
      newPos.longitude,
    );
    
    // Update if moved more than 3 meters or accuracy improved
    return distance > 3.0 || newPos.accuracy < oldPos.accuracy;
  }

  /// Stop sharing location
  Future<void> stopLocationSharing() async {
    await _positionStream?.cancel();
    _locationUpdateTimer?.cancel();
    _positionStream = null;
    _locationUpdateTimer = null;
    _isSharing = false;
    _lastPosition = null;
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
    } catch (e) {
      if (kDebugMode) {
        print('Error updating location: $e');
      }
    }
  }

  /// Update current location (for periodic updates)
  Future<void> _updateCurrentLocation() async {
    if (_currentUserId == null || !_isSharing) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      // Only update if significantly changed
      if (_lastPosition == null || 
          _hasSignificantChange(_lastPosition!, position)) {
        _lastPosition = position;
        await _updateLocation(position);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
    }
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current location once with high accuracy
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) return null;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location: $e');
      }
      return null;
    }
  }

  /// Send emergency location update with highest priority
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

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending emergency location: $e');
      }
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