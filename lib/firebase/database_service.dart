// ignore_for_file: empty_catches

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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

  // ==================== STREAK MANAGEMENT ====================
  // === STREAK FEATURE: Logic to calculate daily logins ===
  Future<int> updateAndGetStreak(String userId, String role) async {
    try {
      String path = getUserPath(role, userId);
      DatabaseEvent event = await _database.ref(path).once();
      
      if (!event.snapshot.exists) return 0;
      
      Map<String, dynamic> data = Map<String, dynamic>.from(event.snapshot.value as Map);
      
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      
      int currentStreak = data['currentStreak'] ?? 0;
      String? lastActiveStr = data['lastActiveDate'];
      DateTime? lastActive = lastActiveStr != null ? DateTime.parse(lastActiveStr) : null;
      
      if (lastActive != null) {
        DateTime lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
        int difference = today.difference(lastActiveDay).inDays;
        
        if (difference == 1) {
          currentStreak += 1; 
        } else if (difference > 1) {
          currentStreak = 1; 
        }
      } else {
        currentStreak = 1; 
      }
      
      await _database.ref(path).update({
        'currentStreak': currentStreak,
        'lastActiveDate': now.toIso8601String(),
      });
      
      return currentStreak;
    } catch (e) {
      debugPrint('Failed to update streak: $e');
      return 0;
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
    String? staffId, 
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
        userData['staffId'] = staffId ?? ''; 
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

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (currentUserId == null) return null;
    return await getUserData(currentUserId!);
  }

  Future<void> testConnection() async {
    try {
      await _database.ref('test').set({
        'message': 'Connection successful',
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required String role,
    String? idNumber,
    String? staffId, 
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
    String? fcmToken,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': ServerValue.timestamp,
      };

      if (idNumber != null) updates['idNumber'] = idNumber;
      if (staffId != null) updates['staffId'] = staffId; 
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
      if (fcmToken != null) updates['fcmToken'] = fcmToken;

      String path = getUserPath(role, userId);
      await _database.ref(path).update(updates);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Stream<Map<String, dynamic>?> streamUserData(String userId, String role) {
    String path = getUserPath(role, userId);
    return _database.ref(path).onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  // ==================== FCM TOKEN MANAGEMENT ====================

  Future<void> saveUserFCMToken(String userId, String role) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      
      if (token != null) {
        String path = getUserPath(role, userId);
        await _database.ref(path).update({
          'fcmToken': token,
        });
        debugPrint("✅ FCM Token successfully saved for $role!");
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        String path = getUserPath(role, userId);
        _database.ref(path).update({
          'fcmToken': newToken,
        });
      });
    } catch (e) {
      debugPrint("Failed to save FCM token: $e");
    }
  }

  // ==================== ROLE VERIFICATION ====================

  Future<bool> verifyUserRole(String userId, String expectedRole) async {
    try {
      Map<String, dynamic>? userData = await getUserData(userId);
      if (userData == null) return false;
      return userData['role'] == expectedRole;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getUserRole(String userId) async {
    try {
      Map<String, dynamic>? userData = await getUserData(userId);
      return userData?['role'] as String?;
    } catch (e) {
      return null;
    }
  }
}

final DatabaseService databaseService = DatabaseService();