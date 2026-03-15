// File: lib/roles/mswd/home/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/urgent_alerts_section.dart';
import 'package:seelai_app/roles/mswd/home/sections/location_track/location_tracking_screen.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/mswd/home/widgets/header_section.dart';
import 'package:seelai_app/roles/mswd/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/announcement.dart';
import 'package:seelai_app/roles/mswd/home/sections/users/users_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/requests/requests_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/profile_content/more_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/dashboard_stats.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/quick_actions.dart';
import 'package:seelai_app/roles/mswd/home/widgets/mswd_notifications_bottom_sheet.dart'; 
import 'package:seelai_app/firebase/firebase_services.dart';

class MSWDHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MSWDHomeScreen({
    super.key,
    required this.userData,
  });

  @override
  State<MSWDHomeScreen> createState() => _MSWDHomeScreenState();
}

class _MSWDHomeScreenState extends State<MSWDHomeScreen> {
  // UI State
  bool _isDarkMode = false;
  int _selectedIndex = 0;
  
  // Data State for Notifications
  int _pendingRequestsCount = 0;
  StreamSubscription<DatabaseEvent>? _requestsSubscription;
  
  // Scroll detection for bottom nav
  final ScrollController _scrollController = ScrollController();
  bool _isNavVisible = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _initializeScrollListener();
    _startPendingRequestsListener();
  }

  void _startPendingRequestsListener() {
    _requestsSubscription = databaseService.database
        .ref('assistance_requests')
        .orderByChild('status')
        .equalTo('pending')
        .onValue
        .listen((event) {
      if (mounted) {
        int count = 0;
        if (event.snapshot.exists) {
          final map = event.snapshot.value as Map<dynamic, dynamic>;
          count = map.length;
        }
        setState(() {
          _pendingRequestsCount = count;
        });
      }
    }, onError: (error) {
      debugPrint('Error listening to pending requests: $error');
    });
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
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final adminName = widget.userData['name'] ?? 'Admin';

    final theme = _isDarkMode ? _getDarkTheme() : _getLightTheme();

    return PopScope(
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
        body: Container(
          decoration: BoxDecoration(gradient: theme.backgroundGradient),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (_selectedIndex != 4)
                  HeaderSection(
                    adminName: adminName,
                    profileImageUrl: widget.userData['profileImageUrl'] as String?,
                    isDarkMode: _isDarkMode,
                    pendingRequestsCount: _pendingRequestsCount, 
                    onToggleDarkMode: _toggleDarkMode,
                    onProfileTap: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                    },
                    onNotificationTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => SizedBox(
                          height: MediaQuery.of(context).size.height * 0.85,
                          child: MSWDNotificationsBottomSheet(
                            adminId: widget.userData['userId'] ?? '',
                            isDarkMode: _isDarkMode,
                            assistanceRequestService: assistanceRequestService,
                          ),
                        ),
                      );
                    },
                    textColor: theme.textColor,
                    subtextColor: theme.subtextColor,
                  ),
                
                // Using AnimatedSwitcher instead of manual AnimationControllers!
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    child: SizedBox(
                      key: ValueKey<int>(_selectedIndex),
                      child: _buildMainContent(screenWidth, screenHeight, theme),
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
    
    if (_selectedIndex == 3) {
      return content;
    }
    
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      child: content,
    );
  }

 Widget _buildDashboardContent(double width, _AppTheme theme) {
    return Padding(
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: 16, // Reduced top padding
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardStats(
            isDarkMode: _isDarkMode,
            theme: theme,
          ),
          
          const SizedBox(height: 20), // TIGHTENED GAP

          QuickActions(
            isDarkMode: _isDarkMode,
            theme: theme,
            onNavigateToTab: _onNavItemTapped, 
          ),

          const SizedBox(height: 40), // TIGHTENED GAP

          UrgentAlertsSection(
            isDarkMode: _isDarkMode,
            theme: theme,
            onNavigateToTab: _onNavItemTapped,
          ),

          const SizedBox(height: 15), // TIGHTENED GAP

          AnnouncementSection(
            isDarkMode: _isDarkMode,
            theme: theme,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
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
      backgroundColor: const Color(0xFF0F1429),
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