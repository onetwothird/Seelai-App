// File: lib/roles/partially_sighted/home/sections/profile_content/about_seelai_screen.dart

import 'package:flutter/material.dart';

class AboutSeelaiScreen extends StatelessWidget {
  final dynamic theme;
  final bool isDarkMode;
  
  // Requested Color Palette
  final Color _primaryColor = const Color(0xFF8B5CF6);

  const AboutSeelaiScreen({
    super.key,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Define clean contrast colors based on theme
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF9FAFB);
    final Color headerColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final Color subTextColor = isDarkMode ? Colors.white70 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ==================== WHITE SCROLLING HEADER ====================
          SliverAppBar(
            backgroundColor: headerColor,
            surfaceTintColor: headerColor, // Prevents color shifting on scroll
            pinned: true,
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            iconTheme: IconThemeData(color: textColor),
            centerTitle: true,
            title: Text(
              'About Seelai',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // ==================== MAIN CONTENT ====================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo/Icon Concept
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.remove_red_eye_rounded, size: 50, color: _primaryColor),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'SEELAI',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        color: _primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Content Cards
                  _buildSectionCard(
                    title: 'Our Mission',
                    icon: Icons.lightbulb_outline_rounded,
                    content: 'SEELAI is an intelligent mobile assistant dedicated to enhancing the daily activities and independence of partially sighted individuals. By bridging the gap between advanced technology and accessibility, we aim to provide a safer, more navigable world for our users.',
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSectionCard(
                    title: 'Core Technology',
                    icon: Icons.memory_rounded,
                    content: 'Powered by state-of-the-art machine learning, SEELAI utilizes the YOLO algorithm and TensorFlow Lite to provide rapid, on-device object and face detection. This ensures real-time environmental awareness without the constant need for an internet connection.',
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                  const SizedBox(height: 16),

                  _buildSectionCard(
                    title: 'Caretaker Integration',
                    icon: Icons.people_outline_rounded,
                    content: 'SEELAI is built for collaboration. The system seamlessly connects users with their registered caretakers, allowing for trusted facial recognition, secure emergency SOS alerts, and remote technical model management.',
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                  
                  const SizedBox(height: 48),
                  Text(
                    'Designed with purpose.\nBuilt for independence.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: subTextColor.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Clean, flat card layout with primary color accents
  Widget _buildSectionCard({
    required String title, 
    required IconData icon, 
    required String content,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        ),
        boxShadow: isDarkMode 
            ? [] 
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _primaryColor, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}