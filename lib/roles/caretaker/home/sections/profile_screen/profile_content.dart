// File: lib/roles/caretaker/home/sections/profile_screen/profile_content.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
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
  late Map<String, dynamic> _userData;
  
  // --- Color Palette (Matched with MoreContent) ---
  final Color _colVerifications = const Color(0xFF3B82F6); // Blue
  final Color _colTracking = const Color(0xFF8B5CF6);      // Purple 
  final Color _colSafety = const Color(0xFFEF4444);        // Red
  final Color _colSupport = const Color(0xFF06B6D4);       // Cyan
  final Color _colSecurity = const Color(0xFF10B981);      // Emerald Green

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
  }

  Future<void> _refreshUserData() async {
    if (databaseService.currentUserId != null) {
      final freshData = await databaseService.getUserDataByRole(
        databaseService.currentUserId!,
        'caretaker',
      );
      if (freshData != null && mounted) {
        setState(() {
          _userData = freshData;
        });
      }
    }
  }

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
          // ==================== PERSONAL INFORMATION (Blue) ====================
          _buildSectionTitle('Personal Information', Icons.person_rounded, _colVerifications),
          SizedBox(height: spacingMedium),
          
          _buildInfoMenuItem(
            'Full Name',
            _userData['name'] ?? 'Not provided',
            Icons.person_outline_rounded,
            _colVerifications, 
          ),
          _buildInfoMenuItem(
            'Email Address',
            _userData['email'] ?? 'Not provided',
            Icons.email_outlined,
            _colVerifications,
          ),
          _buildInfoMenuItem(
            'Phone Number',
            _userData['phone'] ?? _userData['contactNumber'] ?? 'Not provided',
            Icons.phone_outlined,
            _colVerifications,
          ),
          _buildInfoMenuItem(
            'Relationship',
            _userData['relationship'] ?? 'Not specified',
            Icons.people_outline_rounded,
            _colVerifications,
          ),

          SizedBox(height: spacingXLarge),

          // ==================== DEMOGRAPHIC INFORMATION (Purple) ====================
          _buildSectionTitle('Demographic Information', Icons.info_outline_rounded, _colTracking),
          SizedBox(height: spacingMedium),
          
          _buildInfoMenuItem(
            'Age',
            _userData['age'] != null && _userData['age'] > 0
                ? '${_userData['age']} years old'
                : 'Not specified',
            Icons.cake_outlined,
            _colTracking,
          ),
          _buildInfoMenuItem(
            'Gender',
            _userData['sex'] ?? 'Not specified',
            Icons.wc_outlined,
            _colTracking,
          ),
          if (_userData['birthdate'] != null && _userData['birthdate'].isNotEmpty)
            _buildInfoMenuItem(
              'Date of Birth',
              _formatBirthdate(_userData['birthdate']),
              Icons.calendar_today_outlined,
              _colTracking,
            ),

          SizedBox(height: spacingXLarge),

          // ==================== ACCOUNT ACTIONS (Emerald Green) ====================
          _buildSectionTitle('Account Actions', Icons.tune_rounded, _colSecurity),
          SizedBox(height: spacingMedium),
          
          _buildActionMenuItem(
            'Edit Profile',
            'Update your personal information',
            Icons.edit_rounded,
            _colSecurity,
            onTap: _showEditProfileDialog,
          ),
          
          SizedBox(height: spacingSmall),

          _buildActionMenuItem(
            'Change Password',
            'Update your account password',
            Icons.lock_reset_rounded,
            _colSecurity,
            onTap: _showChangePasswordDialog,
          ),
          
          SizedBox(height: spacingLarge),

          // ==================== SUPPORT & INFO (Cyan) ====================
          _buildSectionTitle('Support & Information', Icons.info_outline_rounded, _colSupport),
          SizedBox(height: spacingMedium),
          
          _buildActionMenuItem(
            'How to Use App',
            'Watch tutorial & features tour',
            Icons.play_circle_fill_rounded,
            _colSupport,
            onTap: _showHowToUseDialog,
          ),
          
          SizedBox(height: spacingSmall),
          
          _buildActionMenuItem(
            'Privacy Policy',
            'Data usage and protection',
            Icons.privacy_tip_rounded,
            _colSupport,
            onTap: () => _showInfoDialog(
              'Privacy Policy', 
              'This application collects minimal data required to assist visually impaired individuals. Your location data is shared only with your assigned patients during active monitoring.'
            ),
          ),
          
          SizedBox(height: spacingSmall),
          
          _buildActionMenuItem(
            'Terms of Service',
            'Rules and regulations',
            Icons.description_rounded,
            _colSupport,
            onTap: () => _showInfoDialog(
              'Terms of Service', 
              'By using this app, you agree to act responsibly as a caretaker and respond to emergency alerts promptly.'
            ),
          ),

          SizedBox(height: spacingLarge),

          // ==================== DANGER ZONE (Red) ====================
          _buildSectionTitle('Danger Zone', Icons.warning_amber_rounded, _colSafety),
          SizedBox(height: spacingMedium),
          
          _buildActionMenuItem(
            'Sign Out',
            'Log out of your account',
            Icons.logout_rounded,
            _colSafety, 
            isDestructive: true,
            onTap: () async {
              final confirm = await _showConfirmDialog(
                'Sign Out',
                'Are you sure you want to sign out?',
              );

              if (confirm == true) {
                await authService.value.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
          ),
          SizedBox(height: spacingSmall),
        ],
      ),
    );
  }

  // ==================== WIDGET BUILDERS ====================

  /// Standardized Info Item
  Widget _buildInfoMenuItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Container(
        padding: EdgeInsets.all(spacingMedium),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          border: Border.all(
            color: widget.isDarkMode 
              ? color.withOpacity(0.3) 
              : Colors.black.withOpacity(0.06), 
            width: 1
          ),
          boxShadow: widget.isDarkMode ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(radiusMedium)
              ),
              child: Center(child: Icon(icon, color: color, size: 22)),
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
                      fontWeight: FontWeight.w500
                    )
                  ),
                  SizedBox(height: 6),
                  Text(
                    value, 
                    style: bodyBold.copyWith(
                      fontSize: 15, 
                      color: widget.theme.textColor, 
                      fontWeight: FontWeight.w600
                    ), 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Standardized Action Button
  Widget _buildActionMenuItem(
    String title, 
    String subtitle, 
    IconData icon, 
    Color color, {
    bool isDestructive = false, 
    required VoidCallback onTap
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Container(
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          border: Border.all(
            color: widget.isDarkMode 
              ? (isDestructive ? Colors.red.withOpacity(0.3) : color.withOpacity(0.3)) 
              : (isDestructive ? Colors.red.withOpacity(0.2) : Colors.black.withOpacity(0.06)),
            width: 1,
          ),
          boxShadow: widget.isDarkMode ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
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
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isDestructive ? Colors.red.withOpacity(0.1) : color.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(radiusMedium)
                    ),
                    child: Center(
                      child: Icon(icon, color: isDestructive ? Colors.red : color, size: 22)
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
                            color: isDestructive ? Colors.red : widget.theme.textColor, 
                            fontWeight: FontWeight.w600
                          )
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle, 
                          style: caption.copyWith(fontSize: 12, color: widget.theme.subtextColor)
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded, 
                    color: widget.theme.subtextColor.withOpacity(0.5), 
                    size: 16
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(radiusSmall)
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: spacingSmall),
          Text(
            title.toUpperCase(),
            style: caption.copyWith(
              fontSize: 11,
              color: widget.theme.subtextColor.withOpacity(0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FEATURES IMPLEMENTATION ====================

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userData['name']);
    final phoneController = TextEditingController(text: _userData['phone'] ?? _userData['contactNumber']);
    final relationshipController = TextEditingController(text: _userData['relationship']);
    final ageController = TextEditingController(text: _userData['age']?.toString() ?? '');
    final sexController = TextEditingController(text: _userData['sex'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        title: Text('Edit Profile', style: bodyBold.copyWith(color: widget.theme.textColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Full Name', nameController, Icons.person, focusColor: _colSecurity),
              SizedBox(height: spacingMedium),
              _buildTextField('Phone Number', phoneController, Icons.phone, inputType: TextInputType.phone, focusColor: _colSecurity),
              SizedBox(height: spacingMedium),
              _buildTextField('Relationship', relationshipController, Icons.people, focusColor: _colSecurity),
              SizedBox(height: spacingMedium),
              Row(
                children: [
                  Expanded(child: _buildTextField('Age', ageController, Icons.cake, inputType: TextInputType.number, focusColor: _colSecurity)),
                  SizedBox(width: spacingMedium),
                  Expanded(child: _buildTextField('Gender', sexController, Icons.wc, focusColor: _colSecurity)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: widget.theme.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await databaseService.updateUserProfile(
                  userId: databaseService.currentUserId!,
                  role: 'caretaker',
                  name: nameController.text,
                  phone: phoneController.text,
                  contactNumber: phoneController.text,
                  relationship: relationshipController.text,
                  age: int.tryParse(ageController.text),
                  sex: sexController.text,
                );
                await _refreshUserData();
                _showSnackbar('Profile updated successfully!', _colSecurity);
              } catch (e) {
                _showSnackbar('Error updating profile: $e', error);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _colSecurity, // Emerald Green
              foregroundColor: white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        title: Text('Change Password', style: bodyBold.copyWith(color: widget.theme.textColor)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Current Password', currentPassController, Icons.lock_outline, isPassword: true, focusColor: _colSecurity),
              SizedBox(height: spacingMedium),
              _buildTextField('New Password', newPassController, Icons.lock, isPassword: true, focusColor: _colSecurity),
              SizedBox(height: spacingMedium),
              _buildTextField('Confirm Password', confirmPassController, Icons.lock_clock, isPassword: true, focusColor: _colSecurity),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: widget.theme.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPassController.text != confirmPassController.text) {
                _showSnackbar('New passwords do not match', error);
                return;
              }
              if (newPassController.text.length < 6) {
                _showSnackbar('Password must be at least 6 characters', error);
                return;
              }
              Navigator.pop(context);
              try {
                await authService.value.resetPasswordFromCurrentPassword(
                  email: _userData['email'],
                  currentPassword: currentPassController.text,
                  newPassword: newPassController.text,
                );
                _showSnackbar('Password changed successfully!', _colSecurity);
              } catch (e) {
                _showSnackbar('Failed to change password. Check current password.', error);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _colSecurity, // Emerald Green
              foregroundColor: white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showHowToUseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        insetPadding: EdgeInsets.all(20),
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
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
                    decoration: BoxDecoration(
                      color: Colors.black, // Video background
                      borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill_rounded, color: white, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Tap to Watch Tutorial',
                            style: TextStyle(color: white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              
              // --- CONTENT ---
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Getting Started', style: h3.copyWith(color: widget.theme.textColor)),
                      SizedBox(height: 8),
                      Text(
                        'Learn how to monitor your patients efficiently.',
                        style: body.copyWith(color: widget.theme.subtextColor)
                      ),
                      SizedBox(height: 24),
                      _buildGuideStep(1, 'Connect with Patients', 'Use the QR scanner or enter a Patient ID to link accounts.', _colSupport),
                      _buildGuideStep(2, 'Dashboard Monitoring', 'View real-time location and status of assigned patients.', _colSupport),
                      _buildGuideStep(3, 'Emergency Alerts', 'Receive instant notifications for SOS requests.', _colSupport),
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
                      backgroundColor: _colSupport,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text("I'm Ready!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        title: Text(title, style: bodyBold.copyWith(color: widget.theme.textColor)),
        content: SingleChildScrollView(child: Text(content, style: TextStyle(fontSize: 14, color: widget.theme.subtextColor))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _colSupport)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: error),
            SizedBox(width: spacingSmall),
            Text(title, style: TextStyle(color: widget.theme.textColor)),
          ],
        ),
        content: Text(message, style: TextStyle(color: widget.theme.subtextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: widget.theme.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: error, foregroundColor: white),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
    Color? focusColor, 
  }) {
    final activeColor = focusColor ?? _colTracking; // Default to purple if not specified
    
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      style: TextStyle(color: widget.theme.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: widget.theme.subtextColor),
        prefixIcon: Icon(icon, size: 20, color: widget.theme.subtextColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: widget.theme.subtextColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: activeColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text('$step', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: widget.theme.textColor)),
                SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 13, color: widget.theme.subtextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatBirthdate(String birthdate) {
    try {
      final date = DateTime.parse(birthdate);
      return DateFormat('MMMM dd, yyyy').format(date);
    } catch (e) {
      return birthdate;
    }
  }
}