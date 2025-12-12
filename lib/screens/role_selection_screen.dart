// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/themes/widgets.dart';
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

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;

  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _floatController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;

    return Scaffold(
      body: Stack(
        children: [
          // Enhanced gradient background (matching onboarding)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFAF5FF),
                  Color(0xFFFFF1F2),
                  Color(0xFFF0FDFA),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Top left background shape
          Positioned(
            top: -90,
            left: -30,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/bg_shape_3.png',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Bottom right background shape
          Positioned(
            bottom: -60,
            right: -60,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/bg_shape_1.png',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.06,
                  right: screenWidth * 0.06,
                  top: isSmallScreen ? 12 : 16,
                  bottom: isSmallScreen ? 24 : 32,
                ),
                child: Column(
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back_ios_rounded),
                          color: primary,
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 12 : (isLargeScreen ? screenHeight * 0.025 : screenHeight * 0.02)),

                    // Eye Animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value * 0.5),
                            child: Container(
                              height: isSmallScreen 
                                ? 70 
                                : (isLargeScreen ? 110 : 90),
                              width: isSmallScreen 
                                ? 70 
                                : (isLargeScreen ? 110 : 90),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    primary.withOpacity(0.08),
                                    Colors.transparent,
                                  ],
                                  stops: [0.5, 1.0],
                                ),
                              ),
                              child: Lottie.asset(
                                'assets/icons/eye.json',
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 12 : (isLargeScreen ? 24 : 18)),

                    // Header
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => primaryGradient.createShader(bounds),
                            child: Text(
                              "Select Your Role",
                              style: h1.copyWith(
                                fontSize: _getResponsiveFontSize(
                                  screenWidth, 
                                  isSmallScreen, 
                                  isLargeScreen, 
                                  0.080, 
                                  0.070, 
                                  0.090
                                ),
                                color: white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          Text(
                            "Choose how you'll use the app",
                            style: body.copyWith(
                              fontSize: _getResponsiveFontSize(
                                screenWidth, 
                                isSmallScreen, 
                                isLargeScreen, 
                                0.038, 
                                0.034, 
                                0.042
                              ),
                              color: grey,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 20 : (isLargeScreen ? screenHeight * 0.04 : 28)),

                    // Role Cards Grid
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            _buildEnhancedRoleCard(
                              role: 'visually_impaired',
                              icon: Icons.visibility_off_rounded,
                              title: 'Visually Impaired',
                              subtitle: 'Get personalized support',
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              screenWidth: screenWidth,
                              isSmallScreen: isSmallScreen,
                              isLargeScreen: isLargeScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 10 : 12),
                            _buildEnhancedRoleCard(
                              role: 'caretaker',
                              icon: Icons.favorite_rounded,
                              title: 'Caretaker',
                              subtitle: 'Provide care and support',
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                              ),
                              screenWidth: screenWidth,
                              isSmallScreen: isSmallScreen,
                              isLargeScreen: isLargeScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 10 : 12),
                            _buildEnhancedRoleCard(
                              role: 'admin',
                              icon: Icons.business,
                              title: 'MSWD Staff',
                              subtitle: 'Manage and oversee',
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                              ),
                              screenWidth: screenWidth,
                              isSmallScreen: isSmallScreen,
                              isLargeScreen: isLargeScreen,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 20 : (isLargeScreen ? screenHeight * 0.035 : 28)),

                    // Continue Button
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: CustomButton(
                        text: "Continue",
                        onPressed: _selectedRole == null ? null : () {
                          _showAuthOptions(context);
                        },
                        isLarge: true,
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 12 : 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getResponsiveFontSize(
    double screenWidth,
    bool isSmallScreen,
    bool isLargeScreen,
    double normalSize,
    double smallSize,
    double largeSize,
  ) {
    if (isSmallScreen) {
      return screenWidth * smallSize;
    } else if (isLargeScreen) {
      return screenWidth * largeSize;
    }
    return screenWidth * normalSize;
  }

  Widget _buildEnhancedRoleCard({
    required String role,
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required double screenWidth,
    required bool isSmallScreen,
    required bool isLargeScreen,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.all(isSmallScreen ? 16 : (isLargeScreen ? 24 : 20)),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: isSelected ? 2.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? primary.withOpacity(0.35) : black.withOpacity(0.08),
              blurRadius: isSelected ? 28 : 14,
              offset: Offset(0, isSelected ? 12 : 6),
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon container
                AnimatedContainer(
                  duration: Duration(milliseconds: 400),
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    gradient: isSelected ? gradient : LinearGradient(
                      colors: [greyLighter, greyLighter],
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ] : [],
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? white : grey,
                    size: isSmallScreen ? 28 : (isLargeScreen ? 38 : 32),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 14),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: bodyBold.copyWith(
                          fontSize: _getResponsiveFontSize(
                            screenWidth, 
                            isSmallScreen, 
                            isLargeScreen, 
                            0.050, 
                            0.045, 
                            0.055
                          ),
                          color: isSelected ? primary : black,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Text(
                        subtitle,
                        style: body.copyWith(
                          fontSize: _getResponsiveFontSize(
                            screenWidth, 
                            isSmallScreen, 
                            isLargeScreen, 
                            0.038, 
                            0.034, 
                            0.042
                          ),
                          color: grey,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Check indicator
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: white,
                      size: isSmallScreen ? 16 : 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: black.withOpacity(0.4),
      builder: (context) => Container(
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: black.withOpacity(0.15),
              blurRadius: 30,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: greyLighter,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 32),

            // Icon
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.login_rounded,
                color: white,
                size: 36,
              ),
            ),

            SizedBox(height: 24),

            Text(
              "What's next?",
              style: bodyBold.copyWith(
                fontSize: 22,
                color: black,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Sign in or create an account to get started",
              style: body.copyWith(
                fontSize: 14,
                color: grey,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 32),

            // Login button
            CustomButton(
              text: "Sign In",
              onPressed: () {
                Navigator.pop(context);
                _navigateToLogin(context);
              },
              isLarge: true,
            ),

            SizedBox(height: 14),

            // Sign up button
            CustomButton(
              text: "Create Account",
              isTransparent: true,
              onPressed: () {
                Navigator.pop(context);
                _navigateToSignup(context);
              },
              isLarge: true,
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Widget loginScreen;

    switch (_selectedRole) {
      case 'visually_impaired':
        loginScreen = LoginScreenVisuallyImpaired();
        break;
      case 'caretaker':
        loginScreen = CaretakerLoginScreen();
        break;
      case 'admin':
        loginScreen = MSWDLoginScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => loginScreen),
    );
  }

  void _navigateToSignup(BuildContext context) {
    Widget signupScreen;

    switch (_selectedRole) {
      case 'visually_impaired':
        signupScreen = VisuallyImpairedSignupScreen();
        break;
      case 'caretaker':
        signupScreen = CaretakerSignupScreen();
        break;
      case 'admin':
        signupScreen = MSWDSignupScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => signupScreen),
    );
  }
}