// File: lib/roles/visually_impaired/home/sections/contacts_screen/contact_model.dart
import 'package:flutter/material.dart';

class ContactModel {
  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isEmergencyContact;
  final bool isCaretaker;
  final IconData avatar;
  final Color color;
  final String? profileImageUrl;

  ContactModel({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    required this.isEmergencyContact,
    required this.isCaretaker,
    required this.avatar,
    required this.color,
    this.profileImageUrl,
  });
}