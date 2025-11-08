import 'package:flutter/foundation.dart';
import 'dart:math' as math;

class LocationService {
  // Get patient's current location
  Future<Map<String, dynamic>?> getPatientLocation(String patientId) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      
      // Sample data
      return {
        'latitude': 14.2456,
        'longitude': 121.1234,
        'timestamp': DateTime.now().toIso8601String(),
        'accuracy': 10.0,
      };
    } catch (e) {
      debugPrint('Error getting patient location: $e');
      return null;
    }
  }

  // Track patient location in real-time
  Stream<Map<String, dynamic>?> trackPatientLocation(String patientId) {
    return Stream.periodic(Duration(seconds: 5), (_) {
      return {
        'latitude': 14.2456 + (DateTime.now().second * 0.0001),
        'longitude': 121.1234 + (DateTime.now().second * 0.0001),
        'timestamp': DateTime.now().toIso8601String(),
        'accuracy': 10.0,
      };
    });
  }

  // Get distance between two coordinates using Haversine formula
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // Get formatted distance string
  String getFormattedDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toInt()} m';
    }
    return '${distanceInKm.toStringAsFixed(1)} km';
  }
}
