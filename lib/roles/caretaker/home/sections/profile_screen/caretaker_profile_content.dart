// File: lib/roles/caretaker/home/sections/profile_screen/caretaker_profile_content.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:intl/intl.dart';
import 'package:seelai_app/screens/onboarding_screen.dart';

import 'package:seelai_app/roles/caretaker/home/sections/profile_screen/about_seelai_screen.dart';
import 'package:seelai_app/roles/caretaker/home/sections/profile_screen/privacy_policy_screen.dart';

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
  bool _isLoading = false;
  
  // --- Color Palette ---
  final Color _colVerifications = const Color(0xFF3B82F6); 
  final Color _colTracking = const Color(0xFF8B5CF6);      
  final Color _colSafety = const Color(0xFFEF4444);        
  final Color _colSupport = const Color(0xFF06B6D4);       
  final Color _primaryColor = const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
  }

  @override
  void didUpdateWidget(covariant ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData) {
      setState(() {
        _userData = Map<String, dynamic>.from(widget.userData);
      });
    }
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
    return Padding(
      // 120 bottom padding ensures the last item clears the bottom navigation bar
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 120.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== PAGE HEADER ====================
          Text(
            'Profile & Settings',
           style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: widget.theme.textColor,
            letterSpacing: -0.5,
          ),
          ),
          const SizedBox(height: 32),

          // ==================== PROFILE IMAGE & NAME ====================
          _buildCenteredProfileImage(),
          const SizedBox(height: 32),
          
          // ==================== PERSONAL INFORMATION ====================
          _buildSettingsGroup(
            title: 'Personal Information',
            children: [
              _buildSettingsTile(
                title: 'Email Address',
                icon: Icons.email_outlined,
                iconColor: _colVerifications,
                value: _userData['email'] ?? 'Not provided',
              ),
              _buildSettingsTile(
                title: 'Phone Number',
                icon: Icons.phone_outlined,
                iconColor: _colVerifications,
                value: _userData['phone'] ?? _userData['contactNumber'] ?? 'Not provided',
              ),
              _buildSettingsTile(
                title: 'Relationship',
                icon: Icons.people_outline_rounded,
                iconColor: _colVerifications,
                value: _userData['relationship']?.toString().isNotEmpty == true 
                    ? _userData['relationship'] 
                    : 'Not specified',
                isLast: true,
              ),
            ],
          ),

          // ==================== DEMOGRAPHIC INFORMATION ====================
          _buildSettingsGroup(
            title: 'Demographic Information',
            children: [
              _buildSettingsTile(
                title: 'Age',
                icon: Icons.cake_outlined,
                iconColor: _colTracking,
                value: _userData['age'] != null && _userData['age'] > 0
                    ? '${_userData['age']} years old'
                    : 'Not specified',
              ),
              _buildSettingsTile(
                title: 'Gender',
                icon: Icons.wc_outlined,
                iconColor: _colTracking,
                value: _userData['sex'] ?? 'Not specified',
              ),
              _buildSettingsTile(
                title: 'Date of Birth',
                icon: Icons.calendar_today_outlined,
                iconColor: _colTracking,
                value: _formatBirthdate(_userData['birthdate'] ?? ''),
                isLast: true,
              ),
            ],
          ),

          // ==================== ACCOUNT & SECURITY ====================
          _buildSettingsGroup(
            title: 'Account Actions',
            children: [
              _buildSettingsTile(
                title: 'Edit Profile',
                icon: Icons.edit_outlined,
                iconColor: _primaryColor,
                onTap: _showEditProfileDialog,
              ),
              _buildSettingsTile(
                title: 'Change Password',
                icon: Icons.lock_outline_rounded,
                iconColor: _primaryColor,
                onTap: _showChangePasswordDialog,
                isLast: true,
              ),
            ],
          ),

          // ==================== SUPPORT & INFO ====================
          _buildSettingsGroup(
            title: 'Support & Information',
            children: [
              _buildSettingsTile(
                title: 'How to Use App',
                icon: Icons.info_outline_rounded,
                iconColor: _colSupport,
                onTap: _showHowToUseDialog,
              ),
              _buildSettingsTile(
                title: 'About Seelai', 
                icon: Icons.info_outline_rounded,
                iconColor: _colSupport,
                onTap: _showAboutDialog, 
              ),
              _buildSettingsTile(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_outlined,
                iconColor: _colSupport,
                onTap: _showPrivacyDialog, 
                isLast: true,
              ),
            ],
          ),

          // ==================== DANGER ZONE ====================
          _buildSettingsGroup(
            title: 'Danger Zone',
            children: [
              _buildSettingsTile(
                title: 'Sign Out',
                icon: Icons.logout_rounded,
                iconColor: _colSafety,
                isDestructive: true,
                onTap: _showLogoutDialog,
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== UI COMPONENTS ====================

  Widget _buildCenteredProfileImage() {
    final profileUrl = _userData['profileImageUrl'] as String?;
    final name = _userData['name'] ?? 'Caretaker';
    final initial = name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?';

    return Center(
      child: Column(
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isDarkMode ? Colors.white24 : Colors.black,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: (profileUrl != null && profileUrl.isNotEmpty)
                  ? Image.network(
                      profileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildGradientFallback(initial);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildGradientFallback('', isLoading: true);
                      },
                    )
                  : _buildGradientFallback(initial),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: widget.theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientFallback(String initial, {bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _colVerifications,
            _colVerifications.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                initial,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSettingsGroup({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.theme.subtextColor.withOpacity(0.8),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isDarkMode 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: widget.isDarkMode 
                  ? [] 
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    String? value,
    VoidCallback? onTap,
    bool isDestructive = false,
    bool isLast = false,
  }) {
    final displayIconColor = isDestructive ? _colSafety : widget.theme.textColor;
    final displayContainerColor = isDestructive 
        ? _colSafety.withValues(alpha: 0.1) 
        : widget.theme.textColor.withValues(alpha: 0.05);

    final textColor = isDestructive ? _colSafety : widget.theme.textColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast 
            ? const BorderRadius.vertical(bottom: Radius.circular(16)) 
            : null,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: displayContainerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: displayIconColor),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    flex: 3,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  
                  if (value != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4, 
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        softWrap: true, 
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.theme.subtextColor,
                        ),
                      ),
                    ),
                  ],
                  
                  if (onTap != null && value == null) ...[
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: widget.theme.subtextColor.withOpacity(0.5),
                    ),
                  ]
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                thickness: 1,
                indent: 56,
                color: widget.isDarkMode 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.black.withValues(alpha: 0.05),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== NEW UI: MODERN TEXT FIELD ====================
  Widget _buildDialogTextField(String label, TextEditingController controller, IconData icon, {
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
    Color? focusColor,
  }) {
    final activeColor = focusColor ?? _primaryColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        obscureText: isPassword,
        style: TextStyle(color: widget.theme.textColor, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: widget.theme.subtextColor, fontSize: 14),
          prefixIcon: Icon(icon, color: widget.theme.subtextColor, size: 22),
          filled: true,
          fillColor: widget.isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: activeColor, width: 2),
          ),
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  String _formatBirthdate(String birthdate) {
    if (birthdate.isEmpty) return 'Not specified';
    try {
      final date = DateTime.parse(birthdate);
      return DateFormat('MMMM dd, yyyy').format(date);
    } catch (e) {
      return birthdate;
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: color,
      ),
    );
  }

  // ==================== NAVIGATION DIALOGS ====================

  void _showAboutDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AboutSeelaiScreen(
          theme: widget.theme,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivacyPolicyScreen(
          theme: widget.theme,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  // ==================== NEW UI: EDIT PROFILE DIALOG ====================

  void _showEditProfileDialog() {
    final parentContext = context; 

    final nameController = TextEditingController(text: _userData['name']);
    final phoneController = TextEditingController(text: _userData['phone'] ?? _userData['contactNumber']);
    final relationshipController = TextEditingController(text: _userData['relationship']);
    final ageController = TextEditingController(text: _userData['age']?.toString() ?? '');
    String? selectedSex = _userData['sex'];

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.transparent),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Update Profile',
                      style: TextStyle(color: widget.theme.textColor, fontWeight: FontWeight.w800, fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Modify your personal and contact details below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: widget.theme.subtextColor, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildDialogTextField('Full Name', nameController, Icons.person_outline, focusColor: _primaryColor),
                    _buildDialogTextField('Phone Number', phoneController, Icons.phone_outlined, inputType: TextInputType.phone, focusColor: _primaryColor),
                    _buildDialogTextField('Relationship', relationshipController, Icons.people_outline, focusColor: _primaryColor),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildDialogTextField('Age', ageController, Icons.cake_outlined, inputType: TextInputType.number, focusColor: _primaryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedSex,
                              dropdownColor: widget.theme.cardColor,
                              icon: Icon(Icons.arrow_drop_down_rounded, color: widget.theme.subtextColor),
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                labelStyle: TextStyle(color: widget.theme.subtextColor, fontSize: 14),
                                prefixIcon: Icon(Icons.wc_outlined, color: widget.theme.subtextColor, size: 22),
                                filled: true,
                                fillColor: widget.isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: _primaryColor, width: 2),
                                ),
                              ),
                              items: ['Male', 'Female', 'Not Specified']
                                  .map((sex) => DropdownMenuItem(value: sex, child: Text(sex, style: TextStyle(color: widget.theme.textColor))))
                                  .toList(),
                              onChanged: (val) => setStateDialog(() => selectedSex = val),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    
                    // Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text('Cancel', style: TextStyle(color: widget.theme.subtextColor, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: widget.isDarkMode ? 0 : 4,
                              shadowColor: _primaryColor.withValues(alpha: 0.4),
                            ),
                            onPressed: _isLoading ? null : () async {
                              setStateDialog(() => _isLoading = true);
                              Navigator.pop(dialogContext);

                              try {
                                await databaseService.updateUserProfile(
                                  userId: databaseService.currentUserId!,
                                  role: 'caretaker',
                                  name: nameController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  contactNumber: phoneController.text.trim(),
                                  relationship: relationshipController.text.trim(),
                                  age: int.tryParse(ageController.text.trim()),
                                  sex: selectedSex,
                                );

                                await _refreshUserData();

                                if (!mounted) return;
                                _showSnackbar('Profile updated successfully', _primaryColor);
                              } catch (e) {
                                if (!mounted) return;
                                _showSnackbar('Error updating profile: $e', _colSafety);
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== NEW UI: CHANGE PASSWORD DIALOG ====================

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.transparent),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Change Password',
                      style: TextStyle(color: widget.theme.textColor, fontWeight: FontWeight.w800, fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: widget.theme.subtextColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'For security, you will be required to sign in again after changing your password.',
                              style: TextStyle(color: widget.theme.subtextColor, fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildDialogTextField('Current Password', currentPassController, Icons.lock_outline, isPassword: true, focusColor: _primaryColor),
                    _buildDialogTextField('New Password', newPassController, Icons.lock_outline, isPassword: true, focusColor: _primaryColor),
                    _buildDialogTextField('Confirm Password', confirmPassController, Icons.lock_outline, isPassword: true, focusColor: _primaryColor),
                    
                    const SizedBox(height: 16),
                    
                    // Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => Navigator.pop(builderContext),
                            child: Text('Cancel', style: TextStyle(color: widget.theme.subtextColor, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: widget.isDarkMode ? 0 : 4,
                              shadowColor: _primaryColor.withValues(alpha: 0.4),
                            ),
                            onPressed: _isLoading ? null : () async {
                              if (newPassController.text != confirmPassController.text) {
                                _showSnackbar('New passwords do not match', _colSafety);
                                return;
                              }
                              if (newPassController.text.length < 6) {
                                _showSnackbar('Password must be at least 6 characters', _colSafety);
                                return;
                              }

                              setStateDialog(() => _isLoading = true);
                              try {
                                await authService.value.resetPasswordFromCurrentPassword(
                                  email: _userData['email'],
                                  currentPassword: currentPassController.text,
                                  newPassword: newPassController.text,
                                );
                                
                                if (!builderContext.mounted) return;
                                Navigator.pop(builderContext);
                                _showSnackbar('Password changed successfully', _primaryColor);
                              } catch (e) {
                                _showSnackbar('Failed to change password. Check current password.', _colSafety);
                              } finally {
                                if (builderContext.mounted) {
                                  setStateDialog(() => _isLoading = false);
                                }
                              }
                            },
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // ==================== NEW UI: LOGOUT DIALOG ====================

  void _showLogoutDialog() {
    final parentContext = context;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.transparent),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sign Out',
                style: TextStyle(color: widget.theme.textColor, fontWeight: FontWeight.w800, fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to sign out?',
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.theme.subtextColor, fontSize: 15),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text('Cancel', style: TextStyle(color: widget.theme.subtextColor, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext); 
                        await authService.value.signOut(); 
                        if (!parentContext.mounted) return;
                        Navigator.of(parentContext).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                          (route) => false,
                        );
                        if (mounted) _showSnackbar('Successfully signed out', _primaryColor);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colSafety,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: widget.isDarkMode ? 0 : 4,
                        shadowColor: _colSafety.withValues(alpha: 0.4),
                      ),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowToUseDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => CaretakerGuideSliderDialog(
        theme: widget.theme,
        isDarkMode: widget.isDarkMode,
      ),
    );
  }
}

// ==================== PREMIUM RESPONSIVE IMAGE SLIDER DIALOG (CARETAKER) ====================
class CaretakerGuideSliderDialog extends StatefulWidget {
  final dynamic theme;
  final bool isDarkMode;

  const CaretakerGuideSliderDialog({
    super.key,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  State<CaretakerGuideSliderDialog> createState() => _CaretakerGuideSliderDialogState();
}

class _CaretakerGuideSliderDialogState extends State<CaretakerGuideSliderDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Color _brandPurple = const Color(0xFF8B5CF6);

  final List<Map<String, String>> _guideData = [
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic1.jpg",
      "title": "Role Selection",
      "description": "Select the Caretaker category to get started."
    },
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic2.jpg",
      "title": "Login",
      "description": "Log in to your existing Seelai account."
    },
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic3.jpg",
      "title": "Register",
      "description": "Fill out your details to create a new account."
    },
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic4.jpg",
      "title": "Dashboard",
      "description": "View statistics for Total Registered patients, Pending, In Progress, and Completed tasks."
    },
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic5.jpg",
      "title": "Assistance & Announcements",
      "description": "View the partially sighted users you handle and check announcements created by MSWD."
    },
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic6.jpg",
      "title": "Voice Call",
      "description": "Initiate or receive clear voice calls with your patients."
    },
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic7.jpg",
      "title": "Video Call",
      "description": "Connect face-to-face with your patients using the video call feature."
    },
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic8.jpg",
      "title": "My Patients",
      "description": "View your patients' age, category, and address. Easily phone call or message them."
    },
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic9.jpg",
      "title": "Patient Profile",
      "description": "View the complete profile information that was listed when the patient registered."
    },
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic10.jpg",
      "title": "Location Tracking",
      "description": "Select a specific patient from your list to view their real-time location."
    },
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic11.jpg",
      "title": "Route & Distance",
      "description": "View the profiles of both users and see the exact route or distance between you."
    },
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic12.jpg",
      "title": "Assistance Requests",
      "description": "Track Pending, Active, History, and Deleted requests along with dashboard statistics."
    },
    {
      "image": "assets/how-to-use-seelai_images/caretaker/pic13.jpg",
      "title": "Manage Requests",
      "description": "Review pending requests to decline, accept, or update their status to in-progress or done."
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _guideData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _guideData.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _guideData.length - 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85, 
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(32), 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 20),
            )
          ],
        ),
        child: Column(
          children: [
            // Header Row (Close Button)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, color: widget.theme.subtextColor, size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Main Carousel Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _guideData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _guideData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        // Image Presentation Area - Transparent Floating Look
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 24),
                            color: Colors.transparent, 
                            child: Padding(
                              padding: const EdgeInsets.all(8.0), 
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  item['image']!,
                                  fit: BoxFit.contain, 
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image_not_supported_rounded, size: 40, color: widget.theme.subtextColor),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Image missing:\n${item['image']}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: widget.theme.subtextColor, fontSize: 12),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '(Check pubspec.yaml)',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: widget.theme.subtextColor, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Text Content Area
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800, 
                            color: widget.theme.textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            item['description']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.theme.subtextColor,
                              height: 1.5, 
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Responsive Bottom Navigation Area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  // Flex Box 1: Skip Button (Takes up left space dynamically)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isLastPage ? 0.0 : 1.0,
                        child: TextButton(
                          onPressed: isLastPage ? null : _skipToEnd,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: widget.theme.subtextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Flex Box 2: Animated Dots (Always perfectly centered)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _guideData.length,
                      (index) {
                        final isActive = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          height: 6,
                          width: isActive ? 18 : 6,
                          decoration: BoxDecoration(
                            color: isActive ? _brandPurple : widget.theme.subtextColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      },
                    ),
                  ),

                  // Flex Box 3: Morphing Next/Done Button (Takes up right space dynamically)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _nextPage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          // Morphs from a circle to a wider pill
                          padding: isLastPage 
                              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                              : const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _brandPurple,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _brandPurple.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: isLastPage
                              ? const Text(
                                  "Done", 
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward_rounded, 
                                  color: Colors.white, 
                                  size: 20
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}