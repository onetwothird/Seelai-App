// File: lib/roles/visually_impaired/home/home_screen.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use, duplicate_ignore, unnecessary_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/recent_activities/view_recent_activites.dart';
import 'dart:async';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/partially_sighted/home/widgets/header_section.dart';
import 'package:seelai_app/roles/partially_sighted/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/home_content.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/contacts_screen/contacts_content.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/profile_content/profile_content.dart';
import 'package:seelai_app/firebase/visually_impaired/camera_service.dart';
import 'package:seelai_app/roles/partially_sighted/services/permission_service.dart';
import 'package:seelai_app/roles/partially_sighted/services/accessibility_service.dart';
import 'package:seelai_app/firebase/caretaker/assistance_request_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/roles/partially_sighted/screens/scanner/mode_selection_screen.dart';

// NEW IMPORT FOR THE NOTIFICATIONS BOTTOM SHEET
import 'package:seelai_app/roles/partially_sighted/home/widgets/notifications_bottom_sheet.dart'; 

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
  
  // Scroll detection for bottom nav
  final ScrollController _scrollController = ScrollController();
  bool _isNavVisible = true;
  double _lastScrollPosition = 0;
  
  // Stream subscription
  StreamSubscription? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _initializeScrollListener();
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

  void _initializeScrollListener() {
    _scrollController.addListener(_handleScroll);
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
      // Clear the unread notification badge once the sheet is dismissed
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
    _scrollController.dispose();
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
            Icon(Icons.logout_rounded, color: const Color(0xFF8B5CF6)), 
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final userName = widget.userData['name'] ?? 'User';

    final theme = _isDarkMode 
      ? _getDarkTheme() 
      : _getLightTheme();

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
    );
  }

  Widget _buildMainContent(double width, double height, _AppTheme theme) {
    Widget content;
    final userId = widget.userData['uid'] as String? ?? '';
    
    switch (_selectedIndex) {
      case 0:
        content = HomeContent(
          cameraService: _cameraService,
          permissionService: _permissionService,
          isDarkMode: _isDarkMode,
          theme: theme,
          onNotificationUpdate: _updateNotification,
          userData: widget.userData,
        );
        break;
      case 1:
        return SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: ContactsContent(
            isDarkMode: _isDarkMode,
            theme: theme,
            userData: widget.userData,
          ),
        );
      case 3:
        content = ViewRecentActivities(
          isDarkMode: _isDarkMode,
          theme: theme,
          userId: userId, 
        );
        break;
      case 4:
        content = ProfileContent(
          userData: widget.userData,
          isDarkMode: _isDarkMode,
          theme: theme,
        );
        break;
      default:
        content = HomeContent(
          cameraService: _cameraService,
          permissionService: _permissionService,
          isDarkMode: _isDarkMode,
          theme: theme,
          onNotificationUpdate: _updateNotification,
          userData: widget.userData,
        );
    }
    
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      child: content,
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