
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
      "image": "assets/images/partial.png",
      "title": "Empowering\nIndependence",
      "desc": "Designed for the partially sighted. Navigate the world safely with real-time object detection and smart text reading."
    },
    {
      "image": "assets/images/caretaker.png",
      "title": "Peace of Mind\nfor Caretakers",
      "desc": "Stay connected to your loved ones. Monitor their safety and receive real-time updates from anywhere."
    },
    {
      "image": "assets/images/mswd.png",
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    final primaryColor = Theme.of(context).primaryColor != Colors.blue
        ? Theme.of(context).primaryColor
        : const Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: Colors.white, 
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // 1. TOP SECTION: SKIP & IMAGES
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Skip Button (Top Right)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const RoleSelectionScreen()),
                          );
                        },
                        child: Text(
                          "Skip",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Image Carousel area
                  SizedBox(
                    height: size.height * 0.35, 
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (value) => setState(() => _currentPage = value),
                      itemCount: _onboardingData.length,
                      itemBuilder: (context, index) {
                        return _buildImageCard(
                          imagePath: _onboardingData[index]["image"]!,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 2. BOTTOM SECTION: TEXT & CONTROLS
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    
                    // Animated Text Section
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: Text(
                              _onboardingData[_currentPage]["title"]!,
                              key: ValueKey<String>("title_$_currentPage"),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _onboardingData[_currentPage]["desc"]!,
                              key: ValueKey<String>("desc_$_currentPage"),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Controls (Dots & Button)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
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

                          // Next Button
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
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: Removed the purple circle Stack and padding.
  // The image now takes up the full available space provided by the parent SizedBox.
  Widget _buildImageCard({required String imagePath}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10), // Minimal side padding
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain, // Ensures it scales to the max height available
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                "Image not found:\n$imagePath",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          );
        },
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