import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:seelai_app/screens/onboarding_screen.dart';

class AnimatedSplashScreenWidget extends StatefulWidget {
  const AnimatedSplashScreenWidget({super.key});

  @override
  State<AnimatedSplashScreenWidget> createState() =>
      _AnimatedSplashScreenWidgetState();
}

class _AnimatedSplashScreenWidgetState extends State<AnimatedSplashScreenWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _fadeController.forward().then((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const OnboardingScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Lottie.asset(
            'assets/icons/Seelai.json',
            width: 400,
            height: 400,
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
          ),
        ),
      ),
    );
  }
}