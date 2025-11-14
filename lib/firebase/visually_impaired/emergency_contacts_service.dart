import 'package:firebase_database/firebase_database.dart';
import '../database_service.dart';

/// Service for managing emergency contacts
class EmergencyContactsService {
  final FirebaseDatabase _database = databaseService.database;

  // ==================== EMERGENCY CONTACTS ====================

  /// Add emergency contact for a user
  Future<void> addEmergencyContact({
    required String userId,
    required String contactName,
    required String contactPhone,
    required String relationship, String? profileImageUrl,
  }) async {
    try {
      Map<String, dynamic> contact = {
        'name': contactName,
        'phone': contactPhone,
        'relationship': relationship,
        'addedAt': ServerValue.timestamp,
      };

      String path = 'user_info/visually_impaired/$userId/emergencyContacts';
      String contactId = _database.ref(path).push().key!;
      
      await _database.ref('$path/$contactId').set(contact);
      await _database.ref('user_info/visually_impaired/$userId/updatedAt').set(ServerValue.timestamp);
    } catch (e) {
      throw Exception('Failed to add emergency contact: $e');
    }
  }

  /// Update emergency contact
  Future<void> updateEmergencyContact({
    required String userId,
    required String contactId,
    String? contactName,
    String? contactPhone,
    String? relationship,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      
      if (contactName != null) updates['name'] = contactName;
      if (contactPhone != null) updates['phone'] = contactPhone;
      if (relationship != null) updates['relationship'] = relationship;
      updates['updatedAt'] = ServerValue.timestamp;

      await _database.ref('user_info/visually_impaired/$userId/emergencyContacts/$contactId').update(updates);
      await _database.ref('user_info/visually_impaired/$userId/updatedAt').set(ServerValue.timestamp);
    } catch (e) {
      throw Exception('Failed to update emergency contact: $e');
    }
  }

  /// Remove emergency contact
  Future<void> removeEmergencyContact({
    required String userId,
    required String contactId,
  }) async {
    try {
      await _database.ref('user_info/visually_impaired/$userId/emergencyContacts/$contactId').remove();
      await _database.ref('user_info/visually_impaired/$userId/updatedAt').set(ServerValue.timestamp);
    } catch (e) {
      throw Exception('Failed to remove emergency contact: $e');
    }
  }

  /// Get all emergency contacts for a user
  Future<List<Map<String, dynamic>>> getEmergencyContacts(String userId) async {
    try {
      DatabaseEvent event = await _database.ref('user_info/visually_impaired/$userId/emergencyContacts').once();
      
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

  /// Get a specific emergency contact
  Future<Map<String, dynamic>?> getEmergencyContact({
    required String userId,
    required String contactId,
  }) async {
    try {
      DatabaseEvent event = await _database
          .ref('user_info/visually_impaired/$userId/emergencyContacts/$contactId')
          .once();
      
      if (!event.snapshot.exists) return null;
      
      Map<String, dynamic> contact = Map<String, dynamic>.from(event.snapshot.value as Map);
      contact['contactId'] = contactId;
      
      return contact;
    } catch (e) {
      throw Exception('Failed to get emergency contact: $e');
    }
  }

  /// Stream of emergency contacts for real-time updates
  Stream<List<Map<String, dynamic>>> streamEmergencyContacts(String userId) {
    return _database
        .ref('user_info/visually_impaired/$userId/emergencyContacts')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];
      
      Map<dynamic, dynamic> contactsMap = event.snapshot.value as Map;
      List<Map<String, dynamic>> contacts = [];
      
      contactsMap.forEach((key, value) {
        Map<String, dynamic> contact = Map<String, dynamic>.from(value as Map);
        contact['contactId'] = key;
        contacts.add(contact);
      });
      
      return contacts;
    });
  }
}

// Create a singleton instance
final EmergencyContactsService emergencyContactsService = EmergencyContactsService();