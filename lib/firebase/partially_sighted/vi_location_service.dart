// File: lib/roles/partially_sighted/services/vi_location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart';

class VILocationService {
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  bool _isTracking = false;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  /// Get current location (one-time)
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      return position;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  Future<bool> startLocationTracking({
    required String userId,
    Function(Position)? onLocationUpdate,
  }) async {
    try {
      if (_isTracking) {
        debugPrint('Location tracking already started');
        return true;
      }

      // Check permissions
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions permanently denied');
        return false;
      }

      // Start position stream
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          
          // Update Firebase with new location
          locationTrackingService.updatePatientLocation(
            patientId: userId,
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            altitude: position.altitude,
            speed: position.speed,
            heading: position.heading,
          );

          // Callback for UI updates
          onLocationUpdate?.call(position);

          debugPrint('📍 Location updated: ${position.latitude}, ${position.longitude}');
        },
        onError: (error) {
          debugPrint('❌ Location stream error: $error');
        },
      );

      _isTracking = true;
      debugPrint('✅ Location tracking started for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    debugPrint('🛑 Location tracking stopped');
  }

  /// Get distance to a specific location
  double getDistanceTo({
    required double targetLatitude,
    required double targetLongitude,
  }) {
    if (_currentPosition == null) return 0;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLatitude,
      targetLongitude,
    );
  }

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
  }
}

// Create a singleton instance
final VILocationService viLocationService = VILocationService();