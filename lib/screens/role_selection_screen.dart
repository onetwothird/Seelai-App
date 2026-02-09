// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/roles/visually_impaired/auth/login/login_screen.dart';
import 'package:seelai_app/roles/visually_impaired/auth/signup/signup_screen.dart';
import 'package:seelai_app/roles/caretaker/auth/login/login_screen.dart';
import 'package:seelai_app/roles/caretaker/auth/signup/signup_screen.dart';
import 'package:seelai_app/roles/mswd/auth/login/login_screen.dart';
import 'package:seelai_app/roles/mswd/auth/signup/signup_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedRole;
  
  // Consistent color matching OnboardingScreen
  final Color _primaryColor = const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();

    // Controls the entry of text/cards
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutQuart),
    );

    _contentController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      body: Stack(
        children: [
          // REMOVED: Ambient Background Glows to keep it white only.

          // 2. MAIN CONTENT
          SafeArea(
            child: Column(
              children: [
                // Back Button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
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
                    ],
                  ),
                ),

                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            // Header
                            const Text(
                              "Who is using\nSeelai?",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                letterSpacing: -1.0,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Choose the profile that best describes you to personalize your experience.",
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Cards List
                            Expanded(
                              child: ListView(
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  _buildRoleCard(
                                    id: 'visually_impaired',
                                    title: "Visually Impaired",
                                    subtitle:
                                        "I need assistance navigating my world.",
                                    icon: Icons.visibility_off_outlined,
                                    color: _primaryColor, // Unified Color
                                  ),
                                  const SizedBox(height: 16),
                                  _buildRoleCard(
                                    id: 'caretaker',
                                    title: "Caretaker / Family",
                                    subtitle: "I want to support a loved one.",
                                    icon: Icons.favorite_border_rounded,
                                    color: _primaryColor, // Unified Color
                                  ),
                                  const SizedBox(height: 16),
                                  _buildRoleCard(
                                    id: 'admin',
                                    title: "MSWD Staff",
                                    subtitle:
                                        "I manage cases and support services.",
                                    icon: Icons.badge_outlined,
                                    color: _primaryColor, // Unified Color
                                  ),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _selectedRole != null ? 1.0 : 0.5,
                child: ElevatedButton(
                  onPressed: _selectedRole == null
                      ? null
                      : () => _showAuthBottomSheet(context),
                  style: ElevatedButton.styleFrom(
                    // Unified color
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 8,
                    shadowColor: _primaryColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  void _showAuthBottomSheet(BuildContext context) {
    // Use the unified primary color
    final activeColor = _primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_person_rounded,
                    size: 32, color: activeColor),
              ),
              const SizedBox(height: 24),
              const Text("Let's get you in",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              const Text("Log in or create a new account to continue.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToLogin(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Log In",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToSignup(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    foregroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Create Account",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Widget? targetScreen;
    switch (_selectedRole) {
      case 'visually_impaired':
        targetScreen = const LoginScreenVisuallyImpaired();
        break;
      case 'caretaker':
        targetScreen = const CaretakerLoginScreen();
        break;
      case 'admin':
        targetScreen = const MSWDLoginScreen();
        break;
    }
    if (targetScreen != null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => targetScreen!));
    }
  }

  void _navigateToSignup(BuildContext context) {
    Widget? targetScreen;
    switch (_selectedRole) {
      case 'visually_impaired':
        targetScreen = const VisuallyImpairedSignupScreen();
        break;
      case 'caretaker':
        targetScreen = const CaretakerSignupScreen();
        break;
      case 'admin':
        targetScreen = const MSWDSignupScreen();
        break;
    }
    if (targetScreen != null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => targetScreen!));
    }
  }
}