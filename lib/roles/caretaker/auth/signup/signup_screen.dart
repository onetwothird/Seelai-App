
import 'dart:io';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seelai_app/services/cloudinary_service.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:seelai_app/firebase/activity_logs_service.dart';
import 'package:seelai_app/mobile/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CaretakerSignupScreen extends StatefulWidget {
  final User? googleUser; 

  const CaretakerSignupScreen({super.key, this.googleUser});

  @override
  State<CaretakerSignupScreen> createState() => _CaretakerSignupScreenState();
}

class _CaretakerSignupScreenState extends State<CaretakerSignupScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
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

    // --- PRE-FILL GOOGLE DATA (Name is editable, Email is locked) ---
    if (widget.googleUser != null) {
      _emailController.text = widget.googleUser!.email ?? '';
      _nameController.text = widget.googleUser!.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
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
            ListTile(
              leading: Icon(Icons.camera_alt, color: primary),
              title: const Text('Take Photo'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: primary),
              title: const Text('Gallery'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;
    return await cloudinaryService.uploadProfileImage(_profileImage!, userId, 'caretaker');
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

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

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF1E293B),
        ),
        title: const Text(
          "Create Account",
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset('assets/images/eye background.jpg', fit: BoxFit.cover),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24, 
                right: 24, 
                top: 20, 
                bottom: 20 + keyboardHeight 
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _showImageSourceDialog,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF1F5F9),
                                border: Border.all(color: Colors.black, width: 2.0),
                                image: _profileImage != null
                                    ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: _profileImage == null
                                  ? const Icon(Icons.person_rounded, size: 60, color: Color(0xFFCBD5E1))
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_ageController, 'Age', Icons.cake_outlined, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _emailController, 
                        'Email', 
                        Icons.email_outlined, 
                        keyboardType: TextInputType.emailAddress,
                        readOnly: widget.googleUser != null, // Lock email if Google user
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildTextField(_relationshipController, 'Relationship to Patient', Icons.people_outline),
                      const SizedBox(height: 20),
                    

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            widget.googleUser != null ? "Save & Continue" : "Create Account", 
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
          if (_isLoading) LoadingOverlay(message: 'Creating Account', isVisible: _isLoading),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, bool isPassword = false, bool isConfirm = false, bool readOnly = false}) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFE2E8F0) : const Color(0xFFF8FAFC), // Grey out if read only
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)), 
      ),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboardType,
        obscureText: isPassword ? (isConfirm ? _obscureConfirmPassword : _obscurePassword) : false,
        style: TextStyle(color: readOnly ? const Color(0xFF64748B) : const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
          suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (isConfirm ? _obscureConfirmPassword : _obscurePassword) ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF94A3B8),
                ),
                onPressed: () => setState(() {
                  if (isConfirm) {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  } else {
                    _obscurePassword = !_obscurePassword;
                  }
                }),
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    // 1. STRICT VALIDATION: All fields except password must be filled out
    if (_nameController.text.trim().isEmpty || 
        _ageController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _phoneController.text.trim().isEmpty || 
        _relationshipController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields'), backgroundColor: error));
      return;
    }
    
    // 2. Validate passwords ONLY if they are NOT a Google User
    if (widget.googleUser == null) {
      if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a password'), backgroundColor: error));
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

    try {
      User? finalUser;

      // 3. Determine Auth Flow
      if (widget.googleUser != null) {
        finalUser = widget.googleUser;
      } else {
        UserCredential userCredential = await authService.value.createAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        finalUser = userCredential.user;
        await authService.value.updateUsername(userName: _nameController.text.trim());
      }

      if (finalUser == null) throw Exception("Failed to get user information.");

      // 4. Upload Profile Image
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage(finalUser.uid);
      }

      // 5. Create DB Entry
      await databaseService.createUserDocument(
        userId: finalUser.uid,
        name: _nameController.text.trim(),
        age: age,
        email: _emailController.text.trim(),
        role: 'caretaker',
        phone: _phoneController.text.trim(),
        relationship: _relationshipController.text.trim(),
        approved: false, // Pending MSWD verification
      );

      // 6. Update Database Image URL
      if (profileImageUrl != null) {
        await databaseService.updateUserProfile(
          userId: finalUser.uid,
          role: 'caretaker',
          profileImageUrl: profileImageUrl,
        );
      }

      // 7. Log creation
      await activityLogsService.logActivity(
        userId: finalUser.uid,
        action: 'account_created',
        details: 'User signed up as caretaker',
      );

      // 8. Completion & MSWD Notice
      if (mounted) {
        setState(() => _isLoading = false);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Account Created'),
            content: const Text(
              'Your account has been successfully created.\n\nPlease note that you must be verified by MSWD before you can log in.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to login
                },
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed'), backgroundColor: error));
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: error));
      if (mounted) setState(() => _isLoading = false);
    }
  }
}