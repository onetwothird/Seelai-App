import 'package:flutter/material.dart';
import 'package:seelai_app/screens/role_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "image": "assets/onboarding_icons/partially_sighted.png",
      "title": "Empowering\nIndependence",
      "desc": "Designed for the partially sighted. Navigate the world safely with real-time object detection, caretaker's face detection, and smart text reading."
    },
    {
      "image": "assets/onboarding_icons/caretaker.png",
      "title": "Peace of Mind\nfor Caretakers",
      "desc": "Stay connected to your loved ones. Monitor their safety and receive real-time updates from anywhere."
    },
    {
      "image": "assets/onboarding_icons/mswd.png",
      "title": "Verified\nMSWD Oversight",
      "desc": "Trusted administration. MSWD admins ensure data integrity and secure account management for the entire community."
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    } else {
      // Changed from pushReplacement to push
      Navigator.push( 
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor != Colors.blue
        ? Theme.of(context).primaryColor
        : const Color(0xFF8B5CF6);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. SWIPEABLE CONTENT
          PageView.builder(
            controller: _pageController,
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  
                  // --- BACKGROUND IMAGE ---
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: size.height * 0.70, 
                    child: Image.asset(
                      _onboardingData[index]["image"]!,
                      fit: BoxFit.cover, // Keep cover to maintain the full background look
                      // CHANGED: x changed from 0 to 1.0 to anchor to the right edge
                      alignment: const Alignment(0.6, 0.5), 
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.broken_image, size: 50));
                      },
                    ),
                  ),

                  // --- SHORTER WHITE GRADIENT ---
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: size.height * 0.40, 
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.85),
                            Colors.white,
                            Colors.white,
                          ],
                          stops: const [0.0, 0.3, 0.6, 1.0], 
                        ),
                      ),
                    ),
                  ),

                  // --- TEXT CONTENT ---
                  Positioned(
                    bottom: size.height * 0.18, 
                    left: 32,
                    right: 32,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _onboardingData[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _onboardingData[index]["desc"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. FIXED UI OVERLAY (Buttons & Dots)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Right: Skip Button
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24, top: 10),
                    child: TextButton(
                      onPressed: () {
                        // Changed from pushReplacement to push
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RoleSelectionScreen()),
                        );
                      },
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom: Controls (Dots & Button)
                Padding(
                  padding: const EdgeInsets.only(left: 32, right: 32, bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicator Dots
                      Row(
                        children: List.generate(
                          _onboardingData.length,
                          (index) => _buildDot(index, primaryColor),
                        ),
                      ),

                      // Next / Get Started Button
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: primaryColor.withValues(alpha: 0.4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == _onboardingData.length - 1
                                  ? "Get Started"
                                  : "Next",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentPage != _onboardingData.length - 1) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, Color primaryColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 6),
      height: 8,
      width: _currentPage == index ? 28 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? primaryColor
            : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}