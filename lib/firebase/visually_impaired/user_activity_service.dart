// File: lib/firebase/visually_impaired/user_activity_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../database_service.dart';

/// Service for managing user activities (real-time tracking)
class UserActivityService {
  final FirebaseDatabase _database = databaseService.database;

  // Activity types
  static const String activityObjectScanned = 'object_scanned';
  static const String activityTextRead = 'text_read';
  static const String activityColorDetected = 'color_detected';
  static const String activityEmergencyCalled = 'emergency_called';
  static const String activityCaretakerRequested = 'caretaker_requested';
  static const String activityHotlineAccessed = 'hotline_accessed';
  static const String activityNavigationUsed = 'navigation_used';
  static const String activityVoiceAssistant = 'voice_assistant';

  /// Log a new activity for a user
  Future<bool> logActivity({
    required String userId,
    required String activityType,
    required String title,
    required String description,
    int? iconCode,
    bool isEmergency = false,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activityRef = _database
          .ref('user_info/visually_impaired/$userId/recentActivities')
          .push();
      
      final activityData = {
        'title': title,
        'description': description,
        'activityType': activityType,
        'iconCode': iconCode ?? _getDefaultIconCode(activityType),
        'isEmergency': isEmergency,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata ?? {},
      };

      await activityRef.set(activityData);
      
      // Also log to general activity_logs for admin
      await _logToActivityLogs(
        userId: userId,
        action: activityType,
        details: description,
      );

      debugPrint('✅ Activity logged: $title');
      return true;
    } catch (e) {
      debugPrint('❌ Error logging activity: $e');
      return false;
    }
  }

  /// Get recent activities for a user
  Future<List<Map<String, dynamic>>> getRecentActivities(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _database
          .ref('user_info/visually_impaired/$userId/recentActivities')
          .orderByChild('timestamp')
          .limitToLast(limit)
          .once();

      if (!snapshot.snapshot.exists) {
        return [];
      }

      final activitiesMap = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map
      );
      final activities = <Map<String, dynamic>>[];

      activitiesMap.forEach((key, value) {
        try {
          final activity = Map<String, dynamic>.from(value as Map);
          activity['activityId'] = key;
          activities.add(activity);
        } catch (e) {
          debugPrint('Error parsing activity $key: $e');
        }
      });

      // Sort by timestamp (newest first)
      activities.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      return activities;
    } catch (e) {
      debugPrint('Error getting activities: $e');
      return [];
    }
  }

  /// Stream of recent activities (real-time)
  Stream<List<Map<String, dynamic>>> streamRecentActivities(
    String userId, {
    int limit = 20,
  }) {
    return _database
        .ref('user_info/visually_impaired/$userId/recentActivities')
        .orderByChild('timestamp')
        .limitToLast(limit)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) {
        return <Map<String, dynamic>>[];
      }

      final activitiesMap = Map<String, dynamic>.from(
        event.snapshot.value as Map
      );
      final activities = <Map<String, dynamic>>[];

      activitiesMap.forEach((key, value) {
        try {
          final activity = Map<String, dynamic>.from(value as Map);
          activity['activityId'] = key;
          activities.add(activity);
        } catch (e) {
          debugPrint('Error parsing activity $key: $e');
        }
      });

      // Sort by timestamp (newest first)
      activities.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      return activities;
    });
  }

  /// Clear old activities (keep only last 50)
  Future<void> clearOldActivities(String userId) async {
    try {
      final activities = await getRecentActivities(userId, limit: 100);
      
      if (activities.length > 50) {
        final toDelete = activities.skip(50).toList();
        
        for (final activity in toDelete) {
          await _database
              .ref('user_info/visually_impaired/$userId/recentActivities/${activity['activityId']}')
              .remove();
        }
        
        debugPrint('✅ Cleared ${toDelete.length} old activities');
      }
    } catch (e) {
      debugPrint('Error clearing old activities: $e');
    }
  }

  /// Delete a specific activity
  Future<bool> deleteActivity(String userId, String activityId) async {
    try {
      await _database
          .ref('user_info/visually_impaired/$userId/recentActivities/$activityId')
          .remove();
      
      debugPrint('✅ Activity deleted: $activityId');
      return true;
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      return false;
    }
  }

  /// Clear all activities for a user
  Future<bool> clearAllActivities(String userId) async {
    try {
      await _database
          .ref('user_info/visually_impaired/$userId/recentActivities')
          .remove();
      
      debugPrint('✅ All activities cleared for user: $userId');
      return true;
    } catch (e) {
      debugPrint('Error clearing all activities: $e');
      return false;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Get default icon code based on activity type
  int _getDefaultIconCode(String activityType) {
    switch (activityType) {
      case activityObjectScanned:
        return 0xe8b3; // Icons.qr_code_scanner_rounded
      case activityTextRead:
        return 0xf05e6; // Icons.text_fields_rounded
      case activityColorDetected:
        return 0xee46; // Icons.palette_rounded
      case activityEmergencyCalled:
        return 0xe163; // Icons.emergency_rounded
      case activityCaretakerRequested:
        return 0xef3b; // Icons.person_rounded
      case activityHotlineAccessed:
        return 0xe0b0; // Icons.phone_rounded
      case activityNavigationUsed:
        return 0xef6e; // Icons.navigation_rounded
      case activityVoiceAssistant:
        return 0xe029; // Icons.mic_rounded
      default:
        return 0xe88f; // Icons.info_rounded
    }
  }

  /// Log to general activity_logs for admin
  Future<void> _logToActivityLogs({
    required String userId,
    required String action,
    required String details,
  }) async {
    try {
      final logId = _database.ref('activity_logs').push().key!;
      
      await _database.ref('activity_logs/$logId').set({
        'userId': userId,
        'action': action,
        'details': details,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error logging to activity_logs: $e');
    }
  }

  // ==================== CONVENIENCE METHODS ====================

  /// Log object scan activity
  Future<bool> logObjectScanned({
    required String userId,
    required String objectName,
    String? confidence,
  }) async {
    return await logActivity(
      userId: userId,
      activityType: activityObjectScanned,
      title: 'Object Scanned',
      description: '$objectName - ${_getTimeAgo(DateTime.now())}',
      metadata: {
        'objectName': objectName,
        'confidence': confidence,
      },
    );
  }

  /// Log text reading activity
  Future<bool> logTextRead({
    required String userId,
    required String textType,
    int? wordCount,
  }) async {
    return await logActivity(
      userId: userId,
      activityType: activityTextRead,
      title: 'Text Read',
      description: '$textType - ${_getTimeAgo(DateTime.now())}',
      metadata: {
        'textType': textType,
        'wordCount': wordCount,
      },
    );
  }

  /// Log color detection activity
  Future<bool> logColorDetected({
    required String userId,
    required String colorName,
    required String objectType,
  }) async {
    return await logActivity(
      userId: userId,
      activityType: activityColorDetected,
      title: 'Color Detected',
      description: '$colorName $objectType - ${_getTimeAgo(DateTime.now())}',
      metadata: {
        'colorName': colorName,
        'objectType': objectType,
      },
    );
  }

  /// Log emergency call activity
  Future<bool> logEmergencyCall({
    required String userId,
    required String contactName,
    String? contactType,
  }) async {
    return await logActivity(
      userId: userId,
      activityType: activityEmergencyCalled,
      title: 'Emergency Called',
      description: '$contactName contacted - ${_getTimeAgo(DateTime.now())}',
      isEmergency: true,
      metadata: {
        'contactName': contactName,
        'contactType': contactType,
      },
    );
  }

  /// Log caretaker request activity
  Future<bool> logCaretakerRequest({
    required String userId,
    required String requestType,
    String? priority,
  }) async {
    return await logActivity(
      userId: userId,
      activityType: activityCaretakerRequested,
      title: 'Caretaker Requested',
      description: '$requestType - ${_getTimeAgo(DateTime.now())}',
      metadata: {
        'requestType': requestType,
        'priority': priority,
      },
    );
  }

  /// Format time ago
  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Create a singleton instance
final UserActivityService userActivityService = UserActivityService();