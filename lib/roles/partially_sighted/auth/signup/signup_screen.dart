
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

class VisuallyImpairedSignupScreen extends StatefulWidget {
  final User? googleUser; // Captures the Google Account

  const VisuallyImpairedSignupScreen({super.key, this.googleUser});

  @override
  State<VisuallyImpairedSignupScreen> createState() => _VisuallyImpairedSignupScreenState();
}

class _VisuallyImpairedSignupScreenState extends State<VisuallyImpairedSignupScreen> with TickerProviderStateMixin {
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

  String? _selectedSex;
  String? _selectedDisabilityType;
  DateTime? _selectedBirthdate;

  final List<String> _sexOptions = ['Male', 'Female'];
  final List<String> _disabilityTypes = [
    'Category 1: Moderate (20/70 – 20/200)',
    'Category 2: Severe (20/200 – 20/400)',
    'Category 3: Profound (< 20/400 or visual field ≤ 10°)',
    'Category 4: Near Total (counting fingers ≤ 1m, light perception)',
    'Category 5: Total (no light perception)',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose Profile Picture', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: primary),
              title: Text('Take Photo'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: primary),
              title: Text('Gallery'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;
    return await cloudinaryService.uploadProfileImage(_profileImage!, userId, 'visually_impaired');
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
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          color: Color(0xFF1E293B),
        ),
        title: Text(
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
              physics: BouncingScrollPhysics(),
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
                                color: Color(0xFFF1F5F9),
                                border: Border.all(color: Colors.black, width: 2.0),
                                image: _profileImage != null
                                    ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: _profileImage == null
                                  ? Icon(Icons.person_rounded, size: 60, color: Color(0xFFCBD5E1))
                                  : null,
                            ),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 32),

                      _buildSectionHeader("Personal Information"),
                      SizedBox(height: 16),
                      _buildTextField(_idNumberController, 'ID Number', Icons.badge_outlined),
                      SizedBox(height: 16),
                      _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              _selectedSex, _sexOptions, 'Sex', Icons.wc_outlined, 
                              (val) => setState(() => _selectedSex = val)
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(_ageController, 'Age', Icons.cake_outlined, keyboardType: TextInputType.number),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildDateField(_selectedBirthdate, 'Birthdate', Icons.calendar_today_outlined, _selectBirthdate),
                      SizedBox(height: 16),
                      _buildTextField(_addressController, 'Address', Icons.home_outlined),
                      SizedBox(height: 16),
                      _buildTextField(_contactNumberController, 'Contact', Icons.phone_outlined, keyboardType: TextInputType.phone),

                      SizedBox(height: 32),

                      _buildSectionHeader("Medical Details"),
                      SizedBox(height: 16),
                      _buildDropdownField(
                        _selectedDisabilityType, _disabilityTypes, 'Category', Icons.accessible_outlined, 
                        (val) => setState(() => _selectedDisabilityType = val)
                      ),
                      SizedBox(height: 16),
                      _buildTextField(_diagnosisController, 'Diagnosis', Icons.medical_information_outlined),

                      SizedBox(height: 32),

                      _buildSectionHeader("Account Security"),
                      SizedBox(height: 16),
                      
                      // EMAIL IS LOCKED IF LOGGED IN VIA GOOGLE
                      _buildTextField(
                        _emailController, 
                        'Email', 
                        Icons.email_outlined, 
                        keyboardType: TextInputType.emailAddress,
                        readOnly: widget.googleUser != null, 
                      ),
                      
                      SizedBox(height: 20),
      

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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
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

  // --- Components ---

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, bool isPassword = false, bool isConfirm = false, bool readOnly = false}) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Color(0xFFE2E8F0) : Color(0xFFF8FAFC), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)), 
      ),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboardType,
        obscureText: isPassword ? (isConfirm ? _obscureConfirmPassword : _obscurePassword) : false,
        style: TextStyle(color: readOnly ? Color(0xFF64748B) : Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: Color(0xFF64748B)),
          suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (isConfirm ? _obscureConfirmPassword : _obscurePassword) ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Color(0xFF94A3B8),
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
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String? val, List<String> items, String hint, IconData icon, Function(String?) changed) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: val,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: _isLoading ? null : changed,
        style: TextStyle(color: Color(0xFF1E293B), fontSize: 16),
        isExpanded: true,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDateField(DateTime? date, String hint, IconData icon, VoidCallback tap) {
    return GestureDetector(
      onTap: _isLoading ? null : tap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF64748B)),
            SizedBox(width: 12),
            Text(
              date != null ? "${date.month}/${date.day}/${date.year}" : hint,
              style: TextStyle(color: date != null ? Color(0xFF1E293B) : Color(0xFF94A3B8), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    // 1. STRICT VALIDATION: All fields except password must be filled out
    if (_idNumberController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _selectedSex == null ||
        _ageController.text.trim().isEmpty ||
        _selectedBirthdate == null ||
        _selectedDisabilityType == null ||
        _diagnosisController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _contactNumberController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all required fields'), backgroundColor: error));
      return;
    }

    // 2. Validate passwords ONLY if they are NOT a Google User
    if (widget.googleUser == null) {
      if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a password'), backgroundColor: error));
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passwords do not match'), backgroundColor: error));
        return;
      }
    }

    int? age = int.tryParse(_ageController.text.trim());
    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid age'), backgroundColor: error));
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

      // 4. Upload manually selected image
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage(finalUser.uid);
      } 
      // NOTE: Removed Google profile picture auto-sync here based on your request!

      // 5. Create DB Entry
      await databaseService.createUserDocument(
        userId: finalUser.uid,
        idNumber: _idNumberController.text.trim(),
        name: _nameController.text.trim(),
        sex: _selectedSex!,
        age: age,
        birthdate: _selectedBirthdate!,
        disabilityType: _selectedDisabilityType!,
        diagnosis: _diagnosisController.text.trim(),
        address: _addressController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        email: _emailController.text.trim(),
        role: 'visually_impaired',
      );

      // 6. Save Profile Image to DB (if they took one)
      if (profileImageUrl != null) {
        await databaseService.updateUserProfile(
          userId: finalUser.uid,
          role: 'visually_impaired',
          profileImageUrl: profileImageUrl,
        );
      }

      // 7. Log Activity
      await activityLogsService.logActivity(
        userId: finalUser.uid,
        action: 'account_created',
        details: 'User signed up as visually_impaired',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account Setup Complete!'), backgroundColor: primary));
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