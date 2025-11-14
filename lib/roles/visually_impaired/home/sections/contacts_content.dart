// File: lib/roles/visually_impaired/home/sections/contacts_content.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously, prefer_final_fields

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
  
  bool _isLoadingCaretakers = true;
  bool _isLoadingEmergency = true;
  String? _error;
  String? _patientId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializePatientId();
  }

  Future<void> _initializePatientId() async {
    String? patientId = widget.userData['uid'] as String?;
    
    if (patientId == null || patientId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      patientId = user?.uid;
    }

    if (patientId == null || patientId.isEmpty) {
      setState(() {
        _error = 'Patient ID not found. Please log in again.';
        _isLoadingCaretakers = false;
        _isLoadingEmergency = false;
      });
      return;
    }

    setState(() => _patientId = patientId);
    _setupCaretakersStream();
    _setupEmergencyContactsStream();
  }

  void _setupCaretakersStream() {
    if (_patientId == null) {
      setState(() {
        _error = 'Patient ID not found';
        _isLoadingCaretakers = false;
      });
      return;
    }

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
                profileImageUrl: caretaker['profileImageUrl'] as String?,
              );
            }).toList();
            _isLoadingCaretakers = false;
            _error = null;
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading caretakers: $error');
        if (mounted) {
          setState(() {
            _error = 'Failed to load caretakers: $error';
            _isLoadingCaretakers = false;
          });
        }
      },
    );
  }

  void _setupEmergencyContactsStream() {
    if (_patientId == null) {
      setState(() {
        _error = 'Patient ID not found';
        _isLoadingEmergency = false;
      });
      return;
    }

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
                profileImageUrl: null,
              );
            }).toList();
            _isLoadingEmergency = false;
            _error = null;
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading emergency contacts: $error');
        if (mounted) {
          setState(() {
            _error = 'Failed to load emergency contacts: $error';
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshContacts() async {
    if (_patientId == null) {
      await _initializePatientId();
      return;
    }
    
    setState(() {
      _isLoadingCaretakers = true;
      _isLoadingEmergency = true;
    });
    
    await Future.delayed(Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isLoadingCaretakers = false;
        _isLoadingEmergency = false;
      });
    }
  }

  List<ContactModel> get _allContacts => [..._caretakerContacts, ..._emergencyContacts];

  List<ContactModel> get _filteredContacts {
    if (_searchQuery.isEmpty) return _allContacts;
    
    return _allContacts.where((contact) {
      return contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             contact.relationship.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             contact.phoneNumber.contains(_searchQuery);
    }).toList();
  }

  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final phoneController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        title: Text(
          'Add Emergency Contact',
          style: h3.copyWith(color: widget.theme.textColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
              ),
              SizedBox(height: spacingMedium),
              _buildTextField(
                controller: relationshipController,
                label: 'Relationship',
                icon: Icons.family_restroom_rounded,
              ),
              SizedBox(height: spacingMedium),
              _buildTextField(
                controller: phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
              ),
            ),
            child: Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      style: body.copyWith(color: widget.theme.textColor),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: body.copyWith(color: widget.theme.subtextColor),
        prefixIcon: Icon(icon, color: widget.theme.subtextColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: widget.theme.subtextColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: widget.theme.subtextColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        filled: true,
        fillColor: widget.isDarkMode 
          ? Colors.white.withOpacity(0.03)
          : Colors.black.withOpacity(0.02),
      ),
    );
  }

  Future<void> _deleteContact(ContactModel contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        title: Text(
          contact.isCaretaker ? 'Remove Caretaker' : 'Delete Contact',
          style: h3.copyWith(color: widget.theme.textColor),
        ),
        content: Text(
          contact.isCaretaker
            ? 'Are you sure you want to remove ${contact.name} as your caretaker?'
            : 'Are you sure you want to delete ${contact.name}?',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
              ),
            ),
            child: Text(contact.isCaretaker ? 'Remove' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _patientId != null) {
      try {
        if (contact.isCaretaker) {
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
    final isLoading = (_isLoadingCaretakers || _isLoadingEmergency) && _allContacts.isEmpty;

    return RefreshIndicator(
      onRefresh: _refreshContacts,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: width * 0.05,
          right: width * 0.05,
          top: spacingMedium,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),
            
            SizedBox(height: spacingLarge),
            
            // Search Bar (only show if there are contacts)
            if (_allContacts.isNotEmpty) ...[
              _buildSearchBar(),
              SizedBox(height: spacingLarge),
            ],
            
            // Content
            isLoading
                ? _buildLoadingState()
                : _error != null && _allContacts.isEmpty
                    ? _buildErrorState()
                    : _allContacts.isEmpty
                        ? _buildEmptyState()
                        : _buildContactsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final caretakerCount = _caretakerContacts.length;
    final emergencyCount = _emergencyContacts.length;
    final totalCount = caretakerCount + emergencyCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                  SizedBox(height: 4),
                  Text(
                    totalCount == 0
                      ? 'No contacts yet'
                      : '$totalCount contact${totalCount != 1 ? 's' : ''}'
                        '${caretakerCount > 0 ? ' • $caretakerCount caretaker${caretakerCount != 1 ? 's' : ''}' : ''}',
                    style: body.copyWith(
                      color: widget.theme.subtextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Add Contact Button
            Semantics(
              label: 'Add new contact button',
              button: true,
              hint: 'Double tap to add a new emergency contact',
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showAddContactDialog,
                    borderRadius: BorderRadius.circular(radiusLarge),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.add_rounded, color: white, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: widget.isDarkMode 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.06),
        ),
        boxShadow: widget.isDarkMode
          ? []
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
      ),
      child: TextField(
        controller: _searchController,
        style: body.copyWith(color: widget.theme.textColor),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search contacts...',
          hintStyle: body.copyWith(color: widget.theme.subtextColor),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: widget.theme.subtextColor,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear_rounded, color: widget.theme.subtextColor),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primary),
              strokeWidth: 3,
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
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(spacingXLarge),
              decoration: BoxDecoration(
                color: error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: error.withOpacity(0.5),
              ),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'Failed to load contacts',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              _error ?? 'An error occurred',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacingLarge),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoadingCaretakers = true;
                  _isLoadingEmergency = true;
                  _error = null;
                });
                _initializePatientId();
              },
              icon: Icon(Icons.refresh_rounded),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(
                  horizontal: spacingXLarge,
                  vertical: spacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(spacingXLarge * 1.5),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        border: Border.all(
          color: widget.isDarkMode 
            ? primary.withOpacity(0.2)
            : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(spacingXLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary.withOpacity(0.2),
                  primary.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.contacts_rounded,
              size: 64,
              color: primary.withOpacity(0.5),
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
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Add your emergency contacts and caretakers to stay connected',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    final filteredContacts = _filteredContacts;
    
    if (filteredContacts.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: widget.theme.subtextColor.withOpacity(0.3),
              ),
              SizedBox(height: spacingLarge),
              Text(
                'No contacts found',
                style: bodyBold.copyWith(
                  color: widget.theme.textColor,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: spacingSmall),
              Text(
                'Try a different search term',
                style: body.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Separate caretakers and emergency contacts
    final caretakers = filteredContacts.where((c) => c.isCaretaker).toList();
    final emergencyContacts = filteredContacts.where((c) => c.isEmergencyContact).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Caretakers Section
        if (caretakers.isNotEmpty) ...[
          _buildSectionLabel('My Caretakers', Icons.favorite_rounded, primary),
          SizedBox(height: spacingMedium),
          ...caretakers.map((contact) => Padding(
            padding: EdgeInsets.only(bottom: spacingMedium),
            child: _buildContactCard(contact),
          )),
          if (emergencyContacts.isNotEmpty)
            SizedBox(height: spacingLarge),
        ],
        
        // Emergency Contacts Section
        if (emergencyContacts.isNotEmpty) ...[
          _buildSectionLabel('Emergency Contacts', Icons.medical_services_rounded, error),
          SizedBox(height: spacingMedium),
          ...emergencyContacts.map((contact) => Padding(
            padding: EdgeInsets.only(bottom: spacingMedium),
            child: _buildContactCard(contact),
          )),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        SizedBox(width: spacingSmall),
        Text(
          title,
          style: bodyBold.copyWith(
            fontSize: 14,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(ContactModel contact) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: contact.color.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
        border: Border.all(
          color: widget.isDarkMode
              ? contact.color.withOpacity(0.2)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showContactOptions(contact),
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Column(
              children: [
                Row(
                  children: [
                    // Profile Avatar
                    _buildProfileAvatar(contact),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contact.name,
                                  style: bodyBold.copyWith(
                                    fontSize: 18,
                                    color: widget.theme.textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              // Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacingSmall,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: contact.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(radiusSmall),
                                ),
                                child: Text(
                                  contact.isCaretaker ? 'CARETAKER' : 'SOS',
                                  style: caption.copyWith(
                                    fontSize: 10,
                                    color: contact.color,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.badge_rounded,
                                size: 14,
                                color: widget.theme.subtextColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                contact.relationship,
                                style: caption.copyWith(
                                  fontSize: 13,
                                  color: widget.theme.subtextColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 14,
                                color: widget.theme.subtextColor,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  contact.phoneNumber,
                                  style: caption.copyWith(
                                    fontSize: 13,
                                    color: widget.theme.subtextColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: widget.theme.subtextColor.withOpacity(0.5),
                      size: 18,
                    ),
                  ],
                ),
                
                SizedBox(height: spacingMedium),
                Divider(height: 1, color: widget.theme.subtextColor.withOpacity(0.15)),
                SizedBox(height: spacingMedium),
                
                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.phone_rounded,
                        label: 'Call',
                        color: Colors.green,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Calling ${contact.name}...'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: spacingSmall),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.message_rounded,
                        label: 'Message',
                        color: contact.color,
                        isOutlined: true,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening messages with ${contact.name}...'),
                              backgroundColor: contact.color,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    bool isOutlined = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isOutlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusMedium),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: isOutlined ? Border.all(color: color, width: 1.5) : null,
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isOutlined ? color : white,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: bodyBold.copyWith(
                  fontSize: 14,
                  color: isOutlined ? color : white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactOptions(ContactModel contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXLarge)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.theme.subtextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: spacingLarge),
            if (!contact.isCaretaker)
              ListTile(
                leading: Icon(Icons.edit_rounded, color: primary),
                title: Text('Edit Contact', style: body.copyWith(color: widget.theme.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Edit contact feature coming soon'),
                      backgroundColor: primary,
                    ),
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: error),
              title: Text(
                contact.isCaretaker ? 'Remove Caretaker' : 'Delete Contact',
                style: body.copyWith(color: widget.theme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteContact(contact);
              },
            ),
            SizedBox(height: spacingSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(ContactModel contact) {
    final hasProfileImage = contact.profileImageUrl != null && 
                            contact.profileImageUrl!.isNotEmpty;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasProfileImage ? null : LinearGradient(
          colors: [contact.color.withOpacity(0.2), contact.color.withOpacity(0.1)],
        ),
        border: Border.all(
          color: widget.isDarkMode 
              ? contact.color.withOpacity(0.3) 
              : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: contact.color.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: hasProfileImage
            ? Image.network(
                contact.profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [contact.color.withOpacity(0.2), contact.color.withOpacity(0.1)],
                      ),
                    ),
                    child: Icon(
                      contact.avatar,
                      color: contact.color,
                      size: 28,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [contact.color.withOpacity(0.2), contact.color.withOpacity(0.1)],
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(contact.color),
                      ),
                    ),
                  );
                },
              )
            : Icon(
                contact.avatar,
                color: contact.color,
                size: 28,
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