// File: lib/roles/visually_impaired/services/caretaker_request_service.dart
import 'package:flutter/foundation.dart';

class CaretakerRequestService {
  final List<Function(CaretakerRequest)> _listeners = [];

  /// Send a request to caretaker
  Future<bool> sendCaretakerRequest({
    required String userId,
    required String userName,
    required String requestType,
    String? message,
    Map<String, dynamic>? location,
  }) async {
    try {
      final request = CaretakerRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userName: userName,
        requestType: requestType,
        message: message ?? 'User needs assistance',
        location: location,
        timestamp: DateTime.now(),
        status: RequestStatus.pending,
      );

      // Notify all listeners about the new request
      for (var listener in _listeners) {
        listener(request);
      }

      debugPrint('Caretaker request sent: ${request.requestType}');
      
      // TODO: Send push notification to caretaker
      // TODO: Save request to database
      
      return true;
    } catch (e) {
      debugPrint('Error sending caretaker request: $e');
      return false;
    }
  }

  /// Add a listener for caretaker requests
  void addListener(Function(CaretakerRequest) listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(Function(CaretakerRequest) listener) {
    _listeners.remove(listener);
  }

  /// Clear all listeners
  void clearListeners() {
    _listeners.clear();
  }

  /// Check if caretaker is available
  Future<bool> checkCaretakerAvailability(String caretakerId) async {
    // TODO: Implement actual availability check from database
    // For now, return true as a placeholder
    await Future.delayed(Duration(milliseconds: 500));
    return true;
  }

  /// Get caretaker request history
  Future<List<CaretakerRequest>> getRequestHistory(String userId) async {
    // TODO: Fetch from database
    return [];
  }
}

// Request status enum
enum RequestStatus {
  pending,
  accepted,
  declined,
  completed,
  cancelled,
}

// Caretaker request model
class CaretakerRequest {
  final String id;
  final String userId;
  final String userName;
  final String requestType;
  final String message;
  final Map<String, dynamic>? location;
  final DateTime timestamp;
  final RequestStatus status;
  final String? caretakerResponse;
  final DateTime? responseTime;

  CaretakerRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.requestType,
    required this.message,
    this.location,
    required this.timestamp,
    required this.status,
    this.caretakerResponse,
    this.responseTime,
  });

  // Create from JSON
  factory CaretakerRequest.fromJson(Map<String, dynamic> json) {
    return CaretakerRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      requestType: json['requestType'] as String,
      message: json['message'] as String,
      location: json['location'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: RequestStatus.values.firstWhere(
        (e) => e.toString() == 'RequestStatus.${json['status']}',
        orElse: () => RequestStatus.pending,
      ),
      caretakerResponse: json['caretakerResponse'] as String?,
      responseTime: json['responseTime'] != null
          ? DateTime.parse(json['responseTime'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'requestType': requestType,
      'message': message,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'caretakerResponse': caretakerResponse,
      'responseTime': responseTime?.toIso8601String(),
    };
  }

  // Copy with method
  CaretakerRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? requestType,
    String? message,
    Map<String, dynamic>? location,
    DateTime? timestamp,
    RequestStatus? status,
    String? caretakerResponse,
    DateTime? responseTime,
  }) {
    return CaretakerRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      requestType: requestType ?? this.requestType,
      message: message ?? this.message,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      caretakerResponse: caretakerResponse ?? this.caretakerResponse,
      responseTime: responseTime ?? this.responseTime,
    );
  }

  @override
  String toString() {
    return 'CaretakerRequest(type: $requestType, user: $userName, status: $status)';
  }
}