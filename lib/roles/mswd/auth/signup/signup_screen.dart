// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui'; // <--- REQUIRED for Glassmorphism
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seelai_app/services/cloudinary_service.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:seelai_app/firebase/activity_logs_service.dart';
import 'package:seelai_app/mobile/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MSWDSignupScreen extends StatefulWidget {
  const MSWDSignupScreen({super.key});

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
  }

  @override
  void dispose() {
    _entryController.dispose();
    _nameController.dispose();
    _idNumberController.dispose();
    _ageController.dispose();
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
      
      // 1. EXTEND BODY BEHIND APP BAR (Crucial for glass effect)
      extendBodyBehindAppBar: true, 
      
      appBar: AppBar(
        // 2. MAKE BASE TRANSPARENT
        backgroundColor: Colors.transparent, 
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        
        // 3. ADD THE GLASS EFFECT
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.white.withOpacity(0.2), // Low Opacity Tint
            ),
          ),
        ),

        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded), color: const Color(0xFF1E293B)),
        title: const Text("Register Staff", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE (Fixed Position)
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/eye background.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              // FIX 2: Dynamic Padding for Keyboard
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
                                image: _profileImage != null ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover) : null,
                              ),
                              child: _profileImage == null ? const Icon(Icons.person_rounded, size: 60, color: Color(0xFFCBD5E1)) : null,
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

                      _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_idNumberController, 'Staff ID Number', Icons.badge_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_ageController, 'Age', Icons.cake_outlined, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(_emailController, 'Work Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildTextField(_departmentController, 'Department', Icons.business_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_passwordController, 'Password', Icons.lock_outline, isPassword: true),
                      const SizedBox(height: 16),
                      _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock_outline, isPassword: true, isConfirm: true),
                      
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary, foregroundColor: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Create Staff Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) LoadingOverlay(message: 'Registering...', isVisible: _isLoading),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, bool isPassword = false, bool isConfirm = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: ctrl, keyboardType: keyboardType,
        // Correct logic to toggle password visibility independently
        obscureText: isPassword ? (isConfirm ? _obscureConfirmPassword : _obscurePassword) : false,
        style: const TextStyle(color: Color(0xFF1E293B)),
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
     if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields'), backgroundColor: error));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: error));
      return;
    }
    setState(() => _isLoading = true);

    try {
      int? age = int.tryParse(_ageController.text.trim());

      UserCredential userCredential = await authService.value.createAccount(email: _emailController.text.trim(), password: _passwordController.text);
      await authService.value.updateUsername(userName: _nameController.text.trim());
      
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage(userCredential.user!.uid);
      }

      await databaseService.createUserDocument(
        userId: userCredential.user!.uid,
        name: _nameController.text.trim(),
        idNumber: _idNumberController.text.trim(), 
        age: age ?? 0, 
        email: _emailController.text.trim(),
        department: _departmentController.text.trim(),
        role: 'admin', 
      );

       if (profileImageUrl != null) {
        await databaseService.updateUserProfile(userId: userCredential.user!.uid, role: 'admin', profileImageUrl: profileImageUrl);
      }

      await activityLogsService.logActivity(userId: userCredential.user!.uid, action: 'account_created', details: 'MSWD Staff registered');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff account created!'), backgroundColor: primary));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed'), backgroundColor: error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}