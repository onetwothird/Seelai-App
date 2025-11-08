// File: lib/roles/visually_impaired/home/home_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/home/widgets/header_section.dart';
import 'package:seelai_app/roles/visually_impaired/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/visually_impaired/home/sections/home_content.dart';
import 'package:seelai_app/roles/visually_impaired/home/sections/contacts_content.dart';
import 'package:seelai_app/roles/visually_impaired/home/sections/profile_content.dart';
import 'package:seelai_app/roles/visually_impaired/home/sections/recent_activities_content.dart';
import 'package:seelai_app/roles/visually_impaired/services/camera_service.dart';
import 'package:seelai_app/roles/visually_impaired/services/permission_service.dart';
import 'package:seelai_app/roles/visually_impaired/services/accessibility_service.dart';
import 'package:seelai_app/roles/visually_impaired/services/caretaker_request_service.dart';

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
  late final CaretakerRequestService _caretakerRequestService;
  
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
  
  // Notification
  String _notificationMessage = 'Welcome to SeelAI';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _initializeScrollListener();
    _requestPermissionsAndInitialize();
  }

  void _initializeServices() {
    _cameraService = CameraService();
    _permissionService = PermissionService();
    _accessibilityService = AccessibilityService();
    _caretakerRequestService = CaretakerRequestService();
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
    
    // Threshold to prevent jittery behavior
    const scrollThreshold = 10.0;
    
    if (scrollDelta.abs() > scrollThreshold) {
      final shouldShow = scrollDelta < 0; // Scrolling up
      
      if (shouldShow != _isNavVisible) {
        setState(() {
          _isNavVisible = shouldShow;
        });
      }
      
      _lastScrollPosition = currentScroll;
    }
    
    // Always show nav when at the top
    if (currentScroll <= 0 && !_isNavVisible) {
      setState(() {
        _isNavVisible = true;
      });
    }
  }

  Future<void> _requestPermissionsAndInitialize() async {
    // Request permissions first
    final result = await _permissionService.requestAllPermissions();
    
    if (mounted) {
      setState(() {
        _notificationMessage = result.message;
      });

      // If permissions granted, automatically initialize camera
      if (result.hasAllPermissions) {
        await _initializeCamera();
      } else {
        // Show message about camera not being available
        setState(() {
          _notificationMessage = 'Camera access required for full functionality';
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _notificationMessage = 'Initializing camera...';
    });

    final success = await _cameraService.initialize();
    
    if (mounted) {
      setState(() {
        if (success) {
          _notificationMessage = 'Camera ready';
        } else {
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
  }

  void _onNavItemTapped(int index) {
    // Handle scanner button tap (index 2 - center button)
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

  void _openCameraScanner() {
    _accessibilityService.announce('Opening camera scanner');
    setState(() {
      _notificationMessage = 'Camera scanner opening...';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Camera scanner feature coming soon'),
        backgroundColor: primary,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _updateNotification(String message) {
    setState(() {
      _notificationMessage = message;
    });
  }

  Future<void> _requestCaretaker() async {
    final userName = widget.userData['name'] ?? 'User';
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(spacingXLarge),
          margin: EdgeInsets.symmetric(horizontal: spacingXLarge),
          decoration: BoxDecoration(
            color: _isDarkMode ? Color(0xFF1A1F3A) : white,
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: spacingLarge),
              Text(
                'Checking caretaker availability...',
                style: bodyBold.copyWith(
                  color: _isDarkMode ? white : black,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Check availability
    final isAvailable = await _caretakerRequestService.checkCaretakerAvailability('caretaker_1');
    
    // Close loading dialog
    if (mounted) Navigator.pop(context);
    
    if (isAvailable) {
      // Show request dialog
      _showCaretakerRequestDialog(userName);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No caretaker is currently available'),
            backgroundColor: error,
          ),
        );
      }
    }
  }

  void _showCaretakerRequestDialog(String userName) {
    final requestTypes = [
      'General Assistance',
      'Navigation Help',
      'Reading Assistance',
      'Emergency',
      'Other',
    ];
    
    String selectedType = requestTypes[0];
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Request Caretaker Assistance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type of Assistance:', style: bodyBold),
                SizedBox(height: spacingSmall),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: requestTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value!;
                    });
                  },
                ),
                SizedBox(height: spacingMedium),
                Text('Message (Optional):', style: bodyBold),
                SizedBox(height: spacingSmall),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: 'Describe what you need help with...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                final success = await _caretakerRequestService.sendCaretakerRequest(
                  userId: widget.userData['uid'] ?? '',
                  userName: userName,
                  requestType: selectedType,
                  message: messageController.text.isNotEmpty 
                    ? messageController.text 
                    : 'User needs $selectedType',
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success 
                          ? 'Request sent to caretaker' 
                          : 'Failed to send request'
                      ),
                      backgroundColor: success ? Colors.green : error,
                    ),
                  );
                  
                  if (success) {
                    setState(() {
                      _notificationMessage = 'Waiting for caretaker response...';
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: white,
              ),
              child: Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    _caretakerRequestService.clearListeners();
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
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(double width, double height, _AppTheme theme) {
    Widget content;
    
    switch (_selectedIndex) {
      case 0:
        content = HomeContent(
          cameraService: _cameraService,
          permissionService: _permissionService,
          isDarkMode: _isDarkMode,
          theme: theme,
          onNotificationUpdate: _updateNotification,
          onRequestCaretaker: _requestCaretaker,
        );
        break;
      case 1:
        content = ContactsContent(
          isDarkMode: _isDarkMode,
          theme: theme,
        );
        break;
      case 3:
        content = RecentActivitiesContent(
          isDarkMode: _isDarkMode,
          theme: theme,
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
          onRequestCaretaker: _requestCaretaker,
        );
    }
    
    // Wrap content with ScrollView only if it's scrollable content
    return SingleChildScrollView(
      controller: _scrollController,
      physics: ClampingScrollPhysics(),
      child: content,
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