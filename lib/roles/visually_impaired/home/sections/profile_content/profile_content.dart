// File: lib/roles/visually_impaired/home/sections/profile_content.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/screens/onboarding_screen.dart';
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

class _ProfileContentState extends State<ProfileContent> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
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
            // Personal Information Section
            _buildSectionTitle('Personal Information', Icons.person_rounded),
            SizedBox(height: spacingMedium),
            _buildPersonalInfoGrid(),
            
            SizedBox(height: spacingXLarge),
            
            // Medical & Disability Information
            _buildSectionTitle('Medical Information', Icons.medical_information_rounded),
            SizedBox(height: spacingMedium),
            _buildMedicalInfoGrid(),
            
            SizedBox(height: spacingXLarge),
            
            // Contact & Emergency
            _buildSectionTitle('Contact & Emergency', Icons.phone_in_talk_rounded),
            SizedBox(height: spacingMedium),
            _buildContactGrid(),
            
            SizedBox(height: spacingXLarge),
            
            // Caretaker Information
            _buildSectionTitle('Caretaker Status', Icons.support_agent_rounded),
            SizedBox(height: spacingMedium),
            _buildCaretakerStatus(),
            
            SizedBox(height: spacingXLarge),
            
            // Account Actions
            _buildSectionTitle('Account Actions', Icons.tune_rounded),
            SizedBox(height: spacingMedium),
            
            _buildActionMenuItem(
              'Update Profile',
              'Edit your personal information',
              Icons.edit_rounded,
              primary,
              onTap: () => _showSnackbar('Update profile feature coming soon'),
            ),
            
            SizedBox(height: spacingSmall),
            
            _buildActionMenuItem(
              'Change Password',
              'Update your account password',
              Icons.lock_reset_rounded,
              accent,
              onTap: () => _showSnackbar('Change password feature coming soon'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Preferences Section
            _buildSectionTitle('Preferences', Icons.settings_rounded),
            SizedBox(height: spacingMedium),
            
            _buildActionMenuItem(
              'Notification Settings',
              'Manage alerts and notifications',
              Icons.notifications_rounded,
              Colors.blue,
              onTap: () => _showSnackbar('Notification settings coming soon'),
            ),
            
            SizedBox(height: spacingSmall),
            
            _buildActionMenuItem(
              'Accessibility Settings',
              'Voice speed, text size, and more',
              Icons.accessibility_rounded,
              Colors.teal,
              onTap: () => _showSnackbar('Accessibility settings coming soon'),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Danger Zone
            _buildSectionTitle('Danger Zone', Icons.warning_amber_rounded),
            SizedBox(height: spacingMedium),
            
            _buildActionMenuItem(
              'Sign Out',
              'Log out of your account',
              Icons.logout_rounded,
              error,
              onTap: () => _showLogoutDialog(),
            ),
            
            SizedBox(height: spacingSmall),
           
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoGrid() {
    final name = widget.userData['name'] ?? 'Not provided';
    final email = widget.userData['email'] ?? 'Not provided';
    final age = widget.userData['age'] ?? 0;
    final sex = widget.userData['sex'] ?? 'Not specified';
    final contactNumber = widget.userData['contactNumber'] ?? 'Not provided';
    final address = widget.userData['address'] ?? 'Not provided';
    final idNumber = widget.userData['idNumber'] ?? '';
    
    String formattedBirthdate = '';
    final birthdateStr = widget.userData['birthdate'] ?? '';
    if (birthdateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(birthdateStr);
        formattedBirthdate = DateFormat('MMMM dd, yyyy').format(date);
      } catch (e) {
        formattedBirthdate = birthdateStr;
      }
    }

    return Column(
      children: [
        _buildInfoMenuItem(
          'Full Name',
          name,
          Icons.person_outline_rounded,
          primary,
        ),
        _buildInfoMenuItem(
          'Email Address',
          email,
          Icons.email_outlined,
          accent,
        ),
        _buildInfoMenuItem(
          'Age',
          age > 0 ? '$age years old' : 'Not specified',
          Icons.cake_outlined,
          Colors.orange,
        ),
        _buildInfoMenuItem(
          'Sex',
          sex,
          Icons.wc_outlined,
          Colors.purple,
        ),
        if (formattedBirthdate.isNotEmpty)
          _buildInfoMenuItem(
            'Birthdate',
            formattedBirthdate,
            Icons.calendar_today_outlined,
            Colors.pink,
          ),
        _buildInfoMenuItem(
          'Contact Number',
          contactNumber,
          Icons.phone_outlined,
          Colors.green,
        ),
        _buildInfoMenuItem(
          'Address',
          address,
          Icons.home_outlined,
          Colors.blue,
        ),
        if (idNumber.isNotEmpty)
          _buildInfoMenuItem(
            'ID Number',
            idNumber,
            Icons.badge_outlined,
            Colors.indigo,
          ),
      ],
    );
  }

  Widget _buildMedicalInfoGrid() {
    final disabilityType = widget.userData['disabilityType'] ?? 'Visual Impairment';
    final diagnosis = widget.userData['diagnosis'] ?? 'Not provided';

    return Column(
      children: [
        _buildInfoMenuItem(
          'Type of Disability',
          disabilityType,
          Icons.accessible_outlined,
          error,
        ),
        _buildInfoMenuItem(
          'Diagnosis',
          diagnosis,
          Icons.medical_information_outlined,
          Colors.red.shade400,
        ),
        Container(
          padding: EdgeInsets.all(spacingLarge),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
              ? error.withOpacity(0.12)
              : error.withOpacity(0.06),
            borderRadius: BorderRadius.circular(radiusLarge),
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
                      'Keep Updated',
                      style: bodyBold.copyWith(
                        fontSize: 14,
                        color: widget.theme.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ensure your medical information is current for emergency situations',
                      style: caption.copyWith(
                        fontSize: 12,
                        color: widget.theme.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactGrid() {
    final contactNumber = widget.userData['contactNumber'] ?? 'Not provided';
    final email = widget.userData['email'] ?? 'Not provided';

    return Column(
      children: [
        _buildInfoMenuItem(
          'Primary Phone',
          contactNumber,
          Icons.phone_in_talk_rounded,
          Colors.green,
        ),
        _buildInfoMenuItem(
          'Email',
          email,
          Icons.email_rounded,
          accent,
        ),
        _buildInfoMenuItem(
          'Emergency Contacts',
          'Manage your emergency list',
          Icons.sos_rounded,
          error,
        ),
      ],
    );
  }

  Widget _buildCaretakerStatus() {
    final assignedCaretakers = widget.userData['assignedCaretakers'] as Map?;
    final caretakerCount = assignedCaretakers?.length ?? 0;

    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: widget.isDarkMode
              ? primary.withOpacity(0.2)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Icon(Icons.people_rounded, color: primary, size: 20),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Caretakers',
                      style: bodyBold.copyWith(
                        fontSize: 15,
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      caretakerCount > 0
                          ? '$caretakerCount caretaker${caretakerCount != 1 ? 's' : ''} assigned'
                          : 'No caretakers assigned yet',
                      style: caption.copyWith(
                        fontSize: 13,
                        color: widget.theme.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: caretakerCount > 0 
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radiusSmall),
                ),
                child: Text(
                  caretakerCount > 0 ? 'Active' : 'Pending',
                  style: caption.copyWith(
                    fontSize: 11,
                    color: caretakerCount > 0 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMenuItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Container(
        padding: EdgeInsets.all(spacingMedium),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          border: Border.all(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.06),
            width: 1,
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(radiusMedium),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 22),
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: caption.copyWith(
                      fontSize: 12,
                      color: widget.theme.subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    value,
                    style: bodyBold.copyWith(
                      fontSize: 15,
                      color: widget.theme.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenuItem(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
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
            width: 1,
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
                        Text(
                          title,
                          style: bodyBold.copyWith(
                            fontSize: 15,
                            color: isDestructive
                                ? Colors.red
                                : widget.theme.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
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
            Icon(Icons.logout_rounded, color: error, size: 24),
            SizedBox(width: spacingSmall),
            Text(
              'Sign Out',
              style: h2.copyWith(
                fontSize: 18,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w700,
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
                          'Successfully signed out',
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
  }
}