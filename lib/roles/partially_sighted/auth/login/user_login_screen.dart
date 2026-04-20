import 'package:flutter/material.dart';
import 'package:seelai_app/roles/partially_sighted/caretaker/caretaker_selection_screen.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/partially_sighted/auth/signup/user_signup_screen.dart';
import 'package:seelai_app/roles/partially_sighted/home/home_screen.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:seelai_app/firebase/activity_logs_service.dart';
import 'package:seelai_app/mobile/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreenPartiallySighted extends StatefulWidget {
  const LoginScreenPartiallySighted({super.key});

  @override
  State<LoginScreenPartiallySighted> createState() => _LoginScreenPartiallySightedState();
}

class _LoginScreenPartiallySightedState extends State<LoginScreenPartiallySighted> with TickerProviderStateMixin {
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
          top: -60, // Try -60, -80, or -100 to pull it up more
          left: 0,
          right: 0,
          height: (size.height * 0.40) + 60, // Remember to add that exact amount back here
          child: Image.asset(
            'assets/seelai-icons/seelai_model.gif',
            fit: BoxFit.cover, 
          ),
        ),
         // 2. Back Button (High Contrast & Clear UX)
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3), // Semi-transparent dark circle
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.white, // Crisp white arrow
                iconSize: 22,
                tooltip: 'Go back', // Good for accessibility screen readers!
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
                        color: Colors.black.withValues(alpha: 0.05), // FIXED
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
                              'assets/icons/eye background.jpg',
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

                            // --- GOOGLE SECTION ---
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
                                  side: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Color(0xFF1E293B),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/icons/google.png',
                                      height: 24,
                                      width: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Continue with Google",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: 0.2,
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
                                      builder: (context) => PartiallySightedSignupScreen(),
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
              message: '',
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
    // FIXED: Save parent context
    final parentContext = context;
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: parentContext,
      // FIXED: Rename builder context
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) {
                Navigator.pop(dialogContext);
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(content: Text('Please enter your email'), backgroundColor: error));
                }
                return;
              }
              try {
                await authService.value.sendPasswordResetEmail(email: emailController.text.trim());
                
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                
                if (!parentContext.mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(content: Text('Password reset email sent!'), backgroundColor: success));
              } catch (e) {
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                
                if (!parentContext.mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: error));
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
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential? userCredential = await authService.value.signInWithGoogle();
      
      if (userCredential == null) {
        // User canceled the Google flow
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check if they already have a database profile filled out
      Map<String, dynamic>? userData = await databaseService.getUserData(userCredential.user!.uid);
      
      if (userData != null) {
        // USER EXISTS IN DB: Proceed with normal login routing
        String userRole = userData['role'] ?? '';
        
        if (userRole != 'partially_sighted') {
          await authService.value.signOut();
          if (!mounted) return; 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This account is not registered as a Partially Sighted User'), backgroundColor: error),
          );
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
        
        if (!mounted) return; 
        
        if (hasCaretaker) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PartiallySightedHomeScreen(userData: userData)));
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome back!'), backgroundColor: primary));
            }
          });
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CaretakerSelectionScreen(userData: userData)));
        }
      } else {
        // NEW GOOGLE USER: They authenticated, but haven't filled out the form.
        if (!mounted) return; // FIXED: Add mounted guard
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PartiallySightedSignupScreen(googleUser: userCredential.user),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await authService.value.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      Map<String, dynamic>? userData = await databaseService.getUserData(userCredential.user!.uid);
      
      if (userData != null) {
        String userRole = userData['role'] ?? '';
        
        if (userRole != 'partially_sighted') {
          await authService.value.signOut();
          if (!mounted) return; // FIXED: Add mounted guard
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This account is not registered as a Partially Sighted User'), backgroundColor: error));
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
        
        if (!mounted) return; // FIXED: Add mounted guard
        
        if (hasCaretaker) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PartiallySightedHomeScreen(userData: userData)));
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome back!'), backgroundColor: primary));
            }
          });
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CaretakerSelectionScreen(userData: userData)));
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      
      // FIXED: Wrapped all statements in blocks
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Account disabled';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many attempts. Try again later';
      } else {
        errorMessage = e.message ?? 'Login failed';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: error));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}