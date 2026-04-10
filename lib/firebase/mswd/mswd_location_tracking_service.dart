// File: lib/firebase/mswd/mswd_location_tracking_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// Service for MSWD admins to monitor all users' locations
class MswdLocationTrackingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // ==================== GET ALL LOCATIONS ====================

  Future<List<Map<String, dynamic>>> getAllPatientLocations() async {
    try {
      final snapshot = await _database
          .ref('user_locations/partially_sighted')
          .once();

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
      if (kDebugMode) {
        print('Error getting patient locations: $e');
      }
      return [];
    }
  }

  /// Get all caretakers' locations
  Future<List<Map<String, dynamic>>> getAllCaretakerLocations() async {
    try {
      final snapshot = await _database
          .ref('user_locations/caretaker')
          .once();

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
      if (kDebugMode) {
        print('Error getting caretaker locations: $e');
      }
      return [];
    }
  }

  /// Get all user locations (both patients and caretakers)
  Future<List<Map<String, dynamic>>> getAllUserLocations() async {
    try {
      List<Map<String, dynamic>> allLocations = [];
      
      // Get patient locations
      List<Map<String, dynamic>> patientLocations = await getAllPatientLocations();
      allLocations.addAll(patientLocations);
      
      // Get caretaker locations
      List<Map<String, dynamic>> caretakerLocations = await getAllCaretakerLocations();
      allLocations.addAll(caretakerLocations);
      
      return allLocations;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all user locations: $e');
      }
      return [];
    }
  }

  /// Get specific user location
  Future<Map<String, dynamic>?> getUserLocation(String userId, String userType) async {
    try {
      String path = userType == 'partially_sighted' 
          ? 'user_locations/partially_sighted/$userId'
          : 'user_locations/caretaker/$userId';
      
      final snapshot = await _database.ref(path).once();

      if (snapshot.snapshot.exists) {
        Map<String, dynamic> location = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        location['userId'] = userId;
        location['userType'] = userType;
        return location;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user location: $e');
      }
      return null;
    }
  }

  // ==================== REAL-TIME STREAMS ====================

  Stream<List<Map<String, dynamic>>> streamAllPatientLocations() {
    return _database
        .ref('user_locations/partially_sighted  ')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];

      Map<dynamic, dynamic> locationsMap = event.snapshot.value as Map;
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
    });
  }

  /// Stream all caretakers' locations
  Stream<List<Map<String, dynamic>>> streamAllCaretakerLocations() {
    return _database
        .ref('user_locations/caretaker')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];

      Map<dynamic, dynamic> locationsMap = event.snapshot.value as Map;
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
    });
  }

  /// Stream all user locations (combined patients and caretakers)
  Stream<Map<String, List<Map<String, dynamic>>>> streamAllUserLocations() {
    return _database.ref('user_locations').onValue.map((event) {
      Map<String, List<Map<String, dynamic>>> result = {
        'patients': [],
        'caretakers': [],
      };

      if (!event.snapshot.exists) return result;

      Map<dynamic, dynamic> data = event.snapshot.value as Map;

      // Process partially sighted users
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

      // Process caretakers
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

      return result;
    });
  }

  /// Stream specific user location
  Stream<Map<String, dynamic>?> streamUserLocation(String userId, String userType) {
    String path = userType == 'partially_sighted' 
        ? 'user_locations/partially_sighted/$userId'
        : 'user_locations/caretaker/$userId';
    
    return _database.ref(path).onValue.map((event) {
      if (event.snapshot.exists) {
        Map<String, dynamic> location = Map<String, dynamic>.from(event.snapshot.value as Map);
        location['userId'] = userId;
        location['userType'] = userType;
        return location;
      }
      return null;
    });
  }

  // ==================== DISTANCE CALCULATIONS ====================

  /// Calculate distance between two coordinates using Haversine formula (in meters)
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusMeters = 6371000;

    // Convert degrees to radians
    final double lat1Rad = _toRadians(lat1);
    final double lat2Rad = _toRadians(lat2);
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    // Haversine formula
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
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
      
      return accuracy <= 50.0;
    } catch (e) {
      return false;
    }
  }

  /// Get location status (active, stale, offline)
  String getLocationStatus(Map<String, dynamic> locationData) {
    if (!isLocationRecent(locationData)) {
      return 'offline';
    } else if (!isLocationAccurate(locationData)) {
      return 'poor_signal';
    } else {
      return 'active';
    }
  }

  // ==================== STATISTICS ====================

  /// Get location statistics for all users
  Future<Map<String, dynamic>> getLocationStatistics() async {
    try {
      List<Map<String, dynamic>> allLocations = await getAllUserLocations();
      
      int activeUsers = 0;
      int offlineUsers = 0;
      int poorSignalUsers = 0;
      int totalPatients = 0;
      int totalCaretakers = 0;

      for (var location in allLocations) {
        String status = getLocationStatus(location);
        String userType = location['userType'] ?? '';

        if (userType == 'partially_sighted') {
          totalPatients++;
        } else if (userType == 'caretaker') {
          totalCaretakers++;
        }

        if (status == 'active') {
          activeUsers++;
        } else if (status == 'poor_signal') {
          poorSignalUsers++;
        } else {
          offlineUsers++;
        }
      }

      return {
        'total': allLocations.length,
        'active': activeUsers,
        'offline': offlineUsers,
        'poor_signal': poorSignalUsers,
        'patients': totalPatients,
        'caretakers': totalCaretakers,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location statistics: $e');
      }
      return {
        'total': 0,
        'active': 0,
        'offline': 0,
        'poor_signal': 0,
        'patients': 0,
        'caretakers': 0,
      };
    }
  }

  // ==================== LOCATION HISTORY ====================

  /// Get user location history (if tracking history is implemented)
  Future<List<Map<String, dynamic>>> getUserLocationHistory(
    String userId,
    String userType, {
    Duration duration = const Duration(hours: 24),
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(duration).millisecondsSinceEpoch;
      
      String path = userType == 'partially_sighted'
          ? 'user_locations/partially_sighted/$userId'
          : 'user_locations/caretaker/$userId';
      
      final snapshot = await _database
          .ref(path)
          .orderByChild('lastUpdateMillis')
          .startAt(cutoffTime)
          .once();

      if (snapshot.snapshot.exists) {
        List<Map<String, dynamic>> history = [];
        
        if (snapshot.snapshot.value is Map) {
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
        }
        
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
}

// Singleton instance
final MswdLocationTrackingService mswdLocationTrackingService = MswdLocationTrackingService();