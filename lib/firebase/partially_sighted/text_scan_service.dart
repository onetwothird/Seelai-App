// File: lib/firebase/partially_sighted/text_scan_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../database_service.dart';

/// Service for managing scanned text history
class TextScanService {
  final FirebaseDatabase _database = databaseService.database;

  // ==================== CRUD OPERATIONS ====================

  /// Save scanned text to database (at root level)
  Future<bool> saveScannedText({
    required String userId,
    required String scannedText,
    required int textBlockCount,
    String? imageUrl,
    String? sourceType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('🔄 Attempting to save scanned text for user: $userId');
      
      // Create reference
      final scanRef = _database.ref('scanned_texts/$userId').push();
      final scanId = scanRef.key;
      
      if (scanId == null) {
        debugPrint('❌ Failed to generate scan ID');
        return false;
      }
      
      debugPrint('📝 Generated scan ID: $scanId');
      
      // Prepare data
      final scanData = {
        'userId': userId,
        'text': scannedText,
        'textBlockCount': textBlockCount,
        'sourceType': sourceType ?? 'document',
        'imageUrl': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'wordCount': scannedText.split(' ').length,
        'characterCount': scannedText.length,
        'metadata': metadata ?? {},
        'createdAt': ServerValue.timestamp,
      };

      debugPrint('📦 Prepared data: ${scanData.keys.join(", ")}');
      
      // Save to Firebase
      await scanRef.set(scanData);
      
      debugPrint('✅ Successfully saved to Firebase at: scanned_texts/$userId/$scanId');
      debugPrint('   Text length: ${scannedText.length} characters');
      debugPrint('   Blocks: $textBlockCount');
      
      // Log to activity logs
      await _logToActivityLogs(
        userId: userId,
        action: 'text_scanned',
        // ignore: unnecessary_brace_in_string_interps
        details: 'Scanned ${textBlockCount} text blocks (${scannedText.length} chars)',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving scanned text: $e');
      debugPrint('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get all scanned texts for a user
  Future<List<Map<String, dynamic>>> getScannedTexts(
    String userId, {
    int limit = 50,
  }) async {
    try {
      debugPrint('🔍 Fetching scanned texts for user: $userId');
      
      final snapshot = await _database
          .ref('scanned_texts/$userId')
          .orderByChild('timestamp')
          .limitToLast(limit)
          .once();

      if (!snapshot.snapshot.exists) {
        debugPrint('ℹ️ No scanned texts found for user: $userId');
        return [];
      }

      final textsMap = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map
      );
      final texts = <Map<String, dynamic>>[];

      textsMap.forEach((key, value) {
        try {
          final textData = Map<String, dynamic>.from(value as Map);
          textData['scanId'] = key;
          texts.add(textData);
        } catch (e) {
          debugPrint('⚠️ Error parsing scanned text $key: $e');
        }
      });

      // Sort by timestamp (newest first)
      texts.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      debugPrint('✅ Retrieved ${texts.length} scanned texts');
      return texts;
    } catch (e) {
      debugPrint('❌ Error getting scanned texts: $e');
      return [];
    }
  }

  /// Stream of scanned texts (real-time)
  Stream<List<Map<String, dynamic>>> streamScannedTexts(
    String userId, {
    int limit = 50,
  }) {
    debugPrint('📡 Setting up real-time stream for user: $userId');
    
    return _database
        .ref('scanned_texts/$userId')
        .orderByChild('timestamp')
        .limitToLast(limit)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) {
        return <Map<String, dynamic>>[];
      }

      final textsMap = Map<String, dynamic>.from(
        event.snapshot.value as Map
      );
      final texts = <Map<String, dynamic>>[];

      textsMap.forEach((key, value) {
        try {
          final textData = Map<String, dynamic>.from(value as Map);
          textData['scanId'] = key;
          texts.add(textData);
        } catch (e) {
          debugPrint('⚠️ Error parsing scanned text $key: $e');
        }
      });

      // Sort by timestamp (newest first)
      texts.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      return texts;
    });
  }

  /// Get a specific scanned text
  Future<Map<String, dynamic>?> getScannedText(
    String userId,
    String scanId,
  ) async {
    try {
      final snapshot = await _database
          .ref('scanned_texts/$userId/$scanId')
          .once();

      if (!snapshot.snapshot.exists) {
        debugPrint('ℹ️ Scanned text not found: $scanId');
        return null;
      }

      final textData = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map
      );
      textData['scanId'] = scanId;

      return textData;
    } catch (e) {
      debugPrint('❌ Error getting scanned text: $e');
      return null;
    }
  }

  /// Delete a specific scanned text
  Future<bool> deleteScannedText(String userId, String scanId) async {
    try {
      await _database
          .ref('scanned_texts/$userId/$scanId')
          .remove();
      
      debugPrint('✅ Scanned text deleted: $scanId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting scanned text: $e');
      return false;
    }
  }

  /// Clear all scanned texts for a user
  Future<bool> clearAllScannedTexts(String userId) async {
    try {
      await _database
          .ref('scanned_texts/$userId')
          .remove();
      
      debugPrint('✅ All scanned texts cleared for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing all scanned texts: $e');
      return false;
    }
  }

  /// Clear old scanned texts (keep only last 100)
  Future<void> clearOldScannedTexts(String userId) async {
    try {
      final texts = await getScannedTexts(userId, limit: 200);
      
      if (texts.length > 100) {
        final toDelete = texts.skip(100).toList();
        
        for (final text in toDelete) {
          await _database
              .ref('scanned_texts/$userId/${text['scanId']}')
              .remove();
        }
        
        debugPrint('✅ Cleared ${toDelete.length} old scanned texts');
      }
    } catch (e) {
      debugPrint('❌ Error clearing old scanned texts: $e');
    }
  }

  /// Update scanned text metadata
  Future<bool> updateScannedText({
    required String userId,
    required String scanId,
    String? sourceType,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': ServerValue.timestamp,
      };

      if (sourceType != null) {
        updates['sourceType'] = sourceType;
      }

      if (additionalMetadata != null) {
        updates['metadata'] = additionalMetadata;
      }

      await _database
          .ref('scanned_texts/$userId/$scanId')
          .update(updates);

      debugPrint('✅ Scanned text updated: $scanId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating scanned text: $e');
      return false;
    }
  }

  // ==================== STATISTICS ====================

  /// Get scan statistics for a user
  Future<Map<String, dynamic>> getScanStatistics(String userId) async {
    try {
      final texts = await getScannedTexts(userId, limit: 1000);
      
      int totalScans = texts.length;
      int totalWords = 0;
      int totalCharacters = 0;
      Map<String, int> sourceTypes = {};
      
      for (final text in texts) {
        totalWords += (text['wordCount'] as int?) ?? 0;
        totalCharacters += (text['characterCount'] as int?) ?? 0;
        
        String sourceType = text['sourceType'] ?? 'unknown';
        sourceTypes[sourceType] = (sourceTypes[sourceType] ?? 0) + 1;
      }

      return {
        'totalScans': totalScans,
        'totalWords': totalWords,
        'totalCharacters': totalCharacters,
        'averageWordsPerScan': totalScans > 0 ? (totalWords / totalScans).round() : 0,
        'sourceTypes': sourceTypes,
        'lastScanDate': texts.isNotEmpty ? texts.first['timestamp'] : null,
      };
    } catch (e) {
      debugPrint('❌ Error getting scan statistics: $e');
      return {
        'totalScans': 0,
        'totalWords': 0,
        'totalCharacters': 0,
        'averageWordsPerScan': 0,
        'sourceTypes': {},
        'lastScanDate': null,
      };
    }
  }

  /// Search scanned texts
  Future<List<Map<String, dynamic>>> searchScannedTexts({
    required String userId,
    required String query,
    int limit = 50,
  }) async {
    try {
      final allTexts = await getScannedTexts(userId, limit: limit);
      
      final searchResults = allTexts.where((text) {
        final textContent = (text['text'] as String).toLowerCase();
        return textContent.contains(query.toLowerCase());
      }).toList();

      return searchResults;
    } catch (e) {
      debugPrint('❌ Error searching scanned texts: $e');
      return [];
    }
  }

  /// Get scanned texts by date range
  Future<List<Map<String, dynamic>>> getScannedTextsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final allTexts = await getScannedTexts(userId, limit: 1000);
      
      final filteredTexts = allTexts.where((text) {
        final timestamp = DateTime.parse(text['timestamp'] as String);
        return timestamp.isAfter(startDate) && timestamp.isBefore(endDate);
      }).toList();

      return filteredTexts;
    } catch (e) {
      debugPrint('❌ Error getting texts by date range: $e');
      return [];
    }
  }

  /// Get scanned texts by source type
  Future<List<Map<String, dynamic>>> getScannedTextsBySourceType({
    required String userId,
    required String sourceType,
    int limit = 50,
  }) async {
    try {
      final allTexts = await getScannedTexts(userId, limit: limit);
      
      final filteredTexts = allTexts.where((text) {
        return text['sourceType'] == sourceType;
      }).toList();

      return filteredTexts;
    } catch (e) {
      debugPrint('❌ Error getting texts by source type: $e');
      return [];
    }
  }

  // ==================== ADMIN FUNCTIONS ====================

  /// Get all scanned texts across all users (Admin only)
  Future<List<Map<String, dynamic>>> getAllScannedTexts({
    int limit = 100,
  }) async {
    try {
      final snapshot = await _database
          .ref('scanned_texts')
          .limitToLast(limit)
          .once();

      if (!snapshot.snapshot.exists) {
        return [];
      }

      final usersMap = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map
      );
      final allTexts = <Map<String, dynamic>>[];

      usersMap.forEach((userId, userScans) {
        if (userScans is Map) {
          Map<dynamic, dynamic> scansMap = userScans;
          scansMap.forEach((scanId, scanData) {
            try {
              final textData = Map<String, dynamic>.from(scanData as Map);
              textData['scanId'] = scanId;
              textData['userId'] = userId;
              allTexts.add(textData);
            } catch (e) {
              debugPrint('⚠️ Error parsing scan $scanId: $e');
            }
          });
        }
      });

      // Sort by timestamp (newest first)
      allTexts.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      return allTexts;
    } catch (e) {
      debugPrint('❌ Error getting all scanned texts: $e');
      return [];
    }
  }

  // ==================== HELPER METHODS ====================

  /// Log to general activity_logs for admin
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
      
      debugPrint('📋 Activity logged: $action');
    } catch (e) {
      debugPrint('⚠️ Error logging to activity_logs: $e');
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
      debugPrint('🔍 Testing Firebase connection...');
      
      // Try to read from the database
      final snapshot = await _database.ref('.info/connected').once();
      final isConnected = snapshot.snapshot.value as bool? ?? false;
      
      debugPrint(isConnected 
          ? '✅ Firebase connection: OK' 
          : '❌ Firebase connection: FAILED');
      
      return isConnected;
    } catch (e) {
      debugPrint('❌ Firebase connection test error: $e');
      return false;
    }
  }
}

// Create a singleton instance
final TextScanService textScanService = TextScanService();