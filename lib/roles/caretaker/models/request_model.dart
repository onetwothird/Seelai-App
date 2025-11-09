import 'package:flutter/material.dart';

enum RequestStatus {
  pending,
  accepted,
  inProgress,
  completed,
  declined,
}

enum RequestPriority {
  low,
  medium,
  high,
  emergency,
}

class RequestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String? caretakerId;
  final String requestType;
  final String message;
  final RequestStatus status;
  final RequestPriority priority;
  final DateTime timestamp;
  final Map<String, dynamic>? location;
  final String? caretakerResponse;
  final DateTime? responseTime;
  final DateTime? completedTime;

  RequestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.caretakerId,
    required this.requestType,
    required this.message,
    required this.status,
    this.priority = RequestPriority.medium,
    required this.timestamp,
    this.location,
    this.caretakerResponse,
    this.responseTime,
    this.completedTime,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json, String id) {
    return RequestModel(
      id: id,
      patientId: json['patientId'] as String? ?? json['userId'] as String,
      patientName: json['patientName'] as String? ?? json['userName'] as String,
      caretakerId: json['caretakerId'] as String?,
      requestType: json['requestType'] as String,
      message: json['message'] as String,
      status: _parseStatus(json['status'] as String?),
      priority: _parsePriority(json['priority'] as String?),
      timestamp: DateTime.parse(json['timestamp'] as String),
      location: json['location'] as Map<String, dynamic>?,
      caretakerResponse: json['caretakerResponse'] as String?,
      responseTime: json['responseTime'] != null
          ? DateTime.parse(json['responseTime'] as String)
          : null,
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'] as String)
          : null,
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

  static RequestPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'high':
        return RequestPriority.high;
      case 'emergency':
        return RequestPriority.emergency;
      case 'low':
        return RequestPriority.low;
      default:
        return RequestPriority.medium;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'caretakerId': caretakerId,
      'requestType': requestType,
      'message': message,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'caretakerResponse': caretakerResponse,
      'responseTime': responseTime?.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
    };
  }

  RequestModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? caretakerId,
    String? requestType,
    String? message,
    RequestStatus? status,
    RequestPriority? priority,
    DateTime? timestamp,
    Map<String, dynamic>? location,
    String? caretakerResponse,
    DateTime? responseTime,
    DateTime? completedTime,
  }) {
    return RequestModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      caretakerId: caretakerId ?? this.caretakerId,
      requestType: requestType ?? this.requestType,
      message: message ?? this.message,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      caretakerResponse: caretakerResponse ?? this.caretakerResponse,
      responseTime: responseTime ?? this.responseTime,
      completedTime: completedTime ?? this.completedTime,
    );
  }

  IconData getIcon() {
    switch (requestType) {
      case 'Emergency':
      case 'Emergency Help':
        return Icons.emergency_rounded;
      case 'Navigation Help':
        return Icons.directions_rounded;
      case 'Reading Assistance':
        return Icons.text_fields_rounded;
      case 'General Assistance':
        return Icons.help_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color getPriorityColor() {
    switch (priority) {
      case RequestPriority.emergency:
        return Colors.red;
      case RequestPriority.high:
        return Colors.orange;
      case RequestPriority.medium:
        return Colors.blue;
      case RequestPriority.low:
        return Colors.green;
    }
  }
}