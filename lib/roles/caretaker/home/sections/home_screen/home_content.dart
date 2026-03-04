// File: lib/roles/caretaker/home/sections/home_screen/home_content.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/caretaker/request_service.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart'; 

// Import the separated components
import 'overview.dart';
import 'announcement.dart';

class HomeContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final Function(String) onNotificationUpdate;
  final RequestService requestService;
  final LocationService locationService;

  const HomeContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.onNotificationUpdate,
    required this.requestService,
    required this.locationService,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Statistics & Data
  List<Map<String, dynamic>> _assignedPatients = [];
  int _totalPatients = 0;
  int _pendingRequests = 0;
  int _completedRequests = 0;
  int _activeRequests = 0;  
  
  // SEPARATED LOADING STATES
  bool _isLoadingPatients = true;
  bool _isLoadingRequests = true;
  String? _caretakerId;
  
  // Stream subscriptions
  StreamSubscription? _patientsSubscription;
  StreamSubscription? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCaretakerId();
  }

  @override
  void dispose() {
    _patientsSubscription?.cancel();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeCaretakerId() async {
    String? caretakerId = widget.userData['uid'] as String?;
    caretakerId ??= FirebaseAuth.instance.currentUser?.uid;
    
    if (caretakerId == null || caretakerId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingPatients = false;
          _isLoadingRequests = false;
        });
      }
      return;
    }

    setState(() => _caretakerId = caretakerId);
    
    _setupPatientsStream();
    _setupRequestsStream();
  }

  void _setupPatientsStream() {
    if (_caretakerId == null) return;

    _patientsSubscription = caretakerPatientService
        .streamCaretakerPatients(_caretakerId!)
        .listen(
      (patientsData) {
        if (mounted) {
          setState(() {
            _assignedPatients = List<Map<String, dynamic>>.from(patientsData);
            _totalPatients = patientsData.length;
            _isLoadingPatients = false;
          });
        }
      },
      onError: (error) {
        if (mounted) setState(() => _isLoadingPatients = false);
      },
    );
  }

  void _setupRequestsStream() {
    if (_caretakerId == null) return;

    _requestsSubscription = assistanceRequestService
        .streamCaretakerRequests(_caretakerId!)
        .listen(
      (requests) {
        if (mounted) {
          int pending = 0;
          int active = 0;
          int completed = 0;
          
          for (var request in requests) {
            final status = request.status.toString().split('.').last;
            if (status == 'pending') {
              pending++;
            // ignore: curly_braces_in_flow_control_structures
            } else if (status == 'accepted' || status == 'inProgress') active++;
            // ignore: curly_braces_in_flow_control_structures
            else if (status == 'completed') completed++;
          }
          
          setState(() {
            _pendingRequests = pending;
            _activeRequests = active;
            _completedRequests = completed;
            _isLoadingRequests = false;
          });
        }
      },
      onError: (error) {
        if (mounted) setState(() => _isLoadingRequests = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Because home_screen.dart already wraps this in a SingleChildScrollView, 
    // we only return a Column here to prevent scroll conflicts!
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Alert Banner
          if (_pendingRequests > 0) _buildUrgentAlert(),

          // Stats Grid
          OverviewSection(
            isDarkMode: widget.isDarkMode,
            theme: widget.theme,
            isLoading: _isLoadingRequests,
            totalPatients: _totalPatients,
            pendingRequests: _pendingRequests,
            activeRequests: _activeRequests,
            completedRequests: _completedRequests,
          ),
          
          const SizedBox(height: 32),
          
          // Live Patients List
          _buildPatientsSection(),

          const SizedBox(height: 32),

          // Announcements
          if (_caretakerId != null) 
            AnnouncementSection(
              isDarkMode: widget.isDarkMode,
              theme: widget.theme,
              caretakerId: _caretakerId!, 
            ),
        ],
      ),
    );
  }

  Widget _buildUrgentAlert() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF450a0a) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? const Color(0xFF7f1d1d) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action Required',
                  style: TextStyle(
                    color: widget.isDarkMode ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You have $_pendingRequests pending assistance request(s).',
                  style: TextStyle(
                    color: widget.isDarkMode ? const Color(0xFFFECACA) : const Color(0xFF7F1D1D),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Patients',
              style: TextStyle(
                fontSize: 20,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () => _showAllPatientsBottomSheet(context), 
              child: Text(
                'See All',
                style: TextStyle(color: primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingPatients)
          // --- UPDATED LOADING INDICATOR HERE ---
          Center(
            child: Padding(
              padding: EdgeInsets.all(spacingLarge), 
              child: CircularProgressIndicator(color: primary),
            ),
          )
        else if (_assignedPatients.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.theme.subtextColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.group_off_rounded, size: 40, color: widget.theme.subtextColor.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text(
                  'No patients assigned yet',
                  style: TextStyle(color: widget.theme.subtextColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 140,
            // Horizontal list is safe from scrolling conflicts here
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _assignedPatients.length,
              itemBuilder: (context, index) {
                final patient = _assignedPatients[index];
                return _PatientCard(
                  patient: patient,
                  theme: widget.theme,
                  isDarkMode: widget.isDarkMode,
                );
              },
            ),
          ),
      ],
    );
  }

  // Bottom Sheet to view all patients
 void _showAllPatientsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: widget.theme.backgroundGradient.colors.last, // Match app background
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: widget.theme.subtextColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'All Assigned Patients',
                      style: TextStyle(
                        color: widget.theme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_assignedPatients.length}',
                        style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85, // Changed from 0.75 to make them less awkward/tall
                  ),
                  itemCount: _assignedPatients.length,
                  itemBuilder: (context, index) {
                    return _PatientCard(
                      patient: _assignedPatients[index],
                      theme: widget.theme,
                      isDarkMode: widget.isDarkMode,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Extracted Widget for Patient Card to handle Real-Time Online Status and Images
class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final dynamic theme;
  final bool isDarkMode;

  const _PatientCard({
    required this.patient,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final patientName = patient['name'] ?? 'Unknown';
    final patientId = patient['userId'] ?? '';
    // Safely extract the profile image URL
    final profileImageUrl = patient['profileImageUrl'] as String?; 
    
    // The exact purple color you requested
    final Color primaryPurple = const Color(0xFF8B5CF6);

    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // === PROFILE IMAGE OR PURPLE ICON ===
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // If no image, use the solid purple background
              color: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                  ? (isDarkMode ? Colors.white10 : Colors.grey[200])
                  : primaryPurple, 
              // The black outline you requested
              border: Border.all(
                color: isDarkMode ? Colors.white30 : Colors.black, 
                width: 1.0,
              ), 
              image: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(profileImageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            // Show the white person icon if there is no image
            child: (profileImageUrl == null || profileImageUrl.isEmpty)
                ? const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28, 
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          
          Text(
            patientName,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.textColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          
          // === REAL-TIME STATUS CHECKER ===
          StreamBuilder<Map<String, dynamic>?>(
            stream: locationTrackingService.trackPatientLocation(patientId),
            builder: (context, snapshot) {
              bool isOnline = false;

              if (snapshot.hasData && snapshot.data != null) {
                isOnline = locationTrackingService.isLocationRecent(snapshot.data!);
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey, 
                      shape: BoxShape.circle
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: isOnline ? theme.subtextColor : Colors.grey, 
                      fontSize: 11,
                      fontWeight: isOnline ? FontWeight.w600 : FontWeight.w400,
                    ),
                  )
                ],
              );
            },
          )
        ],
      ),
    );
  }
}