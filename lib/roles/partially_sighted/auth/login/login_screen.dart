// ignore_for_file: deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:seelai_app/roles/partially_sighted/caretaker/caretaker_selection_screen.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/partially_sighted/auth/signup/signup_screen.dart';
import 'package:seelai_app/roles/partially_sighted/home/home_screen.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:seelai_app/firebase/activity_logs_service.dart';
import 'package:seelai_app/mobile/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreenVisuallyImpaired extends StatefulWidget {
  const LoginScreenVisuallyImpaired({super.key});

  @override
  State<LoginScreenVisuallyImpaired> createState() => _LoginScreenVisuallyImpairedState();
}

class _LoginScreenVisuallyImpairedState extends State<LoginScreenVisuallyImpaired> with TickerProviderStateMixin {
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
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
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
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45, 
            child: SafeArea(
              child: Center(
                child: Container(
                  width: size.width * 0.9,
                  padding: EdgeInsets.all(10),
                  child: Lottie.asset(
                    'assets/icons/Seelai.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // 2. Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new_rounded),
              color: const Color(0xFF1E293B),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.all(12),
                elevation: 0,
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),

          // 3. Bottom Section: The Card
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 30,
                        offset: Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                          child: Opacity(
                            opacity: 0.08, 
                            child: Image.asset(
                              'assets/images/eye background.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(32, 40, 32, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome, Partial User!",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Sign in to continue your journey.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            SizedBox(height: 32),

                            // Standard Login Fields
                            _buildTextField(
                              controller: _emailController,
                              hint: "Email address",
                              icon: Icons.email_outlined,
                            ),
                            
                            SizedBox(height: 20),

                            _buildTextField(
                              controller: _passwordController,
                              hint: "Password",
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading ? null : _showForgotPasswordDialog,
                                child: Text(
                                  "Forgot password?",
                                  style: TextStyle(
                                    color: brandColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 24),

                            // --- ADDED GOOGLE SECTION ---
                            Row(
                              children: [
                                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text("OR", style: TextStyle(color: Color(0xFF94A3B8))),
                                ),
                                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                              ],
                            ),
                            
                            SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _handleGoogleLogin,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Color(0xFFE2E8F0)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  backgroundColor: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.g_mobiledata_rounded, size: 40, color: brandColor), 
                                    SizedBox(width: 8),
                                    Text(
                                      "Continue with Google",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // --- END GOOGLE SECTION ---

                            SizedBox(height: 24),

                            Center(
                              child: TextButton(
                                onPressed: _isLoading ? null : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VisuallyImpairedSignupScreen(),
                                    ),
                                  );
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                                    children: [
                                      TextSpan(text: "Don't have an account? "),
                                      TextSpan(
                                        text: "Sign Up",
                                        style: TextStyle(
                                          color: brandColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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

          if (_isLoading)
            LoadingOverlay(
              message: 'Please wait...',
              isVisible: _isLoading,
            ),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: Color(0xFF64748B)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Color(0xFF94A3B8),
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter your email'), backgroundColor: error));
                return;
              }
              try {
                await authService.value.sendPasswordResetEmail(email: emailController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset email sent!'), backgroundColor: success));
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: error));
              }
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  // --- GOOGLE LOGIN LOGIC ---
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential = await authService.value.signInWithGoogle();
      
      if (userCredential == null) {
        // User canceled the Google flow
        setState(() => _isLoading = false);
        return;
      }

      // Check if they already have a database profile filled out
      Map<String, dynamic>? userData = await databaseService.getUserData(userCredential.user!.uid);
      
      if (userData != null) {
        // USER EXISTS IN DB: Proceed with normal login routing
        String userRole = userData['role'] ?? '';
        
        if (userRole != 'visually_impaired') {
          await authService.value.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('This account is not registered as a Partial User'), backgroundColor: error),
            );
          }
          return;
        }
        
        await activityLogsService.logActivity(
          userId: userCredential.user!.uid,
          action: 'login',
          details: 'User logged in via Google as $userRole',
        );
        
        userData['uid'] = userCredential.user!.uid;
        
        bool hasCaretaker = false;
        if (userData['assignedCaretakers'] != null) {
          Map<dynamic, dynamic> assignedCaretakers = userData['assignedCaretakers'] as Map;
          hasCaretaker = assignedCaretakers.isNotEmpty;
        }
        
        if (mounted) {
          if (hasCaretaker) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VisuallyImpairedHomeScreen(userData: userData)));
            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome back!'), backgroundColor: primary));
            });
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CaretakerSelectionScreen(userData: userData)));
          }
        }
      } else {
        // NEW GOOGLE USER: They authenticated, but haven't filled out the form.
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisuallyImpairedSignupScreen(googleUser: userCredential.user),
            ),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Almost there! Please complete your medical profile to finish registration.'), 
              backgroundColor: primary,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- STANDARD LOGIN LOGIC ---
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all fields'), backgroundColor: error));
      return;
    }
    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid email address'), backgroundColor: error));
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await authService.value.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      Map<String, dynamic>? userData = await databaseService.getUserData(userCredential.user!.uid);
      
      if (userData != null) {
        String userRole = userData['role'] ?? '';
        
        if (userRole != 'visually_impaired') {
          await authService.value.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This account is not registered as a User'), backgroundColor: error));
          }
          return;
        }
        
        await activityLogsService.logActivity(
          userId: userCredential.user!.uid,
          action: 'login',
          details: 'User logged in as $userRole',
        );
        
        userData['uid'] = userCredential.user!.uid;
        
        bool hasCaretaker = false;
        if (userData['assignedCaretakers'] != null) {
          Map<dynamic, dynamic> assignedCaretakers = userData['assignedCaretakers'] as Map;
          hasCaretaker = assignedCaretakers.isNotEmpty;
        }
        
        if (mounted) {
          if (hasCaretaker) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VisuallyImpairedHomeScreen(userData: userData)));
            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome back!'), backgroundColor: primary));
            });
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CaretakerSelectionScreen(userData: userData)));
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      if (e.code == 'user-not-found') errorMessage = 'No user found with this email';
      else if (e.code == 'wrong-password') errorMessage = 'Wrong password';
      else if (e.code == 'invalid-email') errorMessage = 'Invalid email address';
      else if (e.code == 'user-disabled') errorMessage = 'Account disabled';
      else if (e.code == 'too-many-requests') errorMessage = 'Too many attempts. Try again later';
      else errorMessage = e.message ?? 'Login failed';
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: error));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}