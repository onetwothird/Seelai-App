// File: lib/roles/caretaker/home/sections/profile_screen/privacy_policy_screen.dart

import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final dynamic theme;
  final bool isDarkMode;
  
  // Requested Color Palette
  final Color _primaryColor = const Color(0xFF8B5CF6);

  const PrivacyPolicyScreen({
    super.key,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Pure white background in light mode to match the header seamlessly
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final Color headerColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
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
              'Privacy Policy',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caretaker\nData Privacy',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      height: 1.1,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Last updated: April 2026\n\nAt SEELAI, we protect the privacy of both our partially sighted users and their dedicated caretakers. This policy outlines your responsibilities regarding patient data and how your own information is handled.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Policy Sections
                  _buildPolicySection(
                    title: '1. Patient Data Access',
                    icon: Icons.visibility_outlined,
                    content: 'As a caretaker, you are granted access to sensitive patient data, including real-time location and emergency SOS alerts. This access is strictly bound to the patients who have explicitly authorized your connection.',
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                  
                  _buildPolicySection(
                    title: '2. Camera & Visual Privacy',
                    icon: Icons.camera_alt_outlined,
                    content: 'You do not have continuous access to the patient\'s live camera feed. Visual data and location are only transmitted during active SOS emergencies or specific assistance requests to protect patient autonomy.',
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),

                  _buildPolicySection(
                    title: '3. Your Information',
                    icon: Icons.admin_panel_settings_outlined,
                    content: 'Your contact information and facial mapping data (if registered into the system for recognition) are encrypted. This data is shared exclusively with your assigned patients to establish trust and recognition.',
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),

                  _buildPolicySection(
                    title: '4. Security & Compliance',
                    icon: Icons.shield_outlined,
                    content: 'All data is stored securely using our Firebase backend services. We require all caretakers to act responsibly, maintain the confidentiality of the patients they monitor, and never share patient data with unauthorized third parties.',
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),

                  const SizedBox(height: 32),
                  
                  // Consent Footer Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _primaryColor.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_outlined, color: _primaryColor, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'By acting as a SEELAI caretaker, you consent to this policy and agree to handle patient data ethically. For account deletion, contact the system administrator.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection({
    required String title, 
    required IconData icon, 
    required String content,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
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
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
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
          ),
        ],
      ),
    );
  }
}