/// Firebase Services - Centralized export file
/// This file exports all Firebase database services for easy importing
library;

// Core database service
export 'database_service.dart';

// Specialized services
export 'activity_logs_service.dart';
export 'visually_impaired/caretaker_patient_service.dart';
export 'visually_impaired/emergency_contacts_service.dart';
export 'visually_impaired/emergency_hotline_service.dart';
export 'visually_impaired/medical_info_service.dart';
export 'admin_service.dart';
export 'assistance_request_service.dart';
export 'auth_service.dart';


/// Usage Example:
/// 
/// Instead of importing individual files:
/// ```dart
/// import 'package:seelai_app/firebase/database_service.dart';
/// import 'package:seelai_app/firebase/activity_logs_service.dart';
/// import 'package:seelai_app/firebase/caretaker_patient_service.dart';
/// ```
/// 
/// You can now import all services at once:
/// ```dart
/// import 'package:seelai_app/firebase/firebase_services.dart';
/// ```
/// 
/// Then use them like:
/// ```dart
/// await databaseService.getUserData(userId);
/// await activityLogsService.logActivity(userId: userId, action: 'login');
/// await caretakerPatientService.assignCaretakerToPatient(
///   caretakerId: caretakerId,
///   patientId: patientId,
/// );
/// ```