// File: lib/firebase/visually_impaired/emergency_hotline_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seelai_app/roles/visually_impaired/models/emergency_hotline_model.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyHotlineService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // UPDATED: New path structure - emergencyHotlines/{userId}
  String _getHotlinesPath(String userId) {
    return 'emergency_hotlines/$userId';
  }

  // ==================== CRUD OPERATIONS ====================

  /// Save emergency hotline to database
  Future<bool> saveHotline(EmergencyHotline hotline) async {
    try {
      if (currentUserId == null) {
        debugPrint('❌ Error: No user logged in');
        return false;
      }

      final path = _getHotlinesPath(currentUserId!);
      
      debugPrint('📍 Attempting to save to path: $path/${hotline.id}');
      debugPrint('📋 Hotline data: ${hotline.toJson()}');
      
      await _database.ref('$path/${hotline.id}').set(hotline.toJson());
      
      debugPrint('✅ Hotline saved: ${hotline.departmentName}');
      
      // Log activity
      await _logActivity(
        action: 'hotline_added',
        details: 'Added hotline: ${hotline.departmentName}',
      );
      
      return true;
    } catch (e) {
      debugPrint('❌ Error saving hotline: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Get all emergency hotlines for current user
  Future<List<EmergencyHotline>> getHotlines() async {
    try {
      if (currentUserId == null) {
        debugPrint('❌ Error: No user logged in');
        return [];
      }

      final path = _getHotlinesPath(currentUserId!);
      debugPrint('🔍 Fetching hotlines from: $path');
      
      final event = await _database.ref(path).once();

      if (!event.snapshot.exists) {
        debugPrint('ℹ️ No hotlines found for user');
        return [];
      }

      final Map<dynamic, dynamic> hotlinesMap = event.snapshot.value as Map;
      final List<EmergencyHotline> hotlines = [];

      hotlinesMap.forEach((key, value) {
        try {
          final hotline = EmergencyHotline.fromJson(
            Map<String, dynamic>.from(value as Map)
          );
          hotlines.add(hotline);
        } catch (e) {
          debugPrint('❌ Error parsing hotline: $e');
        }
      });

      // Sort by creation date (newest first)
      hotlines.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

      debugPrint('✅ Loaded ${hotlines.length} hotlines');
      return hotlines;
    } catch (e) {
      debugPrint('❌ Error getting hotlines: $e');
      return [];
    }
  }

  /// Update emergency hotline
  Future<bool> updateHotline(EmergencyHotline hotline) async {
    try {
      if (currentUserId == null) {
        debugPrint('❌ Error: No user logged in');
        return false;
      }

      final path = _getHotlinesPath(currentUserId!);
      
      // Update with new timestamp
      final updatedHotline = hotline.copyWith(updatedAt: DateTime.now());
      
      debugPrint('🔄 Updating hotline at: $path/${hotline.id}');
      
      await _database.ref('$path/${hotline.id}').update(updatedHotline.toJson());
      
      debugPrint('✅ Hotline updated: ${hotline.departmentName}');
      
      // Log activity
      await _logActivity(
        action: 'hotline_updated',
        details: 'Updated hotline: ${hotline.departmentName}',
      );
      
      return true;
    } catch (e) {
      debugPrint('❌ Error updating hotline: $e');
      return false;
    }
  }

  /// Delete emergency hotline
  Future<bool> deleteHotline(String hotlineId) async {
    try {
      if (currentUserId == null) {
        debugPrint('❌ Error: No user logged in');
        return false;
      }

      final path = _getHotlinesPath(currentUserId!);
      
      // Get hotline name before deleting for logging
      final event = await _database.ref('$path/$hotlineId').once();
      String hotlineName = 'Unknown';
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        hotlineName = data['departmentName'] ?? 'Unknown';
      }
      
      debugPrint('🗑️ Deleting hotline at: $path/$hotlineId');
      
      await _database.ref('$path/$hotlineId').remove();
      
      debugPrint('✅ Hotline deleted: $hotlineName');
      
      // Log activity
      await _logActivity(
        action: 'hotline_deleted',
        details: 'Deleted hotline: $hotlineName',
      );
      
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting hotline: $e');
      return false;
    }
  }

  /// Stream of emergency hotlines (real-time updates)
  Stream<List<EmergencyHotline>> streamHotlines() {
    if (currentUserId == null) {
      debugPrint('❌ Error: No user logged in for stream');
      return Stream.value([]);
    }

    final path = _getHotlinesPath(currentUserId!);
    debugPrint('🔄 Starting stream for: $path');
    
    return _database.ref(path).onValue.map((event) {
      if (!event.snapshot.exists) {
        debugPrint('ℹ️ Stream: No hotlines found');
        return <EmergencyHotline>[];
      }

      final Map<dynamic, dynamic> hotlinesMap = event.snapshot.value as Map;
      final List<EmergencyHotline> hotlines = [];

      hotlinesMap.forEach((key, value) {
        try {
          final hotline = EmergencyHotline.fromJson(
            Map<String, dynamic>.from(value as Map)
          );
          hotlines.add(hotline);
        } catch (e) {
          debugPrint('❌ Error parsing hotline in stream: $e');
        }
      });

      // Sort by creation date
      hotlines.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

      debugPrint('✅ Stream update: ${hotlines.length} hotlines');
      return hotlines;
    });
  }

  // ==================== EMERGENCY ACTIONS ====================

  /// Make emergency call
  Future<bool> makeEmergencyCall(String phoneNumber, String departmentName) async {
    try {
      final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
      
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
        debugPrint('📞 Emergency call initiated to: $phoneNumber');
        
        // Log the call
        await _logActivity(
          action: 'emergency_call',
          details: 'Called $departmentName at $phoneNumber',
        );
        
        return true;
      } else {
        debugPrint('❌ Cannot launch phone dialer');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error making emergency call: $e');
      return false;
    }
  }

  /// Send SMS to emergency contact
  Future<bool> sendEmergencySMS(String phoneNumber, String message) async {
    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        debugPrint('📱 SMS sent to: $phoneNumber');
        
        // Log the SMS
        await _logActivity(
          action: 'emergency_sms',
          details: 'Sent SMS to $phoneNumber',
        );
        
        return true;
      } else {
        debugPrint('❌ Cannot launch SMS app');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending SMS: $e');
      return false;
    }
  }

  /// Open location in maps
  Future<bool> openLocation(String address) async {
    try {
      final Uri mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}'
      );
      
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
        debugPrint('🗺️ Opening location: $address');
        
        // Log the action
        await _logActivity(
          action: 'location_opened',
          details: 'Opened location: $address',
        );
        
        return true;
      } else {
        debugPrint('❌ Cannot open maps');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error opening location: $e');
      return false;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Log activity to Firebase
  Future<void> _logActivity({
    required String action,
    required String details,
  }) async {
    try {
      if (currentUserId == null) return;

      final logId = _database.ref('activity_logs').push().key!;
      
      await _database.ref('activity_logs/$logId').set({
        'userId': currentUserId,
        'action': action,
        'details': details,
        'timestamp': ServerValue.timestamp,
      });
      
      debugPrint('📝 Activity logged: $action');
    } catch (e) {
      debugPrint('❌ Error logging activity: $e');
    }
  }

  /// Test database connection
  Future<bool> testConnection() async {
    try {
      if (currentUserId == null) {
        debugPrint('❌ Test: No user logged in');
        return false;
      }
      
      final path = _getHotlinesPath(currentUserId!);
      debugPrint('🔍 Testing connection to: $path');
      
      await _database.ref(path).once();
      debugPrint('✅ Connection test successful');
      return true;
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
      return false;
    }
  }
}

// Singleton instance
final EmergencyHotlineService emergencyHotlineService = EmergencyHotlineService();