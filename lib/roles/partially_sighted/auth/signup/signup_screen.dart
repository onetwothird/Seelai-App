// File: lib/roles/partially_sighted/auth/signup/signup_screen.dart

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

class PartiallySightedSignupScreen extends StatefulWidget {
  final User? googleUser; // Captures the Google Account

  const PartiallySightedSignupScreen({super.key, this.googleUser});

  @override
  State<PartiallySightedSignupScreen> createState() => _PartiallySightedSignupScreenState();
}

class _PartiallySightedSignupScreenState extends State<PartiallySightedSignupScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedGender; 
  String? _selectedDisabilityType;
  DateTime? _selectedBirthdate;

  final List<String> _genderOptions = ['Male', 'Female', 'Rather Not Say']; 
  
  // Updated with WHO Classifications and functional descriptions
  final List<String> _disabilityTypes = [
    'Near Normal (Struggles with small print)',
    'Moderate (Needs magnifiers to read)',
    'Severe / Legally Blind (Faces are blurry close up)',
    'Profound (Relies heavily on audio/cane)',
    'Near Total (Can only see light or hand motion)',
  ];

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

    // PRE-FILL DATA FROM GOOGLE (Name is editable, Email is locked)
    if (widget.googleUser != null) {
      _emailController.text = widget.googleUser!.email ?? '';
      _nameController.text = widget.googleUser!.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _idNumberController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    _diagnosisController.dispose();
    _emailController.dispose();
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
    return await cloudinaryService.uploadProfileImage(_profileImage!, userId, 'partially_sighted');
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedBirthdate = picked);
  }

  // --- Informational Dialog for Disability Categories ---
  void _showCategoryInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent, // Prevents Material 3 tinting
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            "Which category am I?",
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryItem(
                  title: "Near Normal (20/30 to 20/60)",
                  description: "You have slight difficulty with fine details, like reading small print or street signs, even with normal glasses.",
                ),
                SizedBox(height: 16),
                _CategoryItem(
                  title: "Moderate (20/70 to 20/160)",
                  description: "You likely need strong magnifiers to read. Navigating is generally fine, but recognizing faces from across a room is difficult.",
                ),
                SizedBox(height: 16),
                _CategoryItem(
                  title: "Severe (20/200 to 20/400)",
                  description: "This is the threshold for legal blindness. You cannot read standard print. You can see shapes and large objects, but faces are very blurry even up close.",
                ),
                SizedBox(height: 16),
                _CategoryItem(
                  title: "Profound (20/500 to 20/1000)",
                  description: "You rely heavily on screen readers and mobility aids (like a white cane). You might only be able to see very large, high-contrast letters extremely close to your face.",
                ),
                SizedBox(height: 16),
                _CategoryItem(
                  title: "Near Total (≤ 5° field)",
                  description: "You cannot see shapes. You can only tell if a room is light or dark, or if someone is waving their hand right in front of your eyes.",
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Got it", style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        );
      },
    );
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
            child: Container(color: Colors.white.withValues(alpha: 0.2)),
          ),
        ),

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF1E293B),
        ),
        title: const Text(
          "Complete Profile",
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
                bottom: 20 + MediaQuery.of(context).viewInsets.bottom
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

                      _buildSectionHeader("Personal Information"),
                      const SizedBox(height: 16),
                      _buildTextField(_idNumberController, 'ID Number', Icons.badge_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 16),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2, 
                            child: _buildTextField(_ageController, 'Age', Icons.cake_outlined, keyboardType: TextInputType.number),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3, 
                            child: _buildDropdownField(
                              _selectedGender, _genderOptions, 'Gender', Icons.wc_outlined, 
                              (val) => setState(() => _selectedGender = val)
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      _buildDateField(_selectedBirthdate, 'Birthdate', Icons.calendar_today_outlined, _selectBirthdate),
                      const SizedBox(height: 16),
                      _buildTextField(_addressController, 'Address', Icons.home_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_contactNumberController, 'Contact', Icons.phone_outlined, keyboardType: TextInputType.phone),

                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(child: _buildSectionHeader("Medical Details")),
                          IconButton(
                            icon: Icon(Icons.help_outline, color: primary),
                            onPressed: _showCategoryInfoDialog,
                            tooltip: 'Help me choose',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDropdownField(
                        _selectedDisabilityType, _disabilityTypes, 'Category', Icons.accessible_outlined, 
                        (val) => setState(() => _selectedDisabilityType = val)
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_diagnosisController, 'Diagnosis', Icons.medical_information_outlined),

                      const SizedBox(height: 32),

                      _buildSectionHeader("Account Security"),
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        _emailController, 
                        'Email', 
                        Icons.email_outlined, 
                        keyboardType: TextInputType.emailAddress,
                        readOnly: widget.googleUser != null, 
                      ),
                      
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

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, bool isPassword = false, bool isConfirm = false, bool readOnly = false}) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFE2E8F0) : const Color(0xFFF8FAFC), 
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

  Widget _buildDropdownField(String? val, List<String> items, String hint, IconData icon, Function(String?) changed) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: val,
        items: items.map((i) => DropdownMenuItem(
          value: i, 
          child: Text(i, overflow: TextOverflow.ellipsis) 
        )).toList(),
        onChanged: _isLoading ? null : changed,
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDateField(DateTime? date, String hint, IconData icon, VoidCallback tap) {
    return GestureDetector(
      onTap: _isLoading ? null : tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Text(
              date != null ? "${date.month}/${date.day}/${date.year}" : hint,
              style: TextStyle(color: date != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (_idNumberController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _selectedGender == null ||            
        _ageController.text.trim().isEmpty ||
        _selectedBirthdate == null ||
        _selectedDisabilityType == null ||
        _diagnosisController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _contactNumberController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields'), backgroundColor: error));
      return;
    }

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
      if (widget.googleUser != null) {
        finalUser = widget.googleUser;
      } else {
        UserCredential userCredential = await authService.value.createAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        finalUser = userCredential.user;
        isNewEmailUser = true; 
        await authService.value.updateUsername(userName: _nameController.text.trim());
      }

      if (finalUser == null) throw Exception("Failed to get user information.");

      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage(finalUser.uid);
      } else if (widget.googleUser?.photoURL != null) {
        profileImageUrl = widget.googleUser!.photoURL;
      }

      try {
        await databaseService.createUserDocument(
          userId: finalUser.uid,
          idNumber: _idNumberController.text.trim(),
          name: _nameController.text.trim(),
          sex: _selectedGender!, 
          age: age,
          birthdate: _selectedBirthdate!,
          disabilityType: _selectedDisabilityType!,
          diagnosis: _diagnosisController.text.trim(),
          address: _addressController.text.trim(),
          contactNumber: _contactNumberController.text.trim(),
          email: _emailController.text.trim(),
          role: 'partially_sighted',
        );
      } catch (dbError) {
        if (isNewEmailUser) {
          await finalUser.delete();
        }
        throw Exception("Failed to save profile data. Please try again. ($dbError)");
      }

      if (profileImageUrl != null) {
        await databaseService.updateUserProfile(
          userId: finalUser.uid,
          role: 'partially_sighted',
          profileImageUrl: profileImageUrl,
        );
      }

      await activityLogsService.logActivity(
        userId: finalUser.uid,
        action: 'account_created',
        details: 'User signed up as partially_sighted',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Setup Complete!'), backgroundColor: primary));
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

// Helper widget for clean, justified, and readable list items
class _CategoryItem extends StatelessWidget {
  final String title;
  final String description;

  const _CategoryItem({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.justify,
          style: const TextStyle(
            height: 1.5,
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}