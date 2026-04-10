// File: lib/roles/mswd/auth/signup/signup_screen.dart

import 'dart:io';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seelai_app/storage/cloudinary_service.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:seelai_app/firebase/activity_logs_service.dart';
import 'package:seelai_app/mobile/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MSWDSignupScreen extends StatefulWidget {
  final User? googleUser; // Captures Google Account

  const MSWDSignupScreen({super.key, this.googleUser});

  @override
  State<MSWDSignupScreen> createState() => _MSWDSignupScreenState();
}

class _MSWDSignupScreenState extends State<MSWDSignupScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  String? _selectedGender; 

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutQuart));

    _entryController.forward();

    // --- PRE-FILL GOOGLE DATA (Name editable, Email locked) ---
    if (widget.googleUser != null) {
      _emailController.text = widget.googleUser!.email ?? '';
      _nameController.text = widget.googleUser!.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _nameController.dispose();
    _idNumberController.dispose();
    _ageController.dispose();
    _phoneController.dispose(); 
    _emailController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (pickedFile != null) setState(() => _profileImage = File(pickedFile.path));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: error));
    }
  }

  void _showImageSourceDialog() {
     showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Profile Picture', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(leading: Icon(Icons.camera_alt, color: primary), title: const Text('Take Photo'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
            ListTile(leading: Icon(Icons.photo_library, color: primary), title: const Text('Gallery'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;
    return await cloudinaryService.uploadProfileImage(_profileImage!, userId, 'admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true, 
      
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.white.withValues(alpha: 0.2), 
            ),
          ),
        ),

        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded), color: const Color(0xFF1E293B)),
        title: const Text("Register Staff", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/eye background.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24, 
                right: 24, 
                top: 20, 
                bottom: 20 + MediaQuery.of(context).viewInsets.bottom
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: _isLoading ? null : _showImageSourceDialog,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, color: const Color(0xFFF1F5F9),
                                border: Border.all(color: Colors.black, width: 2.0), 
                                image: _profileImage != null
                                    ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                                    : (widget.googleUser?.photoURL != null)
                                        ? DecorationImage(image: NetworkImage(widget.googleUser!.photoURL!), fit: BoxFit.cover)
                                        : null,
                              ),
                              child: _profileImage == null && widget.googleUser?.photoURL == null
                                  ? const Icon(Icons.person_rounded, size: 60, color: Color(0xFFCBD5E1))
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      _buildSectionHeader("Personal Information"),
                      const SizedBox(height: 16),
                      _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_idNumberController, 'Staff ID Number', Icons.badge_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      
                      // RESPONSIVE AGE & GENDER ROW
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2, // Slightly smaller flex to give space to Gender text
                            child: _buildTextField(_ageController, 'Age', Icons.cake_outlined, keyboardType: TextInputType.number),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3, // Larger flex for Gender
                            child: _buildGenderDropdown(),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      _buildTextField(_departmentController, 'Department', Icons.business_outlined),
                      
                      const SizedBox(height: 32),

                      _buildSectionHeader("Account Security"),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _emailController, 
                        'Email', 
                        Icons.email_outlined, 
                        keyboardType: TextInputType.emailAddress,
                        readOnly: widget.googleUser != null, // Lock email if Google user
                      ),
                      
                      // Only show password fields if NOT signing up with Google
                      if (widget.googleUser == null) ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          _passwordController,
                          'Password',
                          Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _confirmPasswordController,
                          'Confirm Password',
                          Icons.lock_reset_outlined,
                          isPassword: true,
                          isConfirm: true,
                        ),
                      ],
                      
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary, foregroundColor: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            widget.googleUser != null ? "Save & Continue" : "Create Staff Account", 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) LoadingOverlay(message: '', isVisible: _isLoading),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1.0),
      ),
    );
  }

  // UPDATED RESPONSIVE GENDER DROPDOWN
  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true, // Crucial for responsiveness on smaller screens
        initialValue: _selectedGender,
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
        decoration: const InputDecoration(
          hintText: 'Gender',
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: Icon(Icons.wc_outlined, color: Color(0xFF64748B)),
          border: InputBorder.none, 
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        items: ['Male', 'Female', 'Rather not Say'] // Aligned choices with caretaker
            .map((sex) => DropdownMenuItem(
                  value: sex, 
                  child: Text(
                    sex, 
                    style: const TextStyle(color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis, // Added overflow protection
                  )
                ))
            .toList(),
        onChanged: (val) => setState(() => _selectedGender = val),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, bool isPassword = false, bool isConfirm = false, bool readOnly = false}) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFE2E8F0) : const Color(0xFFF8FAFC), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: ctrl, 
        keyboardType: keyboardType,
        readOnly: readOnly,
        obscureText: isPassword ? (isConfirm ? _obscureConfirmPassword : _obscurePassword) : false,
        style: TextStyle(color: readOnly ? const Color(0xFF64748B) : const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  (isConfirm ? _obscureConfirmPassword : _obscurePassword) ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                  color: const Color(0xFF94A3B8)
                ), 
                onPressed: () => setState(() {
                  if (isConfirm) {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  } else {
                    _obscurePassword = !_obscurePassword;
                  }
                })) 
            : null,
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    // 1. STRICT VALIDATION: All fields except password must be filled out
    if (_nameController.text.trim().isEmpty || 
        _idNumberController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty || 
        _phoneController.text.trim().isEmpty ||
        _selectedGender == null ||              // Gender Validation is enforced here
        _emailController.text.trim().isEmpty || 
        _departmentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields'), backgroundColor: error));
      return;
    }
    
    // 2. Validate passwords ONLY if they are NOT a Google User
    if (widget.googleUser == null) {
      if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a password'), backgroundColor: error));
        return;
      }
      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: error));
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: error));
        return;
      }
    }

    int? age = int.tryParse(_ageController.text.trim());
    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid age'), backgroundColor: error));
      return;
    }
    
    setState(() => _isLoading = true);

    User? finalUser;
    bool isNewEmailUser = false;

    try {
      // 3. Determine Auth Flow
      if (widget.googleUser != null) {
        finalUser = widget.googleUser;
      } else {
        UserCredential userCredential = await authService.value.createAccount(
          email: _emailController.text.trim(), 
          password: _passwordController.text
        );
        finalUser = userCredential.user;
        isNewEmailUser = true;
        await authService.value.updateUsername(userName: _nameController.text.trim());
      }

      if (finalUser == null) throw Exception("Failed to get user information.");

      // 4. Upload Profile Image OR use Google's existing image
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage(finalUser.uid);
      } else if (widget.googleUser?.photoURL != null) {
        profileImageUrl = widget.googleUser!.photoURL;
      }

      // 5. Create DB Entry (Wrapped for rollback)
      try {
        await databaseService.createUserDocument(
          userId: finalUser.uid,
          name: _nameController.text.trim(),
          idNumber: _idNumberController.text.trim(), 
          age: age, 
          email: _emailController.text.trim(),
          department: _departmentController.text.trim(),
          contactNumber: _phoneController.text.trim(), 
          sex: _selectedGender, // Pushing the required gender selection                        
          role: 'admin', 
        );
      } catch (dbError) {
        if (isNewEmailUser) {
          await finalUser.delete();
        }
        throw Exception("Failed to save profile data. Please try again. ($dbError)");
      }

      // 6. Update Database Image URL
      if (profileImageUrl != null) {
        await databaseService.updateUserProfile(
          userId: finalUser.uid, 
          role: 'admin', 
          profileImageUrl: profileImageUrl
        );
      }

      // 7. Log Activity
      await activityLogsService.logActivity(
        userId: finalUser.uid, 
        action: 'account_created', 
        details: 'MSWD Staff registered'
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff account created!'), backgroundColor: primary));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed'), backgroundColor: error));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}