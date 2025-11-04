// File: lib/roles/visually_impaired/models/emergency_hotline_model.dart
import 'package:flutter/material.dart';

class EmergencyHotline {
  final String id;
  final String departmentName;
  final String phoneNumber;
  final String address;
  final String description;
  final IconData icon;
  final Color color;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmergencyHotline({
    required this.id,
    required this.departmentName,
    required this.phoneNumber,
    required this.address,
    this.description = '',
    required this.icon,
    required this.color,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create from JSON
  factory EmergencyHotline.fromJson(Map<String, dynamic> json) {
    return EmergencyHotline(
      id: json['id'] as String,
      departmentName: json['departmentName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      address: json['address'] as String,
      description: json['description'] as String? ?? '',
      icon: IconData(
        json['iconCode'] as int,
        fontFamily: 'MaterialIcons',
      ),
      color: Color(json['colorValue'] as int),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'departmentName': departmentName,
      'phoneNumber': phoneNumber,
      'address': address,
      'description': description,
      'iconCode': icon.codePoint,
      'colorValue': color.value,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Copy with method
  EmergencyHotline copyWith({
    String? id,
    String? departmentName,
    String? phoneNumber,
    String? address,
    String? description,
    IconData? icon,
    Color? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyHotline(
      id: id ?? this.id,
      departmentName: departmentName ?? this.departmentName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'EmergencyHotline(department: $departmentName, phone: $phoneNumber, address: $address)';
  }

  // Predefined emergency hotline types for quick setup
  static List<Map<String, dynamic>> getDefaultHotlineTemplates() {
    return [
      {
        'departmentName': 'Police Station',
        'iconCode': Icons.local_police_rounded.codePoint,
        'colorValue': Colors.blue.value,
        'description': 'Emergency police assistance',
      },
      {
        'departmentName': 'Fire Station',
        'iconCode': Icons.local_fire_department_rounded.codePoint,
        'colorValue': Colors.red.value,
        'description': 'Fire and rescue services',
      },
      {
        'departmentName': 'Hospital/Ambulance',
        'iconCode': Icons.local_hospital_rounded.codePoint,
        'colorValue': Colors.green.value,
        'description': 'Medical emergency services',
      },
      {
        'departmentName': 'Emergency Hotline',
        'iconCode': Icons.phone_in_talk_rounded.codePoint,
        'colorValue': Colors.orange.value,
        'description': 'General emergency hotline',
      },
    ];
  }
}