// ignore_for_file: empty_catches

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Main database service - handles basic user operations
class DatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  FirebaseDatabase get database => _database;

  String getUserPath(String role, String userId) {
    switch (role) {
      case 'partially_sighted':
        return 'user_info/partially_sighted/$userId';
      case 'caretaker':
        return 'user_info/caretaker/$userId';
      case 'admin':
        return 'user_info/mswd/$userId';
      case 'superadmin':                                
        return 'user_info/superadmin/$userId';          
      default:
        throw Exception('Invalid role: $role');
    }
  }

  // ==================== USER MANAGEMENT ====================

  Future<void> createUserDocument({
    required String userId,
    required String name,
    required int age,
    required String email,
    required String role,
    String? idNumber,
    String? sex,
    DateTime? birthdate,
    String? disabilityType,
    String? diagnosis,
    String? address,
    String? contactNumber,
    String? phone,
    String? relationship,
    String? department,
    bool? approved,
  }) async {
    try {
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

      if (role == 'caretaker') {
        userData['phone'] = phone ?? '';
        userData['relationship'] = relationship ?? '';
        userData['contactNumber'] = phone ?? contactNumber ?? '';
        userData['assignedPatients'] = {};
        userData['idNumber'] = idNumber ?? '';
        userData['sex'] = sex ?? 'Not Specified';
        userData['birthdate'] = birthdate?.toIso8601String() ?? 
            DateTime.now().subtract(Duration(days: age * 365)).toIso8601String();
        userData['address'] = address ?? '';
        userData['approved'] = approved ?? false; 
      } else if (role == 'admin') {
        userData['department'] = department ?? '';
        userData['sex'] = sex ?? 'Not Specified';
        userData['birthdate'] = birthdate?.toIso8601String() ?? 
            DateTime.now().subtract(Duration(days: age * 365)).toIso8601String();
        userData['address'] = address ?? '';
        userData['contactNumber'] = contactNumber ?? '';
      } else if (role == 'partially_sighted') {
        if (idNumber == null || sex == null || birthdate == null || 
            disabilityType == null || diagnosis == null || 
            address == null || contactNumber == null) {
          throw Exception('All fields are required for partially sighted users');
        }
        userData['idNumber'] = idNumber;
        userData['sex'] = sex;
        userData['birthdate'] = birthdate.toIso8601String();
        userData['disabilityType'] = disabilityType;
        userData['diagnosis'] = diagnosis;
        userData['address'] = address;
        userData['contactNumber'] = contactNumber;
        userData['assignedCaretakers'] = {};
        userData['emergencyContacts'] = {};
      }

      String path = getUserPath(role, userId);
      await _database.ref(path).set(userData);
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  /// Get user data by user ID (searches all role paths)
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      List<String> rolePaths = [
        'user_info/partially_sighted/$userId',
        'user_info/caretaker/$userId',
        'user_info/mswd/$userId',
      ];

      for (String path in rolePaths) {
        DatabaseEvent event = await _database.ref(path).once();
        if (event.snapshot.exists) {
          return Map<String, dynamic>.from(event.snapshot.value as Map);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  /// Get user data when you already know the role
  Future<Map<String, dynamic>?> getUserDataByRole(String userId, String role) async {
    try {
      String path = getUserPath(role, userId);
      DatabaseEvent event = await _database.ref(path).once();
      
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
    } catch (e) {
    }
  }

  /// Update user profile (role-specific updates)
  Future<void> updateUserProfile({
    required String userId,
    required String role,
    String? idNumber,
    String? name,
    String? sex,
    int? age,
    DateTime? birthdate,
    String? disabilityType,
    String? diagnosis,
    String? address,
    String? contactNumber,
    String? phone,
    String? profileImageUrl,
    String? relationship,
    String? department,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': ServerValue.timestamp,
      };

      if (idNumber != null) updates['idNumber'] = idNumber;
      if (name != null) updates['name'] = name;
      if (sex != null) updates['sex'] = sex;
      if (age != null) updates['age'] = age;
      if (birthdate != null) updates['birthdate'] = birthdate.toIso8601String();
      if (disabilityType != null) updates['disabilityType'] = disabilityType;
      if (diagnosis != null) updates['diagnosis'] = diagnosis;
      if (address != null) updates['address'] = address;
      if (contactNumber != null) updates['contactNumber'] = contactNumber;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (phone != null) updates['phone'] = phone;
      if (relationship != null) updates['relationship'] = relationship;
      if (department != null) updates['department'] = department;

      String path = getUserPath(role, userId);
      await _database.ref(path).update(updates);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Stream of user data (real-time updates)
  Stream<Map<String, dynamic>?> streamUserData(String userId, String role) {
    String path = getUserPath(role, userId);
    return _database.ref(path).onValue.map((event) {
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
}

// Create a singleton instance
final DatabaseService databaseService = DatabaseService();