// File: lib/firebase/mswd/announcement_service.dart

// ignore_for_file: avoid_print

import 'package:firebase_database/firebase_database.dart';
import 'package:seelai_app/roles/mswd/home/model/announcement_model.dart';

class AnnouncementService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Reference to announcements node
  DatabaseReference get _announcementsRef => _database.child('announcements');

  // Create a new announcement
  Future<String?> createAnnouncement(AnnouncementModel announcement) async {
    try {
      final newAnnouncementRef = _announcementsRef.push();
      final announcementWithId = announcement.copyWith(id: newAnnouncementRef.key!);
      
      await newAnnouncementRef.set(announcementWithId.toJson());
      
      return newAnnouncementRef.key;
    } catch (e) {
      print('Error creating announcement: $e');
      return null;
    }
  }

  // Get all announcements (sorted by timestamp, newest first)
  Stream<List<AnnouncementModel>> getAnnouncementsStream() {
    return _announcementsRef
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final List<AnnouncementModel> announcements = [];
      
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        
        data.forEach((key, value) {
          if (value != null) {
            announcements.add(
              AnnouncementModel.fromJson(key, Map<dynamic, dynamic>.from(value))
            );
          }
        });
        
        // Sort by timestamp (newest first)
        announcements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      
      return announcements;
    });
  }

  // Get announcements once (for initial load)
  Future<List<AnnouncementModel>> getAnnouncements() async {
    try {
      final snapshot = await _announcementsRef
          .orderByChild('timestamp')
          .get();
      
      final List<AnnouncementModel> announcements = [];
      
      if (snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        
        data.forEach((key, value) {
          if (value != null) {
            announcements.add(
              AnnouncementModel.fromJson(key, Map<dynamic, dynamic>.from(value))
            );
          }
        });
        
        // Sort by timestamp (newest first)
        announcements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      
      return announcements;
    } catch (e) {
      print('Error getting announcements: $e');
      return [];
    }
  }

  // Get a single announcement by ID
  Future<AnnouncementModel?> getAnnouncementById(String id) async {
    try {
      final snapshot = await _announcementsRef.child(id).get();
      
      if (snapshot.value != null) {
        return AnnouncementModel.fromJson(
          id,
          Map<dynamic, dynamic>.from(snapshot.value as Map)
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting announcement: $e');
      return null;
    }
  }

  // Update an announcement
  Future<bool> updateAnnouncement(String id, Map<String, dynamic> updates) async {
    try {
      await _announcementsRef.child(id).update(updates);
      return true;
    } catch (e) {
      print('Error updating announcement: $e');
      return false;
    }
  }

  // Delete an announcement
  Future<bool> deleteAnnouncement(String id) async {
    try {
      await _announcementsRef.child(id).remove();
      return true;
    } catch (e) {
      print('Error deleting announcement: $e');
      return false;
    }
  }

  // Get announcements for a specific target audience
  Stream<List<AnnouncementModel>> getAnnouncementsByAudience(String audience) {
    return _announcementsRef
        .orderByChild('targetAudience')
        .equalTo(audience)
        .onValue
        .map((event) {
      final List<AnnouncementModel> announcements = [];
      
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        
        data.forEach((key, value) {
          if (value != null) {
            announcements.add(
              AnnouncementModel.fromJson(key, Map<dynamic, dynamic>.from(value))
            );
          }
        });
        
        // Sort by timestamp (newest first)
        announcements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      
      return announcements;
    });
  }

  // Get announcements for a specific user
  Stream<List<AnnouncementModel>> getAnnouncementsForUser(String userId, String userRole) {
    return getAnnouncementsStream().map((announcements) {
      return announcements.where((announcement) {
        // Show "All Users" announcements
        if (announcement.targetAudience == 'All Users') {
          return true;
        }
        
        // Show announcements for user's role
        if (announcement.targetAudience == userRole) {
          return true;
        }
        
        // Show announcements for specific users that include this user
        if (announcement.targetAudience == 'Specific Users' &&
            announcement.specificUsers.contains(userId)) {
          return true;
        }
        
        return false;
      }).toList();
    });
  }

  // Delete all announcements (for testing/admin purposes)
  Future<bool> deleteAllAnnouncements() async {
    try {
      await _announcementsRef.remove();
      return true;
    } catch (e) {
      print('Error deleting all announcements: $e');
      return false;
    }
  }
}