import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // NEW IMPORT REQUIRED FOR SCROLL DIRECTION
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:geolocator/geolocator.dart'; 
import 'package:seelai_app/roles/caretaker/home/sections/home_screen/caretaker_home_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patient_location/realtime_tracking_screen.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/caretaker_header_section.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patients_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/requests_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/profile_screen/caretaker_profile_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/roles/caretaker/services/notification_service.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart'; 
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart'; 
import 'package:seelai_app/firebase/caretaker/request_service.dart';

// IMPORT FOR THE BOTTOM SHEET
import 'package:seelai_app/roles/caretaker/home/widgets/notifications_bottom_sheet.dart';

// IMPORT FOR THE GLOBAL CALL LISTENER
import 'package:seelai_app/shared/widgets/incoming_call_listener.dart';

// IMPORT FOR POST-LOGOUT NAVIGATION
import 'package:seelai_app/screens/onboarding_screen.dart';

// NEW IMPORT FOR THE FLOATING MISSED CALL SECTION
import 'package:seelai_app/roles/caretaker/home/sections/home_screen/communication/caretaker_missed_call_alert_section.dart';

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
  
  // Scroll Navigation State
  bool _isNavVisible = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _startLocationTracking();
    _setupGlobalRequestStream();
  }

  void _initializeServices() {
    _notificationService = NotificationService();
    _locationService = LocationService();
    _requestService = RequestService();
  }

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
    _requestsSubscription?.cancel();
    super.dispose();
  }

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
              Navigator.of(context).pop(false); // Close the dialog
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                  (route) => false, // Clear the entire navigation stack
                );
              }
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

    final theme = _isDarkMode 
      ? _getDarkTheme() 
      : _getLightTheme();

    return IncomingCallListener(
      userRole: 'caretaker', 
      child: PopScope(
        canPop: false, 
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return; 
          }

          final bool shouldPop = await _onWillPop();
          
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop(result);
          }
        },
        child: Scaffold(
          extendBody: true,
          body: Container(
            decoration: BoxDecoration(gradient: theme.backgroundGradient),
            child: SafeArea(
              bottom: false,
              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  if (notification.direction == ScrollDirection.forward) {
                    if (!_isNavVisible) setState(() => _isNavVisible = true);
                  } else if (notification.direction == ScrollDirection.reverse) {
                    if (_isNavVisible) setState(() => _isNavVisible = false);
                  }
                  return false; 
                },
                child: Stack(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMainContent(
                        screenWidth,
                        screenHeight,
                        theme,
                      ),
                    ),

                    CaretakerMissedCallAlertSection(
                      caretakerId: FirebaseAuth.instance.currentUser?.uid ?? widget.userData['userId'] ?? widget.userData['uid'] ?? '',
                      isDarkMode: _isDarkMode,
                      theme: theme,
                    ),
                  ],
                ),
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
      ),
    );
  }

  Widget _buildMainContent(double width, double height, _AppTheme theme) {
    // Helper to build the header inside the scrollable content
    Widget buildScrollableHeader() {
      final caretakerName = widget.userData['name'] ?? 'Caretaker';
      return HeaderSection(
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
          String? currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 
                                  widget.userData['userId'] ?? 
                                  widget.userData['uid'];
                                  
          if (currentUserId == null) return;

          showModalBottomSheet(
            context: context,
            isScrollControlled: true, 
            backgroundColor: Colors.transparent, 
            builder: (context) => SizedBox(
              height: height * 0.85, 
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
      );
    }

    return IndexedStack(
      index: _selectedIndex,
      children: [
        // Index 0: Home Content (Header added inside ScrollView)
        SingleChildScrollView(
          physics: const ClampingScrollPhysics(), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildScrollableHeader(),
              HomeContent(
                isDarkMode: _isDarkMode,
                theme: theme,
                userData: widget.userData,
                onNotificationUpdate: _updateNotification,
                requestService: _requestService,
                locationService: _locationService,
              ),
            ],
          ),
        ),
        // Index 1
        PatientsContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
          locationService: _locationService,
        ),
        // Index 2
        RequestsContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
          requestService: _requestService,
          onRequestCountChange: (count) {
            if (_pendingRequestsCount != count) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _pendingRequestsCount = count;
                  });
                }
              });
            }
          },
        ),
        // Index 3
        SingleChildScrollView(
          physics: const ClampingScrollPhysics(), 
          child: ProfileContent(
            userData: widget.userData,
            isDarkMode: _isDarkMode,
            theme: theme,
          ),
        ),
        // Index 4
        RealtimeTrackingScreen(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
          locationService: _locationService,
        ),
      ],
    );
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