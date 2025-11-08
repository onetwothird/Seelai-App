import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';

/// Service for handling activity logging
class ActivityLogsService {
  final FirebaseDatabase _database = databaseService.database;

  // ==================== ACTIVITY LOGGING ====================

  /// Log user activity
  Future<void> logActivity({
    required String userId,
    required String action,
    String? details,
  }) async {
    try {
      String logId = _database.ref('activity_logs').push().key!;
      
      await _database.ref('activity_logs/$logId').set({
        'userId': userId,
        'action': action,
        'details': details ?? '',
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      // Don't throw error for logging failures
    }
  }

  /// Get user activity logs
  Future<List<Map<String, dynamic>>> getUserActivityLogs(
    String userId, {
    int limit = 50,
  }) async {
    try {
      DatabaseEvent event = await _database
          .ref('activity_logs')
          .orderByChild('userId')
          .equalTo(userId)
          .limitToLast(limit)
          .once();
      
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> logsMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> logs = [];
      
      logsMap.forEach((key, value) {
        Map<String, dynamic> log = Map<String, dynamic>.from(value as Map);
        log['logId'] = key;
        logs.add(log);
      });
      
      // Sort by timestamp descending
      logs.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      
      return logs;
    } catch (e) {
      throw Exception('Failed to get activity logs: $e');
    }
  }

  /// Get all activity logs (Admin only)
  Future<List<Map<String, dynamic>>> getAllActivityLogs({int limit = 100}) async {
    try {
      DatabaseEvent event = await _database
          .ref('activity_logs')
          .limitToLast(limit)
          .once();
      
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> logsMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> logs = [];
      
      logsMap.forEach((key, value) {
        Map<String, dynamic> log = Map<String, dynamic>.from(value as Map);
        log['logId'] = key;
        logs.add(log);
      });
      
      // Sort by timestamp descending
      logs.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      
      return logs;
    } catch (e) {
      throw Exception('Failed to get all activity logs: $e');
    }
  }

  /// Stream of activity logs for real-time updates
  Stream<List<Map<String, dynamic>>> streamUserActivityLogs(
    String userId, {
    int limit = 50,
  }) {
    return _database
        .ref('activity_logs')
        .orderByChild('userId')
        .equalTo(userId)
        .limitToLast(limit)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> logsMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> logs = [];
      
      logsMap.forEach((key, value) {
        Map<String, dynamic> log = Map<String, dynamic>.from(value as Map);
        log['logId'] = key;
        logs.add(log);
      });
      
      logs.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      return logs;
    });
  }

  /// Delete activity logs for a specific user
  Future<void> deleteUserActivityLogs(String userId) async {
    try {
      DatabaseEvent event = await _database
          .ref('activity_logs')
          .orderByChild('userId')
          .equalTo(userId)
          .once();
      
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> logsMap = event.snapshot.value as Map;
        
        for (String logId in logsMap.keys) {
          await _database.ref('activity_logs/$logId').remove();
        }
      }
    } catch (e) {
      throw Exception('Failed to delete activity logs: $e');
    }
  }
}

// Create a singleton instance
final ActivityLogsService activityLogsService = ActivityLogsService();