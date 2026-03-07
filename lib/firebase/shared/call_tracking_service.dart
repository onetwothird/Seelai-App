// File: lib/firebase/shared/call_tracking_service.dart

import 'package:firebase_database/firebase_database.dart';
import '../firebase_services.dart'; // Imports your database_service.dart

class CallTrackingService {
  final FirebaseDatabase _database = databaseService.database;

  /// Initiates a call in Firebase and returns the callId
  Future<String> initiateCall({
    required String callerId,
    required String receiverId,
    required String type, // 'video' or 'voice'
    required String path, // 'caretaker_communication' or 'visually_impaired_communication'
  }) async {
    try {
      DatabaseReference ref = _database.ref('$path/calls').push();
      await ref.set({
        'callerId': callerId,
        'receiverId': receiverId,
        'timestamp': ServerValue.timestamp,
        'type': type,
        'status': 'calling', // Statuses: calling, ringing, accepted, rejected, ended
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

  /// Listen to the status of a specific call (so the UI can close if the other person hangs up)
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
}

final CallTrackingService callTrackingService = CallTrackingService();