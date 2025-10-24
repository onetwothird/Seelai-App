import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== USER MANAGEMENT ====================

  /// Create a new user document in Realtime Database
  /// Called during signup after Firebase Auth account creation
  Future<void> createUserDocument({
    required String userId,
    required String name,
    required int age,
    required String email,
    required String role, // 'visually_impaired', 'caretaker', or 'admin'
    String? phone,
    String? relationship,
    String? employeeId,
    String? department,
  }) async {
    try {
      // Base user data - common to all roles
      Map<String, dynamic> userData = {
        'name': name,
        'age': age,
        'email': email,
        'role': role,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'isActive': true,
        'profileImageUrl': '',
      };

      // Add role-specific fields based on the selected role
      if (role == 'caretaker') {
        // Caretaker-specific fields
        userData['phone'] = phone ?? '';
        userData['relationship'] = relationship ?? '';
        userData['assignedPatients'] = {}; // Empty map for assigned patients
      } else if (role == 'admin') {
        // Admin (MSDWD)-specific fields
        userData['employeeId'] = employeeId ?? '';
        userData['department'] = department ?? '';
      } else if (role == 'visually_impaired') {
        // Visually Impaired User-specific fields
        userData['assignedCaretakers'] = {}; // Empty map for assigned caretakers
        userData['emergencyContacts'] = {}; // Empty map for emergency contacts
        userData['deviceSettings'] = {
          'voiceEnabled': true,
          'fontSize': 'medium',
          'highContrast': false,
        };
      }

      // Save to database
      await _database.ref('users/$userId').set(userData);
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  /// Get user data by user ID
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DatabaseEvent event = await _database.ref('users/$userId').once();
      
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  /// Get current user's data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (currentUserId == null) return null;
    return await getUserData(currentUserId!);
  }

  /// Test database connection
  Future<void> testConnection() async {
    try {
      await _database.ref('test').set({
        'message': 'Connection successful',
        'timestamp': ServerValue.timestamp,
      });
      print('✅ Database connection successful!');
    } catch (e) {
      print('❌ Database connection failed: $e');
    }
  }

  /// Update user profile (role-specific updates)
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    int? age,
    String? phone,
    String? profileImageUrl,
    String? relationship,
    String? employeeId,
    String? department,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': ServerValue.timestamp,
      };

      if (name != null) updates['name'] = name;
      if (age != null) updates['age'] = age;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      
      // Role-specific updates
      if (phone != null) updates['phone'] = phone;
      if (relationship != null) updates['relationship'] = relationship;
      if (employeeId != null) updates['employeeId'] = employeeId;
      if (department != null) updates['department'] = department;

      await _database.ref('users/$userId').update(updates);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Stream of user data (real-time updates)
  Stream<Map<String, dynamic>?> streamUserData(String userId) {
    return _database.ref('users/$userId').onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  // ==================== ROLE VERIFICATION ====================

  /// Verify user's role matches expected role
  Future<bool> verifyUserRole(String userId, String expectedRole) async {
    try {
      Map<String, dynamic>? userData = await getUserData(userId);
      if (userData == null) return false;
      
      return userData['role'] == expectedRole;
    } catch (e) {
      return false;
    }
  }

  /// Get user's role
  Future<String?> getUserRole(String userId) async {
    try {
      Map<String, dynamic>? userData = await getUserData(userId);
      return userData?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ==================== CARETAKER-PATIENT MANAGEMENT ====================

  /// Link a caretaker to a patient
  Future<void> assignCaretakerToPatient({
    required String caretakerId,
    required String patientId,
  }) async {
    try {
      // Add patient to caretaker's list
      await _database.ref('users/$caretakerId/assignedPatients/$patientId').set(true);
      
      // Add caretaker to patient's list
      await _database.ref('users/$patientId/assignedCaretakers/$caretakerId').set(true);
      
      // Update timestamps
      await _database.ref('users/$caretakerId/updatedAt').set(ServerValue.timestamp);
      await _database.ref('users/$patientId/updatedAt').set(ServerValue.timestamp);
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
      await _database.ref('users/$caretakerId/assignedPatients/$patientId').remove();
      
      // Remove caretaker from patient's list
      await _database.ref('users/$patientId/assignedCaretakers/$caretakerId').remove();
      
      // Update timestamps
      await _database.ref('users/$caretakerId/updatedAt').set(ServerValue.timestamp);
      await _database.ref('users/$patientId/updatedAt').set(ServerValue.timestamp);
    } catch (e) {
      throw Exception('Failed to remove caretaker: $e');
    }
  }

  /// Get all patients assigned to a caretaker
  Future<List<Map<String, dynamic>>> getCaretakerPatients(String caretakerId) async {
    try {
      Map<String, dynamic>? caretakerData = await getUserData(caretakerId);
      if (caretakerData == null) return [];

      Map<dynamic, dynamic>? patientIdsMap = caretakerData['assignedPatients'] as Map?;
      if (patientIdsMap == null || patientIdsMap.isEmpty) return [];

      List<Map<String, dynamic>> patients = [];

      for (String patientId in patientIdsMap.keys) {
        Map<String, dynamic>? patientData = await getUserData(patientId);
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
      Map<String, dynamic>? patientData = await getUserData(patientId);
      if (patientData == null) return [];

      Map<dynamic, dynamic>? caretakerIdsMap = patientData['assignedCaretakers'] as Map?;
      if (caretakerIdsMap == null || caretakerIdsMap.isEmpty) return [];

      List<Map<String, dynamic>> caretakers = [];

      for (String caretakerId in caretakerIdsMap.keys) {
        Map<String, dynamic>? caretakerData = await getUserData(caretakerId);
        if (caretakerData != null) {
          caretakers.add({...caretakerData, 'userId': caretakerId});
        }
      }

      return caretakers;
    } catch (e) {
      throw Exception('Failed to get patient caretakers: $e');
    }
  }

  // ==================== EMERGENCY CONTACTS ====================

  /// Add emergency contact for a user
  Future<void> addEmergencyContact({
    required String userId,
    required String contactName,
    required String contactPhone,
    required String relationship,
  }) async {
    try {
      Map<String, dynamic> contact = {
        'name': contactName,
        'phone': contactPhone,
        'relationship': relationship,
        'addedAt': ServerValue.timestamp,
      };

      String contactId = _database.ref('users/$userId/emergencyContacts').push().key!;
      
      await _database.ref('users/$userId/emergencyContacts/$contactId').set(contact);
      await _database.ref('users/$userId/updatedAt').set(ServerValue.timestamp);
    } catch (e) {
      throw Exception('Failed to add emergency contact: $e');
    }
  }

  /// Remove emergency contact
  Future<void> removeEmergencyContact({
    required String userId,
    required String contactId,
  }) async {
    try {
      await _database.ref('users/$userId/emergencyContacts/$contactId').remove();
      await _database.ref('users/$userId/updatedAt').set(ServerValue.timestamp);
    } catch (e) {
      throw Exception('Failed to remove emergency contact: $e');
    }
  }

  /// Get all emergency contacts for a user
  Future<List<Map<String, dynamic>>> getEmergencyContacts(String userId) async {
    try {
      DatabaseEvent event = await _database.ref('users/$userId/emergencyContacts').once();
      
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> contactsMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> contacts = [];
      
      contactsMap.forEach((key, value) {
        Map<String, dynamic> contact = Map<String, dynamic>.from(value as Map);
        contact['contactId'] = key;
        contacts.add(contact);
      });
      
      return contacts;
    } catch (e) {
      throw Exception('Failed to get emergency contacts: $e');
    }
  }

  // ==================== MEDICAL INFO (Visually Impaired Users) ====================

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

      await _database.ref('users/$userId').update(updates);
    } catch (e) {
      throw Exception('Failed to update medical info: $e');
    }
  }

  // ==================== ADMIN FUNCTIONS ====================

  /// Get all users (Admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      DatabaseEvent event = await _database.ref('users').once();
      
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> usersMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> users = [];
      
      usersMap.forEach((key, value) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(value as Map);
        userData['userId'] = key;
        users.add(userData);
      });
      
      return users;
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  /// Get users by role
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      DatabaseEvent event = await _database
          .ref('users')
          .orderByChild('role')
          .equalTo(role)
          .once();
      
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> usersMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> users = [];
      
      usersMap.forEach((key, value) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(value as Map);
        userData['userId'] = key;
        users.add(userData);
      });
      
      return users;
    } catch (e) {
      throw Exception('Failed to get users by role: $e');
    }
  }

  /// Deactivate user account (Admin only)
  Future<void> deactivateUser(String userId) async {
    try {
      await _database.ref('users/$userId').update({
        'isActive': false,
        'deactivatedAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to deactivate user: $e');
    }
  }

  /// Reactivate user account (Admin only)
  Future<void> reactivateUser(String userId) async {
    try {
      Map<String, dynamic> updates = {
        'isActive': true,
        'updatedAt': ServerValue.timestamp,
      };
      
      // Remove deactivatedAt field
      await _database.ref('users/$userId/deactivatedAt').remove();
      await _database.ref('users/$userId').update(updates);
    } catch (e) {
      throw Exception('Failed to reactivate user: $e');
    }
  }

  // ==================== ACTIVITY LOGGING ====================

  /// Log user activity
  Future<void> logActivity({
    required String userId,
    required String action,
    String? details,
  }) async {
    try {
      String logId = _database.ref('activity_logs').push().key!;
      
      await _database.ref('activity_logs/$logId').set({
        'userId': userId,
        'action': action,
        'details': details ?? '',
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      // Don't throw error for logging failures
      print('Failed to log activity: $e');
    }
  }

  /// Get user activity logs
  Future<List<Map<String, dynamic>>> getUserActivityLogs(
    String userId, {
    int limit = 50,
  }) async {
    try {
      DatabaseEvent event = await _database
          .ref('activity_logs')
          .orderByChild('userId')
          .equalTo(userId)
          .limitToLast(limit)
          .once();
      
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> logsMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> logs = [];
      
      logsMap.forEach((key, value) {
        Map<String, dynamic> log = Map<String, dynamic>.from(value as Map);
        log['logId'] = key;
        logs.add(log);
      });
      
      // Sort by timestamp descending
      logs.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      
      return logs;
    } catch (e) {
      throw Exception('Failed to get activity logs: $e');
    }
  }

  /// Get all activity logs (Admin only)
  Future<List<Map<String, dynamic>>> getAllActivityLogs({int limit = 100}) async {
    try {
      DatabaseEvent event = await _database
          .ref('activity_logs')
          .limitToLast(limit)
          .once();
      
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> logsMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> logs = [];
      
      logsMap.forEach((key, value) {
        Map<String, dynamic> log = Map<String, dynamic>.from(value as Map);
        log['logId'] = key;
        logs.add(log);
      });
      
      // Sort by timestamp descending
      logs.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      
      return logs;
    } catch (e) {
      throw Exception('Failed to get all activity logs: $e');
    }
  }

  // ==================== USER DELETION ====================

  /// Delete user data from Realtime Database (called when deleting account)
  Future<void> deleteUserData(String userId) async {
    try {
      // Get user data first to clean up relationships
      Map<String, dynamic>? userData = await getUserData(userId);
      
      if (userData != null) {
        String role = userData['role'] ?? '';
        
        // Clean up relationships based on role
        if (role == 'caretaker') {
          // Remove this caretaker from all assigned patients
          Map<dynamic, dynamic>? assignedPatients = userData['assignedPatients'] as Map?;
          if (assignedPatients != null) {
            for (String patientId in assignedPatients.keys) {
              await _database.ref('users/$patientId/assignedCaretakers/$userId').remove();
            }
          }
        } else if (role == 'visually_impaired') {
          // Remove this patient from all assigned caretakers
          Map<dynamic, dynamic>? assignedCaretakers = userData['assignedCaretakers'] as Map?;
          if (assignedCaretakers != null) {
            for (String caretakerId in assignedCaretakers.keys) {
              await _database.ref('users/$caretakerId/assignedPatients/$userId').remove();
            }
          }
        }
      }
      
      // Delete user document
      await _database.ref('users/$userId').remove();
      
      // Delete activity logs
      DatabaseEvent event = await _database
          .ref('activity_logs')
          .orderByChild('userId')
          .equalTo(userId)
          .once();
      
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> logsMap = event.snapshot.value as Map;
        
        for (String logId in logsMap.keys) {
          await _database.ref('activity_logs/$logId').remove();
        }
      }
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }
}

// Create a singleton instance
final DatabaseService databaseService = DatabaseService();