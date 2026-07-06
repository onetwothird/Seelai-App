// File: lib/firebase/partially_sighted/emergency_hotline_service.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seelai_app/roles/partially_sighted/models/emergency_hotline_model.dart';
import 'package:url_launcher/url_launcher.dart';
// --- ADDED IMPORT FOR GLOBAL PREDEFINED DATA ---
import 'package:seelai_app/roles/mswd/home/sections/hotlines/data/predefined_emergency_hotlines.dart';

class EmergencyHotlineService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // --- CHANGED: Path is now global for everyone ---
  final String _globalHotlinesPath = 'global_emergency_hotlines';

  // ==================== INITIALIZATION ====================

  /// Initialize predefined global hotlines
  Future<bool> initializePredefinedHotlines() async {
    try {
      // Check if global list already has the predefined hotlines
      final existingHotlines = await getHotlines();

      final needsInit = PredefinedEmergencyHotlines.needsInitialization(
        existingHotlines,
      );

      if (!needsInit) {
        debugPrint('ℹ️ Global predefined hotlines already initialized');
        return true;
      }

      debugPrint('🔄 Initializing global predefined hotlines...');

      // Get global predefined hotlines (No userId needed anymore)
      final predefinedHotlines = PredefinedEmergencyHotlines.getNaicHotlines();

      // Save each predefined hotline
      int successCount = 0;
      for (final hotline in predefinedHotlines) {
        final success = await saveHotline(hotline);
        if (success) successCount++;
      }

      debugPrint('✅ Initialized $successCount global predefined hotlines');
      return successCount == predefinedHotlines.length;
    } catch (e) {
      debugPrint('❌ Error initializing global predefined hotlines: $e');
      return false;
    }
  }

  /// Check if predefined hotlines need to be initialized globally
  Future<bool> needsPredefinedInitialization() async {
    try {
      final hotlines = await getHotlines();
      return PredefinedEmergencyHotlines.needsInitialization(hotlines);
    } catch (e) {
      debugPrint('❌ Error checking global initialization: $e');
      return false;
    }
  }

  // ==================== CRUD OPERATIONS ====================

  /// Save emergency hotline to global database
  Future<bool> saveHotline(EmergencyHotline hotline) async {
    try {
      debugPrint(
        '📍 Attempting to save to path: $_globalHotlinesPath/${hotline.id}',
      );
      debugPrint('📋 Hotline data: ${hotline.toJson()}');

      await _database
          .ref('$_globalHotlinesPath/${hotline.id}')
          .set(hotline.toJson());

      debugPrint('✅ Global hotline saved: ${hotline.departmentName}');

      // Log activity if an admin/user is logged in
      if (currentUserId != null) {
        await _logActivity(
          action: 'hotline_added',
          details: 'Added global hotline: ${hotline.departmentName}',
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error saving global hotline: $e');
      return false;
    }
  }

  /// Get all emergency hotlines from the global node
  Future<List<EmergencyHotline>> getHotlines() async {
    try {
      debugPrint('📍 Fetching global hotlines from: $_globalHotlinesPath');

      final event = await _database.ref(_globalHotlinesPath).once();

      if (!event.snapshot.exists) {
        debugPrint('ℹ️ No global hotlines found');
        return [];
      }

      final Map<dynamic, dynamic> hotlinesMap = event.snapshot.value as Map;
      final List<EmergencyHotline> hotlines = [];

      hotlinesMap.forEach((key, value) {
        try {
          final hotline = EmergencyHotline.fromJson(
            Map<String, dynamic>.from(value as Map),
          );
          hotlines.add(hotline);
        } catch (e) {
          debugPrint('❌ Error parsing global hotline: $e');
        }
      });

      // Sort: predefined first, then by creation date
      hotlines.sort((a, b) {
        if (a.isPredefined && !b.isPredefined) return -1;
        if (!a.isPredefined && b.isPredefined) return 1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      debugPrint(
        '✅ Loaded ${hotlines.length} global hotlines (${hotlines.where((h) => h.isPredefined).length} predefined)',
      );
      return hotlines;
    } catch (e) {
      debugPrint('❌ Error getting global hotlines: $e');
      return [];
    }
  }

  /// Update a global emergency hotline
  Future<bool> updateHotline(EmergencyHotline hotline) async {
    try {
      // Update with new timestamp
      final updatedHotline = hotline.copyWith(updatedAt: DateTime.now());

      debugPrint(
        '🔄 Updating global hotline at: $_globalHotlinesPath/${hotline.id}',
      );

      await _database
          .ref('$_globalHotlinesPath/${hotline.id}')
          .update(updatedHotline.toJson());

      debugPrint('✅ Global hotline updated: ${hotline.departmentName}');

      if (currentUserId != null) {
        await _logActivity(
          action: 'hotline_updated',
          details: 'Updated global hotline: ${hotline.departmentName}',
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error updating global hotline: $e');
      return false;
    }
  }

  /// Delete a global emergency hotline
  Future<bool> deleteHotline(String hotlineId) async {
    try {
      // Get hotline name before deleting for logging
      final event = await _database
          .ref('$_globalHotlinesPath/$hotlineId')
          .once();
      String hotlineName = 'Unknown';
      bool wasPredefined = false;

      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        hotlineName = data['departmentName'] ?? 'Unknown';
        wasPredefined = data['isPredefined'] ?? false;
      }

      debugPrint(
        '🗑️ Deleting global hotline at: $_globalHotlinesPath/$hotlineId (predefined: $wasPredefined)',
      );

      await _database.ref('$_globalHotlinesPath/$hotlineId').remove();

      debugPrint('✅ Global hotline deleted: $hotlineName');

      if (currentUserId != null) {
        await _logActivity(
          action: 'hotline_deleted',
          details:
              'Deleted global hotline: $hotlineName (predefined: $wasPredefined)',
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error deleting global hotline: $e');
      return false;
    }
  }

  /// Stream of global emergency hotlines (real-time updates)
  Stream<List<EmergencyHotline>> streamHotlines() {
    debugPrint('🔄 Starting stream for: $_globalHotlinesPath');

    return _database.ref(_globalHotlinesPath).onValue.map((event) {
      if (!event.snapshot.exists) {
        debugPrint('ℹ️ Stream: No global hotlines found');
        return <EmergencyHotline>[];
      }

      final Map<dynamic, dynamic> hotlinesMap = event.snapshot.value as Map;
      final List<EmergencyHotline> hotlines = [];

      hotlinesMap.forEach((key, value) {
        try {
          final hotline = EmergencyHotline.fromJson(
            Map<String, dynamic>.from(value as Map),
          );
          hotlines.add(hotline);
        } catch (e) {
          debugPrint('❌ Error parsing global hotline in stream: $e');
        }
      });

      // Sort: predefined first, then by creation date
      hotlines.sort((a, b) {
        if (a.isPredefined && !b.isPredefined) return -1;
        if (!a.isPredefined && b.isPredefined) return 1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      debugPrint('✅ Stream update: ${hotlines.length} global hotlines');
      return hotlines;
    });
  }

  // ==================== EMERGENCY ACTIONS ====================

  /// Make emergency call
  Future<bool> makeEmergencyCall(
    String phoneNumber,
    String departmentName,
  ) async {
    try {
      final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
        debugPrint('📞 Emergency call initiated to: $phoneNumber');

        // Log the call
        if (currentUserId != null) {
          await _logActivity(
            action: 'emergency_call',
            details: 'Called $departmentName at $phoneNumber',
          );
        }

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
        if (currentUserId != null) {
          await _logActivity(
            action: 'emergency_sms',
            details: 'Sent SMS to $phoneNumber',
          );
        }

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
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );

      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
        debugPrint('🗺️ Opening location: $address');

        // Log the action
        if (currentUserId != null) {
          await _logActivity(
            action: 'location_opened',
            details: 'Opened location: $address',
          );
        }

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
      debugPrint('📍 Testing connection to: $_globalHotlinesPath');

      await _database.ref(_globalHotlinesPath).once();
      debugPrint('✅ Connection test successful');
      return true;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }
}

// Singleton instance
final EmergencyHotlineService emergencyHotlineService =
    EmergencyHotlineService();
