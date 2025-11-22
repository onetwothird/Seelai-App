import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for handling calls and messages between caretakers and patients
class CommunicationsService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== CALLS ====================

  /// Create a new call record
  Future<Map<String, dynamic>> initiateCall({
    required String receiverId,
    required String receiverName,
    required String receiverImage,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final callId = _database.ref('caretaker_communication/calls').push().key ?? '';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final callData = {
        'callId': callId,
        'callerId': currentUserId,
        'receiverId': receiverId,
        'callerName': _auth.currentUser?.displayName ?? 'Unknown',
        'callerImage': _auth.currentUser?.photoURL ?? '',
        'receiverName': receiverName,
        'receiverImage': receiverImage,
        'status': 'incoming',
        'timestamp': timestamp,
        'duration': 0,
        'callType': 'audio',
      };

      await _database.ref('caretaker_communication/calls/$callId').set(callData);
      return callData;
    } catch (e) {
      debugPrint('Error initiating call: $e');
      rethrow;
    }
  }

  /// Update call status
  Future<void> updateCallStatus({
    required String callId,
    required String status,
    int duration = 0,
  }) async {
    try {
      await _database.ref('caretaker_communication/calls/$callId').update({
        'status': status,
        'duration': duration,
      });
    } catch (e) {
      debugPrint('Error updating call status: $e');
      rethrow;
    }
  }

  /// End a call
  Future<void> endCall({
    required String callId,
    required int duration,
  }) async {
    try {
      await updateCallStatus(
        callId: callId,
        status: 'completed',
        duration: duration,
      );
    } catch (e) {
      debugPrint('Error ending call: $e');
      rethrow;
    }
  }

  /// Get call history between two users
  Future<List<Map<String, dynamic>>> getCallHistory({
    required String otherUserId,
    int limit = 50,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      DatabaseEvent event = await _database
          .ref('caretaker_communication/calls')
          .orderByChild('timestamp')
          .limitToLast(limit)
          .once();

      if (!event.snapshot.exists) return [];

      List<Map<String, dynamic>> callHistory = [];
      Map<dynamic, dynamic> callsMap = event.snapshot.value as Map;

      callsMap.forEach((key, value) {
        Map<String, dynamic> call = Map<String, dynamic>.from(value as Map);
        
        // Filter calls between current user and other user
        if ((call['callerId'] == currentUserId && call['receiverId'] == otherUserId) ||
            (call['callerId'] == otherUserId && call['receiverId'] == currentUserId)) {
          callHistory.add(call);
        }
      });

      return callHistory.reversed.toList();
    } catch (e) {
      debugPrint('Error getting call history: $e');
      return [];
    }
  }

  /// Stream of incoming calls
  Stream<Map<String, dynamic>?> streamIncomingCalls() {
    if (currentUserId == null) return Stream.empty();

    return _database
        .ref('caretaker_communication/calls')
        .orderByChild('receiverId')
        .equalTo(currentUserId)
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return null;

          Map<dynamic, dynamic> callsMap = event.snapshot.value as Map;
          
          // Get the most recent incoming call
          for (var entry in callsMap.entries.toList().reversed) {
            Map<String, dynamic> call = Map<String, dynamic>.from(entry.value as Map);
            if (call['status'] == 'incoming') {
              return call;
            }
          }
          return null;
        });
  }

  // ==================== MESSAGES ====================

  /// Send a message
  Future<String> sendMessage({
    required String receiverId,
    required String text,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final messageId = _database.ref('caretaker_communication/messages').push().key ?? '';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final conversationId = _generateConversationId(currentUserId!, receiverId);

      final messageData = {
        'messageId': messageId,
        'senderId': currentUserId,
        'receiverId': receiverId,
        'senderName': _auth.currentUser?.displayName ?? 'Unknown',
        'text': text,
        'timestamp': timestamp,
        'isRead': false,
        'conversationId': conversationId,
      };

      await _database.ref('caretaker_communication/messages/$messageId').set(messageData);
      
      // Update conversation
      await _updateConversation(
        conversationId: conversationId,
        receiverId: receiverId,
        lastMessage: text,
        timestamp: timestamp,
      );

      return messageId;
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Get conversation between two users
  Future<List<Map<String, dynamic>>> getConversation({
    required String otherUserId,
    int limit = 100,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final conversationId = _generateConversationId(currentUserId!, otherUserId);

      DatabaseEvent event = await _database
          .ref('caretaker_communication/messages')
          .orderByChild('conversationId')
          .equalTo(conversationId)
          .limitToLast(limit)
          .once();

      if (!event.snapshot.exists) return [];

      List<Map<String, dynamic>> messages = [];
      Map<dynamic, dynamic> messagesMap = event.snapshot.value as Map;

      messagesMap.forEach((key, value) {
        Map<String, dynamic> message = Map<String, dynamic>.from(value as Map);
        messages.add(message);
      });

      return messages.reversed.toList();
    } catch (e) {
      debugPrint('Error getting conversation: $e');
      return [];
    }
  }

  /// Stream of messages in a conversation
  Stream<List<Map<String, dynamic>>> streamConversation({
    required String otherUserId,
  }) {
    if (currentUserId == null) return Stream.empty();

    final conversationId = _generateConversationId(currentUserId!, otherUserId);

    return _database
        .ref('caretaker_communication/messages')
        .orderByChild('conversationId')
        .equalTo(conversationId)
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return [];

          List<Map<String, dynamic>> messages = [];
          Map<dynamic, dynamic> messagesMap = event.snapshot.value as Map;

          messagesMap.forEach((key, value) {
            Map<String, dynamic> message = Map<String, dynamic>.from(value as Map);
            messages.add(message);
          });

          return messages;
        });
  }

  /// Get all conversations for current user
  Stream<List<Map<String, dynamic>>> streamConversations() {
    if (currentUserId == null) return Stream.empty();

    return _database
        .ref('caretaker_communication/conversations')
        .orderByChild('participant1')
        .equalTo(currentUserId)
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return [];

          List<Map<String, dynamic>> conversations = [];
          Map<dynamic, dynamic> conversationsMap = event.snapshot.value as Map;

          conversationsMap.forEach((key, value) {
            Map<String, dynamic> conversation = Map<String, dynamic>.from(value as Map);
            conversations.add(conversation);
          });

          // Sort by last message time
          conversations.sort((a, b) {
            int timeA = a['lastMessageTime'] as int? ?? 0;
            int timeB = b['lastMessageTime'] as int? ?? 0;
            return timeB.compareTo(timeA);
          });

          return conversations;
        });
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _database.ref('caretaker_communication/messages/$messageId').update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Generate conversation ID (ensures consistency)
  String _generateConversationId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Update conversation metadata
  Future<void> _updateConversation({
    required String conversationId,
    required String receiverId,
    required String lastMessage,
    required int timestamp,
  }) async {
    try {
      if (currentUserId == null) return;

      final senderName = _auth.currentUser?.displayName ?? 'Unknown';
      final receiverName = 'User'; // You might want to fetch this

      await _database.ref('caretaker_communication/conversations/$conversationId').update({
        'participant1': currentUserId,
        'participant2': receiverId,
        'participant1Name': senderName,
        'participant2Name': receiverName,
        'lastMessage': lastMessage,
        'lastMessageTime': timestamp,
      });
    } catch (e) {
      debugPrint('Error updating conversation: $e');
    }
  }
}

// Create singleton instance
final CommunicationsService communicationsService = CommunicationsService();