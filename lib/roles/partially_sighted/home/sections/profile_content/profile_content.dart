// File: lib/roles/visually_impaired/home/sections/profile_content.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/firebase/database_service.dart';
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
  // Local state to handle immediate UI updates
  late Map<String, dynamic> _currentData;

  // Controllers for Edit Profile
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _diagnosisController = TextEditingController();
  String? _selectedSex;

  // Controllers for Change Password
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // --- Color Palette (Matched with MSWD & Caretaker) ---
  final Color _colVerifications = const Color(0xFF3B82F6); // Blue (Personal)
  final Color _colTracking = const Color(0xFF8B5CF6);      // Purple (Medical/Caretaker)
  final Color _colComms = const Color(0xFFF59E0B);         // Amber (Contact)
  final Color _colSafety = const Color(0xFFEF4444);        // Red (Danger)
  // final Color _colAdmin = const Color(0xFF64748B);      // Slate (Unused here)
  final Color _colSupport = const Color(0xFF06B6D4);       // Cyan (Support)
  final Color _colSecurity = const Color(0xFF10B981);      // Green (Account)

  @override
  void initState() {
    super.initState();
    _currentData = Map<String, dynamic>.from(widget.userData);
  }

  @override
  void didUpdateWidget(covariant ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData) {
      setState(() {
        _currentData = Map<String, dynamic>.from(widget.userData);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _diagnosisController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
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
            // ==================== PERSONAL INFORMATION (Blue) ====================
            _buildSectionTitle('Personal Information', Icons.person_rounded, _colVerifications),
            SizedBox(height: spacingMedium),
            _buildPersonalInfoGrid(),
            
            SizedBox(height: spacingXLarge),
            
            // ==================== MEDICAL INFORMATION (Purple) ====================
            _buildSectionTitle('Medical Information', Icons.medical_information_rounded, _colTracking),
            SizedBox(height: spacingMedium),
            _buildMedicalInfoGrid(),
            
            SizedBox(height: spacingXLarge),
            
            // ==================== CONTACT & EMERGENCY (Amber) ====================
            _buildSectionTitle('Contact & Emergency', Icons.phone_in_talk_rounded, _colComms),
            SizedBox(height: spacingMedium),
            _buildContactGrid(),
            
            SizedBox(height: spacingXLarge),
            
            // ==================== CARETAKER STATUS (Purple) ====================
            _buildSectionTitle('Caretaker Status', Icons.support_agent_rounded, _colTracking),
            SizedBox(height: spacingMedium),
            _buildCaretakerStatus(),
            
            SizedBox(height: spacingXLarge),
            
            // ==================== ACCOUNT ACTIONS (Green) ====================
            _buildSectionTitle('Account Actions', Icons.tune_rounded, _colSecurity),
            SizedBox(height: spacingMedium),
            
            _buildActionMenuItem(
              'Update Profile',
              'Edit your personal information',
              Icons.edit_rounded,
              _colSecurity,
              onTap: () => _showEditProfileDialog(),
            ),
            
            SizedBox(height: spacingSmall),
            
            _buildActionMenuItem(
              'Change Password',
              'Update your account password',
              Icons.lock_reset_rounded,
              _colSecurity,
              onTap: () => _showChangePasswordDialog(),
            ),
            
            SizedBox(height: spacingLarge),
            
            // ==================== SUPPORT & INFO (Cyan) ====================
            _buildSectionTitle('Support & Information', Icons.info_outline_rounded, _colSupport),
            SizedBox(height: spacingMedium),
            
            _buildActionMenuItem(
              'How to Use Seelai',
              'Watch tutorial & features tour',
              Icons.play_circle_fill_rounded, 
              _colSupport,
              onTap: () => _showAppGuideDialog(),
            ),

            SizedBox(height: spacingSmall),
            
            _buildActionMenuItem(
              'About Seelai',
              'App version and info',
              Icons.perm_device_information_rounded,
              _colSupport,
              onTap: () => _showAboutDialog(),
            ),
            
            SizedBox(height: spacingSmall),
            
            _buildActionMenuItem(
              'Privacy Policy',
              'Data usage and terms',
              Icons.privacy_tip_rounded,
              _colSupport,
              onTap: () => _showPrivacyDialog(),
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
              onTap: () => _showLogoutDialog(),
            ),
            
            SizedBox(height: spacingSmall),
          ],
        ),
      ),
    );
  }

  // ==================== DIALOGS & ACTIONS ====================

  void _showEditProfileDialog() {
    _nameController.text = _currentData['name'] ?? '';
    _addressController.text = _currentData['address'] ?? '';
    _contactController.text = _currentData['contactNumber'] ?? '';
    _diagnosisController.text = _currentData['diagnosis'] ?? '';
    _selectedSex = _currentData['sex'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: widget.theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Update Profile', style: h3.copyWith(color: widget.theme.textColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField('Full Name', _nameController, Icons.person, focusColor: _colSecurity),
                    SizedBox(height: spacingMedium),
                    _buildTextField('Address', _addressController, Icons.home, focusColor: _colSecurity),
                    SizedBox(height: spacingMedium),
                    _buildTextField('Contact Number', _contactController, Icons.phone, isNumber: true, focusColor: _colSecurity),
                    SizedBox(height: spacingMedium),
                    _buildTextField('Diagnosis', _diagnosisController, Icons.medical_services, focusColor: _colSecurity),
                    SizedBox(height: spacingMedium),
                    DropdownButtonFormField<String>(
                      value: _selectedSex,
                      dropdownColor: widget.theme.cardColor,
                      decoration: InputDecoration(
                        labelText: 'Sex',
                        labelStyle: TextStyle(color: widget.theme.subtextColor),
                        prefixIcon: Icon(Icons.wc, color: widget.theme.subtextColor),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radiusMedium),
                          borderSide: BorderSide(color: widget.theme.subtextColor.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radiusMedium),
                          borderSide: BorderSide(color: _colSecurity), // Green focus
                        ),
                      ),
                      items: ['Male', 'Female', 'Not Specified']
                          .map((sex) => DropdownMenuItem(
                                value: sex,
                                child: Text(sex, style: TextStyle(color: widget.theme.textColor)),
                              ))
                          .toList(),
                      onChanged: (val) => setStateDialog(() => _selectedSex = val),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colSecurity, // Green Button
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setStateDialog(() => _isLoading = true);
                          try {
                            final userId = authService.value.currentUser?.uid;
                            if (userId == null) throw Exception("User not found");

                            await databaseService.updateUserProfile(
                              userId: userId,
                              role: 'visually_impaired',
                              name: _nameController.text.trim(),
                              address: _addressController.text.trim(),
                              contactNumber: _contactController.text.trim(),
                              diagnosis: _diagnosisController.text.trim(),
                              sex: _selectedSex,
                            );

                            if (mounted) {
                              setState(() {
                                _currentData['name'] = _nameController.text.trim();
                                _currentData['address'] = _addressController.text.trim();
                                _currentData['contactNumber'] = _contactController.text.trim();
                                _currentData['diagnosis'] = _diagnosisController.text.trim();
                                _currentData['sex'] = _selectedSex;
                              });
                            }

                            Navigator.pop(context);
                            _showSnackbar('Profile updated successfully', _colSecurity);
                          } catch (e) {
                            _showSnackbar('Error updating profile: $e', _colSafety);
                          } finally {
                            if (mounted) setStateDialog(() => _isLoading = false);
                          }
                        },
                  child: _isLoading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: white, strokeWidth: 2))
                      : Text('Save', style: TextStyle(color: white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: widget.theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Change Password', style: h3.copyWith(color: widget.theme.textColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You will need to sign in again after changing your password.',
                      style: caption.copyWith(color: widget.theme.subtextColor),
                    ),
                    SizedBox(height: spacingMedium),
                    _buildTextField('Current Password', _currentPasswordController, Icons.lock_outline, isPassword: true, focusColor: _colSecurity),
                    SizedBox(height: spacingMedium),
                    _buildTextField('New Password', _newPasswordController, Icons.lock, isPassword: true, focusColor: _colSecurity),
                    SizedBox(height: spacingMedium),
                    _buildTextField('Confirm Password', _confirmPasswordController, Icons.lock, isPassword: true, focusColor: _colSecurity),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: widget.theme.subtextColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colSecurity, // Green Button
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_newPasswordController.text != _confirmPasswordController.text) {
                            _showSnackbar('New passwords do not match', _colSafety);
                            return;
                          }
                          if (_newPasswordController.text.length < 6) {
                            _showSnackbar('Password must be at least 6 characters', _colSafety);
                            return;
                          }

                          setStateDialog(() => _isLoading = true);
                          try {
                            final email = authService.value.currentUser?.email;
                            if (email == null) throw Exception("Email not found");

                            await authService.value.resetPasswordFromCurrentPassword(
                              email: email,
                              currentPassword: _currentPasswordController.text,
                              newPassword: _newPasswordController.text,
                            );

                            Navigator.pop(context);
                            _showSnackbar('Password changed successfully', _colSecurity);
                          } catch (e) {
                            _showSnackbar('Error: Please check your current password', _colSafety);
                          } finally {
                            if (mounted) setStateDialog(() => _isLoading = false);
                          }
                        },
                  child: _isLoading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: white, strokeWidth: 2))
                      : Text('Update', style: TextStyle(color: white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAppGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        insetPadding: EdgeInsets.all(20),
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
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill_rounded, color: _colSupport, size: 60),
                          SizedBox(height: 12),
                          Text(
                            "Tap to Watch Tutorial", 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
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
                      Text(
                        "Getting Started",
                        style: h3.copyWith(color: widget.theme.textColor),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Watch the video above or check the quick steps below to learn how to navigate Seelai.",
                        style: body.copyWith(color: widget.theme.subtextColor),
                      ),
                      SizedBox(height: 24),
                      
                      _buildGuideStep(
                        icon: Icons.visibility_rounded,
                        color: _colSupport,
                        title: "Object Detection",
                        description: "Point your camera to detect objects.",
                      ),
                      _buildGuideStep(
                        icon: Icons.support_agent_rounded,
                        color: _colSupport,
                        title: "Caretaker Connection",
                        description: "Your caretakers are one tap away.",
                      ),
                      _buildGuideStep(
                        icon: Icons.sos_rounded,
                        color: _colSafety, // Red for SOS
                        title: "SOS Emergency",
                        description: "Triple-tap for immediate help.",
                      ),
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

  Widget _buildGuideStep({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: bodyBold.copyWith(
                    color: widget.theme.textColor,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: caption.copyWith(
                    color: widget.theme.subtextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('About Seelai', style: h3.copyWith(color: widget.theme.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seelai App', style: bodyBold.copyWith(color: widget.theme.textColor)),
            SizedBox(height: 8),
            Text(
              'A companion app designed to empower partially sighted individuals through technology.',
              style: body.copyWith(color: widget.theme.subtextColor),
            ),
            SizedBox(height: 16),
            Text('Version: 1.0.0', style: caption.copyWith(color: widget.theme.subtextColor)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _colSupport)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Privacy Policy', style: h3.copyWith(color: widget.theme.textColor)),
        content: SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. All personal and medical data is securely stored and used solely for the purpose of providing assistance services within the app.',
            style: body.copyWith(color: widget.theme.subtextColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _colSupport)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, bool isPassword = false, Color? focusColor}) {
    final activeColor = focusColor ?? _colVerifications;
    
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      obscureText: isPassword,
      style: TextStyle(color: widget.theme.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: widget.theme.subtextColor),
        prefixIcon: Icon(icon, color: widget.theme.subtextColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: widget.theme.subtextColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: activeColor),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoGrid() {
    final name = _currentData['name'] ?? 'Not provided';
    final email = _currentData['email'] ?? 'Not provided';
    final age = _currentData['age'] ?? 0;
    final sex = _currentData['sex'] ?? 'Not specified';
    final contactNumber = _currentData['contactNumber'] ?? 'Not provided';
    final address = _currentData['address'] ?? 'Not provided';
    final idNumber = _currentData['idNumber'] ?? '';
    
    String formattedBirthdate = '';
    final birthdateStr = _currentData['birthdate'] ?? '';
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
        _buildInfoMenuItem('Full Name', name, Icons.person_outline_rounded, _colVerifications),
        _buildInfoMenuItem('Email Address', email, Icons.email_outlined, _colVerifications),
        _buildInfoMenuItem('Age', age > 0 ? '$age years old' : 'Not specified', Icons.cake_outlined, _colVerifications),
        _buildInfoMenuItem('Sex', sex, Icons.wc_outlined, _colVerifications),
        if (formattedBirthdate.isNotEmpty)
          _buildInfoMenuItem('Birthdate', formattedBirthdate, Icons.calendar_today_outlined, _colVerifications),
        _buildInfoMenuItem('Contact Number', contactNumber, Icons.phone_outlined, _colVerifications),
        _buildInfoMenuItem('Address', address, Icons.home_outlined, _colVerifications),
        if (idNumber.isNotEmpty)
          _buildInfoMenuItem('ID Number', idNumber, Icons.badge_outlined, _colVerifications),
      ],
    );
  }

  Widget _buildMedicalInfoGrid() {
    final disabilityType = _currentData['disabilityType'] ?? 'Visual Impairment';
    final diagnosis = _currentData['diagnosis'] ?? 'Not provided';

    return Column(
      children: [
        _buildInfoMenuItem('Type of Disability', disabilityType, Icons.accessible_outlined, _colTracking),
        _buildInfoMenuItem('Diagnosis', diagnosis, Icons.medical_information_outlined, _colTracking),
        
        // "Keep Updated" Info Box
        Container(
          padding: EdgeInsets.all(spacingLarge),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? _colTracking.withOpacity(0.12) : _colTracking.withOpacity(0.06),
            borderRadius: BorderRadius.circular(radiusLarge),
            border: Border.all(color: _colTracking.withOpacity(0.25), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: _colTracking.withOpacity(0.15), borderRadius: BorderRadius.circular(radiusMedium)),
                child: Icon(Icons.info_outline_rounded, color: _colTracking, size: 20),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Keep Updated', style: bodyBold.copyWith(fontSize: 14, color: widget.theme.textColor)),
                    SizedBox(height: 4),
                    Text('Ensure your medical information is current for emergency situations', style: caption.copyWith(fontSize: 12, color: widget.theme.subtextColor)),
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
    final contactNumber = _currentData['contactNumber'] ?? 'Not provided';
    final email = _currentData['email'] ?? 'Not provided';

    return Column(
      children: [
        _buildInfoMenuItem('Primary Phone', contactNumber, Icons.phone_in_talk_rounded, _colComms),
        _buildInfoMenuItem('Email', email, Icons.email_rounded, _colComms),
        // Emergency List uses Red for distinction
        _buildInfoMenuItem('Emergency Contacts', 'Manage your emergency list', Icons.sos_rounded, _colSafety),
      ],
    );
  }

  Widget _buildCaretakerStatus() {
    final assignedCaretakers = _currentData['assignedCaretakers'] as Map?;
    final caretakerCount = assignedCaretakers?.length ?? 0;
    // Uses Purple to match "Tracking/Monitoring" concept
    final color = _colTracking;

    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(color: widget.isDarkMode ? color.withOpacity(0.2) : Colors.black.withOpacity(0.06), width: 1),
        boxShadow: widget.isDarkMode ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 16, offset: Offset(0, 6))] : softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(radiusMedium)),
                child: Icon(Icons.people_rounded, color: color, size: 20),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned Caretakers', style: bodyBold.copyWith(fontSize: 15, color: widget.theme.textColor, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text(caretakerCount > 0 ? '$caretakerCount caretaker${caretakerCount != 1 ? 's' : ''} assigned' : 'No caretakers assigned yet', style: caption.copyWith(fontSize: 13, color: widget.theme.subtextColor)),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: caretakerCount > 0 ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radiusSmall),
                ),
                child: Text(caretakerCount > 0 ? 'Active' : 'Pending', style: caption.copyWith(fontSize: 11, color: caretakerCount > 0 ? Colors.green : Colors.orange, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMenuItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Container(
        padding: EdgeInsets.all(spacingMedium),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          border: Border.all(
            color: widget.isDarkMode ? color.withOpacity(0.15) : Colors.black.withOpacity(0.05), 
            width: 1
          ),
          boxShadow: widget.isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(radiusMedium),
                border: Border.all(color: color.withOpacity(0.1), width: 1),
              ),
              child: Center(child: Icon(icon, color: color, size: 22)),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: caption.copyWith(fontSize: 12, color: widget.theme.subtextColor, fontWeight: FontWeight.w500)),
                  SizedBox(height: 6),
                  Text(value, style: bodyBold.copyWith(fontSize: 15, color: widget.theme.textColor, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenuItem(String title, String subtitle, IconData icon, Color color, {bool isDestructive = false, required VoidCallback onTap}) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Container(
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          border: Border.all(
            color: widget.isDarkMode 
              ? (isDestructive ? Colors.red.withOpacity(0.3) : color.withOpacity(0.15)) 
              : (isDestructive ? Colors.red.withOpacity(0.15) : Colors.black.withOpacity(0.05)),
            width: 1,
          ),
          boxShadow: widget.isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                    child: Center(child: Icon(icon, color: isDestructive ? Colors.red : color, size: 22)),
                  ),
                  SizedBox(width: spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: bodyBold.copyWith(fontSize: 15, color: isDestructive ? Colors.red : widget.theme.textColor, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text(subtitle, style: caption.copyWith(fontSize: 12, color: widget.theme.subtextColor)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: widget.theme.subtextColor.withOpacity(0.5), size: 16),
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
            )
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        backgroundColor: color,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: error, size: 24),
            SizedBox(width: spacingSmall),
            Text('Sign Out', style: h2.copyWith(fontSize: 18, color: widget.theme.textColor, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text('Are you sure you want to sign out?', style: body.copyWith(fontSize: 14, color: widget.theme.subtextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: widget.theme.subtextColor, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.value.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      SizedBox(width: spacingSmall),
                      Expanded(child: Text('Successfully signed out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                  margin: EdgeInsets.all(spacingMedium),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: error, 
              foregroundColor: Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium))
            ),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}