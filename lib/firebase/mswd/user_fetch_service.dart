// File: lib/firebase/mswd/user_fetch_service.dart

// ignore_for_file: avoid_print

import 'package:firebase_database/firebase_database.dart';
import '../database_service.dart';

/// Service for fetching users for announcement targeting
class UserFetchService {
  final FirebaseDatabase _database = databaseService.database;

  /// Get all visually impaired users
  Future<List<Map<String, dynamic>>> getVisuallyImpairedUsers() async {
    try {
      DatabaseEvent event = await _database.ref('user_info/visually_impaired').once();
      
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> usersMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> users = [];
      
      usersMap.forEach((key, value) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(value as Map);
        userData['userId'] = key;
        userData['role'] = 'Visually Impaired';
        users.add(userData);
      });
      
      return users;
    } catch (e) {
      print('Error fetching visually impaired users: $e');
      return [];
    }
  }

  /// Get all caretaker users
  Future<List<Map<String, dynamic>>> getCaretakerUsers() async {
    try {
      DatabaseEvent event = await _database.ref('user_info/caretaker').once();
      
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> usersMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> users = [];
      
      usersMap.forEach((key, value) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(value as Map);
        userData['userId'] = key;
        userData['role'] = 'Caretakers';
        users.add(userData);
      });
      
      return users;
    } catch (e) {
      print('Error fetching caretaker users: $e');
      return [];
    }
  }

  /// Get all users (both visually impaired and caretakers)
  Future<List<Map<String, dynamic>>> getAllAppUsers() async {
    try {
      List<Map<String, dynamic>> allUsers = [];
      
      // Get visually impaired users
      List<Map<String, dynamic>> viUsers = await getVisuallyImpairedUsers();
      allUsers.addAll(viUsers);
      
      // Get caretaker users
      List<Map<String, dynamic>> caretakers = await getCaretakerUsers();
      allUsers.addAll(caretakers);
      
      // Sort by name
      allUsers.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      
      return allUsers;
    } catch (e) {
      print('Error fetching all users: $e');
      return [];
    }
  }
}

// Create a singleton instance
final UserFetchService userFetchService = UserFetchService();