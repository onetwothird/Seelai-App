import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:seelai_app/roles/caretaker/models/request_model.dart';
import '../database_service.dart';

/// Transaction record model
class RequestTransaction {
  final String id;
  final String requestId;
  final String patientId;
  final String? caretakerId;
  final String action; // 'created', 'accepted', 'declined', 'inProgress', 'completed'
  final RequestStatus status;
  final DateTime timestamp;
  final String? notes;
  final String? declineReason;
  final Map<String, dynamic>? metadata;

  RequestTransaction({
    required this.id,
    required this.requestId,
    required this.patientId,
    this.caretakerId,
    required this.action,
    required this.status,
    required this.timestamp,
    this.notes,
    this.declineReason,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'patientId': patientId,
      'caretakerId': caretakerId,
      'action': action,
      'status': status.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notes': notes,
      'declineReason': declineReason,
      'metadata': metadata,
    };
  }

  factory RequestTransaction.fromJson(Map<String, dynamic> json, String id) {
    return RequestTransaction(
      id: id,
      requestId: json['requestId'] as String,
      patientId: json['patientId'] as String,
      caretakerId: json['caretakerId'] as String?,
      action: json['action'] as String,
      status: _parseStatus(json['status'] as String?),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      notes: json['notes'] as String?,
      declineReason: json['declineReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static RequestStatus _parseStatus(String? status) {
    switch (status) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'inProgress':
        return RequestStatus.inProgress;
      case 'completed':
        return RequestStatus.completed;
      case 'declined':
        return RequestStatus.declined;
      default:
        return RequestStatus.pending;
    }
  }
}

/// Service for managing request transactions
class RequestTransactionService {
  final FirebaseDatabase _database = databaseService.database;

  /// Log a new request creation
  Future<void> logRequestCreated(
    RequestModel request,
  ) async {
    try {
      String transactionId = _database.ref('request_transactions').push().key ?? '';
      
      final transaction = RequestTransaction(
        id: transactionId,
        requestId: request.id,
        patientId: request.patientId,
        caretakerId: null,
        action: 'created',
        status: RequestStatus.pending,
        timestamp: DateTime.now(),
        metadata: {
          'requestType': request.requestType,
          'priority': request.priority.toString().split('.').last,
        },
      );

      await _database
          .ref('request_transactions/$transactionId')
          .set(transaction.toJson());
    } catch (e) {
      debugPrint('Error logging request created: $e');
      rethrow;
    }
  }

  /// Log request acceptance
  Future<void> logRequestAccepted(
    String requestId,
    String patientId,
    String caretakerId,
  ) async {
    try {
      String transactionId = _database.ref('request_transactions').push().key ?? '';
      
      final transaction = RequestTransaction(
        id: transactionId,
        requestId: requestId,
        patientId: patientId,
        caretakerId: caretakerId,
        action: 'accepted',
        status: RequestStatus.accepted,
        timestamp: DateTime.now(),
      );

      await _database
          .ref('request_transactions/$transactionId')
          .set(transaction.toJson());
    } catch (e) {
      debugPrint('Error logging request accepted: $e');
      rethrow;
    }
  }

  /// Log request decline
  Future<void> logRequestDeclined(
    String requestId,
    String patientId,
    String caretakerId,
    String reason,
  ) async {
    try {
      String transactionId = _database.ref('request_transactions').push().key ?? '';
      
      final transaction = RequestTransaction(
        id: transactionId,
        requestId: requestId,
        patientId: patientId,
        caretakerId: caretakerId,
        action: 'declined',
        status: RequestStatus.declined,
        timestamp: DateTime.now(),
        declineReason: reason,
      );

      await _database
          .ref('request_transactions/$transactionId')
          .set(transaction.toJson());
    } catch (e) {
      debugPrint('Error logging request declined: $e');
      rethrow;
    }
  }

  /// Log request in progress
  Future<void> logRequestInProgress(
    String requestId,
    String patientId,
    String caretakerId,
  ) async {
    try {
      String transactionId = _database.ref('request_transactions').push().key ?? '';
      
      final transaction = RequestTransaction(
        id: transactionId,
        requestId: requestId,
        patientId: patientId,
        caretakerId: caretakerId,
        action: 'inProgress',
        status: RequestStatus.inProgress,
        timestamp: DateTime.now(),
      );

      await _database
          .ref('request_transactions/$transactionId')
          .set(transaction.toJson());
    } catch (e) {
      debugPrint('Error logging request in progress: $e');
      rethrow;
    }
  }

  /// Log request completion
  Future<void> logRequestCompleted(
    String requestId,
    String patientId,
    String caretakerId,
    String notes,
  ) async {
    try {
      String transactionId = _database.ref('request_transactions').push().key ?? '';
      
      final transaction = RequestTransaction(
        id: transactionId,
        requestId: requestId,
        patientId: patientId,
        caretakerId: caretakerId,
        action: 'completed',
        status: RequestStatus.completed,
        timestamp: DateTime.now(),
        notes: notes,
      );

      await _database
          .ref('request_transactions/$transactionId')
          .set(transaction.toJson());
    } catch (e) {
      debugPrint('Error logging request completed: $e');
      rethrow;
    }
  }

  /// Get all transactions for a specific request
  Future<List<RequestTransaction>> getRequestTransactions(String requestId) async {
    try {
      DatabaseEvent event = await _database
          .ref('request_transactions')
          .orderByChild('requestId')
          .equalTo(requestId)
          .once();

      List<RequestTransaction> transactions = [];
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        data.forEach((key, value) {
          transactions.add(RequestTransaction.fromJson(
            Map<String, dynamic>.from(value),
            key,
          ));
        });
      }
      return transactions;
    } catch (e) {
      debugPrint('Error getting request transactions: $e');
      return [];
    }
  }

  /// Get all transactions for a caretaker
  Future<List<RequestTransaction>> getCaretakerTransactions(String caretakerId) async {
    try {
      DatabaseEvent event = await _database
          .ref('request_transactions')
          .orderByChild('caretakerId')
          .equalTo(caretakerId)
          .once();

      List<RequestTransaction> transactions = [];
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        data.forEach((key, value) {
          transactions.add(RequestTransaction.fromJson(
            Map<String, dynamic>.from(value),
            key,
          ));
        });
      }
      return transactions;
    } catch (e) {
      debugPrint('Error getting caretaker transactions: $e');
      return [];
    }
  }

  /// Stream transactions for a request
  Stream<List<RequestTransaction>> streamRequestTransactions(String requestId) {
    return _database
        .ref('request_transactions')
        .orderByChild('requestId')
        .equalTo(requestId)
        .onValue
        .map((event) {
      List<RequestTransaction> transactions = [];
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        data.forEach((key, value) {
          transactions.add(RequestTransaction.fromJson(
            Map<String, dynamic>.from(value),
            key,
          ));
        });
      }
      return transactions;
    });
  }
}

// Singleton instance
final RequestTransactionService requestTransactionService =
    RequestTransactionService();