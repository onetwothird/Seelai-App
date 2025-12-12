// File: lib/roles/visually_impaired/models/emergency_hotline_model.dart
// ignore_for_file: deprecated_member_use

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
  final bool isPredefined; // NEW: Flag to indicate if this is a predefined hotline

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
    this.isPredefined = false, // NEW: Default to false for user-created hotlines
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
      isPredefined: json['isPredefined'] as bool? ?? false, // NEW
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
      'isPredefined': isPredefined, // NEW
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
    bool? isPredefined, // NEW
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
      isPredefined: isPredefined ?? this.isPredefined, // NEW
    );
  }

  @override
  String toString() {
    return 'EmergencyHotline(department: $departmentName, phone: $phoneNumber, address: $address, isPredefined: $isPredefined)';
  }

  // NEW: Predefined emergency hotlines for Naic, Cavite
  static List<EmergencyHotline> getNaicPredefinedHotlines(String userId) {
    final now = DateTime.now();
    
    return [
      EmergencyHotline(
        id: 'predefined_police_$userId',
        departmentName: 'Municipal Police Station',
        phoneNumber: '09564118101',
        address: '',
        description: '',
        icon: Icons.local_police_rounded,
        color: Colors.blue,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        isPredefined: true,
      ),
      EmergencyHotline(
        id: 'predefined_fire_$userId',
        departmentName: 'Bureau of Fire Protection',
        phoneNumber: '09564830226',
        address: '',
        description: '',
        icon: Icons.local_fire_department_rounded,
        color: Colors.red,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        isPredefined: true,
      ),
      EmergencyHotline(
        id: 'predefined_emergency_$userId',
        departmentName: 'Naic Emergency Response Unit',
        phoneNumber: '4105725',
        address: '',
        description: '',
        icon: Icons.emergency_rounded,
        color: Colors.orange,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        isPredefined: true,
      ),
      EmergencyHotline(
        id: 'predefined_dilg_$userId',
        departmentName: 'DILG - Naic',
        phoneNumber: '09565298870',
        address: '',
        description: '',
        icon: Icons.security_rounded,
        color: Colors.purple,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        isPredefined: true,
      ),
      EmergencyHotline(
        id: 'predefined_mswdo_$userId',
        departmentName: 'MSWDO - Naic',
        phoneNumber: '09267511296',
        address: '',
        description: '',
        icon: Icons.medical_services_rounded,
        color: Colors.teal,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        isPredefined: true,
      ),
      EmergencyHotline(
        id: 'predefined_menro_$userId',
        departmentName: 'MENRO - Naic',
        phoneNumber: '09178324244',
        address: '',
        description: '',
        icon: Icons.eco_rounded,
        color: Colors.green,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        isPredefined: true,
      ),
      EmergencyHotline(
        id: 'predefined_rhu_$userId',
        departmentName: 'Rural Health Unit',
        phoneNumber: '09457261593',
        address: '',
        description: '',
        icon: Icons.local_hospital_rounded,
        color: Colors.pink,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        isPredefined: true,
      ),
      EmergencyHotline(
        id: 'predefined_mayor_$userId',
        departmentName: 'Office of the Mayor',
        phoneNumber: '0465070541',
        address: '',
        description: '',
        icon: Icons.account_balance_rounded,
        color: Colors.amber,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        isPredefined: true,
      ),
    ];
  }

  // Predefined emergency hotline templates for quick setup
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