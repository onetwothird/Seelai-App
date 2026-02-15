// File: lib/roles/caretaker/auth/login/login_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/auth/signup/signup_screen.dart';
import 'package:seelai_app/roles/caretaker/home/home_screen.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:seelai_app/firebase/activity_logs_service.dart';
import 'package:seelai_app/mobile/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CaretakerLoginScreen extends StatefulWidget {
  const CaretakerLoginScreen({super.key});

  @override
  State<CaretakerLoginScreen> createState() => _CaretakerLoginScreenState();
}

class _CaretakerLoginScreenState extends State<CaretakerLoginScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _isLoading = false;
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final Color brandColor = primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Top Section: Hero Animation
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.45,
            child: SafeArea(
              child: Center(
                child: Container(
                  width: size.width * 0.9,
                  padding: const EdgeInsets.all(10),
                  child: Lottie.asset('assets/icons/Seelai.json', fit: BoxFit.contain),
                ),
              ),
            ),
          ),

          // 2. Back Button
          Positioned(
            top: 50, left: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: const Color(0xFF1E293B),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                elevation: 0,
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),

          // 3. Bottom Section: White Card
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  height: size.height * 0.60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, -10))],
                  ),
                  child: Stack(
                    children: [
                      // Background Texture
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                          child: Opacity(opacity: 0.08, child: Image.asset('assets/images/eye background.jpg', fit: BoxFit.cover)),
                        ),
                      ),
                      // Content
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Caretaker Login", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                            const SizedBox(height: 8),
                            const Text("Sign in to manage and support your patients.", style: TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w400)),
                            const SizedBox(height: 32),
                            _buildTextField(controller: _emailController, hint: "Email address", icon: Icons.email_outlined),
                            const SizedBox(height: 20),
                            _buildTextField(controller: _passwordController, hint: "Password", icon: Icons.lock_outline_rounded, isPassword: true),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading ? null : _showForgotPasswordDialog,
                                child: Text("Forgot password?", style: TextStyle(color: brandColor, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: TextButton(
                                onPressed: _isLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CaretakerSignupScreen())),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                                    children: [
                                      const TextSpan(text: "Don't have an account? "),
                                      TextSpan(text: "Sign Up", style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
                                    ],
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
              ),
            ),
          ),
          if (_isLoading) LoadingOverlay(message: 'Signing In', isVisible: _isLoading),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8)),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Enter your email', prefixIcon: Icon(Icons.email_outlined)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) { Navigator.pop(context); return; }
              try {
                await authService.value.sendPasswordResetEmail(email: emailController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent!'), backgroundColor: success));
              } catch (e) {
                Navigator.pop(context);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // ==================== UPDATED LOGIN LOGIC ====================
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields'), backgroundColor: error));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Authenticate with Firebase Auth
      UserCredential userCredential = await authService.value.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2. Fetch User Data
      Map<String, dynamic>? userData = await databaseService.getUserData(userCredential.user!.uid);
      
      if (userData != null && userData['role'] == 'caretaker') {
        
        // 3. CHECK FOR APPROVAL (Verification)
        bool isApproved = userData['approved'] == true;

        if (!isApproved) {
          // If not approved, Sign Out immediately and show warning
          await authService.value.signOut();
          
          if (mounted) {
            _showPendingVerificationDialog();
            setState(() => _isLoading = false);
          }
          return; // Stop execution here
        }

        // 4. Log Activity if Approved
        await activityLogsService.logActivity(
          userId: userCredential.user!.uid,
          action: 'login',
          details: 'Caretaker logged in',
        );
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CaretakerHomeScreen(userData: userData)),
          );
        }
      } else {
        // Not a caretaker or user data missing
        await authService.value.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not a registered Caretaker account'), backgroundColor: error));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed'), backgroundColor: error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPendingVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.verified_user_outlined, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Pending Verification'),
          ],
        ),
        content: const Text(
          'Your account is currently under review by MSWD.\n\nYou cannot access the system until your account has been verified and approved.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}