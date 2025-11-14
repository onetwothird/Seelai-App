// File: lib/roles/caretaker/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/header_section.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/caretaker/home/sections/home_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/profile_content.dart';
import 'package:seelai_app/roles/caretaker/screens/realtime_tracking_screen.dart';
import 'package:seelai_app/roles/caretaker/services/notification_service.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/roles/caretaker/services/request_service.dart';

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
    _initializeServices();
    _initializeAnimations();
    _initializeScrollListener();
    _loadPendingRequests();
  }

  void _initializeServices() {
    _notificationService = NotificationService();
    _locationService = LocationService();
    _requestService = RequestService();
    
    // Listen for new requests
    _requestService.addListener(_onNewRequest);
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

  Future<void> _loadPendingRequests() async {
    final requests = await _requestService.getPendingRequests(widget.userData['uid'] ?? '');
    setState(() {
      _pendingRequestsCount = requests.length;
      if (_pendingRequestsCount > 0) {
      }
    });
  }

  void _onNewRequest(dynamic request) {
    setState(() {
      _pendingRequestsCount++;
    });
    
    _notificationService.showNotification(
      'New Request',
      'A patient needs your assistance',
    );
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
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _requestService.removeListener(_onNewRequest);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final caretakerName = widget.userData['name'] ?? 'Caretaker';

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
                caretakerName: caretakerName,
                profileImageUrl: widget.userData['profileImageUrl'] as String?, // ← FETCH PROFILE PICTURE
                isDarkMode: _isDarkMode,
                pendingRequestsCount: _pendingRequestsCount,
                onToggleDarkMode: _toggleDarkMode,
                onProfileTap: () {
                  // Navigate to profile tab when tapped
                  setState(() {
                    _selectedIndex = 3; // Profile is at index 3
                  });
                },
                onNotificationTap: () {
                  // Navigate to requests tab when tapped
                  setState(() {
                    _selectedIndex = 2; // Requests is at index 2
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
    );
  }

  Widget _buildMainContent(double width, double height, _AppTheme theme) {
    switch (_selectedIndex) {
      case 0:
        return SingleChildScrollView(
          controller: _scrollController,
          physics: ClampingScrollPhysics(),
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
        // PatientsContent has its own RefreshIndicator and scrolling
        return PatientsContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
          locationService: _locationService,
        );
      
      case 2:
        // RequestsContent has its own RefreshIndicator and scrolling
        return RequestsContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
          requestService: _requestService,
          onRequestCountChange: (count) {
            setState(() {
              _pendingRequestsCount = count;
            });
          },
        );
      
      case 3:
        return SingleChildScrollView(
          controller: _scrollController,
          physics: ClampingScrollPhysics(),
          child: ProfileContent(
            userData: widget.userData,
            isDarkMode: _isDarkMode,
            theme: theme,
          ),
        );
      
      case 4:
        // Real-time Tracking Screen
        return RealtimeTrackingScreen(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
          locationService: _locationService,
        );
      
      default:
        return SingleChildScrollView(
          controller: _scrollController,
          physics: ClampingScrollPhysics(),
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