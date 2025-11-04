// File: lib/roles/visually_impaired/home/sections/contacts_content.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class ContactsContent extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;

  const ContactsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

    List<ContactModel> get _sampleContacts => [
    ContactModel(
      name: 'Dr. Maria Santos',
      relationship: 'Primary Caretaker',
      phoneNumber: '+63 917 123 4567',
      isEmergencyContact: true,
      avatar: Icons.medical_services_rounded,
      color: Colors.blue,
    ),
    ContactModel(
      name: 'Juan Dela Cruz',
      relationship: 'Family Member',
      phoneNumber: '+63 918 234 5678',
      isEmergencyContact: true,
      avatar: Icons.family_restroom_rounded,
      color: Colors.green,
    ),
    ContactModel(
      name: 'Anna Reyes',
      relationship: 'Friend',
      phoneNumber: '+63 919 345 6789',
      isEmergencyContact: false,
      avatar: Icons.person_rounded,
      color: Colors.purple,
    ),
    ContactModel(
      name: 'Carlos Ramos',
      relationship: 'Neighbor',
      phoneNumber: '+63 920 456 7890',
      isEmergencyContact: false,
      avatar: Icons.home_rounded,
      color: Colors.orange,
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
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
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: spacingSmall),
                      Text(
                        'People you can reach out to',
                        style: body.copyWith(
                          color: theme.subtextColor,
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
                        onTap: () {
                          // TODO: Navigate to add contact screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Add contact feature coming soon'),
                              backgroundColor: primary,
                            ),
                          );
                        },
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
            
            // Emergency Contacts Section
            if (_sampleContacts.any((c) => c.isEmergencyContact)) ...[
              Text(
                'Emergency Contacts',
                style: bodyBold.copyWith(
                  fontSize: 16,
                  color: theme.textColor,
                ),
              ),
              SizedBox(height: spacingMedium),
              ..._sampleContacts
                  .where((contact) => contact.isEmergencyContact)
                  .map((contact) => Padding(
                        padding: EdgeInsets.only(bottom: spacingMedium),
                        child: _buildContactCard(context, contact, true),
                      )),
              SizedBox(height: spacingLarge),
            ],
            
            // Other Contacts Section
            if (_sampleContacts.any((c) => !c.isEmergencyContact)) ...[
              Text(
                'Other Contacts',
                style: bodyBold.copyWith(
                  fontSize: 16,
                  color: theme.textColor,
                ),
              ),
              SizedBox(height: spacingMedium),
              ..._sampleContacts
                  .where((contact) => !contact.isEmergencyContact)
                  .map((contact) => Padding(
                        padding: EdgeInsets.only(bottom: spacingMedium),
                        child: _buildContactCard(context, contact, false),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, ContactModel contact, bool isEmergency) {
    return Semantics(
      label: '${contact.name}, ${contact.relationship}, ${contact.phoneNumber}${isEmergency ? ', Emergency contact' : ''}',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: isDarkMode 
            ? [
                BoxShadow(
                  color: (isEmergency ? error : primary).withOpacity(0.15),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
          border: isDarkMode 
            ? Border.all(
                color: isEmergency 
                  ? error.withOpacity(0.4)
                  : primary.withOpacity(0.3),
                width: 1.5,
              )
            : Border.all(
                color: isEmergency 
                  ? error.withOpacity(0.3)
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
                      style: bodyBold.copyWith(fontSize: 18, color: theme.textColor),
                    ),
                  ),
                  if (isEmergency)
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
                    style: body.copyWith(color: theme.subtextColor, fontSize: 14),
                  ),
                  SizedBox(height: spacingXSmall),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 16, color: theme.subtextColor),
                      SizedBox(width: 6),
                      Text(
                        contact.phoneNumber,
                        style: body.copyWith(color: theme.subtextColor),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                icon: Icon(Icons.more_vert_rounded, color: theme.textColor),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20, color: primary),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                    onTap: () {
                      // TODO: Navigate to edit contact
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
                        Text('Delete'),
                      ],
                    ),
                    onTap: () {
                      // TODO: Delete contact
                      Future.delayed(Duration.zero, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Delete contact feature coming soon'),
                            backgroundColor: error,
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.subtextColor.withOpacity(0.2)),
            Padding(
              padding: EdgeInsets.all(spacingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Make call
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
                      // TODO: Send SMS
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening SMS to ${contact.name}...'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.cardColor,
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
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isEmergencyContact;
  final IconData avatar;
  final Color color;

  ContactModel({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    required this.isEmergencyContact,
    required this.avatar,
    required this.color,
  });
}