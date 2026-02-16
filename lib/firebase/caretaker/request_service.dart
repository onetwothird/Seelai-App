import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/firebase/caretaker/assistance_request_service.dart';
import 'package:seelai_app/firebase/caretaker/request_transaction_service.dart';

class RequestService {
  final AssistanceRequestService _assistanceRequestService = assistanceRequestService;
  final RequestTransactionService _transactionService = requestTransactionService;
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
      bool success = await _assistanceRequestService.acceptRequest(requestId, caretakerId);
      
      if (success) {
        // Get request details for transaction logging
        final request = await _assistanceRequestService.getRequestById(requestId);
        if (request != null) {
          await _transactionService.logRequestAccepted(
            requestId,
            request.patientId,
            caretakerId,
          );
        }
      }
      
      return success;
    } catch (e) {
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
      bool success = await _assistanceRequestService.declineRequest(requestId, caretakerId, reason);
      
      if (success) {
        final request = await _assistanceRequestService.getRequestById(requestId);
        if (request != null) {
          await _transactionService.logRequestDeclined(
            requestId,
            request.patientId,
            caretakerId,
            reason,
          );
        }
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  // Mark request as in progress
  Future<bool> markInProgress(String requestId) async {
    try {
      bool success = await _assistanceRequestService.markRequestInProgress(requestId);
      
      if (success) {
        final request = await _assistanceRequestService.getRequestById(requestId);
        if (request != null && request.caretakerId != null) {
          await _transactionService.logRequestInProgress(
            requestId,
            request.patientId,
            request.caretakerId!,
          );
        }
      }
      
      return success;
    } catch (e) {
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
      bool success = await _assistanceRequestService.completeRequest(requestId, caretakerId, notes);
      
      if (success) {
        final request = await _assistanceRequestService.getRequestById(requestId);
        if (request != null) {
          await _transactionService.logRequestCompleted(
            requestId,
            request.patientId,
            caretakerId,
            notes,
          );
        }
      }
      
      return success;
    } catch (e) {
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
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get transaction history for a request
  Future<List<RequestTransaction>> getRequestTransactionHistory(String requestId) async {
    try {
      return await _transactionService.getRequestTransactions(requestId);
    } catch (e) {
      return [];
    }
  }

  // Stream transaction history for a request
  Stream<List<RequestTransaction>> streamRequestTransactionHistory(String requestId) {
    return _transactionService.streamRequestTransactions(requestId);
  }
}