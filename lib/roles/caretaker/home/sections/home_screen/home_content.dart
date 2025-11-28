// ignore_for_file: unnecessary_to_list_in_spreads, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/caretaker/request_service.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'dart:async';

// Import the separated components
import 'overview.dart';
import 'announcement.dart';
import 'request_breakdown.dart';

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
  // Statistics
  int _totalPatients = 0;
  int _pendingRequests = 0;
  int _completedRequests = 0;
  int _activeRequests = 0;  
  bool _isLoading = true;
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

  /// Initialize caretaker ID - EXACT same as patients_content.dart
  Future<void> _initializeCaretakerId() async {
    String? caretakerId = widget.userData['uid'] as String?;
    
    if (caretakerId == null || caretakerId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      caretakerId = user?.uid;
    }
    
    if (caretakerId == null || caretakerId.isEmpty) {
      debugPrint('❌ HOME: Caretaker ID not found. Please log in again.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    debugPrint('✅ HOME: Caretaker ID initialized: $caretakerId');
    setState(() => _caretakerId = caretakerId);
    
    // Setup all listeners
    _setupPatientsStream();
    _setupRequestsStream();
    await _fetchAnnouncements();
  }

  /// Setup patients stream - EXACT same as patients_content.dart
  void _setupPatientsStream() {
    if (_caretakerId == null) {
      debugPrint('❌ HOME: Cannot setup patients stream - caretaker ID is null');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    debugPrint('🔄 HOME: Setting up patients stream for: $_caretakerId');
    
    _patientsSubscription = caretakerPatientService
        .streamCaretakerPatients(_caretakerId!)
        .listen(
      (patientsData) {
        debugPrint('📊 HOME: Received ${patientsData.length} patients');
        
        if (mounted) {
          setState(() {
            _totalPatients = patientsData.length;
          });
          
          if (patientsData.isNotEmpty) {
            debugPrint('✅ HOME: Patients list:');
            for (var patient in patientsData) {
              debugPrint('   - ${patient['name']} (ID: ${patient['userId']})');
            }
          } else {
            debugPrint('⚠️ HOME: No patients found in assignedPatients');
          }
        }
      },
      onError: (error) {
        debugPrint('❌ HOME: Error loading patients: $error');
        if (mounted) {
          setState(() {
            _totalPatients = 0;
            _isLoading = false;
          });
        }
      },
    );
  }

  /// Setup requests stream
  void _setupRequestsStream() {
    if (_caretakerId == null) {
      debugPrint('❌ HOME: Cannot setup requests stream - caretaker ID is null');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    debugPrint('🔄 HOME: Setting up requests stream');
    
    _requestsSubscription = assistanceRequestService
        .streamCaretakerRequests(_caretakerId!)
        .listen(
      (requests) {
        debugPrint('📊 HOME: Received ${requests.length} requests');
        
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
            _isLoading = false;
          });
          
          debugPrint('✅ HOME: Requests - Pending: $pending, Active: $active, Completed: $completed');
        }
      },
      onError: (error) {
        debugPrint('❌ HOME: Error streaming requests: $error');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  /// Fetch announcements from MSWD
  Future<void> _fetchAnnouncements() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('announcements/mswd')
          .orderByChild('timestamp')
          .limitToLast(5)
          .once();
      
      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final announcementsList = <Map<String, dynamic>>[];
        
        data.forEach((key, value) {
          final announcement = Map<String, dynamic>.from(value as Map);
          announcement['id'] = key;
          announcementsList.add(announcement);
        });
        
        announcementsList.sort((a, b) => 
          (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0)
        );
        
        if (mounted) {
        }
      } else {
        if (mounted) {
          setState(() {
          });
        }
      }
    } catch (e) {
      debugPrint('❌ HOME: Error fetching announcements: $e');
    }
  }

  /// Manual refresh
  Future<void> _refreshDashboardData() async {
    setState(() => _isLoading = true);
    await _fetchAnnouncements();
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Section
          OverviewSection(
            isDarkMode: widget.isDarkMode,
            theme: widget.theme,
            isLoading: _isLoading,
            totalPatients: _totalPatients,
            pendingRequests: _pendingRequests,
            activeRequests: _activeRequests,
            completedRequests: _completedRequests,
            onRefresh: _refreshDashboardData,
          ),
          SizedBox(height: spacingXLarge),
          
            AnnouncementSection(
            isDarkMode: widget.isDarkMode,
            theme: widget.theme,
            caretakerId: _caretakerId!, 
          ),
          SizedBox(height: spacingXLarge),
          
          // Request Breakdown Section
          RequestBreakdownSection(
            isDarkMode: widget.isDarkMode,
            theme: widget.theme,
            isLoading: _isLoading,
            pendingRequests: _pendingRequests,
            activeRequests: _activeRequests,
            completedRequests: _completedRequests,
          ),
          SizedBox(height: spacingXLarge),
        ],
      ),
    );
  }
}