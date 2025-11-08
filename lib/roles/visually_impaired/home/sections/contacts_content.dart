// File: lib/roles/visually_impaired/home/sections/contacts_content.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ContactsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;

  const ContactsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
  });

  @override
  State<ContactsContent> createState() => _ContactsContentState();
}

class _ContactsContentState extends State<ContactsContent> {
  StreamSubscription? _caretakersSubscription;
  StreamSubscription? _emergencyContactsSubscription;
  
  List<ContactModel> _caretakerContacts = [];
  List<ContactModel> _emergencyContacts = [];
  List<ContactModel> _otherContacts = [];
  
  bool _isLoadingCaretakers = true;
  bool _isLoadingEmergency = true;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _initializePatientId();
  }

  void _initializePatientId() {
    // Try multiple ways to get the patient ID
    _patientId = widget.userData['uid'] as String?;
    
    // If not in userData, get from Firebase Auth
    if (_patientId == null || _patientId!.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      _patientId = user?.uid;
    }

    debugPrint('Patient ID for contacts: $_patientId');
    
    if (_patientId != null) {
      _setupCaretakersStream();
      _setupEmergencyContactsStream();
    } else {
      setState(() {
        _isLoadingCaretakers = false;
        _isLoadingEmergency = false;
      });
    }
  }

  void _setupCaretakersStream() {
    if (_patientId == null) return;

    _caretakersSubscription = caretakerPatientService
        .streamPatientCaretakers(_patientId!)
        .listen(
      (caretakersData) {
        if (mounted) {
          setState(() {
            _caretakerContacts = caretakersData.map((caretaker) {
              return ContactModel(
                id: caretaker['userId'] ?? '',
                name: caretaker['name'] ?? 'Unknown',
                relationship: caretaker['relationship'] ?? 'Caretaker',
                phoneNumber: caretaker['phone'] ?? caretaker['contactNumber'] ?? 'N/A',
                isEmergencyContact: false,
                isCaretaker: true,
                avatar: Icons.favorite_rounded,
                color: primary,
              );
            }).toList();
            _isLoadingCaretakers = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading caretakers: $error');
        if (mounted) {
          setState(() {
            _isLoadingCaretakers = false;
          });
        }
      },
    );
  }

  void _setupEmergencyContactsStream() {
    if (_patientId == null) return;

    _emergencyContactsSubscription = emergencyContactsService
        .streamEmergencyContacts(_patientId!)
        .listen(
      (contactsData) {
        if (mounted) {
          setState(() {
            _emergencyContacts = contactsData.map((contact) {
              return ContactModel(
                id: contact['contactId'] ?? '',
                name: contact['name'] ?? 'Unknown',
                relationship: contact['relationship'] ?? 'Contact',
                phoneNumber: contact['phone'] ?? 'N/A',
                isEmergencyContact: true,
                isCaretaker: false,
                avatar: Icons.medical_services_rounded,
                color: error,
              );
            }).toList();
            _isLoadingEmergency = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading emergency contacts: $error');
        if (mounted) {
          setState(() {
            _isLoadingEmergency = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _caretakersSubscription?.cancel();
    _emergencyContactsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final phoneController = TextEditingController();
    bool isEmergencyContact = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          title: Text(
            'Add Contact',
            style: h3.copyWith(color: widget.theme.textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: body.copyWith(color: widget.theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: body.copyWith(color: widget.theme.subtextColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                      borderSide: BorderSide(color: widget.theme.subtextColor.withOpacity(0.3)),
                    ),
                  ),
                ),
                SizedBox(height: spacingMedium),
                TextField(
                  controller: relationshipController,
                  style: body.copyWith(color: widget.theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Relationship',
                    labelStyle: body.copyWith(color: widget.theme.subtextColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                      borderSide: BorderSide(color: widget.theme.subtextColor.withOpacity(0.3)),
                    ),
                  ),
                ),
                SizedBox(height: spacingMedium),
                TextField(
                  controller: phoneController,
                  style: body.copyWith(color: widget.theme.textColor),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: body.copyWith(color: widget.theme.subtextColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                      borderSide: BorderSide(color: widget.theme.subtextColor.withOpacity(0.3)),
                    ),
                  ),
                ),
                SizedBox(height: spacingMedium),
                CheckboxListTile(
                  value: isEmergencyContact,
                  onChanged: (value) {
                    setDialogState(() {
                      isEmergencyContact = value ?? false;
                    });
                  },
                  title: Text(
                    'Emergency Contact',
                    style: body.copyWith(color: widget.theme.textColor),
                  ),
                  activeColor: error,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: body.copyWith(color: widget.theme.subtextColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || 
                    relationshipController.text.isEmpty || 
                    phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill all fields'),
                      backgroundColor: error,
                    ),
                  );
                  return;
                }

                try {
                  if (_patientId != null) {
                    await emergencyContactsService.addEmergencyContact(
                      userId: _patientId!,
                      contactName: nameController.text,
                      contactPhone: phoneController.text,
                      relationship: relationshipController.text,
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contact added successfully'),
                        backgroundColor: success,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add contact: $e'),
                      backgroundColor: error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: white,
              ),
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteContact(ContactModel contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        title: Text(
          'Delete Contact',
          style: h3.copyWith(color: widget.theme.textColor),
        ),
        content: Text(
          'Are you sure you want to delete ${contact.name}?',
          style: body.copyWith(color: widget.theme.subtextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: body.copyWith(color: widget.theme.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: error,
              foregroundColor: white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _patientId != null) {
      try {
        if (contact.isCaretaker) {
          // Remove caretaker assignment
          await caretakerPatientService.removeCaretakerFromPatient(
            caretakerId: contact.id,
            patientId: _patientId!,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Caretaker removed successfully'),
              backgroundColor: success,
            ),
          );
        } else {
          // Remove emergency contact
          await emergencyContactsService.removeEmergencyContact(
            userId: _patientId!,
            contactId: contact.id,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Contact deleted successfully'),
              backgroundColor: success,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete contact: $e'),
            backgroundColor: error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLoading = _isLoadingCaretakers || _isLoadingEmergency;
    final allContacts = [..._caretakerContacts, ..._emergencyContacts, ..._otherContacts];

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isLoadingCaretakers = true;
          _isLoadingEmergency = true;
        });
        _setupCaretakersStream();
        _setupEmergencyContactsStream();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: width * 0.06,
          right: width * 0.06,
          bottom: 100,
        ),
        child: Semantics(
          label: 'Contacts section',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Contacts',
                          style: h2.copyWith(
                            fontSize: 26,
                            color: widget.theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: spacingSmall),
                        Text(
                          'People you can reach out to',
                          style: body.copyWith(
                            color: widget.theme.subtextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Add new contact button',
                    button: true,
                    hint: 'Double tap to add a new contact',
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.circular(radiusMedium),
                        boxShadow: glowShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showAddContactDialog,
                          borderRadius: BorderRadius.circular(radiusMedium),
                          child: Padding(
                            padding: EdgeInsets.all(spacingMedium),
                            child: Icon(Icons.add_rounded, color: white, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: spacingLarge),
              
              if (isLoading && allContacts.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                        ),
                        SizedBox(height: spacingLarge),
                        Text(
                          'Loading contacts...',
                          style: body.copyWith(
                            color: widget.theme.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (allContacts.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacingXLarge),
                          decoration: BoxDecoration(
                            color: widget.theme.subtextColor.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.contacts_rounded,
                            size: 80,
                            color: widget.theme.subtextColor.withOpacity(0.3),
                          ),
                        ),
                        SizedBox(height: spacingLarge),
                        Text(
                          'No contacts yet',
                          style: bodyBold.copyWith(
                            color: widget.theme.textColor,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: spacingSmall),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Add your caretakers and emergency contacts',
                            style: body.copyWith(
                              color: widget.theme.subtextColor,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Caretakers Section
                if (_caretakerContacts.isNotEmpty) ...[
                  Text(
                    'My Caretakers',
                    style: bodyBold.copyWith(
                      fontSize: 16,
                      color: widget.theme.textColor,
                    ),
                  ),
                  SizedBox(height: spacingMedium),
                  ..._caretakerContacts.map((contact) => Padding(
                        padding: EdgeInsets.only(bottom: spacingMedium),
                        child: _buildContactCard(context, contact),
                      )),
                  SizedBox(height: spacingLarge),
                ],
                
                // Emergency Contacts Section
                if (_emergencyContacts.isNotEmpty) ...[
                  Text(
                    'Emergency Contacts',
                    style: bodyBold.copyWith(
                      fontSize: 16,
                      color: widget.theme.textColor,
                    ),
                  ),
                  SizedBox(height: spacingMedium),
                  ..._emergencyContacts.map((contact) => Padding(
                        padding: EdgeInsets.only(bottom: spacingMedium),
                        child: _buildContactCard(context, contact),
                      )),
                  SizedBox(height: spacingLarge),
                ],
                
                // Other Contacts Section
                if (_otherContacts.isNotEmpty) ...[
                  Text(
                    'Other Contacts',
                    style: bodyBold.copyWith(
                      fontSize: 16,
                      color: widget.theme.textColor,
                    ),
                  ),
                  SizedBox(height: spacingMedium),
                  ..._otherContacts.map((contact) => Padding(
                        padding: EdgeInsets.only(bottom: spacingMedium),
                        child: _buildContactCard(context, contact),
                      )),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, ContactModel contact) {
    final isCaretaker = contact.isCaretaker;
    final isEmergency = contact.isEmergencyContact;
    
    return Semantics(
      label: '${contact.name}, ${contact.relationship}, ${contact.phoneNumber}${isCaretaker ? ', Caretaker' : isEmergency ? ', Emergency contact' : ''}',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: widget.isDarkMode 
            ? [
                BoxShadow(
                  color: contact.color.withOpacity(0.15),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
          border: Border.all(
            color: isCaretaker || isEmergency
                ? contact.color.withOpacity(0.3)
                : greyLighter,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.all(spacingLarge),
              leading: Container(
                padding: EdgeInsets.all(spacingMedium),
                decoration: BoxDecoration(
                  color: contact.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Icon(contact.avatar, color: contact.color, size: 28),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      contact.name,
                      style: bodyBold.copyWith(fontSize: 18, color: widget.theme.textColor),
                    ),
                  ),
                  if (isCaretaker)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(radiusSmall),
                      ),
                      child: Text(
                        'CARETAKER',
                        style: caption.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    )
                  else if (isEmergency)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(radiusSmall),
                      ),
                      child: Text(
                        'SOS',
                        style: caption.copyWith(
                          color: error,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: spacingXSmall),
                  Text(
                    contact.relationship,
                    style: body.copyWith(color: widget.theme.subtextColor, fontSize: 14),
                  ),
                  SizedBox(height: spacingXSmall),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 16, color: widget.theme.subtextColor),
                      SizedBox(width: 6),
                      Text(
                        contact.phoneNumber,
                        style: body.copyWith(color: widget.theme.subtextColor),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                icon: Icon(Icons.more_vert_rounded, color: widget.theme.textColor),
                itemBuilder: (context) => [
                  if (!isCaretaker) // Can't edit caretakers, they come from the system
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20, color: primary),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(Duration.zero, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Edit contact feature coming soon'),
                              backgroundColor: primary,
                            ),
                          );
                        });
                      },
                    ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 20, color: error),
                        SizedBox(width: 8),
                        Text(isCaretaker ? 'Remove' : 'Delete'),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(Duration.zero, () => _deleteContact(contact));
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: widget.theme.subtextColor.withOpacity(0.2)),
            Padding(
              padding: EdgeInsets.all(spacingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Calling ${contact.name}...'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: Icon(Icons.phone_rounded, size: 20),
                      label: Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: contact.color,
                        foregroundColor: white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radiusMedium),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: spacingSmall),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening SMS to ${contact.name}...'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.theme.cardColor,
                      foregroundColor: contact.color,
                      padding: EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusMedium),
                        side: BorderSide(color: contact.color),
                      ),
                    ),
                    child: Icon(Icons.message_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Contact Model
class ContactModel {
  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isEmergencyContact;
  final bool isCaretaker;
  final IconData avatar;
  final Color color;

  ContactModel({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    required this.isEmergencyContact,
    required this.isCaretaker,
    required this.avatar,
    required this.color,
  });
}
