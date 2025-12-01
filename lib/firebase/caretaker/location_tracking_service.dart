// File: lib/firebase/caretaker/location_tracking_service.dart
// Improved location tracking with accurate distance calculation and better error handling
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class LocationTrackingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // ==================== PATIENT LOCATION ====================

  /// Update patient location in Firebase
  Future<bool> updatePatientLocation({
    required String patientId,
    required double latitude,
    required double longitude,
    required double accuracy,
    double? altitude,
    double? speed,
    double? heading,
  }) async {
    try {
      final timestamp = DateTime.now();
      await _database.ref('user_locations/visually_impaired/$patientId').set({
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude ?? 0.0,
        'speed': speed ?? 0.0,
        'heading': heading ?? 0.0,
        'timestamp': ServerValue.timestamp,
        'lastUpdated': timestamp.toIso8601String(),
        'lastUpdateMillis': timestamp.millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating patient location: $e');
      }
      return false;
    }
  }

  /// Get patient's current location
  Future<Map<String, dynamic>?> getPatientLocation(String patientId) async {
    try {
      final snapshot = await _database
          .ref('user_locations/visually_impaired/$patientId')
          .once();

      if (snapshot.snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting patient location: $e');
      }
      return null;
    }
  }

  /// Stream patient location updates (real-time)
  Stream<Map<String, dynamic>?> trackPatientLocation(String patientId) {
    return _database
        .ref('user_locations/visually_impaired/$patientId')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  // ==================== CARETAKER LOCATION ====================

  /// Update caretaker location in Firebase
  Future<bool> updateCaretakerLocation({
    required String caretakerId,
    required double latitude,
    required double longitude,
    required double accuracy,
    double? altitude,
    double? speed,
    double? heading,
  }) async {
    try {
      final timestamp = DateTime.now();
      await _database.ref('user_locations/caretaker/$caretakerId').set({
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude ?? 0.0,
        'speed': speed ?? 0.0,
        'heading': heading ?? 0.0,
        'timestamp': ServerValue.timestamp,
        'lastUpdated': timestamp.toIso8601String(),
        'lastUpdateMillis': timestamp.millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating caretaker location: $e');
      }
      return false;
    }
  }

  /// Get caretaker's current location
  Future<Map<String, dynamic>?> getCaretakerLocation(String caretakerId) async {
    try {
      final snapshot = await _database
          .ref('user_locations/caretaker/$caretakerId')
          .once();

      if (snapshot.snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting caretaker location: $e');
      }
      return null;
    }
  }

  /// Stream caretaker location updates (real-time)
  Stream<Map<String, dynamic>?> trackCaretakerLocation(String caretakerId) {
    return _database
        .ref('user_locations/caretaker/$caretakerId')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  // ==================== DISTANCE CALCULATION ====================

  /// Calculate distance between two coordinates using Haversine formula (in meters)
  /// This provides accurate distance calculations for any two points on Earth
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusMeters = 6371000; // Earth's radius in meters

    // Convert degrees to radians
    final double lat1Rad = _toRadians(lat1);
    final double lat2Rad = _toRadians(lat2);
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    // Haversine formula
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    // Distance in meters
    final double distance = earthRadiusMeters * c;

    return distance;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    }
  }

  // ==================== LOCATION HISTORY ====================

  /// Get patient location history (last 24 hours)
  Future<List<Map<String, dynamic>>> getPatientLocationHistory(
    String patientId, {
    Duration duration = const Duration(hours: 24),
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(duration).millisecondsSinceEpoch;
      
      final snapshot = await _database
          .ref('user_locations/visually_impaired/$patientId')
          .orderByChild('lastUpdateMillis')
          .startAt(cutoffTime)
          .once();

      if (snapshot.snapshot.exists) {
        List<Map<String, dynamic>> history = [];
        Map<dynamic, dynamic> data = snapshot.snapshot.value as Map;
        
        data.forEach((key, value) {
          if (value is Map) {
            Map<String, dynamic> location = Map<String, dynamic>.from(value);
            location['id'] = key;
            history.add(location);
          }
        });

        // Sort by timestamp (newest first)
        history.sort((a, b) {
          final aTime = a['lastUpdateMillis'] as int? ?? 0;
          final bTime = b['lastUpdateMillis'] as int? ?? 0;
          return bTime.compareTo(aTime);
        });
        
        return history;
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location history: $e');
      }
      return [];
    }
  }

  // ==================== LOCATION VALIDATION ====================

  /// Check if location data is recent (within last 5 minutes)
  bool isLocationRecent(Map<String, dynamic> locationData) {
    try {
      final lastUpdateMillis = locationData['lastUpdateMillis'] as int?;
      if (lastUpdateMillis == null) return false;

      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
      final now = DateTime.now();
      final difference = now.difference(lastUpdate);

      return difference.inMinutes < 5;
    } catch (e) {
      return false;
    }
  }

  /// Check if location accuracy is acceptable (less than 50 meters)
  bool isLocationAccurate(Map<String, dynamic> locationData) {
    try {
      final accuracy = locationData['accuracy'] as double?;
      if (accuracy == null) return false;
      
      return accuracy <= 50.0; // Consider accurate if within 50 meters
    } catch (e) {
      return false;
    }
  }
}

// Singleton instance
final LocationTrackingService locationTrackingService = LocationTrackingService();