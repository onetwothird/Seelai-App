// File: lib/roles/mswd/home/sections/more_content.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';

class MoreContent extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isDarkMode;
  final dynamic theme;
  final VoidCallback onToggleDarkMode;

  const MoreContent({
    super.key,
    required this.userData,
    required this.isDarkMode,
    required this.theme,
    required this.onToggleDarkMode,
  });

  @override
  State<MoreContent> createState() => _MoreContentState();
}

class _MoreContentState extends State<MoreContent> {
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          _buildProfileCard(),
          
          SizedBox(height: spacingXLarge),
          
          // Management Section
          _buildSectionHeader('Management', Icons.admin_panel_settings_rounded),
          SizedBox(height: spacingMedium),
          _buildMenuItem(
            icon: Icons.verified_user_rounded,
            title: 'Verifications',
            subtitle: 'Pending approvals',
            badge: '12',
            badgeColor: Colors.orange,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Verifications coming soon')),
              );
            },
          ),
          SizedBox(height: spacingSmall),
          _buildMenuItem(
            icon: Icons.map_rounded,
            title: 'Location Tracking',
            subtitle: 'Real-time user locations',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Location Tracking coming soon')),
              );
            },
          ),
          SizedBox(height: spacingSmall),
          _buildMenuItem(
            icon: Icons.bar_chart_rounded,
            title: 'Analytics & Reports',
            subtitle: 'View system statistics',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Analytics coming soon')),
              );
            },
          ),
          
          SizedBox(height: spacingXLarge),
          
          // Communications Section
          _buildSectionHeader('Communications', Icons.campaign_rounded),
          SizedBox(height: spacingMedium),
          _buildMenuItem(
            icon: Icons.announcement_rounded,
            title: 'Send Announcement',
            subtitle: 'Broadcast to all users',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Send Announcement coming soon')),
              );
            },
          ),
          SizedBox(height: spacingSmall),
          _buildMenuItem(
            icon: Icons.phone_in_talk_rounded,
            title: 'Emergency Hotlines',
            subtitle: 'Manage hotline directory',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Emergency Hotlines coming soon')),
              );
            },
          ),
          
          SizedBox(height: spacingXLarge),
          
          // System Section
          _buildSectionHeader('System', Icons.settings_rounded),
          SizedBox(height: spacingMedium),
          _buildMenuItem(
            icon: Icons.history_rounded,
            title: 'Audit Logs',
            subtitle: 'System activity logs',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Audit Logs coming soon')),
              );
            },
          ),
          SizedBox(height: spacingSmall),
          _buildMenuItem(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Admin Management',
            subtitle: 'Manage admin users',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Admin Management coming soon')),
              );
            },
          ),
          SizedBox(height: spacingSmall),
          _buildMenuItem(
            icon: widget.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Theme',
            subtitle: widget.isDarkMode ? 'Dark mode' : 'Light mode',
            trailing: Switch(
              value: widget.isDarkMode,
              onChanged: (value) => widget.onToggleDarkMode(),
              activeColor: primary,
            ),
            onTap: widget.onToggleDarkMode,
          ),
          
          SizedBox(height: spacingXLarge),
          
          // Account Section
          _buildSectionHeader('Account', Icons.person_rounded),
          SizedBox(height: spacingMedium),
          _buildMenuItem(
            icon: Icons.edit_rounded,
            title: 'Edit Profile',
            subtitle: 'Update your information',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Edit Profile coming soon')),
              );
            },
          ),
          SizedBox(height: spacingSmall),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'Log out of your account',
            color: error,
            onTap: () => _showSignOutDialog(),
          ),
          
          SizedBox(height: spacingLarge),
          
          // App Version
          Center(
            child: Text(
              'SeelAI MSWD Portal v1.0.0',
              style: caption.copyWith(
                fontSize: 12,
                color: widget.theme.subtextColor.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final name = widget.userData['name'] ?? 'Admin';
    final email = widget.userData['email'] ?? '';
    final department = widget.userData['department'] ?? 'MSWD Staff';
    final profileImageUrl = widget.userData['profileImageUrl'] as String?;

    return Container(
      padding: EdgeInsets.all(spacingLarge * 1.2),
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: white, width: 3),
            ),
            child: ClipOval(
              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar(name);
                      },
                    )
                  : _buildDefaultAvatar(name),
            ),
          ),
          SizedBox(width: spacingLarge),
          
          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: h2.copyWith(
                    fontSize: 20,
                    color: white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  department,
                  style: bodyBold.copyWith(
                    fontSize: 13,
                    color: white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  email,
                  style: caption.copyWith(
                    fontSize: 12,
                    color: white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Edit button
          Container(
            padding: EdgeInsets.all(spacingSmall),
            decoration: BoxDecoration(
              color: white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_rounded,
              color: white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    String initials = '';
    if (name.isNotEmpty) {
      List<String> parts = name.trim().split(' ');
      if (parts.length >= 2) {
        initials = parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
      } else {
        initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withOpacity(0.8),
            primary.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
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
          title,
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    Color? color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final itemColor = color ?? primary;

    return Container(
      decoration: BoxDecoration(
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: itemColor.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      child: Material(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusLarge),
          splashColor: itemColor.withOpacity(0.1),
          child: Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radiusLarge),
              border: widget.isDarkMode
                  ? Border.all(color: itemColor.withOpacity(0.2), width: 1)
                  : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  child: Icon(icon, color: itemColor, size: 22),
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
                                color: widget.theme.textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: spacingSmall,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor ?? error,
                                borderRadius: BorderRadius.circular(radiusSmall),
                              ),
                              child: Text(
                                badge,
                                style: caption.copyWith(
                                  fontSize: 11,
                                  color: white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: caption.copyWith(
                          fontSize: 13,
                          color: widget.theme.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacingSmall),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: widget.theme.subtextColor,
                      size: 20,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: error),
            SizedBox(width: spacingSmall),
            Text(
              'Sign Out',
              style: bodyBold.copyWith(
                fontSize: 18,
                color: widget.theme.textColor,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: body.copyWith(
            fontSize: 14,
            color: widget.theme.subtextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: bodyBold.copyWith(color: widget.theme.subtextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: error,
              foregroundColor: white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
              ),
            ),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authService.value.signOut();
    }
  }
}