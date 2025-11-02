// File: lib/roles/caretaker/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/header_section.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/caretaker/home/sections/home_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/profile_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/settings_content.dart';
import 'package:seelai_app/roles/caretaker/services/notification_service.dart';
import 'package:seelai_app/service/database_service.dart';

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
  
  // UI State
  bool _isDarkMode = false;
  int _selectedIndex = 0;
  int _pendingNotifications = 0;
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Notification
  String _notificationMessage = 'Welcome back, Caretaker!';
  
  // Assigned Patients
  List<Map<String, dynamic>> _assignedPatients = [];
  bool _isLoadingPatients = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadAssignedPatients();
    _listenToNotifications();
  }

  void _initializeServices() {
    _notificationService = NotificationService();
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

  Future<void> _loadAssignedPatients() async {
    try {
      final userId = widget.userData['userId'] ?? '';
      if (userId.isEmpty) return;
      
      final patients = await databaseService.getCaretakerPatients(userId);
      
      if (mounted) {
        setState(() {
          _assignedPatients = patients;
          _isLoadingPatients = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPatients = false;
        });
      }
    }
  }

  void _listenToNotifications() {
    _notificationService.notificationStream.listen((notification) {
      if (mounted) {
        setState(() {
          _pendingNotifications++;
          _notificationMessage = notification;
        });
      }
    });
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _onNavItemTapped(int index) {
    _animationController.reset();
    setState(() {
      _selectedIndex = index;
    });
    _animationController.forward();
  }

  void _updateNotification(String message) {
    setState(() {
      _notificationMessage = message;
    });
  }

  void _clearNotificationBadge() {
    setState(() {
      _pendingNotifications = 0;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final userName = widget.userData['name'] ?? 'Caretaker';

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
                pendingNotifications: _pendingNotifications,
                onToggleDarkMode: _toggleDarkMode,
                onNotificationTap: _clearNotificationBadge,
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
        notificationBadge: _pendingNotifications,
      ),
    );
  }

  Widget _buildMainContent(double width, double height, _AppTheme theme) {
    switch (_selectedIndex) {
      case 0:
        return HomeContent(
          userData: widget.userData,
          assignedPatients: _assignedPatients,
          isLoadingPatients: _isLoadingPatients,
          isDarkMode: _isDarkMode,
          theme: theme,
          onNotificationUpdate: _updateNotification,
          onRefresh: _loadAssignedPatients,
        );
      case 1:
        return ProfileContent(
          userData: widget.userData,
          isDarkMode: _isDarkMode,
          theme: theme,
        );
      case 2:
        return SettingsContent(
          userData: widget.userData,
          isDarkMode: _isDarkMode,
          theme: theme,
          onToggleDarkMode: _toggleDarkMode,
        );
      default:
        return HomeContent(
          userData: widget.userData,
          assignedPatients: _assignedPatients,
          isLoadingPatients: _isLoadingPatients,
          isDarkMode: _isDarkMode,
          theme: theme,
          onNotificationUpdate: _updateNotification,
          onRefresh: _loadAssignedPatients,
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