import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';

/// Service for admin-only operations
class AdminService {
  final FirebaseDatabase _database = databaseService.database;

  // ==================== ADMIN FUNCTIONS ====================

  /// Get all users (Admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      List<Map<String, dynamic>> allUsers = [];
      
      // Get visually impaired users
      DatabaseEvent viEvent = await _database.ref('user_info/visually_impaired').once();
      if (viEvent.snapshot.exists) {
        Map<dynamic, dynamic> viMap = viEvent.snapshot.value as Map;
        viMap.forEach((key, value) {
          Map<String, dynamic> userData = Map<String, dynamic>.from(value as Map);
          userData['userId'] = key;
          allUsers.add(userData);
        });
      }
      
      // Get caretaker users
      DatabaseEvent ctEvent = await _database.ref('user_info/caretaker').once();
      if (ctEvent.snapshot.exists) {
        Map<dynamic, dynamic> ctMap = ctEvent.snapshot.value as Map;
        ctMap.forEach((key, value) {
          Map<String, dynamic> userData = Map<String, dynamic>.from(value as Map);
          userData['userId'] = key;
          allUsers.add(userData);
        });
      }

      // Get MSWD users
      DatabaseEvent mswdEvent = await _database.ref('user_info/mswd').once();
      if (mswdEvent.snapshot.exists) {
        Map<dynamic, dynamic> mswdMap = mswdEvent.snapshot.value as Map;
        mswdMap.forEach((key, value) {
          Map<String, dynamic> userData = Map<String, dynamic>.from(value as Map);
          userData['userId'] = key;
          allUsers.add(userData);
        });
      }
      
      return allUsers;
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  /// Get users by role
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      String path = role == 'admin' ? 'user_info/mswd' : 'user_info/$role';
      DatabaseEvent event = await _database.ref(path).once();
      
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
  Future<void> deactivateUser(String userId, String role) async {
    try {
      String path = databaseService.getUserPath(role, userId);
      await _database.ref(path).update({
        'isActive': false,
        'deactivatedAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to deactivate user: $e');
    }
  }

  /// Reactivate user account (Admin only)
  Future<void> reactivateUser(String userId, String role) async {
    try {
      String path = databaseService.getUserPath(role, userId);
      Map<String, dynamic> updates = {
        'isActive': true,
        'updatedAt': ServerValue.timestamp,
      };
      
      // Remove deactivatedAt field
      await _database.ref('$path/deactivatedAt').remove();
      await _database.ref(path).update(updates);
    } catch (e) {
      throw Exception('Failed to reactivate user: $e');
    }
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      Map<String, int> stats = {
        'total': 0,
        'visually_impaired': 0,
        'caretaker': 0,
        'admin': 0,
        'active': 0,
        'inactive': 0,
      };

      List<Map<String, dynamic>> allUsers = await getAllUsers();
      
      stats['total'] = allUsers.length;
      
      for (var user in allUsers) {
        String role = user['role'] ?? '';
        bool isActive = user['isActive'] ?? true;
        
        if (role == 'visually_impaired') stats['visually_impaired'] = (stats['visually_impaired'] ?? 0) + 1;
        if (role == 'caretaker') stats['caretaker'] = (stats['caretaker'] ?? 0) + 1;
        if (role == 'admin') stats['admin'] = (stats['admin'] ?? 0) + 1;
        
        if (isActive) {
          stats['active'] = (stats['active'] ?? 0) + 1;
        } else {
          stats['inactive'] = (stats['inactive'] ?? 0) + 1;
        }
      }
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get user statistics: $e');
    }
  }

  /// Stream of all users for real-time updates
  Stream<List<Map<String, dynamic>>> streamAllUsers() {
    return _database.ref('user_info').onValue.map((event) {
      List<Map<String, dynamic>> allUsers = [];
      
      if (!event.snapshot.exists) return allUsers;
      
      Map<dynamic, dynamic> rolesMap = event.snapshot.value as Map;
      
      rolesMap.forEach((roleKey, roleValue) {
        if (roleValue is Map) {
          Map<dynamic, dynamic> usersMap = roleValue;
          usersMap.forEach((userId, userData) {
            if (userData is Map) {
              Map<String, dynamic> user = Map<String, dynamic>.from(userData);
              user['userId'] = userId;
              allUsers.add(user);
            }
          });
        }
      });
      
      return allUsers;
    });
  }

  /// Stream of users by role for real-time updates
  Stream<List<Map<String, dynamic>>> streamUsersByRole(String role) {
    String path = role == 'admin' ? 'user_info/mswd' : 'user_info/$role';
    return _database.ref(path).onValue.map((event) {
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> usersMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> users = [];
      
      usersMap.forEach((key, value) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(value as Map);
        userData['userId'] = key;
        users.add(userData);
      });
      
      return users;
    });
  }
}

// Create a singleton instance
final AdminService adminService = AdminService();