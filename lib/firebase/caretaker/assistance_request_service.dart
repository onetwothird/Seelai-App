// File: lib/firebase/caretaker/assistance_request_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';

class AssistanceRequestService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  Future<bool> sendAssistanceRequest({
    required String patientId,
    required String patientName,
    required String caretakerId,
    required String requestType,
    required String message,
    String? priority,
    Map<String, dynamic>? location,
  }) async {
    try {
      // Generate unique request ID
      final requestRef = _database.ref('assistance_requests').push();
      final requestId = requestRef.key!;
      
      // Create request data
      final requestData = {
        'patientId': patientId,
        'patientName': patientName,
        'caretakerId': caretakerId,
        'requestType': requestType,
        'message': message,
        'status': 'pending',
        'priority': priority ?? 'medium',
        'timestamp': DateTime.now().toIso8601String(),
        'location': location,
      };
      
      // Save to database
      await requestRef.set(requestData);
      
      debugPrint('Assistance request sent successfully: $requestId');
      return true;
    } catch (e) {
      debugPrint('Error sending assistance request: $e');
      return false;
    }
  }
  
  /// Get a single request by ID
  Future<RequestModel?> getRequestById(String requestId) async {
    try {
      final event = await _database
          .ref('assistance_requests/$requestId')
          .once();
      
      if (event.snapshot.exists) {
        final requestData = Map<String, dynamic>.from(event.snapshot.value as Map);
        return RequestModel.fromJson(requestData, requestId);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting request by ID: $e');
      return null;
    }
  }
  
  /// Stream a single request for real-time updates
  Stream<RequestModel?> streamRequestById(String requestId) {
    return _database
        .ref('assistance_requests/$requestId')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final requestData = Map<String, dynamic>.from(event.snapshot.value as Map);
        return RequestModel.fromJson(requestData, requestId);
      }
      return null;
    });
  }
  
  /// Get all requests for a specific caretaker
  Future<List<RequestModel>> getCaretakerRequests(String caretakerId) async {
    try {
      final snapshot = await _database
          .ref('assistance_requests')
          .orderByChild('caretakerId')
          .equalTo(caretakerId)
          .once();
      
      if (!snapshot.snapshot.exists) {
        return [];
      }
      
      final requestsMap = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      final requests = <RequestModel>[];
      
      requestsMap.forEach((key, value) {
        try {
          final requestData = Map<String, dynamic>.from(value as Map);
          requests.add(RequestModel.fromJson(requestData, key));
        } catch (e) {
          debugPrint('Error parsing request $key: $e');
        }
      });
      
      // Sort by timestamp (newest first)
      requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return requests;
    } catch (e) {
      debugPrint('Error getting caretaker requests: $e');
      return [];
    }
  }
  
  /// Stream requests for a specific caretaker (real-time)
  Stream<List<RequestModel>> streamCaretakerRequests(String caretakerId) {
    return _database
        .ref('assistance_requests')
        .orderByChild('caretakerId')
        .equalTo(caretakerId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) {
        return <RequestModel>[];
      }
      
      final requestsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      final requests = <RequestModel>[];
      
      requestsMap.forEach((key, value) {
        try {
          final requestData = Map<String, dynamic>.from(value as Map);
          requests.add(RequestModel.fromJson(requestData, key));
        } catch (e) {
          debugPrint('Error parsing request $key: $e');
        }
      });
      
      // Sort by timestamp (newest first)
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
      if (!event.snapshot.exists) {
        return <RequestModel>[];
      }
      
      final requestsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      final requests = <RequestModel>[];
      
      requestsMap.forEach((key, value) {
        try {
          final requestData = Map<String, dynamic>.from(value as Map);
          requests.add(RequestModel.fromJson(requestData, key));
        } catch (e) {
          debugPrint('Error parsing request $key: $e');
        }
      });
      
      // Sort by timestamp (newest first)
      requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return requests;
    });
  }
  
  /// Stream ALL requests (for admin/MSWD role)
  Stream<List<RequestModel>> streamAllRequests() {
    return _database
        .ref('assistance_requests')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) {
        return <RequestModel>[];
      }
      
      final requestsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      final requests = <RequestModel>[];
      
      requestsMap.forEach((key, value) {
        try {
          final requestData = Map<String, dynamic>.from(value as Map);
          requests.add(RequestModel.fromJson(requestData, key));
        } catch (e) {
          debugPrint('Error parsing request $key: $e');
        }
      });
      
      // Sort by timestamp (newest first)
      requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return requests;
    });
  }
  
  /// Get ALL requests (for admin/MSWD role)
  Future<List<RequestModel>> getAllRequests() async {
    try {
      final snapshot = await _database
          .ref('assistance_requests')
          .once();
      
      if (!snapshot.snapshot.exists) {
        return [];
      }
      
      final requestsMap = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      final requests = <RequestModel>[];
      
      requestsMap.forEach((key, value) {
        try {
          final requestData = Map<String, dynamic>.from(value as Map);
          requests.add(RequestModel.fromJson(requestData, key));
        } catch (e) {
          debugPrint('Error parsing request $key: $e');
        }
      });
      
      // Sort by timestamp (newest first)
      requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return requests;
    } catch (e) {
      debugPrint('Error getting all requests: $e');
      return [];
    }
  }
  
  /// Get pending requests for a caretaker
  Future<List<RequestModel>> getPendingRequests(String caretakerId) async {
    try {
      final allRequests = await getCaretakerRequests(caretakerId);
      return allRequests.where((req) => req.status == RequestStatus.pending).toList();
    } catch (e) {
      debugPrint('Error getting pending requests: $e');
      return [];
    }
  }
  
  /// Accept a request
  Future<bool> acceptRequest(String requestId, String caretakerId) async {
    try {
      await _database.ref('assistance_requests/$requestId').update({
        'status': 'accepted',
        'responseTime': DateTime.now().toIso8601String(),
      });
      
      debugPrint('Request $requestId accepted by $caretakerId');
      return true;
    } catch (e) {
      debugPrint('Error accepting request: $e');
      return false;
    }
  }
  
  /// Decline a request
  Future<bool> declineRequest(
    String requestId,
    String caretakerId,
    String reason,
  ) async {
    try {
      await _database.ref('assistance_requests/$requestId').update({
        'status': 'declined',
        'responseTime': DateTime.now().toIso8601String(),
        'caretakerResponse': reason,
      });
      
      debugPrint('Request $requestId declined: $reason');
      return true;
    } catch (e) {
      debugPrint('Error declining request: $e');
      return false;
    }
  }
  
  /// Complete a request
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
      
      debugPrint('Request $requestId completed');
      return true;
    } catch (e) {
      debugPrint('Error completing request: $e');
      return false;
    }
  }
  
  /// Update request status to inProgress
  Future<bool> markRequestInProgress(String requestId) async {
    try {
      await _database.ref('assistance_requests/$requestId').update({
        'status': 'inProgress',
      });
      
      return true;
    } catch (e) {
      debugPrint('Error marking request in progress: $e');
      return false;
    }
  }
  
  /// Update request status
  Future<bool> updateRequestStatus(
    String requestId,
    RequestStatus status,
  ) async {
    try {
      await _database.ref('assistance_requests/$requestId').update({
        'status': status.toString().split('.').last,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating request status: $e');
      return false;
    }
  }
  
  /// Delete a request
  Future<bool> deleteRequest(String requestId) async {
    try {
      await _database.ref('assistance_requests/$requestId').remove();
      return true;
    } catch (e) {
      debugPrint('Error deleting request: $e');
      return false;
    }
  }
  
  /// Get requests by status
  Future<List<RequestModel>> getRequestsByStatus(
    String caretakerId,
    RequestStatus status,
  ) async {
    try {
      final allRequests = await getCaretakerRequests(caretakerId);
      return allRequests.where((req) => req.status == status).toList();
    } catch (e) {
      debugPrint('Error getting requests by status: $e');
      return [];
    }
  }
}

// Create singleton instance
final AssistanceRequestService assistanceRequestService = AssistanceRequestService();