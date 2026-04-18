// File: lib/roles/caretaker/home/sections/patients_screen/patients_content.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patient_model.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patient_details_screen.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Import the new call and message functions
import 'call_patients.dart';
import 'message_patients.dart';

/// Real-Time Patients Content - Redesigned with Communications
class PatientsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final LocationService locationService;
  final ScrollController? scrollController; 

  const PatientsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.locationService,
    this.scrollController, 
  });

  @override
  State<PatientsContent> createState() => _PatientsContentState();
}

class _PatientsContentState extends State<PatientsContent> {
  // Brand Colors - Vibrant Purple
  final Color _primaryColor = const Color(0xFF7C3AED);

  StreamSubscription? _patientsSubscription;
  List<PatientModel> _patients = [];
  bool _isLoading = true;
  String? _error;
  String? _caretakerId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Animation State for Mascot Messages
  Timer? _messageTimer;
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCaretakerId();
    _startMessageTimer();
  }

  // Helper to safely extract the first name from user data
  String _getFirstName() {
    final name = widget.userData['name'] as String? ?? 'Caretaker';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'Caretaker';
  }

  void _startMessageTimer() {
    // Cycle through messages every 4 seconds just like the header
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        final messagesCount = _getMascotMessages().length;
        if (messagesCount > 1) {
          setState(() {
            _currentMessageIndex = (_currentMessageIndex + 1) % messagesCount;
          });
        }
      }
    });
  }

  List<String> _getMascotMessages() {
    final onlineCount = _patients.where((p) => p.isOnline).length;
    final totalCount = _patients.length;
    
    return [
      'Hello, ${_getFirstName()}! You are currently caring for $totalCount patient${totalCount != 1 ? 's' : ''}${totalCount > 0 ? ', with $onlineCount online right now.' : '.'}',
      'Did you know? You can tap on a patient\'s card to view their full details and location.',
      'Need to reach out? Use the quick action buttons to call or message your patients directly.',
    ];
  }

  Future<void> _initializeCaretakerId() async {
    String? caretakerId = widget.userData['uid'] as String?;
    
    if (caretakerId == null || caretakerId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      caretakerId = user?.uid;
    }
    
    if (caretakerId == null || caretakerId.isEmpty) {
      setState(() {
        _error = 'Caretaker ID not found. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    setState(() => _caretakerId = caretakerId);
    _setupPatientsStream();
  }

  void _setupPatientsStream() {
    if (_caretakerId == null) {
      setState(() {
        _error = 'Caretaker ID not found';
        _isLoading = false;
      });
      return;
    }

    _patientsSubscription = caretakerPatientService
        .streamCaretakerPatients(_caretakerId!)
        .listen(
      (patientsData) {
        if (mounted) {
          setState(() {
            _patients = patientsData.map((patientData) {
              return PatientModel(
                id: patientData['userId'] ?? '',
                name: patientData['name'] ?? 'Unknown',
                age: patientData['age'] ?? 0,
                disabilityType: patientData['disabilityType'] ?? 'Not specified',
                contactNumber: patientData['contactNumber'] ?? patientData['phone'] ?? 'N/A',
                address: patientData['address'] ?? 'No address',
                isOnline: false, // Hook this up to real presence data if needed
                lastActive: DateTime.now(),
                profileImageUrl: patientData['profileImageUrl'] as String?,
              );
            }).toList();
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading patients: $error');
        if (mounted) {
          setState(() {
            _error = 'Failed to load patients: $error';
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _patientsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPatients() async {
    if (_caretakerId == null) {
      await _initializeCaretakerId();
      return;
    }
    
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<PatientModel> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    
    return _patients.where((patient) {
      return patient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             patient.disabilityType.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: _refreshPatients,
      color: _primaryColor,
      child: SingleChildScrollView(
        controller: widget.scrollController, 
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
                  
                  // Search Bar (only show if there are patients)
                  if (_patients.isNotEmpty) ...[
                    _buildSearchBar(),
                    const SizedBox(height: spacingLarge),
                  ],
                  
                  // Content
                  _isLoading && _patients.isEmpty
                      ? _buildLoadingState()
                      : _error != null && _patients.isEmpty
                          ? _buildErrorState()
                          : _patients.isEmpty
                              ? _buildEmptyState()
                              : _buildPatientsList(),
                              
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
        Text(
          'My Patients',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: widget.theme.textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage and monitor your paired users',
          style: TextStyle(
            fontSize: 14,
            color: widget.theme.subtextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMascotBanner() {
    final messages = _getMascotMessages();
    final safeIndex = _currentMessageIndex % messages.length;
    final displayMessage = messages[safeIndex];

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
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Mascot Figure
              Image.asset(
                'assets/seelai-icons/seelai2.png',
                height: 120, // Slightly reduced to fit better
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100, width: 100,
                  alignment: Alignment.bottomCenter,
                  child: Icon(Icons.image_not_supported, color: widget.theme.subtextColor),
                ),
              ),
              
              // Speech Bubble Tail (Pointing left, aligned to mouth)
              Container(
                margin: const EdgeInsets.only(bottom: 40), // Adjusted to connect perfectly
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
                      // NEW TYPEWRITER TEXT WITH FIXED HEIGHT CONTAINER
                      Container(
                        height: 65, // Fixed height keeps the bubble static and fits 3 lines
                        alignment: Alignment.topLeft,
                        child: TypewriterText(
                          text: displayMessage,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: widget.isDarkMode
                                ? Colors.white.withValues(alpha: 0.85)
                                : Colors.black87,
                            height: 1.4,
                          ),
                        ),
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: widget.isDarkMode 
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: widget.isDarkMode
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: TextField(
        controller: _searchController,
        style: body.copyWith(color: widget.theme.textColor),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search patients...',
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
          contentPadding: const EdgeInsets.symmetric(
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
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: spacingLarge),
            Text(
              'Loading patients...',
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
              'Failed to load patients',
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
                  _isLoading = true;
                  _error = null;
                });
                _initializeCaretakerId();
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
            ? _primaryColor.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.06),
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
              Icons.people_outline_rounded,
              size: 64,
              color: _primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: spacingLarge),
          Text(
            'No patients yet',
            style: bodyBold.copyWith(
              color: widget.theme.textColor,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: spacingSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'When partially sighted users select you as their caretaker, they will appear here automatically',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    final filteredPatients = _filteredPatients;
    
    if (filteredPatients.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: widget.theme.subtextColor.withOpacity(0.3),
              ),
              const SizedBox(height: spacingLarge),
              Text(
                'No patients found',
                style: bodyBold.copyWith(
                  color: widget.theme.textColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: spacingSmall),
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
    
    return Column(
      children: filteredPatients.map((patient) {
        return Padding(
          padding: const EdgeInsets.only(bottom: spacingMedium),
          child: _buildPatientCard(patient),
        );
      }).toList(),
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
        border: Border.all(
          color: widget.isDarkMode
              ? _primaryColor.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsScreen(
                  patient: patient,
                  isDarkMode: widget.isDarkMode,
                  locationService: widget.locationService,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: const EdgeInsets.all(spacingLarge),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Avatar
                    Stack(
                      children: [
                        _buildProfileAvatar(patient),
                        if (patient.isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.theme.cardColor,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: spacingMedium),
                    
                    // Main Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: bodyBold.copyWith(
                              fontSize: 18,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          
                          // Tags Row
                          Row(
                            children: [
                              // Age Tag
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: spacingSmall,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(radiusSmall),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.cake_rounded,
                                      size: 12,
                                      color: _primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${patient.age} y/o',
                                      style: caption.copyWith(
                                        fontSize: 12,
                                        color: _primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: spacingSmall),
                              
                              // Disability Tag
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: spacingSmall,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(radiusSmall),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.visibility_off_rounded,
                                        size: 12,
                                        color: accent,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          patient.disabilityType,
                                          style: caption.copyWith(
                                            fontSize: 12,
                                            color: accent,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Address Row
                          if (patient.address != null && patient.address != 'No address') ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: widget.theme.subtextColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    patient.address!,
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
                        ],
                      ),
                    ),
                    
                    // Arrow Icon
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: widget.theme.subtextColor.withOpacity(0.5),
                      size: 18,
                    ),
                  ],
                ),
                
                const SizedBox(height: spacingMedium),
                Divider(height: 1, color: widget.theme.subtextColor.withOpacity(0.15)),
                const SizedBox(height: spacingMedium),
                
                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.phone_rounded,
                        label: 'Call',
                        color: Colors.green,
                        onTap: () => callPatient(context, patientName: patient.name),
                      ),
                    ),
                    const SizedBox(width: spacingSmall),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.message_rounded,
                        label: 'Message',
                        color: _primaryColor,
                        isOutlined: true,
                        onTap: () => messagePatient(context, patientName: patient.name),
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

  Widget _buildProfileAvatar(PatientModel patient) {
    final hasProfileImage = patient.profileImageUrl != null && 
                            patient.profileImageUrl!.isNotEmpty;

    return Hero(
      tag: 'patient_avatar_${patient.id}',
      child: Material(
        color: Colors.transparent,
        type: MaterialType.transparency,
        child: Container(
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
            color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
          ),
          child: ClipOval(
            child: hasProfileImage
                ? Image.network(
                    patient.profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildAvatarPlaceholder(),
                    loadingBuilder: (context, child, loadingProgress) {
                       if (loadingProgress == null) return child;
                       return _buildAvatarPlaceholder(isLoading: true);
                    },
                  )
                : _buildAvatarPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder({bool isLoading = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9333EA), // Purple
            Color(0xFF7C3AED), // Darker purple
          ],
        ),
      ),
      child: Center(
        child: isLoading 
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.person_rounded, color: Colors.white, size: 32),
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
    
    // Draw a triangle pointing to the left
    path.moveTo(size.width, 0); // Top right corner
    path.lineTo(0, size.height / 2); // Pointing left (middle)
    path.lineTo(size.width, size.height); // Bottom right corner
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// CUSTOM TYPEWRITER ANIMATION WIDGET
// ==========================================
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;
  bool _wasActive = true; 

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _setupAnimation();
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool isActive = TickerMode.of(context);
    
    if (isActive && !_wasActive) {
      _controller.reset();
      _controller.forward();
    }
    _wasActive = isActive;
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
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
        String visibleString = widget.text.substring(0, _characterCount.value);
        return Text(
          visibleString,
          style: widget.style,
        );
      },
    );
  }
}