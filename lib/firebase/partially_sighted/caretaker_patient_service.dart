import 'package:firebase_database/firebase_database.dart';
import '../database_service.dart';

/// Service for managing caretaker-patient relationships
class CaretakerPatientService {
  final FirebaseDatabase _database = databaseService.database;

  // ==================== CARETAKER-PATIENT MANAGEMENT ====================

  /// Link a caretaker to a patient
  Future<void> assignCaretakerToPatient({
    required String caretakerId,
    required String patientId,
  }) async {
    try {
      // Add patient to caretaker's list
      await _database.ref('user_info/caretaker/$caretakerId/assignedPatients/$patientId').set(true);
      
      // Add caretaker to patient's list
      await _database.ref('user_info/partially_sighted/$patientId/assignedCaretakers/$caretakerId').set(true);
      
      // Update timestamps
      await _database.ref('user_info/caretaker/$caretakerId/updatedAt').set(ServerValue.timestamp);
      await _database.ref('user_info/partially_sighted/$patientId/updatedAt').set(ServerValue.timestamp);
    } catch (e) {
      throw Exception('Failed to assign caretaker: $e');
    }
  }

  /// Remove caretaker from patient
  Future<void> removeCaretakerFromPatient({
    required String caretakerId,
    required String patientId,
  }) async {
    try {
      // Remove patient from caretaker's list
      await _database.ref('user_info/caretaker/$caretakerId/assignedPatients/$patientId').remove();
      
      // Remove caretaker from patient's list
      await _database.ref('user_info/partially_sighted/$patientId/assignedCaretakers/$caretakerId').remove();
      
      // Update timestamps
      await _database.ref('user_info/caretaker/$caretakerId/updatedAt').set(ServerValue.timestamp);
      await _database.ref('user_info/partially_sighted/$patientId/updatedAt').set(ServerValue.timestamp);
    } catch (e) {
      throw Exception('Failed to remove caretaker: $e');
    }
  }

  /// Get all patients assigned to a caretaker
  Future<List<Map<String, dynamic>>> getCaretakerPatients(String caretakerId) async {
    try {
      Map<String, dynamic>? caretakerData = await databaseService.getUserDataByRole(caretakerId, 'caretaker');
      if (caretakerData == null) return [];

      Map<dynamic, dynamic>? patientIdsMap = caretakerData['assignedPatients'] as Map?;
      if (patientIdsMap == null || patientIdsMap.isEmpty) return [];

      List<Map<String, dynamic>> patients = [];

      for (String patientId in patientIdsMap.keys) {
        Map<String, dynamic>? patientData = await databaseService.getUserDataByRole(patientId, 'partially_sighted');
        if (patientData != null) {
          patients.add({...patientData, 'userId': patientId});
        }
      }

      return patients;
    } catch (e) {
      throw Exception('Failed to get caretaker patients: $e');
    }
  }

  /// Get all caretakers assigned to a patient
  Future<List<Map<String, dynamic>>> getPatientCaretakers(String patientId) async {
    try {
      Map<String, dynamic>? patientData = await databaseService.getUserDataByRole(patientId, 'partially_sighted');
      if (patientData == null) return [];

      Map<dynamic, dynamic>? caretakerIdsMap = patientData['assignedCaretakers'] as Map?;
      if (caretakerIdsMap == null || caretakerIdsMap.isEmpty) return [];

      List<Map<String, dynamic>> caretakers = [];

      for (String caretakerId in caretakerIdsMap.keys) {
        Map<String, dynamic>? caretakerData = await databaseService.getUserDataByRole(caretakerId, 'caretaker');
        if (caretakerData != null) {
          caretakers.add({...caretakerData, 'userId': caretakerId});
        }
      }

      return caretakers;
    } catch (e) {
      throw Exception('Failed to get patient caretakers: $e');
    }
  }

  /// Stream of caretaker's patients for real-time updates
  Stream<List<Map<String, dynamic>>> streamCaretakerPatients(String caretakerId) {
    return _database
        .ref('user_info/caretaker/$caretakerId/assignedPatients')
        .onValue
        .asyncMap((event) async {
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> patientIdsMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> patients = [];

      for (String patientId in patientIdsMap.keys) {
        Map<String, dynamic>? patientData = await databaseService.getUserDataByRole(patientId, 'partially_sighted');
        if (patientData != null) {
          patients.add({...patientData, 'userId': patientId});
        }
      }

      return patients;
    });
  }

  /// Stream of patient's caretakers for real-time updates
  Stream<List<Map<String, dynamic>>> streamPatientCaretakers(String patientId) {
    return _database
        .ref('user_info/partially_sighted/$patientId/assignedCaretakers')
        .onValue
        .asyncMap((event) async {
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> caretakerIdsMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> caretakers = [];

      for (String caretakerId in caretakerIdsMap.keys) {
        Map<String, dynamic>? caretakerData = await databaseService.getUserDataByRole(caretakerId, 'caretaker');
        if (caretakerData != null) {
          caretakers.add({...caretakerData, 'userId': caretakerId});
        }
      }

      return caretakers;
    });
  }
}

// Create a singleton instance
final CaretakerPatientService caretakerPatientService = CaretakerPatientService();