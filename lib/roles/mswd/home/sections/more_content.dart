// File: lib/roles/mswd/home/sections/more_content.dart
// ignore_for_file: deprecated_member_use, prefer_final_fields, use_build_context_synchronously

import 'package:flutter/material.dart';
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
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      controller: widget.scrollController,
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
            
            // Verifications Section
            _buildSectionTitle('Approvals & Verifications', Icons.verified_user_rounded),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Verifications',
              'Pending approvals and documents',
              Icons.verified_user_rounded,
              Colors.orange,
              badge: _pendingVerifications,
              onTap: () => _showSnackbar('Opening Verifications...'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Tracking & Monitoring Section
            _buildSectionTitle('Tracking & Monitoring', Icons.map_rounded),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Location Tracking',
              'Real-time map view of all users',
              Icons.map_rounded,
              Colors.green,
              onTap: () => _showSnackbar('Opening Location Tracking...'),
            ),
            _buildMenuItem(
              'Analytics & Reports',
              'Usage statistics and demographics',
              Icons.analytics_rounded,
              Colors.blue,
              onTap: () => _showSnackbar('Opening Analytics...'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Communications Section
            _buildSectionTitle('Communications', Icons.campaign_rounded),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Send Announcement',
              'Broadcast messages to users',
              Icons.campaign_rounded,
              Colors.purple,
              onTap: () => _showSnackbar('Opening Communications...'),
            ),
            _buildMenuItem(
              'Message Templates',
              'Manage announcement templates',
              Icons.message_rounded,
              accent,
              onTap: () => _showSnackbar('Opening Templates...'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Emergency & Safety Section
            _buildSectionTitle('Emergency & Safety', Icons.phone_in_talk_rounded),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Emergency Hotlines',
              'Manage emergency contact directory',
              Icons.phone_in_talk_rounded,
              error,
              onTap: () => _showSnackbar('Opening Hotlines...'),
            ),
            _buildMenuItem(
              'Audit Logs',
              'System activity and security events',
              Icons.history_rounded,
              Colors.indigo,
              onTap: () => _showSnackbar('Opening Audit Logs...'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Administration Section
            _buildSectionTitle('Administration', Icons.admin_panel_settings_rounded),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Admin Management',
              'Manage admin users and permissions',
              Icons.admin_panel_settings_rounded,
              Colors.deepPurple,
              onTap: () => _showSnackbar('Opening Admin Management...'),
            ),
            _buildMenuItem(
              'System Settings',
              'App configuration and maintenance',
              Icons.settings_rounded,
              Colors.grey,
              onTap: () => _showSnackbar('Opening System Settings...'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Support Section
            _buildSectionTitle('Help & Support', Icons.help_rounded),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Help Center',
              'FAQ, user manual, and support',
              Icons.help_rounded,
              Colors.teal,
              onTap: () => _showSnackbar('Opening Help Center...'),
            ),
            _buildMenuItem(
              'Report a Bug',
              'Submit technical issues',
              Icons.bug_report_rounded,
              Colors.red,
              onTap: () => _showSnackbar('Opening Bug Report...'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Account Actions
            _buildSectionTitle('Account', Icons.security_rounded),
            SizedBox(height: spacingMedium),
            _buildMenuItem(
              'Security Settings',
              'Password, 2FA, and active sessions',
              Icons.security_rounded,
              Colors.cyan,
              onTap: () => _showSnackbar('Opening Security Settings...'),
            ),
            _buildMenuItem(
              'Logout',
              'Sign out of your account',
              Icons.logout_rounded,
              Colors.red,
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
            child: Icon(icon, color: primary, size: 16),
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
                    : Colors.white.withOpacity(0.1))
                : (isDestructive
                    ? Colors.red.withOpacity(0.2)
                    : Colors.black.withOpacity(0.06)),
          ),
          boxShadow: widget.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                                    color: white,
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: primary,
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
                      Icon(Icons.check_circle_rounded, color: white, size: 20),
                      SizedBox(width: spacingSmall),
                      Expanded(
                        child: Text(
                          'Successfully logged out',
                          style: TextStyle(
                            color: white,
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
              foregroundColor: white,
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