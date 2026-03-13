// File: lib/firebase/shared/call_tracking_service.dart

import 'package:firebase_database/firebase_database.dart';
import '../firebase_services.dart'; 

class CallTrackingService {
  final FirebaseDatabase _database = databaseService.database;

  /// Initiates a call in Firebase and returns the callId
  Future<String> initiateCall({
    required String callerId,
    required String receiverId,
    required String type, 
    required String path, 
  }) async {
    try {
      DatabaseReference ref = _database.ref('$path/calls').push();
      await ref.set({
        'callerId': callerId,
        'receiverId': receiverId,
        'timestamp': ServerValue.timestamp,
        'type': type,
        'status': 'calling', 
      });
      return ref.key!;
    } catch (e) {
      throw Exception('Failed to initiate call: $e');
    }
  }

  /// Update the status of an ongoing call (e.g., accept, reject, end)
  Future<void> updateCallStatus({
    required String path,
    required String callId,
    required String status,
  }) async {
    try {
      await _database.ref('$path/calls/$callId').update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update call status: $e');
    }
  }

  /// Listen to the status of a specific call
  Stream<DatabaseEvent> listenToCallStatus(String path, String callId) {
    return _database.ref('$path/calls/$callId').onValue;
  }

  /// Stream to listen for incoming calls for a specific user
  Stream<DatabaseEvent> listenForIncomingCalls(String path, String userId) {
    return _database.ref('$path/calls')
        .orderByChild('receiverId')
        .equalTo(userId)
        .onValue;
  }

  // ========================================================================
  // NEW: MISSED CALL HANDLER
  // ========================================================================

  /// Stream all missed calls for a specific user, automatically sorted by newest first
  Stream<List<Map<String, dynamic>>> streamMissedCalls({
    required String path,
    required String userId,
  }) {
    return _database.ref('$path/calls')
        .orderByChild('receiverId')
        .equalTo(userId)
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return [];
          
          final callsMap = event.snapshot.value as Map<dynamic, dynamic>;
          List<Map<String, dynamic>> missedCalls = [];
          
          // Filter to ONLY grab calls marked as 'missed'
          callsMap.forEach((key, value) {
            final callData = Map<String, dynamic>.from(value as Map);
            if (callData['status'] == 'missed') {
              callData['callId'] = key;
              missedCalls.add(callData);
            }
          });
          
          // Sort newest first
          missedCalls.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
          return missedCalls;
        });
  }

  /// Clears missed calls (changes status to 'cleared') so they no longer show in the UI
  Future<void> clearMissedCalls({
    required String path, 
    required List<String> callIds,
  }) async {
    for (var callId in callIds) {
      try {
        await _database.ref('$path/calls/$callId').update({'status': 'cleared'});
      } catch (e) {
        // Ignore individual failures to ensure the loop continues running
      }
    }
  }
}

final CallTrackingService callTrackingService = CallTrackingService();