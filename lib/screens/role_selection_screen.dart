import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/themes/widgets.dart';
import 'package:seelai_app/roles/visually_impaired/login/login_screen.dart';
import 'package:seelai_app/roles/visually_impaired/signup/signup_screen.dart';
import 'package:seelai_app/roles/caretaker/login/login_screen.dart';
import 'package:seelai_app/roles/caretaker/signup/signup_screen.dart';
import 'package:seelai_app/roles/msdwd/login/login_screen.dart';
import 'package:seelai_app/roles/msdwd/signup/signup_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;

  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _floatController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
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

          // Animated background shapes
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Positioned(
                top: -90 + _floatAnimation.value,
                left: -30,
                child: Opacity(
                  opacity: 0.7,
                  child: Image.asset(
                    'assets/images/bg_shape_3.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),

          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: -60 - _floatAnimation.value,
                right: -60,
                child: Opacity(
                  opacity: 0.7,
                  child: Image.asset(
                    'assets/images/bg_shape_1.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.05),

                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_rounded),
                        color: primary,
                        iconSize: 24,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Header with animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
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
                              Icons.people_rounded,
                              size: 48,
                              color: white,
                            ),
                          ),
                          SizedBox(height: 24),
                          ShaderMask(
                            shaderCallback: (bounds) => primaryGradient.createShader(bounds),
                            child: Text(
                              "Choose Your Role",
                              style: h1.copyWith(
                                fontSize: screenWidth * 0.085,
                                color: white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Select how you'll be using the app",
                            style: body.copyWith(
                              fontSize: screenWidth * 0.042,
                              color: grey,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    // Role Cards with staggered animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            _buildModernRoleCard(
                              role: 'visually_impaired',
                              icon: Icons.remove_red_eye_rounded,
                              title: 'Visually Impaired',
                              description: 'Visually impaired individual',
                              gradient: LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              screenWidth: screenWidth,
                            ),
                            SizedBox(height: 16),
                            _buildModernRoleCard(
                              role: 'caretaker',
                              icon: Icons.favorite_rounded,
                              title: 'Caretaker',
                              description: 'Care provider and support',
                              gradient: LinearGradient(
                                colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                              ),
                              screenWidth: screenWidth,
                            ),
                            SizedBox(height: 16),
                            _buildModernRoleCard(
                              role: 'admin',
                              icon: Icons.admin_panel_settings_rounded,
                              title: 'MSDWD Staff',
                              description: 'Department administrator',
                              gradient: LinearGradient(
                                colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                              ),
                              screenWidth: screenWidth,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

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

                    SizedBox(height: screenHeight * 0.04),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRoleCard({
    required String role,
    required IconData icon,
    required String title,
    required String description,
    required LinearGradient gradient,
    required double screenWidth,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : greyLighter,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon container with gradient
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : LinearGradient(
                  colors: [greyLighter, greyLighter],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ] : [],
              ),
              child: Icon(
                icon,
                color: isSelected ? white : grey,
                size: 32,
              ),
            ),
            SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: bodyBold.copyWith(
                      fontSize: screenWidth * 0.048,
                      color: isSelected ? primary : black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: caption.copyWith(
                      fontSize: screenWidth * 0.036,
                      color: grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Check icon
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: white,
                  size: 20,
                ),
              ),
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
      builder: (context) => Container(
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: greyLighter,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 28),
            
            // Icon
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.login_rounded,
                color: white,
                size: 32,
              ),
            ),
            
            SizedBox(height: 20),
            
            Text(
              "What would you like to do?",
              style: bodyBold.copyWith(
                fontSize: 20,
                color: black,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Choose an option to continue",
              style: body.copyWith(
                fontSize: 14,
                color: grey,
              ),
            ),
            
            SizedBox(height: 28),
            
            // Login button
            CustomButton(
              text: "Login to Existing Account",
              onPressed: () {
                Navigator.pop(context);
                _navigateToLogin(context);
              },
              isLarge: true,
            ),
            
            SizedBox(height: 12),
            
            // Sign up button
            CustomButton(
              text: "Create New Account",
              isTransparent: true,
              onPressed: () {
                Navigator.pop(context);
                _navigateToSignup(context);
              },
              isLarge: true,
            ),
            
            SizedBox(height: 16),
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
        loginScreen = MSDWDLoginScreen();
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
        signupScreen = MSDWDSignupScreen();
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