// File: lib/roles/caretaker/services/location_tracking_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Service for real-time location tracking of visually impaired patients
class LocationTrackingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // ==================== LOCATION TRACKING ====================

  /// Update patient's current location (called by visually impaired user's app)
  Future<bool> updatePatientLocation({
    required String patientId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
  }) async {
    try {
      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'timestamp': DateTime.now().toIso8601String(),
        'lastUpdated': ServerValue.timestamp,
      };

      await _database
          .ref('user_locations/visually_impaired/$patientId')
          .set(locationData);

      debugPrint('✅ Location updated for patient: $patientId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
      return false;
    }
  }

  /// Get patient's current location (one-time fetch)
  Future<Map<String, dynamic>?> getPatientLocation(String patientId) async {
    try {
      final snapshot = await _database
          .ref('user_locations/visually_impaired/$patientId')
          .once();

      if (!snapshot.snapshot.exists) {
        debugPrint('ℹ️ No location found for patient: $patientId');
        return null;
      }

      final locationData = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map
      );

      debugPrint('✅ Location retrieved for patient: $patientId');
      return locationData;
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      return null;
    }
  }

  /// Stream patient's location (real-time tracking)
  Stream<Map<String, dynamic>?> trackPatientLocation(String patientId) {
    return _database
        .ref('user_locations/visually_impaired/$patientId')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) {
        debugPrint('ℹ️ No location data in stream for: $patientId');
        return null;
      }

      final locationData = Map<String, dynamic>.from(
        event.snapshot.value as Map
      );

      debugPrint('📍 Location update received for: $patientId');
      return locationData;
    });
  }

  /// Get caretaker's current location
  Future<Map<String, dynamic>?> getCaretakerLocation(String caretakerId) async {
    try {
      final snapshot = await _database
          .ref('user_locations/caretaker/$caretakerId')
          .once();

      if (!snapshot.snapshot.exists) {
        return null;
      }

      return Map<String, dynamic>.from(snapshot.snapshot.value as Map);
    } catch (e) {
      debugPrint('❌ Error getting caretaker location: $e');
      return null;
    }
  }

  /// Update caretaker's location
  Future<bool> updateCaretakerLocation({
    required String caretakerId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    try {
      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': DateTime.now().toIso8601String(),
        'lastUpdated': ServerValue.timestamp,
      };

      await _database
          .ref('user_locations/caretaker/$caretakerId')
          .set(locationData);

      return true;
    } catch (e) {
      debugPrint('❌ Error updating caretaker location: $e');
      return false;
    }
  }

  /// Check if patient location is stale (older than 5 minutes)
  bool isLocationStale(Map<String, dynamic> locationData) {
    try {
      final timestamp = DateTime.parse(locationData['timestamp'] as String);
      final difference = DateTime.now().difference(timestamp);
      return difference.inMinutes > 5;
    } catch (e) {
      return true;
    }
  }

  /// Calculate distance between two points (in meters)
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371000; // meters
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final sinDLat2 = _sin(dLat / 2);
    final sinDLon2 = _sin(dLon / 2);
    final cosLat1 = _cos(_degreesToRadians(lat1));
    final cosLat2 = _cos(_degreesToRadians(lat2));
    
    final a = sinDLat2 * sinDLat2 + cosLat1 * cosLat2 * sinDLon2 * sinDLon2;
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * 3.14159265359 / 180.0;
  }
  
  double _sin(double radians) {
    return radians - (radians * radians * radians) / 6 + 
           (radians * radians * radians * radians * radians) / 120;
  }
  
  double _cos(double radians) {
    return 1 - (radians * radians) / 2 + 
           (radians * radians * radians * radians) / 24;
  }
  
  double _sqrt(double x) {
    if (x == 0) return 0;
    double result = x;
    for (int i = 0; i < 10; i++) {
      result = (result + x / result) / 2;
    }
    return result;
  }
  
  double _atan2(double y, double x) {
    if (x == 0) {
      if (y > 0) return 3.14159265359 / 2;
      if (y < 0) return -3.14159265359 / 2;
      return 0;
    }
    final atan = _atan(y / x);
    if (x > 0) return atan;
    if (y >= 0) return atan + 3.14159265359;
    return atan - 3.14159265359;
  }
  
  double _atan(double x) {
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5 - 
           (x * x * x * x * x * x * x) / 7;
  }

  /// Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Delete patient location data
  Future<bool> deletePatientLocation(String patientId) async {
    try {
      await _database
          .ref('user_locations/visually_impaired/$patientId')
          .remove();
      
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting location: $e');
      return false;
    }
  }

  /// Get all tracked patients locations (for caretaker)
  Future<Map<String, Map<String, dynamic>>> getAllPatientsLocations(
    List<String> patientIds
  ) async {
    try {
      final Map<String, Map<String, dynamic>> locations = {};

      for (final patientId in patientIds) {
        final location = await getPatientLocation(patientId);
        if (location != null) {
          locations[patientId] = location;
        }
      }

      return locations;
    } catch (e) {
      debugPrint('❌ Error getting all locations: $e');
      return {};
    }
  }

  /// Stream multiple patients locations
  Stream<Map<String, Map<String, dynamic>>> trackMultiplePatientsLocations(
    List<String> patientIds
  ) async* {
    final controllers = <String, StreamSubscription>{};
    final locations = <String, Map<String, dynamic>>{};

    try {
      for (final patientId in patientIds) {
        controllers[patientId] = trackPatientLocation(patientId).listen(
          (location) {
            if (location != null) {
              locations[patientId] = location;
            } else {
              locations.remove(patientId);
            }
          },
        );
      }

      // Yield updates periodically
      await for (final _ in Stream.periodic(Duration(seconds: 1))) {
        yield Map.from(locations);
      }
    } finally {
      for (final controller in controllers.values) {
        await controller.cancel();
      }
    }
  }
}

// Create a singleton instance
final LocationTrackingService locationTrackingService = LocationTrackingService();