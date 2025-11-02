// File: lib/roles/caretaker/models/activity_model.dart
import 'package:flutter/material.dart';

class ActivityModel {
  final String patientName;
  final String action;
  final String description;
  final DateTime timestamp;
  final IconData icon;
  final bool isEmergency;
  final bool isPending;

  ActivityModel({
    required this.patientName,
    required this.action,
    required this.description,
    required this.timestamp,
    required this.icon,
    this.isEmergency = false,
    this.isPending = false,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      patientName: json['patientName'] as String,
      action: json['action'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      icon: IconData(
        json['iconCode'] as int,
        fontFamily: 'MaterialIcons',
      ),
      isEmergency: json['isEmergency'] as bool? ?? false,
      isPending: json['isPending'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientName': patientName,
      'action': action,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'iconCode': icon.codePoint,
      'isEmergency': isEmergency,
      'isPending': isPending,
    };
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}