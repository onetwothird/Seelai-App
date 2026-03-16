// File: lib/firebase/partially_sighted/object_detection_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../database_service.dart';

/// Service for managing object detection history
class ObjectDetectionService {
  final FirebaseDatabase _database = databaseService.database;

  // ==================== CRUD OPERATIONS ====================

  /// Save detected objects to database (EXACT pattern from text_scan_service.dart)
  Future<bool> saveDetectedObjects({
    required String userId,
    required List<Map<String, dynamic>> detectedObjects,
    required int objectCount,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create reference - EXACT same pattern as text_scan_service
      final detectionRef = _database.ref('detected_objects/$userId').push();
      final detectionId = detectionRef.key;
      
      if (detectionId == null) {
        return false;
      }
      
      // Prepare objects data
      final objectsList = detectedObjects.map((obj) {
        try {
          return {
            'label': obj['tag'] ?? 'unknown',
            'confidence': obj['box'][4] ?? 0.0,
            'boundingBox': {
              'x': obj['box'][0],
              'y': obj['box'][1],
              'width': obj['box'][2],
              'height': obj['box'][3],
            },
          };
        } catch (e) {
          return {
            'label': 'unknown',
            'confidence': 0.0,
            'boundingBox': {'x': 0, 'y': 0, 'width': 0, 'height': 0},
          };
        }
      }).toList();
      
      // Prepare data - EXACT same structure as text_scan_service
      final detectionData = {
        'userId': userId,
        'objects': objectsList,
        'objectCount': objectCount,
        'imageUrl': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata ?? {},
        'createdAt': ServerValue.timestamp,
      };
      
      // Save to Firebase - EXACT same method as text_scan_service
      await detectionRef.set(detectionData);
      
      // Log to activity logs
      await _logToActivityLogs(
        userId: userId,
        action: 'objects_detected',
        details: 'Detected $objectCount objects: ${objectsList.map((o) => o['label']).join(', ')}',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all detected objects for a user
  Future<List<Map<String, dynamic>>> getDetectedObjects(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _database
          .ref('detected_objects/$userId')
          .orderByChild('timestamp')
          .limitToLast(limit)
          .once();

      if (!snapshot.snapshot.exists) {
        return [];
      }

      final objectsMap = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map
      );
      final objects = <Map<String, dynamic>>[];

      objectsMap.forEach((key, value) {
        try {
          final objectData = Map<String, dynamic>.from(value as Map);
          objectData['detectionId'] = key;
          objects.add(objectData);
        } catch (e) {
          // Skip invalid entries
        }
      });

      // Sort by timestamp (newest first)
      objects.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      return objects;
    } catch (e) {
      return [];
    }
  }

  /// Stream of detected objects (real-time)
  Stream<List<Map<String, dynamic>>> streamDetectedObjects(
    String userId, {
    int limit = 50,
  }) {
    return _database
        .ref('detected_objects/$userId')
        .orderByChild('timestamp')
        .limitToLast(limit)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) {
        return <Map<String, dynamic>>[];
      }

      final objectsMap = Map<String, dynamic>.from(
        event.snapshot.value as Map
      );
      final objects = <Map<String, dynamic>>[];

      objectsMap.forEach((key, value) {
        try {
          final objectData = Map<String, dynamic>.from(value as Map);
          objectData['detectionId'] = key;
          objects.add(objectData);
        } catch (e) {
          // Skip invalid entries
        }
      });

      // Sort by timestamp (newest first)
      objects.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      return objects;
    });
  }

  /// Get a specific detection
  Future<Map<String, dynamic>?> getDetection(
    String userId,
    String detectionId,
  ) async {
    try {
      final snapshot = await _database
          .ref('detected_objects/$userId/$detectionId')
          .once();

      if (!snapshot.snapshot.exists) {
        return null;
      }

      final detectionData = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map
      );
      detectionData['detectionId'] = detectionId;

      return detectionData;
    } catch (e) {
      return null;
    }
  }

  /// Delete a specific detection
  Future<bool> deleteDetection(String userId, String detectionId) async {
    try {
      await _database
          .ref('detected_objects/$userId/$detectionId')
          .remove();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all detections for a user
  Future<bool> clearAllDetections(String userId) async {
    try {
      await _database
          .ref('detected_objects/$userId')
          .remove();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear old detections (keep only last 100)
  Future<void> clearOldDetections(String userId) async {
    try {
      final detections = await getDetectedObjects(userId, limit: 200);
      
      if (detections.length > 100) {
        final toDelete = detections.skip(100).toList();
        
        for (final detection in toDelete) {
          await _database
              .ref('detected_objects/$userId/${detection['detectionId']}')
              .remove();
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  // ==================== STATISTICS ====================

  /// Get detection statistics for a user
  Future<Map<String, dynamic>> getDetectionStatistics(String userId) async {
    try {
      final detections = await getDetectedObjects(userId, limit: 1000);
      
      int totalDetections = detections.length;
      int totalObjects = 0;
      Map<String, int> objectTypes = {};
      
      for (final detection in detections) {
        final objects = detection['objects'] as List? ?? [];
        totalObjects += objects.length;
        
        for (final obj in objects) {
          final objMap = obj as Map<String, dynamic>;
          String label = objMap['label'] ?? 'unknown';
          objectTypes[label] = (objectTypes[label] ?? 0) + 1;
        }
      }

      return {
        'totalDetections': totalDetections,
        'totalObjects': totalObjects,
        'averageObjectsPerDetection': totalDetections > 0 ? (totalObjects / totalDetections).toStringAsFixed(1) : '0',
        'objectTypes': objectTypes,
        'lastDetectionDate': detections.isNotEmpty ? detections.first['timestamp'] : null,
      };
    } catch (e) {
      return {
        'totalDetections': 0,
        'totalObjects': 0,
        'averageObjectsPerDetection': '0',
        'objectTypes': {},
        'lastDetectionDate': null,
      };
    }
  }

  /// Search detections by object type
  Future<List<Map<String, dynamic>>> searchDetectionsByObject({
    required String userId,
    required String objectLabel,
    int limit = 50,
  }) async {
    try {
      final allDetections = await getDetectedObjects(userId, limit: limit);
      
      final searchResults = allDetections.where((detection) {
        final objects = detection['objects'] as List? ?? [];
        return objects.any((obj) {
          final objMap = obj as Map<String, dynamic>;
          final label = (objMap['label'] as String).toLowerCase();
          return label.contains(objectLabel.toLowerCase());
        });
      }).toList();

      return searchResults;
    } catch (e) {
      return [];
    }
  }

  /// Get detections by date range
  Future<List<Map<String, dynamic>>> getDetectionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final allDetections = await getDetectedObjects(userId, limit: 1000);
      
      final filteredDetections = allDetections.where((detection) {
        final timestamp = DateTime.parse(detection['timestamp'] as String);
        return timestamp.isAfter(startDate) && timestamp.isBefore(endDate);
      }).toList();

      return filteredDetections;
    } catch (e) {
      return [];
    }
  }

  // ==================== ADMIN FUNCTIONS ====================

  /// Get all detections across all users (Admin only)
  Future<List<Map<String, dynamic>>> getAllDetections({
    int limit = 100,
  }) async {
    try {
      final snapshot = await _database
          .ref('detected_objects')
          .limitToLast(limit)
          .once();

      if (!snapshot.snapshot.exists) {
        return [];
      }

      final usersMap = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map
      );
      final allDetections = <Map<String, dynamic>>[];

      usersMap.forEach((userId, userDetections) {
        if (userDetections is Map) {
          Map<dynamic, dynamic> detectionsMap = userDetections;
          detectionsMap.forEach((detectionId, detectionData) {
            try {
              final data = Map<String, dynamic>.from(detectionData as Map);
              data['detectionId'] = detectionId;
              data['userId'] = userId;
              allDetections.add(data);
            } catch (e) {
              // Skip invalid entries
            }
          });
        }
      });

      // Sort by timestamp (newest first)
      allDetections.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      return allDetections;
    } catch (e) {
      return [];
    }
  }

  // ==================== HELPER METHODS ====================

  /// Log to general activity_logs for admin (EXACT pattern from text_scan_service.dart)
  Future<void> _logToActivityLogs({
    required String userId,
    required String action,
    required String details,
  }) async {
    try {
      final logRef = _database.ref('activity_logs').push();
      
      await logRef.set({
        'userId': userId,
        'action': action,
        'details': details,
        'timestamp': ServerValue.timestamp,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail
    }
  }

  /// Format time ago
  String getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  /// Test Firebase connection
  Future<bool> testConnection() async {
    try {
      final snapshot = await _database.ref('.info/connected').once();
      final isConnected = snapshot.snapshot.value as bool? ?? false;
      
      return isConnected;
    } catch (e) {
      return false;
    }
  }
}

// Create a singleton instance
final ObjectDetectionService objectDetectionService = ObjectDetectionService();