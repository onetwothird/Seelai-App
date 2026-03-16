// File: lib/roles/partially_sighted/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/recent_activities/view_recent_activites.dart';
import 'dart:async';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/partially_sighted/home/widgets/header_section.dart';
import 'package:seelai_app/roles/partially_sighted/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/home_content.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/contacts_screen/contacts_content.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/profile_content/profile_content.dart';
import 'package:seelai_app/firebase/partially_sighted/camera_service.dart';
import 'package:seelai_app/roles/partially_sighted/services/permission_service.dart';
import 'package:seelai_app/roles/partially_sighted/services/accessibility_service.dart';
import 'package:seelai_app/firebase/caretaker/assistance_request_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/roles/partially_sighted/screens/scanner/mode_selection_screen.dart';

// NEW IMPORT FOR REGISTRATION SCREEN
import 'package:seelai_app/roles/partially_sighted/home/sections/registration/subject_registration_screen.dart';

// IMPORT FOR THE NOTIFICATIONS BOTTOM SHEET
import 'package:seelai_app/roles/partially_sighted/home/widgets/notifications_bottom_sheet.dart'; 

// IMPORT FOR THE GLOBAL CALL LISTENER
import 'package:seelai_app/shared/widgets/incoming_call_listener.dart';

class VisuallyImpairedHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const VisuallyImpairedHomeScreen({
    super.key,
    required this.userData,
  });

  @override
  State<VisuallyImpairedHomeScreen> createState() => _VisuallyImpairedHomeScreenState();
}

class _VisuallyImpairedHomeScreenState extends State<VisuallyImpairedHomeScreen> 
    with SingleTickerProviderStateMixin {
  // Services
  late final CameraService _cameraService;
  late final PermissionService _permissionService;
  late final AccessibilityService _accessibilityService;
  late final AssistanceRequestService _assistanceRequestService;
  
  // UI State
  bool _isDarkMode = false;
  int _selectedIndex = 0;
  int _unreadNotificationCount = 0;
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<ScrollController> _scrollControllers = [];
  List<double> _lastScrollPositions = [];
  bool _isNavVisible = true;
  
  // Stream subscription
  StreamSubscription? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    
    // Initialize a scroll controller and position tracker for each tab
    _lastScrollPositions = List.filled(5, 0.0);
    _scrollControllers = List.generate(5, (index) {
      final controller = ScrollController();
      controller.addListener(() => _handleScroll(controller, index));
      return controller;
    });

    _requestPermissionsAndInitialize();
    _setupRequestListener();
  }

  void _initializeServices() {
    _cameraService = CameraService();
    _permissionService = PermissionService();
    _accessibilityService = AccessibilityService();
    _assistanceRequestService = assistanceRequestService;
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

  void _setupRequestListener() {
    final userId = widget.userData['uid'] as String?;
    if (userId == null || userId.isEmpty) return;

    _requestsSubscription = _assistanceRequestService
        .streamPatientRequests(userId)
        .listen((requests) {
      if (mounted) {
        final acceptedRequests = requests.where((req) => 
          req.status == RequestStatus.accepted && 
          req.responseTime != null &&
          DateTime.now().difference(req.responseTime!).inMinutes < 5
        ).toList();
        
        setState(() {
          _unreadNotificationCount = acceptedRequests.length;
          
          if (acceptedRequests.isNotEmpty) {
            _accessibilityService.announce('Caretaker accepted your assistance request');
          }
        });
      }
    });
  }

  void _handleScroll(ScrollController controller, int index) {
    if (!controller.hasClients || _lastScrollPositions.isEmpty) return;
    
    if (index != _selectedIndex) return;

    final currentScroll = controller.position.pixels;
    final scrollDelta = currentScroll - _lastScrollPositions[index];
    
    const scrollThreshold = 10.0;
    
    if (scrollDelta.abs() > scrollThreshold) {
      final shouldShow = scrollDelta < 0;
      
      if (shouldShow != _isNavVisible) {
        setState(() {
          _isNavVisible = shouldShow;
        });
      }
      
      _lastScrollPositions[index] = currentScroll;
    }
    
    if (currentScroll <= 0 && !_isNavVisible) {
      setState(() {
        _isNavVisible = true;
      });
    }
  }

  Future<void> _requestPermissionsAndInitialize() async {
    final result = await _permissionService.requestAllPermissions();
    
    if (mounted) {
      if (result.hasAllPermissions) {
        await _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initialize();
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    
    _accessibilityService.announce(
      _isDarkMode ? 'Dark mode enabled' : 'Light mode enabled'
    );
  }

  void _activateVoiceAssistant() {
    _accessibilityService.announce('Voice assistant activated. Listening...');
  }

  void _openNotifications() {
    _accessibilityService.announce('Opening notifications');
    
    final userId = widget.userData['uid'] as String?;
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85, 
        child: ViNotificationsBottomSheet(
          userId: userId,
          isDarkMode: _isDarkMode,
          requestService: _assistanceRequestService, 
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    });
  }

  void _onNavItemTapped(int index) {
    if (index == 2) {
      _openCameraScanner();
      return;
    }
    
    _animationController.reset();
    setState(() {
      _selectedIndex = index;
    });
    _animationController.forward();
    
    final labels = ['Home', 'Contacts', 'Scanner', 'Recent Activities', 'Profile'];
    _accessibilityService.announce('Navigated to ${labels[index]}');
  }

  void _openCameraScanner() async {
    _accessibilityService.announce('Opening camera scanner');
    if (!_cameraService.isInitialized) {
      await _cameraService.initialize();
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModeSelectionScreen(
            cameraService: _cameraService,
            isDarkMode: _isDarkMode,
          ),
        ),
      );
    }
  }

  void _updateNotification(String message) {
    setState(() {});
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _animationController.dispose();
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    _requestsSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
        _animationController.reset();
        _animationController.forward();
      });
      return false;
    }

    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_scrollControllers.isEmpty) {
      _lastScrollPositions = List.filled(5, 0.0);
      _scrollControllers = List.generate(5, (index) {
        final controller = ScrollController();
        controller.addListener(() => _handleScroll(controller, index));
        return controller;
      });
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final userName = widget.userData['name'] ?? 'User';

    final theme = _isDarkMode 
      ? _getDarkTheme() 
      : _getLightTheme();

    return IncomingCallListener(
      userRole: 'partially_sighted',
      child: PopScope(
        canPop: false, 
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return; 

          final bool shouldPop = await _onWillPop();
          
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop(result); 
          }
        },
        child: Scaffold(
          extendBody: true,
          
          // --- FLOATING ACTION BUTTON ---
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _isNavVisible && _selectedIndex != 2 // Hides when opening scanner (index 2)
              ? Container(
                  height: 56,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () => _showAddOptionsBottomSheet(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.center_focus_strong_rounded,
                              color: Colors.white, 
                              size: 22
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Add Face/Object',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ) 
              : null,

          body: Container(
            decoration: BoxDecoration(gradient: theme.backgroundGradient),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  if (_selectedIndex != 4)
                    HeaderSection(
                      userName: userName,
                      profileImageUrl: widget.userData['profileImageUrl'] as String?,
                      isDarkMode: _isDarkMode,
                      onVoiceAssistant: _activateVoiceAssistant,
                      onToggleDarkMode: _toggleDarkMode,
                      onNotificationTap: _openNotifications,
                      onProfileTap: () {
                        setState(() {
                          _selectedIndex = 4;
                        });
                      },
                      textColor: theme.textColor,
                      subtextColor: theme.subtextColor,
                      unreadNotificationCount: _unreadNotificationCount,
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(double width, double height, _AppTheme theme) {
    final userId = widget.userData['uid'] as String? ?? '';
    
    return IndexedStack(
      index: _selectedIndex,
      children: [
        SingleChildScrollView(
          controller: _scrollControllers[0],
          physics: const ClampingScrollPhysics(),
          child: HomeContent(
            cameraService: _cameraService,
            permissionService: _permissionService,
            isDarkMode: _isDarkMode,
            theme: theme,
            onNotificationUpdate: _updateNotification,
            userData: widget.userData,
          ),
        ),
        SingleChildScrollView(
          controller: _scrollControllers[1],
          physics: const ClampingScrollPhysics(),
          child: ContactsContent(
            isDarkMode: _isDarkMode,
            theme: theme,
            userData: widget.userData,
          ),
        ),
        const SizedBox.shrink(),
        SingleChildScrollView(
          controller: _scrollControllers[3],
          physics: const ClampingScrollPhysics(),
          child: ViewRecentActivities(
            isDarkMode: _isDarkMode,
            theme: theme,
            userId: userId, 
          ),
        ),
        SingleChildScrollView(
          controller: _scrollControllers[4],
          physics: const ClampingScrollPhysics(),
          child: ProfileContent(
            userData: widget.userData,
            isDarkMode: _isDarkMode,
            theme: theme,
          ),
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
      backgroundColor: const Color(0xFF0A0E27),
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
      backgroundColor: backgroundPrimary,
      textColor: black,
      subtextColor: grey,
      cardColor: white,
    );
  }

  // =========================================================================
  // ADD OPTIONS BOTTOM SHEET METHODS
  // =========================================================================

  void _showAddOptionsBottomSheet(BuildContext context) {
    final Color primaryColor = const Color(0xFF8B5CF6);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'What would you like to add?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Register a new subject for detection',
                style: TextStyle(
                  fontSize: 14,
                  color: _isDarkMode ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              
              // Option 1: Caretaker Face
              _buildAddOptionCard(
                icon: Icons.face_retouching_natural_rounded,
                title: 'Caretaker Face',
                subtitle: 'Scan and register a new trusted person',
                gradientColors: [
                  primaryColor, 
                  primaryColor.withValues(alpha: 0.8)
                ], 
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectRegistrationScreen(
                        isDarkMode: _isDarkMode,
                        subjectType: SubjectType.face,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Option 2: Object
              _buildAddOptionCard(
                icon: Icons.view_in_ar_rounded, 
                title: 'New Object',
                subtitle: 'Scan an everyday item for detection',
                gradientColors: [
                  primaryColor.withValues(alpha: 0.8), 
                  primaryColor.withValues(alpha: 0.6)
                ], 
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectRegistrationScreen(
                        isDarkMode: _isDarkMode,
                        subjectType: SubjectType.object,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF0F1429) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _isDarkMode ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTheme {
  final LinearGradient backgroundGradient;
  final Color backgroundColor;
  final Color textColor;
  final Color subtextColor;
  final Color cardColor;

  _AppTheme({
    required this.backgroundGradient,
    required this.backgroundColor,
    required this.textColor,
    required this.subtextColor,
    required this.cardColor,
  });
}