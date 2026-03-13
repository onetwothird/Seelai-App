// File: lib/roles/visually_impaired/home/sections/profile_content.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  bool _isLoading = false;

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

  // Color Palette 
  final Color _colPersonal = const Color(0xFF3B82F6); // Kept for the gradient fallback avatar
  final Color _colSecurity = const Color(0xFF10B981); // Kept for success snackbars/buttons
  final Color _colSupport = const Color(0xFF06B6D4);  
  final Color _colSafety = const Color(0xFFEF4444);   // Kept for Sign Out / SOS

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
    // NO SingleChildScrollView here to prevent scrolling conflicts with home_screen.dart
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
              fontSize: 21,
              fontWeight: FontWeight.bold,
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
                title: 'Phone Number',
                icon: Icons.phone_outlined,
                iconColor: _colPersonal, // Passed but overridden internally for a clean look
                value: _currentData['contactNumber']?.toString().isNotEmpty == true 
                    ? _currentData['contactNumber'] 
                    : 'Not provided',
              ),
              _buildSettingsTile(
                title: 'Address',
                icon: Icons.home_outlined,
                iconColor: _colPersonal,
                value: _currentData['address']?.toString().isNotEmpty == true 
                    ? _currentData['address'] 
                    : 'Not provided',
              ),
              _buildSettingsTile(
                title: 'Birthdate',
                icon: Icons.cake_outlined,
                iconColor: _colPersonal,
                value: _formatDate(_currentData['birthdate']),
              ),
              _buildSettingsTile(
                title: 'Sex',
                icon: Icons.wc_outlined,
                iconColor: _colPersonal,
                value: _currentData['sex'] ?? 'Not specified',
                isLast: true,
              ),
            ],
          ),

          // ==================== MEDICAL & CARE ====================
          _buildSettingsGroup(
            title: 'Medical & Care',
            children: [
              _buildSettingsTile(
                title: 'Disability Type',
                icon: Icons.accessible_outlined,
                iconColor: _colPersonal,
                value: _currentData['disabilityType'] ?? 'Visual Impairment',
              ),
              _buildSettingsTile(
                title: 'Diagnosis',
                icon: Icons.medical_information_outlined,
                iconColor: _colPersonal,
                value: _currentData['diagnosis']?.toString().isNotEmpty == true 
                    ? _currentData['diagnosis'] 
                    : 'Not provided',
              ),
              _buildSettingsTile(
                title: 'Assigned Caretakers',
                icon: Icons.people_outline_rounded,
                iconColor: _colPersonal,
                value: _getCaretakerStatus(),
                isLast: true,
              ),
            ],
          ),

          // ==================== ACCOUNT & SECURITY ====================
          _buildSettingsGroup(
            title: 'Account & Security',
            children: [
              _buildSettingsTile(
                title: 'Update Profile',
                icon: Icons.edit_outlined,
                iconColor: _colPersonal,
                onTap: _showEditProfileDialog,
              ),
              _buildSettingsTile(
                title: 'Change Password',
                icon: Icons.lock_outline_rounded,
                iconColor: _colPersonal,
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
                title: 'How to Use Seelai',
                icon: Icons.play_circle_fill_rounded,
                iconColor: _colPersonal,
                onTap: _showAppGuideDialog,
              ),
              _buildSettingsTile(
                title: 'About Seelai',
                icon: Icons.info_outline_rounded,
                iconColor: _colPersonal,
                onTap: _showAboutDialog,
              ),
              _buildSettingsTile(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_outlined,
                iconColor: _colPersonal,
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
    final profileUrl = _currentData['profileImageUrl'] as String?;
    final name = _currentData['name'] ?? 'User';
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
            _colPersonal,
            _colPersonal.withValues(alpha: 0.6),
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
                  
                  // The title takes up its required space
                  Expanded(
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
                    // THE FIX: Expanded -> Row(end) -> Flexible -> ScrollView
                    Expanded(
                      flex: 2, 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: widget.theme.subtextColor,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  String _formatDate(dynamic dateString) {
    if (dateString == null || dateString.toString().isEmpty) return 'Not specified';
    try {
      final date = DateTime.parse(dateString.toString());
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString.toString();
    }
  }

  String _getCaretakerStatus() {
    final map = _currentData['assignedCaretakers'] as Map?;
    final count = map?.length ?? 0;
    return count > 0 ? '$count Active' : 'None';
  }

  Widget _buildDialogTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, bool isPassword = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      obscureText: isPassword,
      style: TextStyle(color: widget.theme.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: widget.theme.subtextColor),
        prefixIcon: Icon(icon, color: widget.theme.subtextColor),
        filled: true,
        fillColor: widget.isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _colSecurity, width: 1.5),
        ),
      ),
    );
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

  // ==================== DIALOGS ====================

  void _showEditProfileDialog() {
    _nameController.text = _currentData['name'] ?? '';
    _addressController.text = _currentData['address'] ?? '';
    _contactController.text = _currentData['contactNumber'] ?? '';
    _diagnosisController.text = _currentData['diagnosis'] ?? '';
    _selectedSex = _currentData['sex'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setStateDialog) {
            return AlertDialog(
              backgroundColor: widget.theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Update Profile', style: TextStyle(color: widget.theme.textColor, fontWeight: FontWeight.bold, fontSize: 20)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField('Full Name', _nameController, Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildDialogTextField('Address', _addressController, Icons.home_outlined),
                    const SizedBox(height: 16),
                    _buildDialogTextField('Phone Number', _contactController, Icons.phone_outlined, isNumber: true),
                    const SizedBox(height: 16),
                    _buildDialogTextField('Diagnosis', _diagnosisController, Icons.medical_services_outlined),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSex,
                      dropdownColor: widget.theme.cardColor,
                      decoration: InputDecoration(
                        labelText: 'Sex',
                        labelStyle: TextStyle(color: widget.theme.subtextColor),
                        prefixIcon: Icon(Icons.wc_outlined, color: widget.theme.subtextColor),
                        filled: true,
                        fillColor: widget.isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: ['Male', 'Female', 'Not Specified']
                          .map((sex) => DropdownMenuItem(value: sex, child: Text(sex, style: TextStyle(color: widget.theme.textColor))))
                          .toList(),
                      onChanged: (val) => setStateDialog(() => _selectedSex = val),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(statefulContext),
                  child: Text('Cancel', style: TextStyle(color: widget.theme.subtextColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colSecurity,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : () async {
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

                      if (!statefulContext.mounted) return;
                      Navigator.pop(statefulContext);

                      if (!mounted) return;
                      setState(() {
                        _currentData['name'] = _nameController.text.trim();
                        _currentData['address'] = _addressController.text.trim();
                        _currentData['contactNumber'] = _contactController.text.trim();
                        _currentData['diagnosis'] = _diagnosisController.text.trim();
                        _currentData['sex'] = _selectedSex;
                      });
                      
                      _showSnackbar('Profile updated successfully', _colSecurity);
                      
                    } catch (e) {
                      if (statefulContext.mounted) {
                        setStateDialog(() => _isLoading = false);
                      }
                      if (mounted) {
                        _showSnackbar('Error updating profile: $e', _colSafety);
                      }
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setStateDialog) {
            return AlertDialog(
              backgroundColor: widget.theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Change Password', style: TextStyle(color: widget.theme.textColor, fontWeight: FontWeight.bold, fontSize: 20)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You will need to sign in again after changing your password.',
                      style: TextStyle(color: widget.theme.subtextColor, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    _buildDialogTextField('Current Password', _currentPasswordController, Icons.lock_outline, isPassword: true),
                    const SizedBox(height: 16),
                    _buildDialogTextField('New Password', _newPasswordController, Icons.lock_outline, isPassword: true),
                    const SizedBox(height: 16),
                    _buildDialogTextField('Confirm Password', _confirmPasswordController, Icons.lock_outline, isPassword: true),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(statefulContext),
                  child: Text('Cancel', style: TextStyle(color: widget.theme.subtextColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colSecurity,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : () async {
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

                      if (!statefulContext.mounted) return;
                      Navigator.pop(statefulContext);
                      
                      if (mounted) {
                        _showSnackbar('Password changed successfully', _colSecurity);
                      }
                      
                    } catch (e) {
                      if (statefulContext.mounted) {
                        setStateDialog(() => _isLoading = false);
                      }
                      if (mounted) {
                        _showSnackbar('Error: Please check your current password', _colSafety);
                      }
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      builder: (context) => AppGuideVideoDialog(
        theme: widget.theme,
        colSupport: _colSupport,
        colSafety: _colSafety,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('About Seelai', style: TextStyle(color: widget.theme.textColor, fontWeight: FontWeight.bold, fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seelai App', style: TextStyle(color: widget.theme.textColor, fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'A companion app designed to empower partially sighted individuals through technology.',
              style: TextStyle(color: widget.theme.subtextColor, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text('Version: 1.0.0', style: TextStyle(color: widget.theme.subtextColor, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _colSupport, fontWeight: FontWeight.w600)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Privacy Policy', style: TextStyle(color: widget.theme.textColor, fontWeight: FontWeight.bold, fontSize: 20)),
        content: Text(
          'Your privacy is important to us. All personal and medical data is securely stored and used solely for the purpose of providing assistance services within the app.',
          style: TextStyle(color: widget.theme.subtextColor, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _colSupport, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

 void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: widget.theme.subtextColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _colSafety.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.logout_rounded, color: _colSafety, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Sign Out', 
                  style: TextStyle(
                    color: widget.theme.textColor, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out?', 
          style: TextStyle(
            color: widget.theme.subtextColor, 
            fontSize: 16, 
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel', 
              style: TextStyle(
                color: widget.theme.subtextColor, 
                fontWeight: FontWeight.w600, 
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              await authService.value.signOut();
              
              if (!mounted) return; 

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                (route) => false,
              );
              _showSnackbar('Successfully signed out', Colors.green);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _colSafety,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Sign Out', 
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== VIDEO PLAYER DIALOG ====================
class AppGuideVideoDialog extends StatefulWidget {
  final dynamic theme;
  final Color colSupport;
  final Color colSafety;

  const AppGuideVideoDialog({
    super.key,
    required this.theme,
    required this.colSupport,
    required this.colSafety,
  });

  @override
  State<AppGuideVideoDialog> createState() => _AppGuideVideoDialogState();
}

class _AppGuideVideoDialogState extends State<AppGuideVideoDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/sample_vid.mp4')
      ..initialize().then((_) {
        if (mounted) setState(() => _isInitialized = true);
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = error.toString();
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.theme.cardColor,
      insetPadding: const EdgeInsets.all(20),
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: _hasError 
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                "Video failed to load.\nCheck path or run 'flutter clean'.\n\nError: $_errorMessage",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          )
                        : _isInitialized
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                                  });
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox.expand(
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _controller.value.size.width,
                                          height: _controller.value.size.height,
                                          child: VideoPlayer(_controller),
                                        ),
                                      ),
                                    ),
                                    if (!_controller.value.isPlaying)
                                      Container(
                                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                                        padding: const EdgeInsets.all(12),
                                        child: Icon(Icons.play_arrow_rounded, color: widget.colSupport, size: 50),
                                      ),
                                  ],
                                ),
                              )
                            : Center(child: CircularProgressIndicator(color: widget.colSupport)),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Getting Started", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.theme.textColor)),
                    const SizedBox(height: 8),
                    Text("Watch the video above or check the quick steps below.", style: TextStyle(fontSize: 14, color: widget.theme.subtextColor)),
                    const SizedBox(height: 24),
                    _buildGuideStep(icon: Icons.visibility_rounded, title: "Object Detection", description: "Point your camera to detect objects."),
                    _buildGuideStep(icon: Icons.support_agent_rounded, title: "Caretaker Connection", description: "Your caretakers are one tap away."),
                    _buildGuideStep(icon: Icons.sos_rounded, title: "SOS Emergency", description: "Triple-tap for immediate help.", isDestructive: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep({
    required IconData icon, 
    required String title, 
    required String description, 
    bool isDestructive = false
  }) {
    // 🎨 Apply the same clean adaptive style to the video guide items! 🎨
    final displayIconColor = isDestructive ? widget.colSafety : widget.theme.textColor;
    final displayContainerColor = isDestructive 
        ? widget.colSafety.withValues(alpha: 0.15) 
        : widget.theme.textColor.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: displayContainerColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: displayIconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: widget.theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: widget.theme.subtextColor, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}