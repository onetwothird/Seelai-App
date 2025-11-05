import 'package:flutter/foundation.dart';
import 'package:seelai_app/roles/caretaker/models/patient_model.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:seelai_app/firebase/caretaker_patient_service.dart';

class PatientService {
  final DatabaseService _databaseService = databaseService;
  final CaretakerPatientService _caretakerPatientService = caretakerPatientService;

  // Get all assigned patients for a caretaker
  Future<List<PatientModel>> getAssignedPatients(String caretakerId) async {
    try {
      final patientsData = await _caretakerPatientService.getCaretakerPatients(caretakerId);
      
      return patientsData.map((data) {
        return PatientModel.fromJson(data, data['userId'] as String);
      }).toList();
    } catch (e) {
      debugPrint('Error getting assigned patients: $e');
      return [];
    }
  }

  // Get single patient details
  Future<PatientModel?> getPatientDetails(String patientId) async {
    try {
      final patientData = await _databaseService.getUserDataByRole(
        patientId,
        'visually_impaired',
      );
      
      if (patientData != null) {
        return PatientModel.fromJson(patientData, patientId);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting patient details: $e');
      return null;
    }
  }

  // Make call to patient
  Future<bool> callPatient(String phoneNumber) async {
    try {
      // TODO: Use url_launcher to make phone call
      debugPrint('Calling patient: $phoneNumber');
      await Future.delayed(Duration(milliseconds: 300));
      return true;
    } catch (e) {
      debugPrint('Error calling patient: $e');
      return false;
    }
  }

  // Send SMS to patient
  Future<bool> sendSMS(String phoneNumber, String message) async {
    try {
      // TODO: Use url_launcher to send SMS
      debugPrint('Sending SMS to $phoneNumber: $message');
      await Future.delayed(Duration(milliseconds: 300));
      return true;
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return false;
    }
  }
}