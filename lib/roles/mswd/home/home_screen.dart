// File: lib/roles/mswd/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/roles/mswd/home/sections/location_track/location_tracking_screen.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/mswd/home/widgets/header_section.dart';
import 'package:seelai_app/roles/mswd/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/announcement.dart';
import 'package:seelai_app/roles/mswd/home/sections/users/users_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/requests/requests_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/more_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/dashboard_stats.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/quick_actions.dart';

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
            Icon(Icons.logout_rounded, color: const Color(0xFF8B5CF6)), 
            SizedBox(width: 10),
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
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              // Optional: Add logic here if you want to explicitly sign out before closing
              // await authService.signOut(); 
            },
            // Use PURPLE Theme color
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final adminName = widget.userData['name'] ?? 'Admin';

    final theme = _isDarkMode 
      ? _getDarkTheme() 
      : _getLightTheme();

    return PopScope(
      canPop: false, // Prevents the default back button so your custom logic runs
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return; // Screen was already popped
        }

        // Run your existing _onWillPop logic
        final bool shouldPop = await _onWillPop();
        
        // If the logic returns true, safely pop the screen
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
            child: Column(
              children: [
                HeaderSection(
                  adminName: adminName,
                  profileImageUrl: widget.userData['profileImageUrl'] as String?,
                  isDarkMode: _isDarkMode,
                  onToggleDarkMode: _toggleDarkMode,
                  onProfileTap: () {
                    setState(() {
                      _selectedIndex = 4;
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          offset: _isNavVisible ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
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
      ),
    );
  }

  Widget _buildMainContent(double width, double height, _AppTheme theme) {
    Widget content;
    
    switch (_selectedIndex) {
      case 0:
        content = _buildDashboardContent(width, theme);
        break;
      
      case 1:
        content = UsersContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
          onNavigateToLocation: () => _onNavItemTapped(3),
        );
        break;
        
      case 3:
        // LOCATION SCREEN
        content = MswdLocationTrackingScreen(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
        );
        break;

      case 2:
        content = RequestsContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
        );
        break;
      
      case 4:
        content = MoreContent(
          userData: widget.userData,
          isDarkMode: _isDarkMode,
          theme: theme,
          onToggleDarkMode: _toggleDarkMode,
        );
        break;
      
      default:
        content = _buildDashboardContent(width, theme);
    }
    
    // Ensure map (index 3) isn't wrapped in scroll view
    if (_selectedIndex == 3) {
      return content;
    }
    
    return SingleChildScrollView(
      controller: _scrollController,
      physics: ClampingScrollPhysics(),
      child: content,
    );
  }

  /// Build dashboard content with separated sections
  Widget _buildDashboardContent(double width, _AppTheme theme) {
    return Padding(
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingLarge, // Slightly more top padding for breathing room
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. New System Stats Overview
          DashboardStats(
            isDarkMode: _isDarkMode,
            theme: theme,
          ),
          
          SizedBox(height: spacingLarge * 1.5),

          // 2. New Quick Actions Row
          QuickActions(
            isDarkMode: _isDarkMode,
            theme: theme,
          ),

          SizedBox(height: spacingLarge * 1.5),

          // 3. The existing Announcements Section 
          // (It now sits perfectly below the high-level admin tools)
          AnnouncementSection(
            isDarkMode: _isDarkMode,
            theme: theme,
          ),
          
          SizedBox(height: spacingXLarge),
        ],
      ),
    );
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
      backgroundColor: Color(0xFF0F1429),
    );
  }

  _AppTheme _getLightTheme() {
    return _AppTheme(
      // White Background as requested previously
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Colors.white],
      ),
      textColor: black,
      subtextColor: grey,
      cardColor: white,
      backgroundColor: backgroundPrimary,
    );
  }
}

class _AppTheme {
  final LinearGradient backgroundGradient;
  final Color textColor;
  final Color subtextColor;
  final Color cardColor;
  final Color backgroundColor;

  _AppTheme({
    required this.backgroundGradient,
    required this.textColor,
    required this.subtextColor,
    required this.cardColor,
    required this.backgroundColor,
  });
}