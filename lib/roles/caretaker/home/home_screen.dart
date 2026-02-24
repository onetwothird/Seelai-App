// File: lib/roles/caretaker/home/home_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:geolocator/geolocator.dart'; 
import 'package:seelai_app/roles/caretaker/home/sections/home_screen/home_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patient_location/realtime_tracking_screen.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/header_section.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patients_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/requests_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/profile_screen/profile_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/roles/caretaker/services/notification_service.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart'; 
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart'; 
import 'package:seelai_app/firebase/caretaker/request_service.dart';
// Add the new import for the bottom sheet
import 'package:seelai_app/roles/caretaker/home/widgets/notifications_bottom_sheet.dart';

class CaretakerHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CaretakerHomeScreen({
    super.key,
    required this.userData,
  });

  @override
  State<CaretakerHomeScreen> createState() => _CaretakerHomeScreenState();
}

class _CaretakerHomeScreenState extends State<CaretakerHomeScreen> 
    with SingleTickerProviderStateMixin {
  // Services
  late final NotificationService _notificationService;
  late final LocationService _locationService;
  late final RequestService _requestService;
  
  // UI State
  bool _isDarkMode = false;
  int _selectedIndex = 0;
  int _pendingRequestsCount = 0;
  
  // Logic State
  StreamSubscription<List<RequestModel>>? _requestsSubscription;
  int? _lastPendingCount; 

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Scroll detection
  final ScrollController _scrollController = ScrollController();
  bool _isNavVisible = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _initializeScrollListener();
    _startLocationTracking();
    _setupGlobalRequestStream();
  }

  void _initializeServices() {
    _notificationService = NotificationService();
    _locationService = LocationService();
    _requestService = RequestService();
  }

  // ==================== FIX: ROBUST ID HANDLING ====================
  void _setupGlobalRequestStream() {
    // 1. Get Nullable ID
    String? rawId = FirebaseAuth.instance.currentUser?.uid;
    rawId ??= widget.userData['userId'] ?? widget.userData['uid'];

    // 2. Check and Return
    if (rawId == null || rawId.isEmpty) {
      debugPrint("Error: No User ID found for Request Stream.");
      return;
    }

    // 3. Create Non-Nullable 'Safe' ID
    final String userId = rawId;

    debugPrint("Home Screen: Monitoring requests for $userId");

    _requestsSubscription = _requestService.streamRequests(userId).listen((requests) {
      if (mounted) {
        final pendingCount = requests
            .where((req) => req.status == RequestStatus.pending)
            .length;

        setState(() {
          _pendingRequestsCount = pendingCount;
        });

        if (_lastPendingCount != null && pendingCount > _lastPendingCount!) {
          _notificationService.showNotification(
            'New Request',
            'A patient needs your assistance',
          );
        }

        _lastPendingCount = pendingCount;
      }
    });
  }
  // ================================================================

  Future<void> _startLocationTracking() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      // 1. Get Nullable ID
      String? rawId = FirebaseAuth.instance.currentUser?.uid;
      rawId ??= widget.userData['userId'] ?? widget.userData['uid'];
      
      // 2. Check
      if (rawId == null) return;

      // 3. Create Non-Nullable 'Safe' ID
      final String userId = rawId;

      try {
        Position position = await Geolocator.getCurrentPosition(
          // ignore: duplicate_ignore
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high
        );
        
        await locationTrackingService.updateCaretakerLocation(
          caretakerId: userId, // Now safe to use
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          speed: position.speed,
          heading: position.heading,
          altitude: position.altitude,
        );
      } catch (e) {
        debugPrint("Error sending initial location: $e");
      }

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, 
        ),
      ).listen((Position position) {
        locationTrackingService.updateCaretakerLocation(
          caretakerId: userId, // Now safe to use inside closure
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          speed: position.speed,
          heading: position.heading,
          altitude: position.altitude,
        );
      });
      
    } catch (e) {
      debugPrint("Location tracking error: $e");
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );
    
    _animationController.forward();
  }

  void _initializeScrollListener() {
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final currentScroll = _scrollController.position.pixels;
    final scrollDelta = currentScroll - _lastScrollPosition;
    
    const scrollThreshold = 10.0;
    
    if (scrollDelta.abs() > scrollThreshold) {
      final shouldShow = scrollDelta < 0;
      
      if (shouldShow != _isNavVisible) {
        setState(() {
          _isNavVisible = shouldShow;
        });
      }
      
      _lastScrollPosition = currentScroll;
    }
    
    if (currentScroll <= 0 && !_isNavVisible) {
      setState(() {
        _isNavVisible = true;
      });
    }
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    _animationController.reset();
    setState(() {
      _selectedIndex = index;
    });
    _animationController.forward();
  }

  void _updateNotification(String message) {
    setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  // --- NEW: Handle Back Button Press ---
  Future<bool> _onWillPop() async {
    // If not on Home tab (index 0), go back to Home tab first
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
        _animationController.reset();
        _animationController.forward();
      });
      return false; // Prevent exit
    }

    // If on Home tab, show Exit Confirmation Dialog
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            // Use PURPLE Theme color
            const Icon(Icons.logout_rounded, color: Color(0xFF8B5CF6)), 
            const SizedBox(width: 10),
            Text('Exit App?', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          ],
        ),
        content: Text(
          'Are you sure you want to exit and log out?',
          style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              // Optional: Add logic here if you want to explicitly sign out before closing
              // await authService.signOut(); 
            },
            // Use PURPLE Theme color
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final caretakerName = widget.userData['name'] ?? 'Caretaker';

    final theme = _isDarkMode 
      ? _getDarkTheme() 
      : _getLightTheme();

    // WRAP SCAFFOLD IN WILLPOPSCOPE
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        body: Container(
          decoration: BoxDecoration(gradient: theme.backgroundGradient),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // THIS CONDITION HIDES THE HEADER ON THE PROFILE TAB (INDEX 3)
                if (_selectedIndex != 3)
                  HeaderSection(
                    caretakerName: caretakerName,
                    profileImageUrl: widget.userData['profileImageUrl'] as String?, 
                    isDarkMode: _isDarkMode,
                    pendingRequestsCount: _pendingRequestsCount,
                    onToggleDarkMode: _toggleDarkMode,
                    onProfileTap: () {
                      setState(() {
                        _selectedIndex = 3; 
                      });
                    },
                    onNotificationTap: () {
                      // 1. Safely grab the Caretaker's ID
                      String? currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 
                                              widget.userData['userId'] ?? 
                                              widget.userData['uid'];
                                              
                      if (currentUserId == null) return;

                      // 2. Trigger the Facebook-style bottom sheet
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true, 
                        backgroundColor: Colors.transparent, 
                        builder: (context) => SizedBox(
                          height: screenHeight * 0.85, 
                          child: NotificationsBottomSheet(
                            caretakerId: currentUserId,
                            isDarkMode: _isDarkMode,
                            requestService: _requestService, 
                          ),
                        ),
                      );
                    },
                    textColor: theme.textColor,
                    subtextColor: theme.subtextColor,
                  ),
                
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildMainContent(
                      screenWidth,
                      screenHeight,
                      theme,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          offset: _isNavVisible ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isNavVisible ? 1.0 : 0.0,
            child: CustomBottomNavigation(
              selectedIndex: _selectedIndex,
              isDarkMode: _isDarkMode,
              onItemTapped: _onNavItemTapped,
              textColor: theme.textColor,
              subtextColor: theme.subtextColor,
              pendingRequestsCount: _pendingRequestsCount,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(double width, double height, _AppTheme theme) {
    switch (_selectedIndex) {
      case 0:
        return SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: HomeContent(
            isDarkMode: _isDarkMode,
            theme: theme,
            userData: widget.userData,
            onNotificationUpdate: _updateNotification,
            requestService: _requestService,
            locationService: _locationService,
          ),
        );
      
      case 1:
        return PatientsContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
          scrollController: _scrollController, 
          locationService: _locationService,
        );
      
      case 2:
        return RequestsContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
          requestService: _requestService,
          scrollController: _scrollController,
          onRequestCountChange: (count) {
            if (_pendingRequestsCount != count) {
              setState(() {
                _pendingRequestsCount = count;
              });
            }
          },
        );
      
      case 3:
        return SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: ProfileContent(
            userData: widget.userData,
            isDarkMode: _isDarkMode,
            theme: theme,
          ),
        );
      
      case 4:
        return RealtimeTrackingScreen(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
          locationService: _locationService,
        );
      
      default:
        return SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: HomeContent(
            isDarkMode: _isDarkMode,
            theme: theme,
            userData: widget.userData,
            onNotificationUpdate: _updateNotification,
            requestService: _requestService,
            locationService: _locationService,
          ),
        );
    }
  }

  _AppTheme _getDarkTheme() {
    return _AppTheme(
      backgroundGradient: const LinearGradient(
        colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF2A2F4A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.5, 1.0],
      ),
      textColor: white,
      subtextColor: const Color(0xFFB0B8D4),
      cardColor: const Color(0xFF1A1F3A),
    );
  }

  _AppTheme _getLightTheme() {
    return _AppTheme(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Colors.white], 
      ),
      textColor: black,
      subtextColor: grey,
      cardColor: white,
    );
  }
}

class _AppTheme {
  final LinearGradient backgroundGradient;
  final Color textColor;
  final Color subtextColor;
  final Color cardColor;

  _AppTheme({
    required this.backgroundGradient,
    required this.textColor,
    required this.subtextColor,
    required this.cardColor,
  });
}