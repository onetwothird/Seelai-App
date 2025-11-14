// File: lib/roles/visually_impaired/home/home_screen.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use, duplicate_ignore, unnecessary_import

import 'package:flutter/material.dart';
import 'dart:async';
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
import 'package:seelai_app/firebase/assistance_request_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/caretaker/models/request_model.dart';
import 'package:seelai_app/roles/visually_impaired/camera_scanner/camera_scanner_screen.dart';

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
  late final UserActivityService _userActivityService;
  
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
    _userActivityService = userActivityService;
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

    // Listen to real-time request updates
    _requestsSubscription = _assistanceRequestService
        .streamPatientRequests(userId)
        .listen((requests) {
      if (mounted) {
        // Check for accepted requests
        final acceptedRequests = requests.where((req) => 
          req.status == RequestStatus.accepted && 
          req.responseTime != null &&
          DateTime.now().difference(req.responseTime!).inMinutes < 5
        ).toList();
        
        setState(() {
          _unreadNotificationCount = acceptedRequests.length;
          
          if (acceptedRequests.isNotEmpty) {
            _accessibilityService.announce('Caretaker accepted your assistance request');
          } else {
            final pendingRequests = requests.where((req) => req.status == RequestStatus.pending).toList();
            if (pendingRequests.isNotEmpty) {
            } else {
            }
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
      setState(() {
      });

      if (result.hasAllPermissions) {
        await _initializeCamera();
      } else {
        setState(() {
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
    });

    final success = await _cameraService.initialize();
    
    if (mounted) {
      setState(() {
        if (success) {
        } else {
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
    
    // Log voice assistant usage
    final userId = widget.userData['uid'] as String?;
    if (userId != null) {
      _userActivityService.logActivity(
        userId: userId,
        activityType: UserActivityService.activityVoiceAssistant,
        title: 'Voice Assistant',
        description: 'Voice assistant activated - Just now',
      );
    }
  }

  void _openNotifications() async {
    _accessibilityService.announce('Opening notifications');
    
    final userId = widget.userData['uid'] as String?;
    if (userId == null) return;

    // Get all requests
    final requests = await _assistanceRequestService
        .streamPatientRequests(userId)
        .first;
    
    // Show notifications dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications_rounded, color: primary),
              SizedBox(width: spacingSmall),
              Text('Notifications'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (requests.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: spacingLarge),
                    child: Center(
                      child: Text(
                        'No notifications',
                        style: body.copyWith(color: grey),
                      ),
                    ),
                  )
                else
                  ...requests.take(5).map((request) => Column(
                    children: [
                      _buildNotificationItem(
                        icon: _getRequestIcon(request.status),
                        iconColor: _getRequestColor(request.status),
                        title: _getRequestTitle(request.status),
                        message: request.message,
                        time: _getTimeAgo(request.responseTime ?? request.timestamp),
                      ),
                      if (request != requests.last) Divider(),
                    ],
                  // ignore: unnecessary_to_list_in_spreads
                  )).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Mark as read
                setState(() {
                  _unreadNotificationCount = 0;
                });
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  IconData _getRequestIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
        return Icons.check_circle_rounded;
      case RequestStatus.inProgress:
        return Icons.pending_rounded;
      case RequestStatus.completed:
        return Icons.check_circle_outline_rounded;
      case RequestStatus.declined:
        return Icons.cancel_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  Color _getRequestColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.declined:
        return error;
      case RequestStatus.inProgress:
        return accent;
      default:
        return primary;
    }
  }

  String _getRequestTitle(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
        return 'Request Accepted';
      case RequestStatus.inProgress:
        return 'In Progress';
      case RequestStatus.completed:
        return 'Request Completed';
      case RequestStatus.declined:
        return 'Request Declined';
      default:
        return 'Request Pending';
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          SizedBox(width: spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: bodyBold.copyWith(fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  message,
                  style: body.copyWith(fontSize: 13, color: grey),
                ),
                SizedBox(height: 4),
                Text(
                  time,
                  style: body.copyWith(fontSize: 11, color: grey.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    
    // Check if camera is initialized
    if (!_cameraService.isInitialized) {
      setState(() {
      });
      
      final success = await _cameraService.initialize();
      
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to initialize camera. Please check permissions.'),
              backgroundColor: error,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
            ),
          );
        }
        return;
      }
    }
    
    // Log camera scanner usage
    final userId = widget.userData['uid'] as String?;
    if (userId != null) {
      _userActivityService.logActivity(
        userId: userId,
        activityType: 'camera_scanner',
        title: 'Camera Scanner',
        description: 'Camera scanner opened - Just now',
      );
    }
    
    // Navigate to camera scanner screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScannerScreen(
            cameraService: _cameraService,
            isDarkMode: _isDarkMode,
          ),
        ),
      );
    }
  }

  void _updateNotification(String message) {
    setState(() {
    });
  }

  Future<void> _requestCaretaker() async {
    final userName = widget.userData['name'] ?? 'User';
    final userId = widget.userData['uid'] ?? '';
    
    // Get assigned caretakers
    final assignedCaretakers = widget.userData['assignedCaretakers'] as Map<dynamic, dynamic>?;
    
    if (assignedCaretakers == null || assignedCaretakers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No caretaker assigned. Please assign a caretaker first.'),
          backgroundColor: error,
        ),
      );
      return;
    }
    
    // Get first caretaker ID
    final caretakerId = assignedCaretakers.keys.first.toString();
    
    // Show request dialog
    _showCaretakerRequestDialog(userName, userId, caretakerId);
  }

  void _showCaretakerRequestDialog(String userName, String userId, String caretakerId) {
    final requestTypes = [
      'General Assistance',
      'Navigation Help',
      'Reading Assistance',
      'Emergency Help',
      'Other',
    ];
    
    final priorityLevels = [
      'Low',
      'Medium',
      'High',
      'Emergency',
    ];
    
    String selectedType = requestTypes[0];
    String selectedPriority = 'Medium';
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
                Text('Priority Level:', style: bodyBold),
                SizedBox(height: spacingSmall),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: priorityLevels.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPriority = value!;
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
                
                final success = await _assistanceRequestService.sendAssistanceRequest(
                  patientId: userId,
                  patientName: userName,
                  caretakerId: caretakerId,
                  requestType: selectedType,
                  message: messageController.text.isNotEmpty 
                    ? messageController.text 
                    : 'User needs $selectedType',
                  priority: selectedPriority.toLowerCase(),
                );
                
                // Log the caretaker request activity
                if (success) {
                  await _userActivityService.logCaretakerRequest(
                    userId: userId,
                    requestType: selectedType,
                    priority: selectedPriority,
                  );
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success 
                          ? 'Request sent to caretaker successfully' 
                          : 'Failed to send request'
                      ),
                      backgroundColor: success ? Colors.green : error,
                    ),
                  );
                  
                  if (success) {
                    setState(() {
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
    _requestsSubscription?.cancel();
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
              profileImageUrl: widget.userData['profileImageUrl'] as String?, // ← ADD THIS LINE
              isDarkMode: _isDarkMode,
              onVoiceAssistant: _activateVoiceAssistant,
              onToggleDarkMode: _toggleDarkMode,
              onNotificationTap: _openNotifications,
              onProfileTap: () {
                // Navigate to profile tab when tapped
                setState(() {
                  _selectedIndex = 4; // Profile is at index 4
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
  final userId = widget.userData['uid'] as String? ?? '';
  
  switch (_selectedIndex) {
    case 0:
      content = HomeContent(
        cameraService: _cameraService,
        permissionService: _permissionService,
        isDarkMode: _isDarkMode,
        theme: theme,
        onNotificationUpdate: _updateNotification,
        onRequestCaretaker: _requestCaretaker,
        userData: widget.userData,
      );
      break;
    case 1:
      // Wrap ContactsContent with SingleChildScrollView to enable scroll detection
      return SingleChildScrollView(
        controller: _scrollController,
        physics: ClampingScrollPhysics(),
        child: ContactsContent(
          isDarkMode: _isDarkMode,
          theme: theme,
          userData: widget.userData,
        ),
      );
    case 3:
      content = RecentActivitiesContent(
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
        onRequestCaretaker: _requestCaretaker,
        userData: widget.userData,
      );
  }
  
  // Wrap other sections in SingleChildScrollView
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