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
    
    return Padding(
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        children: [
          
          SizedBox(height: spacingLarge),
          
          // Tab Bar
          _buildTabBar(width),
          
          SizedBox(height: spacingLarge),
          
          // Tab Content
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

  

  Widget _buildTabBar(double width) {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.1),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
        border: widget.isDarkMode 
          ? Border.all(color: primary.withOpacity(0.2), width: 1)
          : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.person_outline_rounded, 'Profile'),
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
                      color: primary.withOpacity(0.25),
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
                  size: 20,
                  color: isSelected 
                    ? white 
                    : widget.theme.subtextColor,
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected 
                      ? white 
                      : widget.theme.subtextColor,
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
    final email = widget.userData['email'] ?? '';
    final idNumber = widget.userData['idNumber'] ?? '';
    final sex = widget.userData['sex'] ?? '';
    final age = widget.userData['age'] ?? 0;
    final birthdateStr = widget.userData['birthdate'] ?? '';
    final address = widget.userData['address'] ?? '';
    final contactNumber = widget.userData['contactNumber'] ?? '';
    
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
        _buildSectionLabel('Personal Information', Icons.person_rounded),
        
        SizedBox(height: spacingMedium),
        
        _buildInfoCard([
          _InfoItem(icon: Icons.person_outline, label: 'Full Name', value: name),
          _InfoItem(icon: Icons.email_outlined, label: 'Email', value: email),
          if (idNumber.isNotEmpty)
            _InfoItem(icon: Icons.badge_outlined, label: 'ID Number', value: idNumber),
          _InfoItem(icon: Icons.wc_outlined, label: 'Sex', value: sex),
          _InfoItem(icon: Icons.cake_outlined, label: 'Age', value: age > 0 ? '$age years old' : 'Not specified'),
          _InfoItem(icon: Icons.calendar_today_outlined, label: 'Birthdate', value: formattedBirthdate),
          _InfoItem(icon: Icons.phone_outlined, label: 'Phone Number', value: contactNumber),
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
        _buildSectionLabel('Disability Information', Icons.accessible_outlined),
        
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
        
        SizedBox(height: spacingLarge),
        
        // Important Notice
        Container(
          padding: EdgeInsets.all(spacingLarge),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
              ? error.withOpacity(0.12)
              : error.withOpacity(0.06),
            borderRadius: BorderRadius.circular(radiusXLarge),
            border: Border.all(
              color: error.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Icon(Icons.info_outline_rounded, color: error, size: 20),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important',
                      style: bodyBold.copyWith(
                        fontSize: 15,
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
        _buildSectionLabel('Account Actions', Icons.tune_rounded),
        
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
        
        SizedBox(height: spacingSmall),
        
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
        
        SizedBox(height: spacingLarge),
        
        _buildSectionLabel('Danger Zone', Icons.warning_amber_rounded),
        
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
        
        SizedBox(height: spacingSmall),
        
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

  Widget _buildSectionLabel(String title, IconData icon) {
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
            fontSize: 14,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w600,
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
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.1),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
        border: Border.all(
          color: widget.isDarkMode
              ? primary.withOpacity(0.2)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildInfoRow(items[i]),
            if (i < items.length - 1) ...[
              SizedBox(height: spacingMedium),
              Divider(
                height: 1,
                color: widget.theme.subtextColor.withOpacity(0.15),
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
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isDarkMode 
                ? primary.withOpacity(0.15)
                : primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
            child: Icon(
              item.icon,
              size: 18,
              color: primary,
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
                  style: body.copyWith(
                    fontSize: 14,
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
                  color: color.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        child: Material(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radiusXLarge),
            splashColor: color.withOpacity(0.2),
            child: Container(
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                gradient: isDanger 
                  ? LinearGradient(
                      colors: [
                        color.withOpacity(widget.isDarkMode ? 0.2 : 0.1),
                        color.withOpacity(widget.isDarkMode ? 0.1 : 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                borderRadius: BorderRadius.circular(radiusXLarge),
                border: Border.all(
                  color: color.withOpacity(widget.isDarkMode ? 0.3 : 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  SizedBox(width: spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: bodyBold.copyWith(
                            fontSize: 15,
                            color: widget.theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: caption.copyWith(
                            fontSize: 12,
                            color: widget.theme.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color,
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

  Future<bool?> _showConfirmDialog(
    String title,
    String message, {
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        title: Row(
          children: [
            Icon(
              isDanger ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
              color: isDanger ? error : primary,
              size: 24,
            ),
            SizedBox(width: spacingSmall),
            Expanded(
              child: Text(
                title,
                style: bodyBold.copyWith(
                  fontSize: 16,
                  color: widget.theme.textColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
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
              style: body.copyWith(color: widget.theme.subtextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? error : primary,
              foregroundColor: white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
              ),
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