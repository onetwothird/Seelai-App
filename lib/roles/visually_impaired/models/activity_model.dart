// File: lib/roles/visually_impaired/models/activity_model.dart
import 'package:flutter/material.dart';

class ActivityModel {
  final String title;
  final String description;
  final IconData icon;
  final bool isEmergency;
  final DateTime? timestamp;

  ActivityModel({
    required this.title,
    required this.description,
    required this.icon,
    this.isEmergency = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Create from JSON
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      title: json['title'] as String,
      description: json['description'] as String,
      icon: IconData(
        json['iconCode'] as int,
        fontFamily: 'MaterialIcons',
      ),
      isEmergency: json['isEmergency'] as bool? ?? false,
      timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'iconCode': icon.codePoint,
      'isEmergency': isEmergency,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  // Copy with method for immutable updates
  ActivityModel copyWith({
    String? title,
    String? description,
    IconData? icon,
    bool? isEmergency,
    DateTime? timestamp,
  }) {
    return ActivityModel(
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isEmergency: isEmergency ?? this.isEmergency,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'ActivityModel(title: $title, description: $description, isEmergency: $isEmergency)';
  }
}