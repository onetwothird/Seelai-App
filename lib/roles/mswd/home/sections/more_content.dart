// File: lib/roles/mswd/home/sections/more_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

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
            _buildProfileCard(),
            SizedBox(height: spacingLarge),
            
            // Verifications Section
            _buildSectionTitle('Approvals & Verifications'),
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
            _buildSectionTitle('Tracking & Monitoring'),
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
            _buildSectionTitle('Communications'),
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
            _buildSectionTitle('Emergency & Safety'),
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
            _buildSectionTitle('Administration'),
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
            _buildSectionTitle('Help & Support'),
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
            _buildSectionTitle('Account'),
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
            
            // App Info
            _buildAppInfo(),
            
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

  Widget _buildProfileCard() {
    final adminName = widget.userData['name'] ?? 'Admin';
    final adminEmail = widget.userData['email'] ?? 'admin@mswd.gov.ph';
    
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        gradient: widget.isDarkMode
            ? LinearGradient(
                colors: [
                  primary.withOpacity(0.2),
                  primary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  primary.withOpacity(0.1),
                  primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(radiusXLarge),
        border: Border.all(
          color: widget.isDarkMode
              ? primary.withOpacity(0.3)
              : primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: primaryGradient,
              border: Border.all(
                color: white,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                adminName.substring(0, 1).toUpperCase(),
                style: h2.copyWith(
                  color: white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminName,
                  style: bodyBold.copyWith(
                    fontSize: 16,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  adminEmail,
                  style: caption.copyWith(
                    fontSize: 12,
                    color: widget.theme.subtextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacingSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(radiusSmall),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Admin',
                        style: caption.copyWith(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: widget.theme.subtextColor,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: caption.copyWith(
          fontSize: 11,
          color: widget.theme.subtextColor.withOpacity(0.7),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
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

  Widget _buildAppInfo() {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 32,
            color: widget.theme.subtextColor.withOpacity(0.5),
          ),
          SizedBox(height: spacingSmall),
          Text(
            'SEELAI MSWD',
            style: bodyBold.copyWith(
              fontSize: 14,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Version 2.1.0',
            style: caption.copyWith(
              fontSize: 12,
              color: widget.theme.subtextColor,
            ),
          ),
          SizedBox(height: spacingSmall),
          Text(
            '© 2024 MSWD Philippines',
            style: caption.copyWith(
              fontSize: 11,
              color: widget.theme.subtextColor.withOpacity(0.7),
            ),
          ),
        ],
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
            onPressed: () {
              Navigator.pop(context);
              _showSnackbar('Logged out successfully');
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