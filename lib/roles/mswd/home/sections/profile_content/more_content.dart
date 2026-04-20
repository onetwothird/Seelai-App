// File: lib/roles/mswd/home/sections/more_content.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:seelai_app/screens/onboarding_screen.dart';
import 'package:intl/intl.dart';

// IMPORTANT: Import the new screens here!
import 'package:seelai_app/roles/mswd/home/sections/profile_content/about_seelai_screen.dart';
import 'package:seelai_app/roles/mswd/home/sections/profile_content/privacy_policy_screen.dart';

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
  late Map<String, dynamic> _userData;
  bool _isLoading = false;
  
  // --- Color Palette ---
  final Color _colVerifications = const Color(0xFF3B82F6); 
  final Color _colTracking = const Color(0xFF8B5CF6);      
  final Color _colSafety = const Color(0xFFEF4444);        
  final Color _colSupport = const Color(0xFF06B6D4);       
  final Color _colSecurity = const Color(0xFF10B981);      
  final Color _colAdmin = const Color(0xFFF59E0B);         
  final Color _primaryColor = const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
  }

  @override
  void didUpdateWidget(covariant MoreContent oldWidget) {
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
        'admin',
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
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 120.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile & Settings',
                style: TextStyle(
                color: widget.theme.textColor,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildCenteredProfileImage(),
          const SizedBox(height: 32),
          
          _buildSettingsGroup(
            title: 'Administrative Details',
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
                title: 'Department',
                icon: Icons.business_center_outlined,
                iconColor: _colVerifications,
                value: _userData['department']?.toString().isNotEmpty == true 
                    ? _userData['department'] 
                    : 'MSWD General',
              ),
              _buildSettingsTile(
                title: 'Admin ID',
                icon: Icons.badge_outlined,
                iconColor: _colVerifications,
                value: _userData['adminId']?.toString().isNotEmpty == true 
                    ? _userData['adminId'] 
                    : 'A-${_userData['userId']?.substring(0, 5).toUpperCase() ?? '00000'}',
                isLast: true,
              ),
            ],
          ),

          _buildSettingsGroup(
            title: 'System Management',
            children: [
              _buildSettingsTile(
                title: 'System Activity Logs',
                icon: Icons.manage_search_rounded,
                iconColor: _colAdmin,
                onTap: () {
                  _showSnackbar('Navigating to system logs...', _colAdmin);
                },
              ),
              _buildSettingsTile(
                title: 'Export System Report',
                icon: Icons.file_download_outlined,
                iconColor: _colAdmin,
                onTap: () {
                  _showSnackbar('Generating PDF report...', _colSecurity);
                },
                isLast: true,
              ),
            ],
          ),

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

          _buildSettingsGroup(
            title: 'Account Actions',
            children: [
              _buildSettingsTile(
                title: 'Edit Profile',
                icon: Icons.edit_outlined,
                iconColor: _colSecurity,
                onTap: _showEditProfileDialog,
              ),
              _buildSettingsTile(
                title: 'Change Password',
                icon: Icons.lock_outline_rounded,
                iconColor: _colSecurity,
                onTap: _showChangePasswordDialog,
                isLast: true,
              ),
            ],
          ),

          // ==================== SUPPORT & INFO (UPDATED) ====================
          _buildSettingsGroup(
            title: 'Support & Information',
            children: [
              _buildSettingsTile(
                title: 'Admin Guide Video',
                icon: Icons.play_circle_fill_rounded,
                iconColor: _colSupport,
                onTap: _showHowToUseDialog,
              ),
              _buildSettingsTile(
                title: 'About Seelai', // NEW ITEM
                icon: Icons.info_outline_rounded,
                iconColor: _colSupport,
                onTap: _showAboutDialog, // Triggers new screen
              ),
              _buildSettingsTile(
                title: 'Privacy Policy', // UPDATED
                icon: Icons.privacy_tip_outlined,
                iconColor: _colSupport,
                onTap: _showPrivacyDialog, // Triggers new screen
                isLast: true,
              ),
            ],
          ),

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

  // ==================== UI COMPONENTS (Keep existing UI Builders) ====================
  // (Your _buildCenteredProfileImage, _buildGradientFallback, _buildSettingsGroup,
  // _buildSettingsTile, _buildDialogTextField, _formatBirthdate, _showSnackbar stay EXACTLY the same as your code)

  Widget _buildCenteredProfileImage() {
    final profileUrl = _userData['profileImageUrl'] as String?;
    final name = _userData['name'] ?? 'Admin';
    final initial = name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : 'A';

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
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
              // MSWD Verified Badge
              Positioned(
                bottom: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _colTracking,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.theme.backgroundColor, width: 2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 4),
                      Text(
                        'MSWSD',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
            _colTracking,
            _colTracking.withValues(alpha: 0.6),
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

  Widget _buildDialogTextField(String label, TextEditingController controller, IconData icon, {
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
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

  // ==================== NEW NAVIGATION DIALOGS ====================

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

  // ==================== EDIT/LOGOUT DIALOGS (Keep Existing Code) ====================
  // (Your _showEditProfileDialog, _showChangePasswordDialog, _showLogoutDialog, 
  // _showHowToUseDialog stay exactly the same here)
  
  void _showEditProfileDialog() {
    final parentContext = context; 

    final nameController = TextEditingController(text: _userData['name']);
    final phoneController = TextEditingController(text: _userData['phone'] ?? _userData['contactNumber']);
    final departmentController = TextEditingController(text: _userData['department']);
    final ageController = TextEditingController(text: _userData['age']?.toString() ?? '');
    String? selectedSex = _userData['sex'];

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return AlertDialog(
            backgroundColor: widget.theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Update Admin Profile',
              style: TextStyle(color: widget.theme.textColor, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField('Full Name', nameController, Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildDialogTextField('Phone Number', phoneController, Icons.phone_outlined, inputType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildDialogTextField('Department', departmentController, Icons.business_center_outlined),
                    const SizedBox(height: 16),
                    _buildDialogTextField('Age', ageController, Icons.cake_outlined, inputType: TextInputType.number),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSex,
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
                      onChanged: (val) => setStateDialog(() => selectedSex = val),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
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
                  Navigator.pop(dialogContext);

                  try {
                    await databaseService.updateUserProfile(
                      userId: databaseService.currentUserId!,
                      role: 'admin',
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      contactNumber: phoneController.text.trim(),
                      department: departmentController.text.trim(),
                      age: int.tryParse(ageController.text.trim()),
                      sex: selectedSex,
                    );

                    await _refreshUserData();

                    if (!mounted) return;
                    _showSnackbar('Profile updated successfully', _colSecurity);
                  } catch (e) {
                    if (!mounted) return;
                    _showSnackbar('Error updating profile: $e', _colSafety);
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setStateDialog) {
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
                  _buildDialogTextField('Current Password', currentPassController, Icons.lock_outline, isPassword: true),
                  const SizedBox(height: 16),
                  _buildDialogTextField('New Password', newPassController, Icons.lock_outline, isPassword: true),
                  const SizedBox(height: 16),
                  _buildDialogTextField('Confirm Password', confirmPassController, Icons.lock_outline, isPassword: true),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(builderContext),
                child: Text('Cancel', style: TextStyle(color: widget.theme.subtextColor)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colSecurity,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
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
                    _showSnackbar('Password changed successfully', _colSecurity);
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
            ],
          );
        }
      ),
    );
  }

 void _showLogoutDialog() {
    final parentContext = context;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: _colSafety),
            const SizedBox(width: 10),
            Text(
              'Sign Out?',
              style: TextStyle(color: widget.theme.textColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of the Admin Portal?',
          style: TextStyle(color: widget.theme.subtextColor, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // 1. Closes the dialog
              
              await authService.value.signOut(); // 2. Clears Firebase session
              
              if (!parentContext.mounted) return;

              // 3. Routes to Onboarding and clears navigation stack
              Navigator.of(parentContext).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                (route) => false,
              );
              
              if (mounted) {
                _showSnackbar('Successfully signed out', _primaryColor);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _colSafety,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHowToUseDialog() {
    showDialog(
      context: context,
      builder: (context) => AdminGuideVideoDialog(
        theme: widget.theme,
        colSupport: _colSupport,
        colSafety: _colSafety,
        colAdmin: _colAdmin,
      ),
    );
  }
}

// ==================== ADMIN VIDEO PLAYER DIALOG WIDGET ====================
// (Your AdminGuideVideoDialog stays completely identical as well!)
class AdminGuideVideoDialog extends StatefulWidget {
  final dynamic theme;
  final Color colSupport;
  final Color colSafety;
  final Color colAdmin;

  const AdminGuideVideoDialog({
    super.key,
    required this.theme,
    required this.colSupport,
    required this.colSafety,
    required this.colAdmin,
  });

  @override
  State<AdminGuideVideoDialog> createState() => _AdminGuideVideoDialogState();
}

class _AdminGuideVideoDialogState extends State<AdminGuideVideoDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    
    _controller = VideoPlayerController.asset('assets/video/sample_vid.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
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
                                    _controller.value.isPlaying
                                        ? _controller.pause()
                                        : _controller.play();
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
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: widget.colSupport,
                                          size: 50,
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : Center(
                                child: CircularProgressIndicator(
                                  color: widget.colSupport,
                                ),
                              ),
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
                    Text(
                      'Admin Training Guide', 
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Learn how to effectively manage the MSWD system.',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.theme.subtextColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGuideStep(
                      icon: Icons.map_rounded, 
                      title: 'Live Tracking', 
                      description: 'Use the Command Center Map to globally track all active users.'
                    ),
                    _buildGuideStep(
                      icon: Icons.people_outline_rounded, 
                      title: 'User Management', 
                      description: 'Access the Directory to securely review profiles and make direct communications.'
                    ),
                    _buildGuideStep(
                      icon: Icons.campaign_rounded, 
                      title: 'System Broadcasts', 
                      description: 'Send critical announcements targeting specific groups or individuals.',
                      colorOverride: widget.colAdmin,
                    ),
                    _buildGuideStep(
                      icon: Icons.warning_rounded, 
                      title: 'Emergency Dispatch', 
                      description: 'Monitor the live alerts feed to coordinate critical SOS requests.',
                      isDestructive: true,
                    ),
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
    bool isDestructive = false,
    Color? colorOverride,
  }) {
    final displayIconColor = isDestructive 
        ? widget.colSafety 
        : (colorOverride ?? widget.theme.textColor);
        
    final displayContainerColor = isDestructive 
        ? widget.colSafety.withValues(alpha: 0.15) 
        : (colorOverride?.withValues(alpha: 0.15) ?? widget.theme.textColor.withValues(alpha: 0.05));

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