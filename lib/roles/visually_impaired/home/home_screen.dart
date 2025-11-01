// File: lib/roles/visually_impaired/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/themes/widgets.dart';
import 'package:seelai_app/service/auth_service.dart';

class VisuallyImpairedHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const VisuallyImpairedHomeScreen({
    super.key,
    required this.userData,
  });

  @override
  State<VisuallyImpairedHomeScreen> createState() => _VisuallyImpairedHomeScreenState();
}

class _VisuallyImpairedHomeScreenState extends State<VisuallyImpairedHomeScreen> with SingleTickerProviderStateMixin {
  // Camera controller
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  
  // Permission states
  bool _hasPermissions = false;
  String _permissionStatus = 'Checking permissions...';
  
  // High contrast mode toggle
  bool _isHighContrastMode = false;
  
  // Bottom navigation
  int _selectedIndex = 0;
  
  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Notification message
  String _notificationMessage = 'Welcome to SeelAI';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestPermissions();
  }

  // Request all required permissions
  Future<void> _requestPermissions() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      
      // Request storage permissions based on Android version
      PermissionStatus storageStatus;
      if (await _isAndroid13OrHigher()) {
        // For Android 13+, request media permissions
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        storageStatus = (photos.isGranted && videos.isGranted) 
          ? PermissionStatus.granted 
          : PermissionStatus.denied;
      } else {
        // For Android 12 and below
        storageStatus = await Permission.storage.request();
      }

      if (mounted) {
        setState(() {
          _hasPermissions = cameraStatus.isGranted && storageStatus.isGranted;
          
          if (_hasPermissions) {
            _permissionStatus = 'All permissions granted';
            _notificationMessage = 'Camera and storage access enabled';
            _initializeCamera();
          } else {
            _permissionStatus = _getPermissionDeniedMessage(cameraStatus, storageStatus);
            _notificationMessage = 'Some permissions were denied';
          }
        });
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
      if (mounted) {
        setState(() {
          _permissionStatus = 'Error requesting permissions';
          _notificationMessage = 'Unable to request permissions';
        });
      }
    }
  }

  // Check if Android version is 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    // This is a simple check, you might want to use a platform-specific plugin
    // for more accurate version detection
    return false; // Default to false for iOS and older Android
  }

  // Get detailed permission denial message
  String _getPermissionDeniedMessage(PermissionStatus camera, PermissionStatus storage) {
    List<String> denied = [];
    
    if (!camera.isGranted) denied.add('Camera');
    if (!storage.isGranted) denied.add('Storage');
    
    if (denied.isEmpty) return 'All permissions granted';
    
    return '${denied.join(' and ')} permission${denied.length > 1 ? 's' : ''} denied';
  }

  // Initialize camera
  Future<void> _initializeCamera() async {
    if (!_hasPermissions) {
      debugPrint('Cannot initialize camera: permissions not granted');
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _permissionStatus = 'No cameras available';
            _notificationMessage = 'No camera found on device';
          });
        }
        return;
      }
      
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _permissionStatus = 'Camera initialization failed';
          _notificationMessage = 'Unable to initialize camera';
        });
      }
    }
  }

  // Initialize animations
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

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Toggle high contrast mode
  void _toggleHighContrast() {
    setState(() {
      _isHighContrastMode = !_isHighContrastMode;
    });
    
    // Announce to screen reader
    _announceToScreenReader(
      _isHighContrastMode 
        ? 'High contrast mode enabled' 
        : 'High contrast mode disabled'
    );
  }

  // Voice assistant action
  void _activateVoiceAssistant() {
    _announceToScreenReader('Voice assistant activated. Listening...');
    // TODO: Implement voice command functionality
  }

  // Announce to screen reader
  void _announceToScreenReader(String message) {
    setState(() {
      _notificationMessage = message;
    });
  }

  // Open app settings for manual permission grant
  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  // Handle bottom navigation
  void _onNavItemTapped(int index) {
    _animationController.reset();
    setState(() {
      _selectedIndex = index;
    });
    _animationController.forward();
    
    // Announce navigation change
    final labels = ['Home', 'Profile', 'Recent Activities'];
    _announceToScreenReader('Navigated to ${labels[index]}');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final userName = widget.userData['name'] ?? 'User';

    // Dynamic colors based on contrast mode
    final bgColor = _isHighContrastMode ? Colors.black : backgroundPrimary;
    final textColor = _isHighContrastMode ? white : black;
    final cardColor = _isHighContrastMode ? Color(0xFF1A1A1A) : white;
    final subtextColor = _isHighContrastMode ? Colors.white70 : grey;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _isHighContrastMode 
            ? LinearGradient(
                colors: [Colors.black, Color(0xFF1A1A1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [backgroundPrimary, backgroundSecondary, lightBlue.withOpacity(0.3)],
                stops: [0.0, 0.5, 1.0],
              ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              _buildHeader(screenWidth, screenHeight, userName, textColor, subtextColor),
              
              // Main Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildMainContent(screenWidth, screenHeight, cardColor, textColor, subtextColor),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(textColor, subtextColor),
    );
  }

  // Header with greeting and date
  Widget _buildHeader(double width, double height, String name, Color textColor, Color subtextColor) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
    
    return Semantics(
      label: 'Header section. Hi $name. Today is $formattedDate',
      child: Container(
        padding: EdgeInsets.all(width * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting and controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: 'Greeting',
                        child: Text(
                          'Hi, $name 👋',
                          style: h1.copyWith(
                            fontSize: width * 0.075,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      SizedBox(height: spacingXSmall),
                      Semantics(
                        label: 'Today\'s date',
                        child: Text(
                          formattedDate,
                          style: body.copyWith(
                            fontSize: width * 0.04,
                            color: subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Voice Assistant Button
                Semantics(
                  label: 'Voice assistant button',
                  hint: 'Double tap to activate voice commands',
                  button: true,
                  child: _buildIconButton(
                    icon: Icons.mic_rounded,
                    onPressed: _activateVoiceAssistant,
                    size: 32,
                  ),
                ),
                
                SizedBox(width: spacingSmall),
                
                // High Contrast Toggle
                Semantics(
                  label: _isHighContrastMode 
                    ? 'High contrast mode is on' 
                    : 'High contrast mode is off',
                  hint: 'Double tap to toggle high contrast mode',
                  button: true,
                  child: _buildIconButton(
                    icon: _isHighContrastMode 
                      ? Icons.contrast_rounded 
                      : Icons.brightness_6_rounded,
                    onPressed: _toggleHighContrast,
                    size: 32,
                    isSpecial: _isHighContrastMode,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: spacingMedium),
            
            // Notification Area with TTS support
            Semantics(
              label: 'Notification',
              liveRegion: true,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: _isHighContrastMode 
                    ? LinearGradient(colors: [white, white])
                    : LinearGradient(
                        colors: [primaryLight.withOpacity(0.15), accent.withOpacity(0.1)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                  borderRadius: BorderRadius.circular(radiusLarge),
                  border: Border.all(
                    color: _isHighContrastMode ? white : primary.withOpacity(0.25),
                    width: _isHighContrastMode ? 2 : 1.5,
                  ),
                  boxShadow: _isHighContrastMode ? [] : softShadow,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: _isHighContrastMode ? black : primary,
                      size: 22,
                    ),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: Text(
                        _notificationMessage,
                        style: bodyBold.copyWith(
                          fontSize: 15,
                          color: _isHighContrastMode ? black : primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Icon button helper
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 28,
    bool isSpecial = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: _isHighContrastMode ? [] : softShadow,
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      child: Material(
        color: _isHighContrastMode 
          ? (isSpecial ? Colors.yellow : white)
          : primaryLight.withOpacity(0.12),
        borderRadius: BorderRadius.circular(radiusMedium),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radiusMedium),
          splashColor: primary.withOpacity(0.2),
          child: Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              border: _isHighContrastMode 
                ? Border.all(color: white, width: 2)
                : null,
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Icon(
              icon,
              size: size,
              color: _isHighContrastMode 
                ? (isSpecial ? Colors.black : Colors.black)
                : primary,
            ),
          ),
        ),
      ),
    );
  }

  // Main content based on selected navigation
  Widget _buildMainContent(double width, double height, Color cardColor, Color textColor, Color subtextColor) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent(width, height, cardColor, textColor, subtextColor);
      case 1:
        return _buildProfileContent(width, height, cardColor, textColor, subtextColor);
      case 2:
        return _buildRecentActivitiesContent(width, height, cardColor, textColor, subtextColor);
      default:
        return _buildHomeContent(width, height, cardColor, textColor, subtextColor);
    }
  }

  // Home content with camera preview
  Widget _buildHomeContent(double width, double height, Color cardColor, Color textColor, Color subtextColor) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: width * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Camera Preview Section
          Semantics(
            label: 'Camera preview section',
            hint: 'Real-time camera feed for visual assistance',
            child: Container(
              height: height * 0.38,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(radiusXLarge),
                boxShadow: _isHighContrastMode ? [] : cardShadow,
                border: _isHighContrastMode 
                  ? Border.all(color: white, width: 2.5)
                  : Border.all(color: greyLighter.withOpacity(0.5), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radiusXLarge),
                child: _isCameraInitialized && _cameraController != null
                  ? Stack(
                      children: [
                        CameraPreview(_cameraController!),
                        // Camera overlay gradient
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(spacingMedium),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_rounded, color: white, size: 18),
                                  SizedBox(width: spacingSmall),
                                  Text(
                                    'Camera Active',
                                    style: caption.copyWith(
                                      color: white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(spacingLarge),
                            decoration: BoxDecoration(
                              gradient: _hasPermissions ? primaryGradient : LinearGradient(
                                colors: [grey, grey.withOpacity(0.8)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: _hasPermissions ? glowShadow : [],
                            ),
                            child: Icon(
                              _hasPermissions ? Icons.camera_alt_rounded : Icons.no_photography_rounded,
                              size: 48,
                              color: white,
                            ),
                          ),
                          SizedBox(height: spacingLarge),
                          Text(
                            _permissionStatus,
                            textAlign: TextAlign.center,
                            style: h3.copyWith(
                              color: textColor,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: spacingMedium),
                          if (!_hasPermissions)
                            Semantics(
                              label: 'Open settings button',
                              button: true,
                              hint: 'Double tap to open app settings and grant permissions',
                              child: TextButton.icon(
                                onPressed: _openAppSettings,
                                icon: Icon(Icons.settings_rounded),
                                label: Text('Open Settings'),
                                style: TextButton.styleFrom(
                                  foregroundColor: _isHighContrastMode ? white : primary,
                                  textStyle: bodyBold.copyWith(fontSize: 16),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _isHighContrastMode ? white : primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
              ),
            ),
          ),
          
          SizedBox(height: spacingXLarge),
          
          // Quick Action Buttons
          Semantics(
            label: 'Quick actions section',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: h2.copyWith(
                    fontSize: 24,
                    color: textColor,
                  ),
                ),
                SizedBox(height: spacingMedium),
                Text(
                  'Tap any button to activate assistance',
                  style: body.copyWith(
                    color: subtextColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: spacingLarge),
                
                // Action buttons grid
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Scan Object',
                        Icons.qr_code_scanner_rounded,
                        () => _announceToScreenReader('Object scanning started'),
                        cardColor,
                        textColor,
                      ),
                    ),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: _buildActionButton(
                        'Read Text',
                        Icons.text_fields_rounded,
                        () => _announceToScreenReader('Text reading activated'),
                        cardColor,
                        textColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacingMedium),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Detect Colors',
                        Icons.palette_rounded,
                        () => _announceToScreenReader('Color detection started'),
                        cardColor,
                        textColor,
                      ),
                    ),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: _buildActionButton(
                        'Emergency',
                        Icons.emergency_rounded,
                        () => _announceToScreenReader('Emergency assistance activated'),
                        cardColor,
                        textColor,
                        isEmergency: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: spacingXLarge),
        ],
      ),
    );
  }

  // Action button widget
  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
    Color cardColor,
    Color textColor, {
    bool isEmergency = false,
  }) {
    return Semantics(
      label: '$label button',
      button: true,
      hint: 'Double tap to activate $label',
      child: Container(
        decoration: BoxDecoration(
          boxShadow: _isHighContrastMode ? [] : softShadow,
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        child: Material(
          color: _isHighContrastMode 
            ? (isEmergency ? error : white)
            : cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(radiusLarge),
            splashColor: primary.withOpacity(0.1),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: spacingLarge),
              decoration: BoxDecoration(
                gradient: isEmergency && !_isHighContrastMode
                  ? LinearGradient(
                      colors: [error.withOpacity(0.1), error.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                borderRadius: BorderRadius.circular(radiusLarge),
                border: _isHighContrastMode 
                  ? Border.all(color: isEmergency ? white : white, width: 2.5)
                  : Border.all(
                      color: isEmergency 
                        ? error.withOpacity(0.3)
                        : greyLighter,
                      width: 1.5,
                    ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacingMedium),
                    decoration: BoxDecoration(
                      gradient: isEmergency 
                        ? LinearGradient(colors: [error, error.withOpacity(0.8)])
                        : primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: isEmergency ? [] : glowShadow,
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: white,
                    ),
                  ),
                  SizedBox(height: spacingMedium),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: bodyBold.copyWith(
                      fontSize: 15,
                      color: _isHighContrastMode 
                        ? (isEmergency ? white : black)
                        : textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Profile content
  Widget _buildProfileContent(double width, double height, Color cardColor, Color textColor, Color subtextColor) {
    final userName = widget.userData['name'] ?? 'User';
    final userEmail = widget.userData['email'] ?? '';
    final userAge = widget.userData['age'] ?? 0;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: width * 0.06),
      child: Semantics(
        label: 'Profile information section',
        child: Container(
          padding: EdgeInsets.all(spacingXLarge),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(radiusXLarge),
            boxShadow: _isHighContrastMode ? [] : cardShadow,
            border: _isHighContrastMode 
              ? Border.all(color: white, width: 2.5)
              : Border.all(color: greyLighter.withOpacity(0.5), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacingLarge),
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(radiusMedium),
                      boxShadow: glowShadow,
                    ),
                    child: Icon(Icons.person_rounded, color: white, size: 36),
                  ),
                  SizedBox(width: spacingLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: h2.copyWith(
                            fontSize: 26,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: spacingXSmall),
                        Text(
                          'Your account information',
                          style: caption.copyWith(
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: spacingXLarge),
              
              // Profile info
              _buildInfoRow('Name', userName, textColor, subtextColor),
              _buildInfoRow('Email', userEmail, textColor, subtextColor),
              _buildInfoRow('Age', '$userAge years old', textColor, subtextColor),
              _buildInfoRow('Role', 'User', textColor, subtextColor),
              
              SizedBox(height: spacingXLarge),
              
              // Sign out button
              Semantics(
                label: 'Sign out button',
                button: true,
                hint: 'Double tap to sign out of your account',
                child: CustomButton(
                  text: 'Sign Out',
                  isLarge: true,
                  onPressed: () async {
                    await authService.value.signOut();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Recent activities content
  Widget _buildRecentActivitiesContent(double width, double height, Color cardColor, Color textColor, Color subtextColor) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: width * 0.06),
      child: Semantics(
        label: 'Recent activities section',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activities',
              style: h2.copyWith(
                fontSize: 26,
                color: textColor,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              'Your latest interactions with SeelAI',
              style: body.copyWith(
                color: subtextColor,
                fontSize: 14,
              ),
            ),
            SizedBox(height: spacingLarge),
            
            _buildActivityCard(
              'Object Scanned',
              'Water Bottle - 2 minutes ago',
              Icons.qr_code_scanner_rounded,
              cardColor,
              textColor,
              subtextColor,
            ),
            SizedBox(height: spacingMedium),
            _buildActivityCard(
              'Text Read',
              'Product Label - 15 minutes ago',
              Icons.text_fields_rounded,
              cardColor,
              textColor,
              subtextColor,
            ),
            SizedBox(height: spacingMedium),
            _buildActivityCard(
              'Color Detected',
              'Blue Fabric - 1 hour ago',
              Icons.palette_rounded,
              cardColor,
              textColor,
              subtextColor,
            ),
            SizedBox(height: spacingMedium),
            _buildActivityCard(
              'Emergency Called',
              'Contact alerted - 2 hours ago',
              Icons.emergency_rounded,
              cardColor,
              textColor,
              subtextColor,
              isEmergency: true,
            ),
          ],
        ),
      ),
    );
  }

  // Activity card widget
  Widget _buildActivityCard(
    String title,
    String time,
    IconData icon,
    Color cardColor,
    Color textColor,
    Color subtextColor, {
    bool isEmergency = false,
  }) {
    return Semantics(
      label: '$title, $time',
      child: Container(
        padding: EdgeInsets.all(spacingLarge),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: _isHighContrastMode ? [] : softShadow,
          border: _isHighContrastMode 
            ? Border.all(color: white, width: 2)
            : Border.all(
                color: isEmergency 
                  ? error.withOpacity(0.3)
                  : greyLighter,
                width: 1.5,
              ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(spacingMedium),
              decoration: BoxDecoration(
                gradient: isEmergency 
                  ? LinearGradient(colors: [error, error.withOpacity(0.8)])
                  : primaryGradient,
                borderRadius: BorderRadius.circular(radiusMedium),
                boxShadow: isEmergency ? [] : glowShadow,
              ),
              child: Icon(icon, color: white, size: 24),
            ),
            SizedBox(width: spacingLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: bodyBold.copyWith(
                      fontSize: 17,
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: spacingXSmall),
                  Text(
                    time,
                    style: caption.copyWith(
                      fontSize: 14,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: subtextColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // Info row helper
  Widget _buildInfoRow(String label, String value, Color textColor, Color subtextColor) {
    return Semantics(
      label: '$label: $value',
      child: Padding(
        padding: EdgeInsets.only(bottom: spacingLarge),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: body.copyWith(
                  fontSize: 16,
                  color: subtextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: bodyBold.copyWith(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavBar(Color textColor, Color subtextColor) {
    return Semantics(
      label: 'Bottom navigation bar',
      child: Container(
        decoration: BoxDecoration(
          color: _isHighContrastMode ? Colors.black : white,
          boxShadow: _isHighContrastMode 
            ? [] 
            : [
                BoxShadow(
                  color: primary.withOpacity(0.08),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                  spreadRadius: -2,
                ),
              ],
          border: _isHighContrastMode 
            ? Border(top: BorderSide(color: white, width: 2.5))
            : Border(top: BorderSide(color: greyLighter.withOpacity(0.5), width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: spacingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home', textColor, subtextColor),
                _buildNavItem(1, Icons.person_rounded, 'Profile', textColor, subtextColor),
                _buildNavItem(2, Icons.history_rounded, 'Recent', textColor, subtextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation item
  Widget _buildNavItem(int index, IconData icon, String label, Color textColor, Color subtextColor) {
    final isSelected = _selectedIndex == index;
    
    return Semantics(
      label: '$label tab',
      selected: isSelected,
      button: true,
      hint: 'Double tap to navigate to $label',
      child: GestureDetector(
        onTap: () => _onNavItemTapped(index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          decoration: BoxDecoration(
            gradient: isSelected 
              ? primaryGradient
              : null,
            color: isSelected 
              ? null
              : Colors.transparent,
            borderRadius: BorderRadius.circular(radiusMedium),
            border: _isHighContrastMode && isSelected
              ? Border.all(color: white, width: 2.5)
              : null,
            boxShadow: isSelected && !_isHighContrastMode
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ]
              : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected 
                  ? white 
                  : _isHighContrastMode ? white : grey,
              ),
              SizedBox(height: spacingXSmall),
              Text(
                label,
                style: caption.copyWith(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected 
                    ? white 
                    : _isHighContrastMode ? white : grey,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}