import 'package:firebase_database/firebase_database.dart';
import '../database_service.dart';

/// Service for managing medical information (for visually impaired users)
class MedicalInfoService {
  final FirebaseDatabase _database = databaseService.database;

  // ==================== MEDICAL INFO ====================

  /// Update medical information for visually impaired user
  Future<void> updateMedicalInfo({
    required String userId,
    List<String>? conditions,
    List<String>? medications,
    List<String>? allergies,
    String? lastCheckup,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (conditions != null) updates['medicalInfo/conditions'] = conditions;
      if (medications != null) updates['medicalInfo/medications'] = medications;
      if (allergies != null) updates['medicalInfo/allergies'] = allergies;
      if (lastCheckup != null) updates['medicalInfo/lastCheckup'] = lastCheckup;
      
      updates['updatedAt'] = ServerValue.timestamp;

      await _database.ref('user_info/visually_impaired/$userId').update(updates);
    } catch (e) {
      throw Exception('Failed to update medical info: $e');
    }
  }

  /// Get medical information for a user
  Future<Map<String, dynamic>?> getMedicalInfo(String userId) async {
    try {
      DatabaseEvent event = await _database
          .ref('user_info/visually_impaired/$userId/medicalInfo')
          .once();
      
      if (!event.snapshot.exists) return null;
      
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    } catch (e) {
      throw Exception('Failed to get medical info: $e');
    }
  }

  /// Add a medical condition
  Future<void> addMedicalCondition({
    required String userId,
    required String condition,
  }) async {
    try {
      // Get current conditions
      Map<String, dynamic>? medicalInfo = await getMedicalInfo(userId);
      List<String> conditions = [];
      
      if (medicalInfo != null && medicalInfo['conditions'] != null) {
        conditions = List<String>.from(medicalInfo['conditions']);
      }
      
      if (!conditions.contains(condition)) {
        conditions.add(condition);
        await updateMedicalInfo(userId: userId, conditions: conditions);
      }
    } catch (e) {
      throw Exception('Failed to add medical condition: $e');
    }
  }

  /// Remove a medical condition
  Future<void> removeMedicalCondition({
    required String userId,
    required String condition,
  }) async {
    try {
      Map<String, dynamic>? medicalInfo = await getMedicalInfo(userId);
      
      if (medicalInfo != null && medicalInfo['conditions'] != null) {
        List<String> conditions = List<String>.from(medicalInfo['conditions']);
        conditions.remove(condition);
        await updateMedicalInfo(userId: userId, conditions: conditions);
      }
    } catch (e) {
      throw Exception('Failed to remove medical condition: $e');
    }
  }

  /// Add a medication
  Future<void> addMedication({
    required String userId,
    required String medication,
  }) async {
    try {
      Map<String, dynamic>? medicalInfo = await getMedicalInfo(userId);
      List<String> medications = [];
      
      if (medicalInfo != null && medicalInfo['medications'] != null) {
        medications = List<String>.from(medicalInfo['medications']);
      }
      
      if (!medications.contains(medication)) {
        medications.add(medication);
        await updateMedicalInfo(userId: userId, medications: medications);
      }
    } catch (e) {
      throw Exception('Failed to add medication: $e');
    }
  }

  /// Remove a medication
  Future<void> removeMedication({
    required String userId,
    required String medication,
  }) async {
    try {
      Map<String, dynamic>? medicalInfo = await getMedicalInfo(userId);
      
      if (medicalInfo != null && medicalInfo['medications'] != null) {
        List<String> medications = List<String>.from(medicalInfo['medications']);
        medications.remove(medication);
        await updateMedicalInfo(userId: userId, medications: medications);
      }
    } catch (e) {
      throw Exception('Failed to remove medication: $e');
    }
  }

  /// Add an allergy
  Future<void> addAllergy({
    required String userId,
    required String allergy,
  }) async {
    try {
      Map<String, dynamic>? medicalInfo = await getMedicalInfo(userId);
      List<String> allergies = [];
      
      if (medicalInfo != null && medicalInfo['allergies'] != null) {
        allergies = List<String>.from(medicalInfo['allergies']);
      }
      
      if (!allergies.contains(allergy)) {
        allergies.add(allergy);
        await updateMedicalInfo(userId: userId, allergies: allergies);
      }
    } catch (e) {
      throw Exception('Failed to add allergy: $e');
    }
  }

  /// Remove an allergy
  Future<void> removeAllergy({
    required String userId,
    required String allergy,
  }) async {
    try {
      Map<String, dynamic>? medicalInfo = await getMedicalInfo(userId);
      
      if (medicalInfo != null && medicalInfo['allergies'] != null) {
        List<String> allergies = List<String>.from(medicalInfo['allergies']);
        allergies.remove(allergy);
        await updateMedicalInfo(userId: userId, allergies: allergies);
      }
    } catch (e) {
      throw Exception('Failed to remove allergy: $e');
    }
  }

  /// Stream of medical info for real-time updates
  Stream<Map<String, dynamic>?> streamMedicalInfo(String userId) {
    return _database
        .ref('user_info/visually_impaired/$userId/medicalInfo')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }
}

// Create a singleton instance
final MedicalInfoService medicalInfoService = MedicalInfoService();