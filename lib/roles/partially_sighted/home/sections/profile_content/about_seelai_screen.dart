// File: lib/roles/partially_sighted/home/sections/profile_content/about_seelai_screen.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Added shimmer

class AboutSeelaiScreen extends StatefulWidget {
  final dynamic theme;
  final bool isDarkMode;

  const AboutSeelaiScreen({
    super.key,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  State<AboutSeelaiScreen> createState() => _AboutSeelaiScreenState();
}

class _AboutSeelaiScreenState extends State<AboutSeelaiScreen> {
  // Requested Color Palette
  final Color _primaryColor = const Color(0xFF8B5CF6);
  bool _isSimulatingLoad = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isSimulatingLoad = false);
    });
  }

  // ==========================================
  // WIDGET: SKELETON
  // ==========================================
  Widget _buildSkeletonAbout() {
    final baseColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo skeleton
            Container(width: 110, height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28.0))),
            const SizedBox(height: 16),
            
            // App Title & Version skeleton
            Container(width: 120, height: 26, color: Colors.white),
            const SizedBox(height: 6),
            Container(width: 80, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 24),
            
            // Cards skeleton
            Container(width: double.infinity, height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            
            const SizedBox(height: 32),
            Container(width: 160, height: 12, color: Colors.white),
            const SizedBox(height: 6),
            Container(width: 140, height: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define clean contrast colors based on theme
    final Color bgColor = widget.isDarkMode ? const Color(0xFF121212) : Colors.white;
    final Color headerColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF111827);
    final Color subTextColor = widget.isDarkMode ? Colors.white70 : const Color(0xFF6B7280);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ==================== WHITE SCROLLING HEADER ====================
          SliverAppBar(
            backgroundColor: headerColor,
            surfaceTintColor: headerColor, 
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
            child: _isSimulatingLoad
              ? _buildSkeletonAbout()
              : Padding(
                  // Reduced top padding slightly to bring content up
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      
                      // ==================== REFINED LOGO SECTION ====================
                      Container(
                        width: 110, // Smaller, tighter size
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28.0), // Smooth, continuous curve
                          boxShadow: widget.isDarkMode ? [] : [ 
                            BoxShadow(
                              color: _primaryColor.withValues(alpha: 0.25), // Soft purple glow instead of harsh black shadow
                              blurRadius: 24,
                              spreadRadius: -4,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28.0), 
                          child: Image.asset(
                            'assets/seelai_app_logo/seelai_app_logo.png',
                            fit: BoxFit.cover, // Removes the awkward white box-in-box look
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.white,
                              child: Icon(
                                Icons.image_not_supported_rounded, 
                                color: Colors.grey[400], 
                                size: 40
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // Tighter spacing
                      
                      // ==================== APP TITLE & VERSION ====================
                      Text(
                        'SEELAI',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: 1.5,
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
                            fontSize: 12,
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24), // Significantly reduced gap before cards
                      
                      // ==================== CONTENT CARDS ====================
                      _buildSectionCard(
                        title: 'Our Mission',
                        icon: Icons.lightbulb_outline_rounded,
                        content: 'SEELAI is an intelligent mobile assistant dedicated to enhancing the daily activities and independence of partially sighted individuals. By bridging the gap between advanced technology and accessibility, we aim to provide a safer, more navigable world for our users.',
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      const SizedBox(height: 12), // Tighter gap between cards
                      
                      _buildSectionCard(
                        title: 'Core Technology',
                        icon: Icons.memory_rounded,
                        content: 'Powered by state-of-the-art machine learning, SEELAI utilizes the YOLO algorithm and TensorFlow Lite to provide rapid, on-device object and face detection. This ensures real-time environmental awareness without the constant need for an internet connection.',
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      const SizedBox(height: 12),

                      _buildSectionCard(
                        title: 'Caretaker Integration',
                        icon: Icons.people_outline_rounded,
                        content: 'SEELAI is built for collaboration. The system seamlessly connects users with their registered caretakers, allowing for trusted facial recognition, secure emergency SOS alerts, and remote technical model management.',
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      
                      const SizedBox(height: 32),
                      Text(
                        'Designed with purpose.\nBuilt for independence.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: subTextColor.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24), 
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // Refined card layout with slightly tighter padding
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
      padding: const EdgeInsets.all(20), // Reduced from 24 to save space
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        ),
        boxShadow: widget.isDarkMode 
            ? [] 
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced from 10
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17, // Slightly smaller
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced gap
          Text(
            content,
            style: TextStyle(
              fontSize: 14, // Scaled down slightly for better density
              height: 1.5,
              color: subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}