// File: lib/roles/mswd/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/mswd/home/widgets/header_section.dart';
import 'package:seelai_app/roles/mswd/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/users_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/tracking_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/analytics_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/profile_content.dart';

class MSWDHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MSWDHomeScreen({
    super.key,
    required this.userData,
  });

  @override
  State<MSWDHomeScreen> createState() => _MSWDHomeScreenState();
}

class _MSWDHomeScreenState extends State<MSWDHomeScreen> 
    with SingleTickerProviderStateMixin {
  
  // UI State
  bool _isDarkMode = false;
  int _selectedIndex = 0;
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Scroll detection for bottom nav
  final ScrollController _scrollController = ScrollController();
  bool _isNavVisible = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeScrollListener();
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
    _animationController.reset();
    setState(() {
      _selectedIndex = index;
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final adminName = widget.userData['name'] ?? 'Admin';

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
                adminName: adminName,
                profileImageUrl: widget.userData['profileImageUrl'] as String?,
                isDarkMode: _isDarkMode,
                onToggleDarkMode: _toggleDarkMode,
                onProfileTap: () {
                  setState(() {
                    _selectedIndex = 4; // Profile is at index 4
                  });
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
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        offset: _isNavVisible ? Offset.zero : Offset(0, 1),
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 300),
          opacity: _isNavVisible ? 1.0 : 0.0,
          child: MSWDBottomNavigation(
            selectedIndex: _selectedIndex,
            isDarkMode: _isDarkMode,
            onItemTapped: _onNavItemTapped,
            textColor: theme.textColor,
            subtextColor: theme.subtextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(double width, double height, _AppTheme theme) {
    switch (_selectedIndex) {
      case 0:
        return DashboardContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
          scrollController: _scrollController,
        );
      
      case 1:
        return UsersContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
        );
      
      case 2:
        return TrackingContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
        );
      
      case 3:
        return AnalyticsContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
        );
      
      case 4:
        return ProfileContent(
          userData: widget.userData,
          isDarkMode: _isDarkMode,
          theme: theme,
        );
      
      default:
        return DashboardContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
          scrollController: _scrollController,
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
        // ignore: deprecated_member_use
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