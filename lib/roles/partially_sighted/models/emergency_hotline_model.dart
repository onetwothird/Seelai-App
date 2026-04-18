// File: lib/roles/partially_sighted/models/emergency_hotline_model.dart

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
  final bool isPredefined;
  final String imageAsset;

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
    this.isPredefined = false,
    this.imageAsset = '',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // --- NEW HELPER METHOD ---
  // Keeps tree-shaking intact by mapping dynamic integers to constant IconData.
  static IconData _getSafeIconFromCode(int codePoint) {
    if (codePoint == Icons.local_police_rounded.codePoint) return Icons.local_police_rounded;
    if (codePoint == Icons.local_fire_department_rounded.codePoint) return Icons.local_fire_department_rounded;
    if (codePoint == Icons.emergency_rounded.codePoint) return Icons.emergency_rounded;
    if (codePoint == Icons.security_rounded.codePoint) return Icons.security_rounded;
    if (codePoint == Icons.medical_services_rounded.codePoint) return Icons.medical_services_rounded;
    if (codePoint == Icons.eco_rounded.codePoint) return Icons.eco_rounded;
    if (codePoint == Icons.local_hospital_rounded.codePoint) return Icons.local_hospital_rounded;
    if (codePoint == Icons.account_balance_rounded.codePoint) return Icons.account_balance_rounded;
    if (codePoint == Icons.phone_in_talk_rounded.codePoint) return Icons.phone_in_talk_rounded;
    
    // Fallback icon
    return Icons.phone_rounded;
  }

  // Create from JSON
  factory EmergencyHotline.fromJson(Map<String, dynamic> json) {
    return EmergencyHotline(
      id: json['id'] as String,
      departmentName: json['departmentName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      address: json['address'] as String,
      description: json['description'] as String? ?? '',
      // FIX: Used the safe mapper instead of dynamic IconData parsing
      icon: _getSafeIconFromCode(json['iconCode'] as int? ?? Icons.phone_rounded.codePoint),
      // THIS IS THE FIX: Using Color.fromARGB32 instead of Color()
      color: Color(json['colorValue'] as int),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isPredefined: json['isPredefined'] as bool? ?? false,
      imageAsset: json['imageAsset'] as String? ?? '',
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
      // THIS IS THE FIX: Using toARGB32() instead of .value
      'colorValue': color.toARGB32(),
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPredefined': isPredefined,
      'imageAsset': imageAsset,
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
    bool? isPredefined,
    String? imageAsset,
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
      isPredefined: isPredefined ?? this.isPredefined,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }

  @override
  String toString() {
    return 'EmergencyHotline(department: $departmentName, phone: $phoneNumber, image: $imageAsset)';
  }

  // Predefined emergency hotlines for Naic, Cavite
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
        imageAsset: 'assets/emergency_images/pnp.png',
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
        imageAsset: 'assets/emergency_images/bfp.png',
      ),
      EmergencyHotline(
        id: 'predefined_emergency_$userId',
        departmentName: 'MDRRMO Naic',
        phoneNumber: '4105725',
        address: '',
        description: 'Naic Emergency Response Unit',
        icon: Icons.emergency_rounded,
        color: Colors.orange,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        isPredefined: true,
        imageAsset: 'assets/emergency_images/mdrrmo.png',
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
        imageAsset: 'assets/emergency_images/dilg.png',
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
        imageAsset: 'assets/emergency_images/mswd.png',
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
        imageAsset: 'assets/emergency_images/menro.png',
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
        imageAsset: 'assets/emergency_images/rural_health.png',
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
        imageAsset: 'assets/emergency_images/office_mayor.png',
      ),
      EmergencyHotline(
        id: 'predefined_naic_doctors_$userId',
        departmentName: 'Naic Doctors Hospital',
        phoneNumber: '(046) 412 1443',
        address: '',
        description: 'Private Hospital',
        icon: Icons.local_hospital_rounded,
        color: Colors.blueAccent,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        isPredefined: true,
        imageAsset: 'assets/emergency_images/naic_doctors.jpg',
      ),
    ];
  }

  // Predefined emergency hotline templates for quick setup
  static List<Map<String, dynamic>> getDefaultHotlineTemplates() {
    return [
      {
        'departmentName': 'Police Station',
        'iconCode': Icons.local_police_rounded.codePoint,
        // THESE ARE THE FIXES: Using toARGB32() on the Colors
        'colorValue': Colors.blue.toARGB32(),
        'description': 'Emergency police assistance',
        'imageAsset': '',
      },
      {
        'departmentName': 'Fire Station',
        'iconCode': Icons.local_fire_department_rounded.codePoint,
        'colorValue': Colors.red.toARGB32(),
        'description': 'Fire and rescue services',
        'imageAsset': '',
      },
      {
        'departmentName': 'Hospital/Ambulance',
        'iconCode': Icons.local_hospital_rounded.codePoint,
        'colorValue': Colors.green.toARGB32(),
        'description': 'Medical emergency services',
        'imageAsset': '',
      },
      {
        'departmentName': 'Emergency Hotline',
        'iconCode': Icons.phone_in_talk_rounded.codePoint,
        'colorValue': Colors.orange.toARGB32(),
        'description': 'General emergency hotline',
        'imageAsset': '',
      },
    ];
  }
}