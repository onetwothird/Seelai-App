// File: lib/firebase/visually_impaired/emergency_contacts_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:seelai_app/firebase/database_service.dart';

/// Service for managing emergency contacts for visually impaired users
class EmergencyContactsService {
  final FirebaseDatabase _database = databaseService.database;

  // ==================== EMERGENCY CONTACTS MANAGEMENT ====================

  /// Add emergency contact for a user
  Future<String> addEmergencyContact({
    required String userId,
    required String contactName,
    required String contactPhone,
    required String relationship,
    String? profileImageUrl,
  }) async {
    try {
      // Generate unique contact ID
      final contactRef = _database
          .ref('user_info/visually_impaired/$userId/emergencyContacts')
          .push();
      
      final contactId = contactRef.key!;
      
      final contactData = {
        'contactId': contactId,
        'name': contactName,
        'phone': contactPhone,
        'relationship': relationship,
        'profileImageUrl': profileImageUrl ?? '',
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      };

      await contactRef.set(contactData);
      return contactId;
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
    String? profileImageUrl,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': ServerValue.timestamp,
      };

      if (contactName != null) updates['name'] = contactName;
      if (contactPhone != null) updates['phone'] = contactPhone;
      if (relationship != null) updates['relationship'] = relationship;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _database
          .ref('user_info/visually_impaired/$userId/emergencyContacts/$contactId')
          .update(updates);
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
      await _database
          .ref('user_info/visually_impaired/$userId/emergencyContacts/$contactId')
          .remove();
    } catch (e) {
      throw Exception('Failed to remove emergency contact: $e');
    }
  }

  /// Get all emergency contacts for a user
  Future<List<Map<String, dynamic>>> getEmergencyContacts(String userId) async {
    try {
      DatabaseEvent event = await _database
          .ref('user_info/visually_impaired/$userId/emergencyContacts')
          .once();

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

  /// Stream emergency contacts (real-time updates)
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

  /// Get specific emergency contact
  Future<Map<String, dynamic>?> getEmergencyContact({
    required String userId,
    required String contactId,
  }) async {
    try {
      DatabaseEvent event = await _database
          .ref('user_info/visually_impaired/$userId/emergencyContacts/$contactId')
          .once();

      if (!event.snapshot.exists) return null;

      Map<String, dynamic> contact = Map<String, dynamic>.from(
        event.snapshot.value as Map
      );
      contact['contactId'] = contactId;
      return contact;
    } catch (e) {
      throw Exception('Failed to get emergency contact: $e');
    }
  }
}

// Create a singleton instance
final EmergencyContactsService emergencyContactsService = EmergencyContactsService();