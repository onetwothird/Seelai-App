// File: lib/roles/partially_sighted/home/sections/contacts_screen/contacts_content.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'contact_model.dart';
import 'adding_contact.dart';
import 'call_contact.dart';
import 'message_contact.dart';
import 'edit_contact.dart';

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
  // Brand Colors
  final Color _primaryColor = const Color(0xFF7C3AED);

  StreamSubscription? _caretakersSubscription;
  StreamSubscription? _emergencyContactsSubscription;
  
  List<ContactModel> _caretakerContacts = [];
  List<ContactModel> _emergencyContacts = [];
  
  bool _isLoadingCaretakers = true;
  bool _isLoadingEmergency = true;
  String? _error;
  String? _patientId;
  final String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // 0 = All, 1 = Caretakers, 2 = SOS
  int _selectedFilterIndex = 0; 
  
  // Animation State
  Timer? _messageTimer;
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializePatientId();
    _startMessageTimer();
  }
  
  void _startMessageTimer() {
    _messageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % 2;
        });
      }
    });
  }

  // Helper to safely extract the first name from user data
  String _getFirstName() {
    final name = widget.userData['name'] as String? ?? 'User';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'User';
  }
  
  List<String> _getMascotMessages() {
    return [
      'Hello, ${_getFirstName()}! You have ${_caretakerContacts.length} caretaker${_caretakerContacts.length != 1 ? 's' : ''} and ${_emergencyContacts.length} SOS contact${_emergencyContacts.length != 1 ? 's' : ''} in your network.',
      'Did you know? You can tap on a contact card to quickly call or send them a message.',
    ];
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
                color: _primaryColor,
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
              profileImageUrl: contact['profileImageUrl'] as String?, 
            );
          }).toList();
            _isLoadingEmergency = false;
            _error = null;
          });
        }
      },
      onError: (err) {
        debugPrint('Error loading emergency contacts: $err');
        if (mounted) {
          setState(() {
            _error = 'Failed to load emergency contacts: $err';
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
    _messageTimer?.cancel();
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
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isLoadingCaretakers = false;
        _isLoadingEmergency = false;
      });
    }
  }

  List<ContactModel> get _allContacts => [..._caretakerContacts, ..._emergencyContacts];

  List<ContactModel> get _filteredContacts {
    List<ContactModel> baseList = _allContacts;
    
    // Filter by Pill (All, Caretakers, SOS)
    if (_selectedFilterIndex == 1) {
      baseList = _caretakerContacts;
    } else if (_selectedFilterIndex == 2) {
      baseList = _emergencyContacts;
    }

    // Search query filter
    if (_searchQuery.isEmpty) {
      return baseList;
    }
    
    return baseList.where((contact) {
      return contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             contact.relationship.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             contact.phoneNumber.contains(_searchQuery);
    }).toList();
  }

  Future<void> _showAddContactDialog() async {
    if (_patientId != null) {
      await showDialog(
        context: context,
        builder: (dialogContext) => AddContactDialog(
          patientId: _patientId!,
          isDarkMode: widget.isDarkMode,
          theme: widget.theme,
          onContactAdded: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact added successfully'),
                  backgroundColor: success,
                ),
              );
            }
          },
        ),
      );
    }
  }

  Future<void> _handleCall(ContactModel contact) async {
    if (contact.phoneNumber == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number not available for ${contact.name}'),
          backgroundColor: error,
        ),
      );
      return;
    }

    await CallContact.call(
      context: context,
      contact: contact,
      isDarkMode: widget.isDarkMode,
      theme: widget.theme,
    );
  }

  Future<void> _handleMessage(ContactModel contact) async {
    if (contact.phoneNumber == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number not available for ${contact.name}'),
          backgroundColor: error,
        ),
      );
      return;
    }

    await MessageContact.message(
      context: context,
      contact: contact,
      isDarkMode: widget.isDarkMode,
      theme: widget.theme,
    );
  }

  Future<void> _editContact(ContactModel contact) async {
    if (_patientId != null && !contact.isCaretaker) {
      await showDialog(
        context: context,
        builder: (dialogContext) => EditContactDialog(
          patientId: _patientId!,
          contact: contact,
          isDarkMode: widget.isDarkMode,
          theme: widget.theme,
          onContactUpdated: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact updated successfully'),
                  backgroundColor: success,
                ),
              );
            }
          },
        ),
      );
    }
  }

  Future<void> _deleteContact(ContactModel contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: body.copyWith(color: widget.theme.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Caretaker removed successfully'),
              backgroundColor: success,
            ),
          );
        } else {
          await emergencyContactsService.removeEmergencyContact(
            userId: _patientId!,
            contactId: contact.id,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact deleted successfully'),
              backgroundColor: success,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
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
      color: _primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: width * 0.05,
                right: width * 0.05,
                top: spacingLarge,
              ),
              child: _buildHeader(),
            ),
            const SizedBox(height: spacingMedium),
            
            // Edge-to-edge Mascot Banner with Bubble
            _buildMascotBanner(),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: spacingMedium),
                  
                  // Filter Pills replacing search bar
                  if (_allContacts.isNotEmpty) _buildFilterTabs(),
                  
                  const SizedBox(height: spacingLarge),
                  
                  isLoading
                      ? _buildLoadingState()
                      : _error != null && _allContacts.isEmpty
                          ? _buildErrorState()
                          : _allContacts.isEmpty
                              ? _buildEmptyState()
                              : _buildContactsList(),
                              
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Contacts',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: widget.theme.textColor,
                letterSpacing: -0.5,
              ),
            ),
            InkWell(
              onTap: _showAddContactDialog,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: widget.isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: _primaryColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Add Contact',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your network and SOS',
          style: TextStyle(
            fontSize: 14,
            color: widget.theme.subtextColor,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

 Widget _buildMascotBanner() {
    final messages = _getMascotMessages();
    final displayMessage = messages[_currentMessageIndex % messages.length];
    
    // Find the longest message to lock the bubble size
    final longestMessage = messages.reduce((a, b) => a.length > b.length ? a : b);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Edge-to-edge gradient background strictly tied to the top
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withValues(alpha: widget.isDarkMode ? 0.25 : 0.15),
                  _primaryColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        
        // Mascot and Speech Bubble
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.06,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Mascot Figure
             Image.asset(
                        'assets/seelai-icons/seelai2.png',
                        width: 90,
                        height: 105,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.smart_toy_outlined,
                            color: _primaryColor,
                            size: 36,
                          ),
                        ),
                      ),
              
              // Speech Bubble Tail (Pointing left, aligned to mouth)
              Container(
                margin: const EdgeInsets.only(bottom: 40),
                child: CustomPaint(
                  size: const Size(12, 16),
                  painter: _TailPainter(
                    color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                  ),
                ),
              ),

              // Speech Bubble Content - Conversational text
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: widget.isDarkMode ? [] : [
                      BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Keep it compact
                    children: [
                      Text(
                        'Seelai',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // THE STACK TRICK - No cutting, no jumping!
                      Stack(
                        children: [
                          // 1. Invisible text uses the LONGEST message to keep bubble size fixed
                          Text(
                            longestMessage,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.transparent, 
                              height: 1.4,
                            ),
                          ),
                          // 2. Typewriter text types out the current message
                          Positioned.fill(
                            child: TypewriterText(
                              text: displayMessage,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Pill Filters mimicking the "All, Debit, Credit" style
  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: _buildFilterPill('All', 0)),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterPill('Caretakers', 1)),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterPill('SOS', 2)),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, int index) {
    bool isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : widget.theme.cardColor,
          borderRadius: BorderRadius.circular(24), // Pill shape
          border: Border.all(
            color: isSelected 
                ? _primaryColor 
                : (widget.isDarkMode ? Colors.white10 : Colors.black12),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : widget.theme.subtextColor,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: spacingLarge),
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
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(spacingXLarge),
              decoration: BoxDecoration(
                color: error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: error.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: spacingLarge),
            Text(
              'Failed to load contacts',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: spacingSmall),
            Text(
              _error ?? 'An error occurred',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: spacingLarge),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoadingCaretakers = true;
                  _isLoadingEmergency = true;
                  _error = null;
                });
                _initializePatientId();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(
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
      width: double.infinity,
      padding: const EdgeInsets.all(spacingXLarge * 1.5),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        border: Border.all(
          color: widget.isDarkMode 
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(spacingXLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withValues(alpha: 0.2),
                  _primaryColor.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.contacts_rounded,
              size: 64,
              color: _primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: spacingLarge),
          Text(
            'No contacts yet',
            style: bodyBold.copyWith(
              color: widget.theme.textColor,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: spacingSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
    
    if (filteredContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(
                Icons.filter_list_off_rounded,
                size: 64,
                color: widget.theme.subtextColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: spacingLarge),
              Text(
                'No contacts in this category',
                style: bodyBold.copyWith(
                  color: widget.theme.textColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final caretakers = filteredContacts.where((c) => c.isCaretaker).toList();
    final emergencyContacts = filteredContacts.where((c) => c.isEmergencyContact).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (caretakers.isNotEmpty) ...[
          if (_selectedFilterIndex == 0) _buildSectionLabel('My Caretakers', _primaryColor),
          const SizedBox(height: spacingMedium),
          ...caretakers.map((contact) => Padding(
            padding: const EdgeInsets.only(bottom: spacingMedium),
            child: _buildContactCard(contact),
          )),
          if (emergencyContacts.isNotEmpty && _selectedFilterIndex == 0)
            const SizedBox(height: spacingLarge),
        ],

        if (emergencyContacts.isNotEmpty) ...[
          if (_selectedFilterIndex == 0) _buildSectionLabel('Emergency Contacts', error),
          const SizedBox(height: spacingMedium),
          ...emergencyContacts.map((contact) => Padding(
            padding: const EdgeInsets.only(bottom: spacingMedium),
            child: _buildContactCard(contact),
          )),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        color: widget.theme.textColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildContactCard(ContactModel contact) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showContactOptions(contact),
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: const EdgeInsets.all(spacingLarge),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildProfileAvatar(contact),
                    const SizedBox(width: spacingMedium),

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

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: spacingSmall,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: contact.color.withValues(alpha: 0.15),
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

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              Icon(Icons.badge_rounded,
                                  size: 14, color: widget.theme.subtextColor),
                              const SizedBox(width: 4),
                              Text(
                                contact.relationship,
                                style: caption.copyWith(
                                  fontSize: 13,
                                  color: widget.theme.subtextColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Icon(Icons.phone_rounded,
                                  size: 14, color: widget.theme.subtextColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  contact.phoneNumber,
                                  style: caption.copyWith(
                                    fontSize: 13,
                                    color: widget.theme.subtextColor,
                                    fontWeight: FontWeight.w400,
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
                      color: widget.theme.subtextColor.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ],
                ),

                const SizedBox(height: spacingMedium),
                Divider(height: 1, color: widget.theme.subtextColor.withValues(alpha: 0.15)),
                const SizedBox(height: spacingMedium),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.phone_rounded,
                        label: 'Call',
                        color: Colors.green,
                        onTap: () => _handleCall(contact),
                      ),
                    ),
                    const SizedBox(width: spacingSmall),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.message_rounded,
                        label: 'Message',
                        color: contact.color,
                        isOutlined: true,
                        onTap: () => _handleMessage(contact),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              const SizedBox(width: 8),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXLarge)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: const EdgeInsets.all(spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.theme.subtextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: spacingLarge),
            if (!contact.isCaretaker)
              ListTile(
                leading: Icon(Icons.edit_rounded, color: _primaryColor),
                title: Text('Edit Contact', style: body.copyWith(color: widget.theme.textColor)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _editContact(contact);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: error),
              title: Text(
                contact.isCaretaker ? 'Remove Caretaker' : 'Delete Contact',
                style: body.copyWith(color: widget.theme.textColor),
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _deleteContact(contact);
              },
            ),
            const SizedBox(height: spacingSmall),
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
        border: Border.all(
          color: widget.isDarkMode 
              ? Colors.white.withValues(alpha: 0.1) 
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
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
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primaryColor, 
                          _primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Icon(
                      contact.avatar,
                      color: Colors.white,
                      size: 28,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_primaryColor, _primaryColor.withValues(alpha: 0.8)],
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  );
                },
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primaryColor, _primaryColor.withValues(alpha: 0.8)],
                  ),
                ),
                child: Icon(contact.avatar, color: Colors.white, size: 28),
              ),
      ),
    );
  }
}

// Custom Painter to draw the speech bubble tail pointing to the mascot
class _TailPainter extends CustomPainter {
  final Color color;

  _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    
    path.moveTo(size.width, 0); 
    path.lineTo(0, size.height / 2); 
    path.lineTo(size.width, size.height); 
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// TYPEWRITER ANIMATION WIDGET (DYNAMIC SPEED)
// ==========================================
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    // THE FIX: Dynamic speed! 40 milliseconds per character.
    // Long messages and short messages will now type at the exact same natural speed.
    int msDuration = widget.text.length * 40; 
    
    _controller = AnimationController(
      vsync: this, 
      duration: Duration(milliseconds: msDuration),
    );
    _setupAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      int msDuration = widget.text.length * 40; 
      _controller.duration = Duration(milliseconds: msDuration);
      _setupAnimation();
      _controller.reset();
      _controller.forward();
    }
  }

  void _setupAnimation() {
    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        int end = _characterCount.value;
        // Strict safety check to prevent out-of-bounds text duplication
        if (end > widget.text.length) end = widget.text.length;
        if (end < 0) end = 0;
        
        return Text(
          widget.text.substring(0, end),
          style: widget.style,
        );
      },
    );
  }
}