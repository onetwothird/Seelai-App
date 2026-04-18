import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seelai_app/screens/role_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer; // Add Timer variable

  final List<Map<String, String>> _onboardingData = [
    {
      "image": "assets/onboarding_icons/onboarding_0.png", 
      "title": "Empowering\nIndependence",
      "desc": "Your daily assistant. Navigate safely with real-time detection of objects, face, and text documents."
    },
    {
      "image": "assets/onboarding_icons/onboarding_1.png", 
      "title": "Stay connected\nand in control",
      "desc": "Caretakers can track the real-time location of partially sighted users, ensuring safety, quick assistance, and peace of mind wherever they go."
    },
    {
      "image": "assets/onboarding_icons/onboarding_2.png", 
      "title": "Manage Network\n& SOS",
      "desc": ""
    },
    {
      "image": "assets/onboarding_icons/onboarding_3.png", 
      "title": "Users Assistance\nRequests",
      "desc": ""
    },
     {
      "image": "assets/onboarding_icons/onboarding_4.png", 
      "title": "MSWD Centralized\nMonitoring",
      "desc": ""
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer(); // Start the auto-slide timer when screen loads
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer to prevent memory leaks
    _pageController.dispose();
    super.dispose();
  }

  // Logic to auto-slide every 5 seconds
  void _startTimer() {
    _timer?.cancel(); 
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _onboardingData.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuart,
        );
      } else {
        _timer?.cancel(); // Stop auto-sliding on the last page
      }
    });
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    } else {
      Navigator.pushReplacement( 
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
    }
  }

  Widget _buildDescriptionText(String text) {
    if (text.isEmpty) return const SizedBox.shrink();

    const baseStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    );

    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w900);

    if (text.startsWith("Your daily assistant")) {
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            const TextSpan(text: "Your daily "),
            TextSpan(text: "assistant", style: boldStyle),
            const TextSpan(text: ". Navigate safely with real-time detection of "),
            TextSpan(text: "objects", style: boldStyle),
            const TextSpan(text: ", "),
            TextSpan(text: "face", style: boldStyle),
            const TextSpan(text: ", and "),
            TextSpan(text: "text documents", style: boldStyle),
            const TextSpan(text: "."),
          ],
        ),
      );
    }

    if (text.startsWith("Caretakers can track")) {
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            const TextSpan(text: "Caretakers can "),
            TextSpan(text: "track the real-time location", style: boldStyle),
            const TextSpan(text: " of partially sighted users, "),
            TextSpan(text: "ensuring safety", style: boldStyle),
            const TextSpan(text: ", "),
            TextSpan(text: "quick assistance", style: boldStyle),
            const TextSpan(text: ", and "),
            TextSpan(text: "peace of mind", style: boldStyle),
            const TextSpan(text: " wherever they go."),
          ],
        ),
      );
    }

    return Text(text, style: baseStyle);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor != Colors.blue
        ? Theme.of(context).primaryColor
        : const Color(0xFF200E4B);
        
    final darkPurple = const Color(0xFF3B0764); 
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (value) {
              setState(() => _currentPage = value);
              _startTimer(); // Reset the timer if the user manually swipes
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              final imagePath = _onboardingData[index]["image"]!;
              final isSvg = imagePath.toLowerCase().endsWith('.svg');

              return Stack(
                children: [
                  Positioned.fill(
                    child: isSvg 
                      ? SvgPicture.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          alignment: Alignment.center, 
                        )
                      : Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          alignment: Alignment.center, 
                        ),
                  ),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: size.height * 0.4, 
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            darkPurple.withValues(alpha: 0.0),   
                            darkPurple.withValues(alpha: 0.3),   
                            darkPurple.withValues(alpha: 0.8),   
                            darkPurple,                          
                          ],
                          stops: const [0.0, 0.4, 0.75, 1.0], 
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: size.height * 0.09, 
                    left: 32,
                    right: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_onboardingData[index]["title"]!.isNotEmpty)
                          Text(
                            _onboardingData[index]["title"]!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800, 
                              height: 1.2,
                            ),
                          ),
                        const SizedBox(height: 16),
                        _buildDescriptionText(_onboardingData[index]["desc"]!),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24, top: 10),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RoleSelectionScreen()),
                        );
                      },
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 32, right: 32, bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _onboardingData.length,
                          (index) => _buildDot(index, Colors.white),
                        ),
                      ),

                      TextButton(
                        onPressed: _nextPage,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.white60, width: 1.5), 
                          ),
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

  Widget _buildDot(int index, Color activeColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 6),
      height: 8,
      width: _currentPage == index ? 28 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? activeColor 
            : Colors.white30, 
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}