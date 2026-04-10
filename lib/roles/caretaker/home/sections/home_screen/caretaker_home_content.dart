// File: lib/roles/caretaker/home/sections/home_screen/home_content.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/firebase/caretaker/request_service.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

// Import the separated components
import 'overview.dart';
import 'announcement.dart';
import 'my_patients.dart'; 

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
            } else if (status == 'accepted' || status == 'inProgress') {
              active++;
            } else if (status == 'completed') {
              completed++;
            }
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
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Alert Banner

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
          MyPatientsSection(
            isDarkMode: widget.isDarkMode,
            theme: widget.theme,
            isLoadingPatients: _isLoadingPatients,
            assignedPatients: _assignedPatients,
          ),

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

}