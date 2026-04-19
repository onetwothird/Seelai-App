// File: lib/roles/mswd/home/mswd_home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; 
import 'package:firebase_database/firebase_database.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/urgent_alerts_section.dart';
import 'package:seelai_app/roles/mswd/home/sections/location_track/location_tracking_screen.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/mswd/home/widgets/mswd_header_section.dart';
import 'package:seelai_app/roles/mswd/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/announcement.dart';
import 'package:seelai_app/roles/mswd/home/sections/users/users_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/requests/requests_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/profile_content/more_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/dashboard_stats.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/quick_actions.dart';
import 'package:seelai_app/roles/mswd/home/widgets/mswd_notifications_bottom_sheet.dart'; 
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/screens/onboarding_screen.dart';
import 'package:seelai_app/roles/mswd/home/sections/registration/subject_registration_screen.dart';

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
  
  // Data State for Notifications & Dashboard
  int _pendingRequestsCount = 0;
  StreamSubscription<DatabaseEvent>? _requestsSubscription;
  late Future<Map<String, int>> _dashboardStatsFuture; 
  
  // Scroll Navigation State
  bool _isNavVisible = true;

  @override
  void initState() {
    super.initState();
    _startPendingRequestsListener();
    _dashboardStatsFuture = adminService.getUserStatistics(); 
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
    
    final theme = _isDarkMode ? _getDarkTheme() : _getLightTheme();

    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return; 
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            (Route<dynamic> route) => false, 
          );
        }
      },
      child: Scaffold(
        extendBody: true,
        
        // --- ONLY SHOW "ADD FACE/OBJECT" HERE ---
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _isNavVisible 
            ? (_selectedIndex != 2 ? _buildAddFaceObjectFab(context) : null)
            : null, 
        
        body: Container(
          decoration: BoxDecoration(gradient: theme.backgroundGradient),
          child: SafeArea(
            bottom: false,
            // --- WE WRAPPED THIS IN A STACK SO WE CAN PIN THE BUTTON TO THE BOTTOM ---
            child: Stack(
              children: [
                Positioned.fill(
                  child: NotificationListener<UserScrollNotification>(
                    onNotification: (notification) {
                      if (notification.direction == ScrollDirection.forward) {
                        if (!_isNavVisible) setState(() => _isNavVisible = true);
                      } else if (notification.direction == ScrollDirection.reverse) {
                        if (_isNavVisible) setState(() => _isNavVisible = false);
                      }
                      return false; 
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter, 
                          children: <Widget>[
                            ...previousChildren,
                            ?currentChild,
                          ],
                        );
                      },
                      child: SizedBox(
                        key: ValueKey<int>(_selectedIndex),
                        child: _buildMainContent(screenWidth, screenHeight, theme),
                      ),
                    ),
                  ),
                ),
                
                // ==========================================
                // FLOATING "SHOW MENU" BUTTON
                // ==========================================
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  // Hide it off-screen when nav is visible, slide it up when hidden
                  bottom: _isNavVisible ? -100 : MediaQuery.of(context).padding.bottom + 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildShowMenuFab(),
                  ),
                ),
                // ==========================================
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
    Widget buildScrollableHeader() {
      final adminName = widget.userData['name'] ?? 'Admin';
      return HeaderSection(
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
      );
    }

    Widget content;
    
    switch (_selectedIndex) {
      case 0:
        content = Column(
          children: [
            buildScrollableHeader(),
            _buildDashboardContent(width, theme),
          ],
        );
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
          onScroll: (isScrollingDown) {
            if (isScrollingDown) {
              if (_isNavVisible) setState(() => _isNavVisible = false);
            } else {
              if (!_isNavVisible) setState(() => _isNavVisible = true);
            }
          },
          onRestoreMenu: () {
            if (!_isNavVisible) {
              setState(() => _isNavVisible = true);
            }
          },
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
        content = Column(
          children: [
            buildScrollableHeader(),
            _buildDashboardContent(width, theme),
          ],
        );
    }
    
    // Tab 1 (Users), Tab 2 (Requests), and Tab 3 (Location) 
    // already have their own built-in scrolling mechanics.
    if (_selectedIndex == 1 || _selectedIndex == 2 || _selectedIndex == 3) {
      return content;
    }
    
    // Only wrap Tab 0 (Dashboard) and Tab 4 (More/Profile) 
    // in the global scroll view.
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), 
      child: content,
    );
  }

 Widget _buildDashboardContent(double width, _AppTheme theme) {
    return Padding(
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: 16, 
        bottom: 120, 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardStats(
            isDarkMode: _isDarkMode,
            theme: theme,
            statsFuture: _dashboardStatsFuture, 
          ),
          
          const SizedBox(height: 20),

          QuickActions(
            isDarkMode: _isDarkMode,
            theme: theme,
            onNavigateToTab: _onNavItemTapped, 
          ),

          const SizedBox(height: 40),

          UrgentAlertsSection(
            isDarkMode: _isDarkMode,
            theme: theme,
            onNavigateToTab: _onNavItemTapped,
          ),

          const SizedBox(height: 15),

          AnnouncementSection(
            isDarkMode: _isDarkMode,
            theme: theme,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // =========================================================================
  // FLOATING ACTION BUTTON BUILDERS
  // =========================================================================

  Widget _buildAddFaceObjectFab(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _showAddOptionsBottomSheet(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.center_focus_strong_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
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
    );
  }

  Widget _buildShowMenuFab() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isDarkMode ? Colors.white24 : Colors.grey.shade200,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() => _isNavVisible = true);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Color(0xFF8B5CF6), // Primary Purple
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Show Menu',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
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

  void _showAddOptionsBottomSheet(BuildContext context) {
    final Color primaryColor = const Color(0xFF8B5CF6);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Add New Registry',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select the type of subject you want to scan for the partially sighted user.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _isDarkMode ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),
                
                _buildAddOptionCard(
                  icon: Icons.face_retouching_natural_rounded,
                  title: 'Caretaker Face',
                  subtitle: 'Scan and register a new trusted person',
                  primaryColor: primaryColor, 
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
                
                _buildAddOptionCard(
                  icon: Icons.view_in_ar_rounded, 
                  title: 'New Object',
                  subtitle: 'Scan an everyday item for detection',
                  primaryColor: const Color(0xFF3B82F6), 
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF0F1429) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isDarkMode ? Colors.white10 : Colors.grey.shade200,
          ),
          boxShadow: _isDarkMode ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor, size: 28),
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
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _isDarkMode ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: _isDarkMode ? Colors.white38 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
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