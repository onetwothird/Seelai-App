// File: lib/roles/mswd/home/sections/mswd_profile_content.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';

class MSWDProfileContent extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isDarkMode;
  final dynamic theme;

  const MSWDProfileContent({
    super.key,
    required this.userData,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        children: [
          // Profile Header Card
          _buildProfileHeader(width),
          
          SizedBox(height: spacingLarge),
          
          // Personal Information
          _buildSectionHeader('Personal Information', Icons.person_outline_rounded),
          
          SizedBox(height: spacingMedium),
          
          _buildInfoCard([
            _InfoItem(
              icon: Icons.person_outline,
              label: 'Full Name',
              value: userData['name'] ?? 'N/A',
            ),
            _InfoItem(
              icon: Icons.cake_outlined,
              label: 'Age',
              value: '${userData['age'] ?? 'N/A'} years old',
            ),
            _InfoItem(
              icon: Icons.email_outlined,
              label: 'Email',
              value: userData['email'] ?? 'N/A',
            ),
          ]),
          
          SizedBox(height: spacingXLarge),
          
          // Staff Information
          _buildSectionHeader('Staff Information', Icons.badge_outlined),
          
          SizedBox(height: spacingMedium),
          
          _buildInfoCard([
            _InfoItem(
              icon: Icons.business_outlined,
              label: 'Department',
              value: userData['department'] ?? 'N/A',
            ),
            _InfoItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Role',
              value: 'MSWD Staff',
            ),
            _InfoItem(
              icon: Icons.verified_outlined,
              label: 'Status',
              value: 'Active',
            ),
          ]),
          
          SizedBox(height: spacingXLarge),
          
          // Account Actions
          _buildSectionHeader('Account Actions', Icons.settings_outlined),
          
          SizedBox(height: spacingMedium),
          
          _buildActionButton(
            icon: Icons.edit_outlined,
            label: 'Update Profile',
            subtitle: 'Edit your personal information',
            color: primary,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Update profile feature coming soon'),
                  backgroundColor: primary,
                ),
              );
            },
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildActionButton(
            icon: Icons.lock_reset_outlined,
            label: 'Change Password',
            subtitle: 'Update your account password',
            color: accent,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Change password feature coming soon'),
                  backgroundColor: accent,
                ),
              );
            },
          ),
          
          SizedBox(height: spacingXLarge),
          
          // Danger Zone
          _buildSectionHeader('Danger Zone', Icons.warning_amber_rounded),
          
          SizedBox(height: spacingMedium),
          
          _buildActionButton(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            subtitle: 'Log out of your account',
            color: error,
            onTap: () async {
              final confirm = await _showConfirmDialog(
                context,
                'Sign Out',
                'Are you sure you want to sign out?',
              );
              
              if (confirm == true) {
                await authService.value.signOut();
              }
            },
          ),
          
          SizedBox(height: spacingLarge),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(double width) {
    final userName = userData['name'] ?? 'User';
    final userEmail = userData['email'] ?? '';
    final department = userData['department'] ?? '';
    
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        gradient: isDarkMode 
          ? LinearGradient(
              colors: [
                primary.withOpacity(0.3),
                accent.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : primaryGradient,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ]
          : glowShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacingMedium + 2),
            decoration: BoxDecoration(
              color: white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: white.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 36,
              color: white,
            ),
          ),
          
          SizedBox(width: spacingMedium),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: h2.copyWith(
                    fontSize: 20,
                    color: white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  userEmail,
                  style: body.copyWith(
                    fontSize: 13,
                    color: white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (department.isNotEmpty) ...[
                  SizedBox(height: spacingSmall),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacingSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(radiusSmall),
                      border: Border.all(color: white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business_outlined, color: white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          department,
                          style: caption.copyWith(
                            color: white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(spacingSmall),
          decoration: BoxDecoration(
            gradient: primaryGradient,
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          child: Icon(icon, color: white, size: 18),
        ),
        SizedBox(width: spacingSmall),
        Text(
          title,
          style: bodyBold.copyWith(
            fontSize: 18,
            color: theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.15),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ]
          : softShadow,
        border: isDarkMode 
          ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
          : Border.all(color: greyLighter.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildInfoRow(items[i]),
            if (i < items.length - 1) ...[
              SizedBox(height: spacingMedium),
              Divider(
                height: 1,
                color: theme.subtextColor.withOpacity(0.2),
              ),
              SizedBox(height: spacingMedium),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(spacingSmall),
          decoration: BoxDecoration(
            color: isDarkMode 
              ? primary.withOpacity(0.2)
              : primaryLight.withOpacity(0.15),
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          child: Icon(
            item.icon,
            size: 20,
            color: isDarkMode ? primaryLight : primary,
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: caption.copyWith(
                  fontSize: 12,
                  color: theme.subtextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                item.value,
                style: bodyBold.copyWith(
                  fontSize: 15,
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ]
          : softShadow,
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusLarge),
          splashColor: color.withOpacity(0.2),
          child: Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radiusLarge),
              border: isDarkMode 
                ? Border.all(color: color.withOpacity(0.4), width: 1.5)
                : Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: bodyBold.copyWith(
                          fontSize: 16,
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: caption.copyWith(
                          fontSize: 13,
                          color: theme.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: primary),
            SizedBox(width: spacingSmall),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: white,
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}