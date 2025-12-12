// File: lib/roles/visually_impaired/home/sections/home_screen/data/predefined_emergency_hotlines.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/roles/visually_impaired/models/emergency_hotline_model.dart';

class PredefinedEmergencyHotlines {
  /// Get list of predefined emergency hotlines for Naic, Cavite
  static List<EmergencyHotline> getNaicHotlines(String userId) {
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
  
  /// Check if user needs predefined hotlines initialized
  static bool needsInitialization(List<EmergencyHotline> existingHotlines) {
    // Check if any predefined hotlines exist
    final hasPredefined = existingHotlines.any((h) => h.isPredefined == true);
    return !hasPredefined;
  }
}