// File: lib/roles/mswd/home/sections/more_content.dart
// ignore_for_file: deprecated_member_use, prefer_final_fields, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/screens/onboarding_screen.dart';

class MoreContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final VoidCallback? onToggleDarkMode;
  final ScrollController? scrollController;

  const MoreContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    this.onToggleDarkMode,
    this.scrollController,
  });

  @override
  State<MoreContent> createState() => _MoreContentState();
}

class _MoreContentState extends State<MoreContent> {
  int _pendingVerifications = 12;

  // --- Color Palette for Sections ---
  final Color _colVerifications = const Color(0xFF3B82F6); // Blue
  final Color _colTracking = const Color(0xFF8B5CF6);      // Purple (kept for tech/data)
  final Color _colComms = const Color(0xFFF59E0B);         // Amber/Orange
  final Color _colSafety = const Color(0xFFEF4444);        // Red
  final Color _colAdmin = const Color(0xFF64748B);         // Slate/Blue-Grey
  final Color _colSupport = const Color(0xFF06B6D4);       // Cyan
  final Color _colSecurity = const Color(0xFF10B981);      // Emerald Green

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(
          left: width * 0.05,
          right: width * 0.05,
          top: spacingMedium,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: spacingLarge),
            
            // --- Verifications Section (Blue) ---
            _buildSectionTitle('Approvals & Verifications', Icons.verified_user_rounded, _colVerifications),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Verifications',
              'Pending approvals and documents',
              Icons.verified_user_rounded,
              _colVerifications, 
              badge: _pendingVerifications,
              onTap: () => _showSnackbar('Opening Verifications...'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // --- Tracking & Monitoring Section (Purple) ---
            _buildSectionTitle('Tracking & Monitoring', Icons.map_rounded, _colTracking),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Location Tracking',
              'Real-time map view of all users',
              Icons.map_rounded,
              _colTracking,
              onTap: () => _showSnackbar('Opening Location Tracking...'),
            ),
            _buildMenuItem(
              'Analytics & Reports',
              'Usage statistics and demographics',
              Icons.analytics_rounded,
              _colTracking,
              onTap: () => _showSnackbar('Opening Analytics...'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // --- Communications Section (Amber/Orange) ---
            _buildSectionTitle('Communications', Icons.campaign_rounded, _colComms),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Send Announcement',
              'Broadcast messages to users',
              Icons.campaign_rounded,
              _colComms,
              onTap: () => _showSnackbar('Opening Communications...'),
            ),
            _buildMenuItem(
              'Message Templates',
              'Manage announcement templates',
              Icons.message_rounded,
              _colComms,
              onTap: () => _showSnackbar('Opening Templates...'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // --- Emergency & Safety Section (Red) ---
            _buildSectionTitle('Emergency & Safety', Icons.phone_in_talk_rounded, _colSafety),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Emergency Hotlines',
              'Manage emergency contact directory',
              Icons.phone_in_talk_rounded,
              _colSafety, 
              onTap: () => _showSnackbar('Opening Hotlines...'),
            ),
            _buildMenuItem(
              'Audit Logs',
              'System activity and security events',
              Icons.history_rounded,
              _colSafety,
              onTap: () => _showSnackbar('Opening Audit Logs...'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // --- Administration Section (Grey/Slate) ---
            _buildSectionTitle('Administration', Icons.admin_panel_settings_rounded, _colAdmin),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Admin Management',
              'Manage admin users and permissions',
              Icons.admin_panel_settings_rounded,
              _colAdmin,
              onTap: () => _showSnackbar('Opening Admin Management...'),
            ),
            _buildMenuItem(
              'System Settings',
              'App configuration and maintenance',
              Icons.settings_rounded,
              _colAdmin,
              onTap: () => _showSnackbar('Opening System Settings...'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // --- Support Section (Cyan) ---
            _buildSectionTitle('Help & Support', Icons.help_rounded, _colSupport),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'How to Use App',
              'Watch tutorial & features tour',
              Icons.play_circle_fill_rounded,
              _colSupport,
              onTap: () => _showAppGuideDialog(),
            ),
            _buildMenuItem(
              'Help Center',
              'FAQ, user manual, and support',
              Icons.help_rounded,
              _colSupport,
              onTap: () => _showSnackbar('Opening Help Center...'),
            ),
            _buildMenuItem(
              'Report a Bug',
              'Submit technical issues',
              Icons.bug_report_rounded,
              _colSupport,
              onTap: () => _showSnackbar('Opening Bug Report...'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // --- Account Actions (Green for Security, Red for Logout) ---
            _buildSectionTitle('Account', Icons.security_rounded, _colSecurity),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Security Settings',
              'Password, 2FA, and active sessions',
              Icons.security_rounded,
              _colSecurity,
              onTap: () => _showSnackbar('Opening Security Settings...'),
            ),
            _buildMenuItem(
              'Logout',
              'Sign out of your account',
              Icons.logout_rounded,
              error, // Keep Red for destructive
              isDestructive: true,
              onTap: () => _showLogoutDialog(),
            ),
            
            SizedBox(height: spacingLarge),
            
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'More Options',
                style: h2.copyWith(
                  fontSize: 24,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Settings and management',
                style: body.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // UPDATED: Added `color` parameter to section title
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15), // Uses the section color
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
            child: Icon(icon, color: color, size: 16), // Uses the section color
          ),
          SizedBox(width: spacingSmall),
          Text(
            title.toUpperCase(),
            style: caption.copyWith(
              fontSize: 11,
              color: widget.theme.subtextColor.withOpacity(0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    int? badge,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Container(
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          border: Border.all(
            color: widget.isDarkMode
                ? (isDestructive 
                    ? Colors.red.withOpacity(0.3) 
                    : color.withOpacity(0.3)) // Increased opacity slightly for visibility
                : (isDestructive
                    ? Colors.red.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05)),
            width: 1,
          ),
          boxShadow: widget.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radiusLarge),
            child: Padding(
              padding: EdgeInsets.all(spacingMedium),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      // Uses the specific section color
                      color: isDestructive
                          ? Colors.red.withOpacity(0.1)
                          : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: isDestructive ? Colors.red : color,
                        size: 22,
                      ),
                    ),
                  ),
                  SizedBox(width: spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: bodyBold.copyWith(
                                  fontSize: 15,
                                  color: isDestructive
                                      ? Colors.red
                                      : widget.theme.textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (badge != null && badge > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: error,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: error.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  badge > 99 ? '99+' : badge.toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: caption.copyWith(
                            fontSize: 12,
                            color: widget.theme.subtextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: spacingSmall),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: widget.theme.subtextColor.withOpacity(0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAppGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => MSWDGuideVideoDialog(
        theme: widget.theme,
        colSupport: _colSupport,
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        // Default to purple for general snackbars or you can make this dynamic
        backgroundColor: const Color(0xFF8B5CF6), 
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.logout_rounded,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(width: spacingSmall),
            Text(
              'Logout',
              style: h2.copyWith(
                fontSize: 18,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from your account?',
          style: body.copyWith(
            fontSize: 14,
            color: widget.theme.subtextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: widget.theme.subtextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              
              // Sign out
              await authService.value.signOut();
              
              // Navigate to onboarding screen and remove all previous routes
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const OnboardingScreen(),
                ),
                (route) => false,
              );
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      SizedBox(width: spacingSmall),
                      Expanded(
                        child: Text(
                          'Successfully logged out',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                  margin: EdgeInsets.all(spacingMedium),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: spacingLarge,
                vertical: spacingMedium,
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MSWD VIDEO PLAYER DIALOG WIDGET ====================
class MSWDGuideVideoDialog extends StatefulWidget {
  final dynamic theme;
  final Color colSupport;

  const MSWDGuideVideoDialog({
    super.key,
    required this.theme,
    required this.colSupport,
  });

  @override
  State<MSWDGuideVideoDialog> createState() => _MSWDGuideVideoDialogState();
}

class _MSWDGuideVideoDialogState extends State<MSWDGuideVideoDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    
    _controller = VideoPlayerController.asset('assets/video/sample_vid.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = error.toString();
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.theme.cardColor,
      insetPadding: const EdgeInsets.all(20),
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- VIDEO HEADER ---
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: _hasError 
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                "Video failed to load.\nCheck path or run 'flutter clean'.\n\nError: $_errorMessage",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          )
                        : _isInitialized
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _controller.value.isPlaying
                                        ? _controller.pause()
                                        : _controller.play();
                                  });
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox.expand(
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _controller.value.size.width,
                                          height: _controller.value.size.height,
                                          child: VideoPlayer(_controller),
                                        ),
                                      ),
                                    ),
                                    
                                    // Play/Pause Button Overlay
                                    if (!_controller.value.isPlaying)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: widget.colSupport,
                                          size: 50,
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : Center(
                                child: CircularProgressIndicator(
                                  color: widget.colSupport,
                                ),
                              ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),

            // --- CONTENT ---
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Getting Started', 
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Learn how to manage the system efficiently.',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.theme.subtextColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGuideStep(1, 'Manage Verifications', 'Review and approve new user registrations.', widget.colSupport),
                    _buildGuideStep(2, 'Tracking & Reports', 'Monitor live locations and view usage analytics.', widget.colSupport),
                    _buildGuideStep(3, 'Global Announcements', 'Send push notifications and alerts to all users.', widget.colSupport),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.colSupport,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("I'm Ready!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(int step, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text('$step', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: widget.theme.textColor)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 13, color: widget.theme.subtextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}