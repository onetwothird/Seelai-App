// File: lib/roles/caretaker/home/sections/profile_screen/about_seelai_screen.dart

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
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  
                  // ==================== REFINED LOGO SECTION ====================
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28.0),
                      boxShadow: isDarkMode ? [] : [ 
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.25), 
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
                        fit: BoxFit.cover, 
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
                  const SizedBox(height: 16),
                  
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
                  const SizedBox(height: 24),
                  
                  // ==================== CONTENT CARDS ====================
                  _buildSectionCard(
                    title: 'Our Mission',
                    icon: Icons.lightbulb_outline_rounded,
                    content: 'SEELAI bridges the gap between advanced technology and accessibility. For caretakers, it provides a comprehensive suite of tools to monitor, assist, and ensure the safety of partially sighted individuals from anywhere.',
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSectionCard(
                    title: 'Monitoring & Alerts',
                    icon: Icons.notification_important_rounded,
                    content: 'Receive instant SOS emergency notifications, track real-time locations during critical moments, and maintain a secure line of communication with your assigned patients to provide immediate assistance.',
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                  const SizedBox(height: 12),

                  _buildSectionCard(
                    title: 'System Management',
                    icon: Icons.dashboard_customize_rounded,
                    content: 'Use the SEELAI ecosystem to remotely manage trusted face registrations and monitor technical statistics, helping your patients navigate their world safely and independently.',
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                  
                  const SizedBox(height: 32),
                  Text(
                    'Designed for support.\nBuilt for peace of mind.',
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        ),
        boxShadow: isDarkMode 
            ? [] 
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
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
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}