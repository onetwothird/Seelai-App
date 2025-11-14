// File: lib/roles/caretaker/services/location_tracking_service.dart
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
      await _database.ref('user_locations/visually_impaired/$patientId').set({
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude ?? 0.0,
        'speed': speed ?? 0.0,
        'heading': heading ?? 0.0,
        'timestamp': ServerValue.timestamp,
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Patient location updated in Firebase: $patientId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating patient location: $e');
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
      debugPrint('❌ Error getting patient location: $e');
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
      await _database.ref('user_locations/caretaker/$caretakerId').set({
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude ?? 0.0,
        'speed': speed ?? 0.0,
        'heading': heading ?? 0.0,
        'timestamp': ServerValue.timestamp,
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Caretaker location updated in Firebase: $caretakerId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating caretaker location: $e');
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
      debugPrint('❌ Error getting caretaker location: $e');
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

  /// Calculate distance between two coordinates (in meters)
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371000; // meters

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
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
          .orderByChild('timestamp')
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
        history.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
        
        return history;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting location history: $e');
      return [];
    }
  }
}

// Singleton instance
final LocationTrackingService locationTrackingService = LocationTrackingService();