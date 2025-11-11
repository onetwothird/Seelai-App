// File: lib/roles/visually_impaired/home/sections/profile_content.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:intl/intl.dart';

class ProfileContent extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isDarkMode;
  final dynamic theme;

  const ProfileContent({
    super.key,
    required this.userData,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          
          // Tab Bar
          _buildTabBar(width),
          
          SizedBox(height: spacingLarge),
          
          // Tab Content - Removed fixed height and TabBarView
          if (_selectedTab == 0)
            _buildMyProfileTab(width)
          else if (_selectedTab == 1)
            _buildMedicalInfoTab(width)
          else
            _buildSettingsTab(width),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(double width) {
    final userName = widget.userData['name'] ?? 'User';
    final userEmail = widget.userData['email'] ?? '';
    final idNumber = widget.userData['idNumber'] ?? '';
    
    return Semantics(
      label: 'Profile header for $userName',
      child: Container(
        padding: EdgeInsets.all(spacingLarge),
        decoration: BoxDecoration(
          gradient: widget.isDarkMode 
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
          boxShadow: widget.isDarkMode 
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
            // Avatar
            Container(
              padding: EdgeInsets.all(spacingMedium + 2),
              decoration: BoxDecoration(
                color: white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: white.withOpacity(0.3), width: 2),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 36,
                color: white,
              ),
            ),
            
            SizedBox(width: spacingMedium),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
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
                  
                  // Email
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
                  
                  if (idNumber.isNotEmpty) ...[
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
                          Icon(Icons.badge_outlined, color: white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'ID: $idNumber',
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
      ),
    );
  }

  Widget _buildTabBar(double width) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.15),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ]
          : softShadow,
        border: widget.isDarkMode 
          ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
          : null,
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.person_outline_rounded, 'My Profile'),
          _buildTab(1, Icons.medical_information_outlined, 'Medical'),
          _buildTab(2, Icons.settings_outlined, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    
    return Expanded(
      child: Semantics(
        label: '$label tab',
        selected: isSelected,
        button: true,
        child: GestureDetector(
          onTap: () {
            _tabController.animateTo(index);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.symmetric(vertical: spacingMedium),
            decoration: BoxDecoration(
              gradient: isSelected ? primaryGradient : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(radiusMedium),
              boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected 
                    ? white 
                    : (widget.isDarkMode ? widget.theme.subtextColor : grey),
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected 
                      ? white 
                      : (widget.isDarkMode ? widget.theme.subtextColor : grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyProfileTab(double width) {
    final name = widget.userData['name'] ?? '';
    final sex = widget.userData['sex'] ?? '';
    final age = widget.userData['age'] ?? 0;
    final birthdateStr = widget.userData['birthdate'] ?? '';
    final address = widget.userData['address'] ?? '';
    final contactNumber = widget.userData['contactNumber'] ?? '';
    final email = widget.userData['email'] ?? '';
    
    String formattedBirthdate = '';
    if (birthdateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(birthdateStr);
        formattedBirthdate = DateFormat('MMMM dd, yyyy').format(date);
      } catch (e) {
        formattedBirthdate = birthdateStr;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Personal Information', Icons.info_outline_rounded),
        
        SizedBox(height: spacingMedium),
        
        _buildInfoCard([
          _InfoItem(icon: Icons.person_outline, label: 'Full Name', value: name),
          _InfoItem(icon: Icons.wc_outlined, label: 'Sex', value: sex),
          _InfoItem(icon: Icons.cake_outlined, label: 'Age', value: '$age years old'),
          _InfoItem(icon: Icons.calendar_today_outlined, label: 'Birthdate', value: formattedBirthdate),
        ]),
        
        SizedBox(height: spacingXLarge),
        
        _buildSectionHeader('Contact Information', Icons.contact_phone_rounded),
        
        SizedBox(height: spacingMedium),
        
        _buildInfoCard([
          _InfoItem(icon: Icons.phone_outlined, label: 'Phone Number', value: contactNumber),
          _InfoItem(icon: Icons.email_outlined, label: 'Email', value: email),
          _InfoItem(icon: Icons.home_outlined, label: 'Address', value: address),
        ]),
        
        SizedBox(height: spacingLarge),
      ],
    );
  }

  Widget _buildMedicalInfoTab(double width) {
    final disabilityType = widget.userData['disabilityType'] ?? '';
    final diagnosis = widget.userData['diagnosis'] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Disability Information', Icons.accessible_outlined),
        
        SizedBox(height: spacingMedium),
        
        _buildInfoCard([
          _InfoItem(
            icon: Icons.medical_information_outlined,
            label: 'Type of Disability',
            value: disabilityType,
          ),
          _InfoItem(
            icon: Icons.assignment_outlined,
            label: 'Diagnosis',
            value: diagnosis,
          ),
        ]),
        
        SizedBox(height: spacingXLarge),
        
        // Emergency Notice
        Container(
          padding: EdgeInsets.all(spacingLarge),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
              ? error.withOpacity(0.15)
              : error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(radiusLarge),
            border: Border.all(
              color: error.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacingMedium),
                decoration: BoxDecoration(
                  color: error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Icon(Icons.warning_amber_rounded, color: error, size: 24),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important',
                      style: bodyBold.copyWith(
                        fontSize: 16,
                        color: widget.theme.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Keep your medical information updated for emergency situations.',
                      style: caption.copyWith(
                        fontSize: 13,
                        color: widget.theme.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: spacingLarge),
      ],
    );
  }

  Widget _buildSettingsTab(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Account Actions', Icons.admin_panel_settings_outlined),
        
        SizedBox(height: spacingMedium),
        
        // Update Profile Button
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
        
        // Change Password Button
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
        
        _buildSectionHeader('Danger Zone', Icons.warning_amber_rounded),
        
        SizedBox(height: spacingMedium),
        
        // Sign Out Button
        _buildActionButton(
          icon: Icons.logout_rounded,
          label: 'Sign Out',
          subtitle: 'Log out of your account',
          color: error,
          onTap: () async {
            final confirm = await _showConfirmDialog(
              'Sign Out',
              'Are you sure you want to sign out?',
            );
            
            if (confirm == true) {
              await authService.value.signOut();
            }
          },
        ),
        
        SizedBox(height: spacingMedium),
        
        // Delete Account Button
        _buildActionButton(
          icon: Icons.delete_forever_outlined,
          label: 'Delete Account',
          subtitle: 'Permanently delete your account',
          color: error,
          isDanger: true,
          onTap: () async {
            final confirm = await _showConfirmDialog(
              'Delete Account',
              'This action cannot be undone. Are you sure you want to delete your account?',
              isDanger: true,
            );
            
            if (confirm == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Delete account feature coming soon'),
                  backgroundColor: error,
                ),
              );
            }
          },
        ),
        
        SizedBox(height: spacingLarge),
      ],
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
            color: widget.theme.textColor,
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
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.15),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ]
          : softShadow,
        border: widget.isDarkMode 
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
                color: widget.theme.subtextColor.withOpacity(0.2),
              ),
              SizedBox(height: spacingMedium),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Semantics(
      label: '${item.label}: ${item.value}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(spacingSmall),
            decoration: BoxDecoration(
              color: widget.isDarkMode 
                ? primary.withOpacity(0.2)
                : primaryLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: widget.isDarkMode ? primaryLight : primary,
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
                    color: widget.theme.subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  item.value.isNotEmpty ? item.value : 'Not provided',
                  style: bodyBold.copyWith(
                    fontSize: 15,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Semantics(
      label: '$label button',
      button: true,
      hint: subtitle,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: widget.isDarkMode 
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
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radiusLarge),
            splashColor: color.withOpacity(0.2),
            child: Container(
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                gradient: isDanger 
                  ? LinearGradient(
                      colors: [
                        color.withOpacity(widget.isDarkMode ? 0.25 : 0.1),
                        color.withOpacity(widget.isDarkMode ? 0.15 : 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                borderRadius: BorderRadius.circular(radiusLarge),
                border: widget.isDarkMode 
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
                            color: widget.theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
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
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    String title,
    String message, {
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        title: Row(
          children: [
            Icon(
              isDanger ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
              color: isDanger ? error : primary,
            ),
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
              backgroundColor: isDanger ? error : primary,
              foregroundColor: white,
            ),
            child: Text(isDanger ? 'Delete' : 'Confirm'),
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