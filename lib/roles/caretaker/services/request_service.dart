import 'package:flutter/foundation.dart';
import 'package:seelai_app/roles/caretaker/models/request_model.dart';
import 'package:seelai_app/firebase/assistance_request_service.dart';

class RequestService {
  final AssistanceRequestService _assistanceRequestService = assistanceRequestService;
  final List<Function(RequestModel)> _listeners = [];

  // Add listener for new requests
  void addListener(Function(RequestModel) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(RequestModel) listener) {
    _listeners.remove(listener);
  }

  // Get pending requests for caretaker
  Future<List<RequestModel>> getPendingRequests(String caretakerId) async {
    try {
      return await _assistanceRequestService.getPendingRequests(caretakerId);
    } catch (e) {
      debugPrint('Error getting pending requests: $e');
      return [];
    }
  }

  // Get all requests (with filter)
  Future<List<RequestModel>> getRequests(
    String caretakerId, {
    RequestStatus? status,
  }) async {
    try {
      if (status != null) {
        return await _assistanceRequestService.getRequestsByStatus(caretakerId, status);
      }
      return await _assistanceRequestService.getCaretakerRequests(caretakerId);
    } catch (e) {
      debugPrint('Error getting requests: $e');
      return [];
    }
  }

  // Stream requests (real-time)
  Stream<List<RequestModel>> streamRequests(String caretakerId) {
    return _assistanceRequestService.streamCaretakerRequests(caretakerId);
  }

  // Accept a request
  Future<bool> acceptRequest(String requestId, String caretakerId) async {
    try {
      return await _assistanceRequestService.acceptRequest(requestId, caretakerId);
    } catch (e) {
      debugPrint('Error accepting request: $e');
      return false;
    }
  }

  // Decline a request
  Future<bool> declineRequest(
    String requestId,
    String caretakerId,
    String reason,
  ) async {
    try {
      return await _assistanceRequestService.declineRequest(requestId, caretakerId, reason);
    } catch (e) {
      debugPrint('Error declining request: $e');
      return false;
    }
  }

  // Mark request as in progress
  Future<bool> markInProgress(String requestId) async {
    try {
      return await _assistanceRequestService.markRequestInProgress(requestId);
    } catch (e) {
      debugPrint('Error marking request in progress: $e');
      return false;
    }
  }

  // Complete a request
  Future<bool> completeRequest(
    String requestId,
    String caretakerId,
    String notes,
  ) async {
    try {
      return await _assistanceRequestService.completeRequest(requestId, caretakerId, notes);
    } catch (e) {
      debugPrint('Error completing request: $e');
      return false;
    }
  }

  // Send message to patient (placeholder)
  Future<bool> sendMessage(
    String patientId,
    String caretakerId,
    String message,
  ) async {
    try {
      await Future.delayed(Duration(milliseconds: 300));
      debugPrint('Message sent to patient $patientId');
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }
}