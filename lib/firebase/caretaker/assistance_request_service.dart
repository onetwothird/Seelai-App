// File: lib/firebase/caretaker/assistance_request_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';

class AssistanceRequestService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<bool> sendAssistanceRequest({
    required String patientId,
    required String patientName,
    String? caretakerId,
    required String requestType,
    required String message,
    String? priority,
    Map<String, dynamic>? location,
  }) async {
    try {
      final requestRef = _database.ref('assistance_requests').push();
      final requestId = requestRef.key!;

      final requestData = {
        'patientId': patientId,
        'patientName': patientName,
        'caretakerId': caretakerId,
        'escalatedToMSWD': caretakerId == null,
        'requestType': requestType,
        'message': message,
        'status': 'pending',
        'priority': priority ?? 'medium',
        'timestamp': DateTime.now().toIso8601String(),
        'location': location,
      };

      await requestRef.set(requestData);
      debugPrint('Assistance request sent successfully: $requestId');
      return true;
    } catch (e) {
      debugPrint('Error sending assistance request: $e');
      return false;
    }
  }

  Future<RequestModel?> getRequestById(String requestId) async {
    try {
      final event = await _database
          .ref('assistance_requests/$requestId')
          .once();
      if (event.snapshot.exists) {
        final requestData = Map<String, dynamic>.from(
          event.snapshot.value as Map,
        );
        return RequestModel.fromJson(requestData, requestId);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<RequestModel?> streamRequestById(String requestId) {
    return _database.ref('assistance_requests/$requestId').onValue.map((event) {
      if (event.snapshot.exists) {
        final requestData = Map<String, dynamic>.from(
          event.snapshot.value as Map,
        );
        return RequestModel.fromJson(requestData, requestId);
      }
      return null;
    });
  }

  Future<List<RequestModel>> getCaretakerRequests(String caretakerId) async {
    try {
      final snapshot = await _database
          .ref('assistance_requests')
          .orderByChild('caretakerId')
          .equalTo(caretakerId)
          .once();

      if (!snapshot.snapshot.exists) return [];

      final requestsMap = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map,
      );
      final requests = <RequestModel>[];

      requestsMap.forEach((key, value) {
        try {
          final requestData = Map<String, dynamic>.from(value as Map);
          requests.add(RequestModel.fromJson(requestData, key));
        } catch (_) {}
      });

      requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return requests;
    } catch (e) {
      return [];
    }
  }

  Stream<List<RequestModel>> streamCaretakerRequests(String caretakerId) {
    return _database
        .ref('assistance_requests')
        .orderByChild('caretakerId')
        .equalTo(caretakerId)
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return <RequestModel>[];

          final requestsMap = Map<String, dynamic>.from(
            event.snapshot.value as Map,
          );
          final requests = <RequestModel>[];

          requestsMap.forEach((key, value) {
            try {
              final requestData = Map<String, dynamic>.from(value as Map);
              requests.add(RequestModel.fromJson(requestData, key));
            } catch (_) {}
          });

          requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return requests;
        });
  }

  Stream<List<RequestModel>> streamPatientRequests(String patientId) {
    return _database
        .ref('assistance_requests')
        .orderByChild('patientId')
        .equalTo(patientId)
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return <RequestModel>[];

          final requestsMap = Map<String, dynamic>.from(
            event.snapshot.value as Map,
          );
          final requests = <RequestModel>[];

          requestsMap.forEach((key, value) {
            try {
              final requestData = Map<String, dynamic>.from(value as Map);
              requests.add(RequestModel.fromJson(requestData, key));
            } catch (_) {}
          });

          requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return requests;
        });
  }

  Stream<List<RequestModel>> streamAllRequests() {
    return _database.ref('assistance_requests').onValue.map((event) {
      if (!event.snapshot.exists) return <RequestModel>[];

      final requestsMap = Map<String, dynamic>.from(
        event.snapshot.value as Map,
      );
      final requests = <RequestModel>[];

      requestsMap.forEach((key, value) {
        try {
          final requestData = Map<String, dynamic>.from(value as Map);
          requests.add(RequestModel.fromJson(requestData, key));
        } catch (_) {}
      });

      requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return requests;
    });
  }

  Future<List<RequestModel>> getAllRequests() async {
    try {
      final snapshot = await _database.ref('assistance_requests').once();
      if (!snapshot.snapshot.exists) return [];

      final requestsMap = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map,
      );
      final requests = <RequestModel>[];

      requestsMap.forEach((key, value) {
        try {
          final requestData = Map<String, dynamic>.from(value as Map);
          requests.add(RequestModel.fromJson(requestData, key));
        } catch (_) {}
      });

      requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return requests;
    } catch (e) {
      return [];
    }
  }

  Future<List<RequestModel>> getPendingRequests(String caretakerId) async {
    try {
      final allRequests = await getCaretakerRequests(caretakerId);
      return allRequests
          .where((req) => req.status == RequestStatus.pending)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> acceptRequest(String requestId, String caretakerId) async {
    try {
      await _database.ref('assistance_requests/$requestId').update({
        'status': 'accepted',
        'caretakerId': caretakerId,
        'escalatedToMSWD': false,
        'responseTime': DateTime.now().toIso8601String(),
      });

      debugPrint('Request $requestId accepted by $caretakerId');
      return true;
    } catch (e) {
      debugPrint('Error accepting request: $e');
      return false;
    }
  }

  Future<bool> declineRequest(
    String requestId,
    String caretakerId,
    String reason,
  ) async {
    try {
      await _database.ref('assistance_requests/$requestId').update({
        'status': 'pending',
        'caretakerId': null,
        'escalatedToMSWD': true,
        'responseTime': DateTime.now().toIso8601String(),
        'caretakerResponse': 'Declined by caretaker: $reason',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> completeRequest(
    String requestId,
    String caretakerId,
    String notes,
  ) async {
    try {
      await _database.ref('assistance_requests/$requestId').update({
        'status': 'completed',
        'completedTime': DateTime.now().toIso8601String(),
        'caretakerResponse': notes,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markRequestInProgress(String requestId) async {
    try {
      await _database.ref('assistance_requests/$requestId').update({
        'status': 'inProgress',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateRequestStatus(
    String requestId,
    RequestStatus status,
  ) async {
    try {
      await _database.ref('assistance_requests/$requestId').update({
        'status': status.name, // FIXED: Safer string serialization
      });
      return true;
    } catch (e) {
      debugPrint('Error updating request status: $e');
      return false;
    }
  }

  Future<bool> deleteRequest(String requestId) async {
    try {
      await _database.ref('assistance_requests/$requestId').remove();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<RequestModel>> getRequestsByStatus(
    String caretakerId,
    RequestStatus status,
  ) async {
    try {
      final allRequests = await getCaretakerRequests(caretakerId);
      return allRequests.where((req) => req.status == status).toList();
    } catch (e) {
      return [];
    }
  }
}

final AssistanceRequestService assistanceRequestService =
    AssistanceRequestService();
