// File: lib/roles/caretaker/home/sections/home_screen/caretaker_home_content.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart'; 
import 'package:seelai_app/firebase/caretaker/request_service.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

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
  
  bool _isLoadingPatients = true;
  bool _isLoadingRequests = true;
  String? _caretakerId;
  
  bool _isSimulatingLoad = true;
  
  StreamSubscription? _patientsSubscription;
  StreamSubscription? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCaretakerId();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSimulatingLoad = false;
        });
      }
    });
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

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isLoadingPatients) {
        setState(() => _isLoadingPatients = false);
      }
    });

    _patientsSubscription = caretakerPatientService
        .streamCaretakerPatients(_caretakerId!)
        .listen(
      (patientsData) {
        if (mounted) {
          setState(() {
            _assignedPatients = patientsData.map((data) {
              return {
                ...data,
                'userId': data['userId']?.toString() ?? '',
                'name': data['name']?.toString() ?? 'Unknown',
                'profileImageUrl': data['profileImageUrl']?.toString(),
              };
            }).toList();
            
            _totalPatients = patientsData.length;
            _isLoadingPatients = false;
          });
        }
      },
      onError: (error) {
        debugPrint("Error loading assigned patients stream: $error");
        if (mounted) setState(() => _isLoadingPatients = false);
      },
    );
  }

  void _setupRequestsStream() {
    if (_caretakerId == null) return;

    // ADDED FAIL-SAFE TIMEOUT TO PREVENT INFINITE SKELETON
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isLoadingRequests) {
        setState(() => _isLoadingRequests = false);
      }
    });

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

  Widget _buildSkeletonHome() {
    final baseColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 140, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Container(height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
                const SizedBox(width: 16),
                Expanded(child: Container(height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Container(height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
                const SizedBox(width: 16),
                Expanded(child: Container(height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
              ],
            ),
            const SizedBox(height: 32),
            
            Container(width: 120, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(3, (index) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(width: 140, height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                )),
              ),
            ),
            
            const SizedBox(height: 32),
            Container(width: 160, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 16),
            Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 12),
            Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Shows skeleton if artificially loading OR if actual data is still fetching
    if (_isSimulatingLoad || _isLoadingPatients || _isLoadingRequests) {
      return _buildSkeletonHome();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          
          MyPatientsSection(
            isDarkMode: widget.isDarkMode,
            theme: widget.theme,
            isLoadingPatients: _isLoadingPatients,
            assignedPatients: _assignedPatients,
          ),

          const SizedBox(height: 32),

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