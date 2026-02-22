/// Firebase Services - Centralized export file
/// This file exports all Firebase database services for easy importing
library;

// Core database service
export 'database_service.dart';

// Specialized services
export 'activity_logs_service.dart';
export 'partially_sighted/caretaker_patient_service.dart';
export 'partially_sighted/emergency_contacts_service.dart';
export 'partially_sighted/emergency_hotline_service.dart';
export 'partially_sighted/medical_info_service.dart';
export 'admin_service.dart';
export 'caretaker/assistance_request_service.dart';
export 'auth_service.dart';
export 'partially_sighted/user_activity_service.dart'; 
export 'partially_sighted/text_scan_service.dart'; 
export 'partially_sighted/object_detection_service.dart';
export 'caretaker/communications_service.dart';
export 'partially_sighted/communications_service.dart';
export 'mswd/mswd_location_tracking_service.dart';
export 'partially_sighted/face_detection_service.dart';
export 'mswd/mswd_call_service.dart';
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