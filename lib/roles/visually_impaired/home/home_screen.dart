// File: lib/roles/visually_impaired/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/home/widgets/header_section.dart';
import 'package:seelai_app/roles/visually_impaired/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/visually_impaired/home/sections/home_content.dart';
import 'package:seelai_app/roles/visually_impaired/home/sections/profile_content.dart';
import 'package:seelai_app/roles/visually_impaired/home/sections/recent_activities_content.dart';
import 'package:seelai_app/roles/visually_impaired/services/camera_service.dart';
import 'package:seelai_app/roles/visually_impaired/services/permission_service.dart';
import 'package:seelai_app/roles/visually_impaired/services/accessibility_service.dart';

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
  
  // UI State
  bool _isDarkMode = false;
  int _selectedIndex = 0;
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Notification
  String _notificationMessage = 'Welcome to SeelAI';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _requestPermissions();
  }

  void _initializeServices() {
    _cameraService = CameraService();
    _permissionService = PermissionService();
    _accessibilityService = AccessibilityService();
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

  Future<void> _requestPermissions() async {
    final result = await _permissionService.requestAllPermissions();
    
    if (mounted) {
      setState(() {
        _notificationMessage = result.message;
      });

      if (result.hasAllPermissions) {
        await _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    final success = await _cameraService.initialize();
    
    if (mounted) {
      setState(() {
        if (!success) {
          _notificationMessage = 'Unable to initialize camera';
        }
      });
    }
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
    // TODO: Implement voice command functionality
  }

  void _onNavItemTapped(int index) {
    _animationController.reset();
    setState(() {
      _selectedIndex = index;
    });
    _animationController.forward();
    
    final labels = ['Home', 'Profile', 'Recent Activities'];
    _accessibilityService.announce('Navigated to ${labels[index]}');
  }

  void _updateNotification(String message) {
    setState(() {
      _notificationMessage = message;
    });
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final userName = widget.userData['name'] ?? 'User';

    final theme = _isDarkMode 
      ? _getDarkTheme() 
      : _getLightTheme();

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: theme.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HeaderSection(
                userName: userName,
                isDarkMode: _isDarkMode,
                notificationMessage: _notificationMessage,
                onVoiceAssistant: _activateVoiceAssistant,
                onToggleDarkMode: _toggleDarkMode,
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
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        isDarkMode: _isDarkMode,
        onItemTapped: _onNavItemTapped,
        textColor: theme.textColor,
        subtextColor: theme.subtextColor,
      ),
    );
  }

  Widget _buildMainContent(double width, double height, _AppTheme theme) {
    switch (_selectedIndex) {
      case 0:
        return HomeContent(
          cameraService: _cameraService,
          permissionService: _permissionService,
          isDarkMode: _isDarkMode,
          theme: theme,
          onNotificationUpdate: _updateNotification,
        );
      case 1:
        return ProfileContent(
          userData: widget.userData,
          isDarkMode: _isDarkMode,
          theme: theme,
        );
      case 2:
        return RecentActivitiesContent(
          isDarkMode: _isDarkMode,
          theme: theme,
        );
      default:
        return HomeContent(
          cameraService: _cameraService,
          permissionService: _permissionService,
          isDarkMode: _isDarkMode,
          theme: theme,
          onNotificationUpdate: _updateNotification,
        );
    }
  }

  _AppTheme _getDarkTheme() {
    return _AppTheme(
      backgroundGradient: LinearGradient(
        colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF2A2F4A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.5, 1.0],
      ),
      textColor: white,
      subtextColor: Color(0xFFB0B8D4),
      cardColor: Color(0xFF1A1F3A),
    );
  }

  _AppTheme _getLightTheme() {
    return _AppTheme(
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [backgroundPrimary, backgroundSecondary, lightBlue.withOpacity(0.3)],
        stops: [0.0, 0.5, 1.0],
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