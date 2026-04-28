// File: lib/firebase/mswd/mswd_location_tracking_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// Service for MSWD admins to monitor all users' locations
class MswdLocationTrackingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // ==================== UPDATE ADMIN LOCATION ====================

  /// ✅ NEW: Update MSWD Admin's own location in Firebase
  Future<void> updateMswdLocation({
    required String adminId,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    try {
      await _database.ref('user_locations/mswd/$adminId').set({
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'lastUpdateMillis': ServerValue.timestamp,
        'userType': 'mswd',
      });
    } catch (e) {
      if (kDebugMode) print('Error updating MSWD location: $e');
    }
  }

  // ==================== GET ALL LOCATIONS ====================

  Future<List<Map<String, dynamic>>> getAllPatientLocations() async {
    try {
      final snapshot = await _database.ref('user_locations/partially_sighted').once();
      if (!snapshot.snapshot.exists) return [];

      Map<dynamic, dynamic> locationsMap = snapshot.snapshot.value as Map;
      List<Map<String, dynamic>> locations = [];

      locationsMap.forEach((userId, locationData) {
        if (locationData is Map) {
          Map<String, dynamic> location = Map<String, dynamic>.from(locationData);
          location['userId'] = userId;
          location['userType'] = 'partially_sighted';
          locations.add(location);
        }
      });
      return locations;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllCaretakerLocations() async {
    try {
      final snapshot = await _database.ref('user_locations/caretaker').once();
      if (!snapshot.snapshot.exists) return [];

      Map<dynamic, dynamic> locationsMap = snapshot.snapshot.value as Map;
      List<Map<String, dynamic>> locations = [];

      locationsMap.forEach((userId, locationData) {
        if (locationData is Map) {
          Map<String, dynamic> location = Map<String, dynamic>.from(locationData);
          location['userId'] = userId;
          location['userType'] = 'caretaker';
          locations.add(location);
        }
      });
      return locations;
    } catch (e) {
      return [];
    }
  }

  /// ✅ UPDATED: Fetch MSWD Admin locations too
  Future<List<Map<String, dynamic>>> getAllUserLocations() async {
    try {
      List<Map<String, dynamic>> allLocations = [];
      
      List<Map<String, dynamic>> patientLocations = await getAllPatientLocations();
      allLocations.addAll(patientLocations);
      
      List<Map<String, dynamic>> caretakerLocations = await getAllCaretakerLocations();
      allLocations.addAll(caretakerLocations);

      // Fetch other admins
      final snapshot = await _database.ref('user_locations/mswd').once();
      if (snapshot.snapshot.exists) {
        Map<dynamic, dynamic> mswdMap = snapshot.snapshot.value as Map;
        mswdMap.forEach((userId, locationData) {
          if (locationData is Map) {
            Map<String, dynamic> location = Map<String, dynamic>.from(locationData);
            location['userId'] = userId;
            location['userType'] = 'mswd';
            allLocations.add(location);
          }
        });
      }
      
      return allLocations;
    } catch (e) {
      return [];
    }
  }

  // ==================== REAL-TIME STREAMS ====================

  /// ✅ UPDATED: Stream includes MSWD Admins
  Stream<Map<String, List<Map<String, dynamic>>>> streamAllUserLocations() {
    return _database.ref('user_locations').onValue.map((event) {
      Map<String, List<Map<String, dynamic>>> result = {
        'patients': [],
        'caretakers': [],
        'mswd': [], // Added MSWD group
      };

      if (!event.snapshot.exists) return result;
      Map<dynamic, dynamic> data = event.snapshot.value as Map;

      if (data['partially_sighted'] != null) {
        Map<dynamic, dynamic> patientsMap = data['partially_sighted'] as Map;
        patientsMap.forEach((userId, locationData) {
          if (locationData is Map) {
            Map<String, dynamic> location = Map<String, dynamic>.from(locationData);
            location['userId'] = userId;
            location['userType'] = 'partially_sighted';
            result['patients']!.add(location);
          }
        });
      }

      if (data['caretaker'] != null) {
        Map<dynamic, dynamic> caretakersMap = data['caretaker'] as Map;
        caretakersMap.forEach((userId, locationData) {
          if (locationData is Map) {
            Map<String, dynamic> location = Map<String, dynamic>.from(locationData);
            location['userId'] = userId;
            location['userType'] = 'caretaker';
            result['caretakers']!.add(location);
          }
        });
      }

      // Process MSWD Admins
      if (data['mswd'] != null) {
        Map<dynamic, dynamic> mswdMap = data['mswd'] as Map;
        mswdMap.forEach((userId, locationData) {
          if (locationData is Map) {
            Map<String, dynamic> location = Map<String, dynamic>.from(locationData);
            location['userId'] = userId;
            location['userType'] = 'mswd';
            result['mswd']!.add(location);
          }
        });
      }

      return result;
    });
  }

  // ==================== DISTANCE CALCULATIONS ====================

  double calculateDistance({required double lat1, required double lon1, required double lat2, required double lon2}) {
    const double earthRadiusMeters = 6371000;
    final double lat1Rad = lat1 * pi / 180;
    final double lat2Rad = lat2 * pi / 180;
    final double dLat = (lat2 - lat1) * pi / 180;
    final double dLon = (lon2 - lon1) * pi / 180;

    final double a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    }
  }

  // ==================== LOCATION VALIDATION ====================

  bool isLocationRecent(Map<String, dynamic> locationData) {
    try {
      final lastUpdateMillis = locationData['lastUpdateMillis'] as int?;
      if (lastUpdateMillis == null) return false;
      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
      return DateTime.now().difference(lastUpdate).inMinutes < 5;
    } catch (e) {
      return false;
    }
  }

  bool isLocationAccurate(Map<String, dynamic> locationData) {
    try {
      final accuracy = locationData['accuracy'] as double?;
      if (accuracy == null) return false;
      return accuracy <= 50.0;
    } catch (e) {
      return false;
    }
  }
}

final MswdLocationTrackingService mswdLocationTrackingService = MswdLocationTrackingService();