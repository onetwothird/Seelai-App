// File: lib/roles/mswd/home/sections/profile_content/privacy_policy_screen.dart

import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final dynamic theme;
  final bool isDarkMode;
  
  final Color _primaryColor = const Color(0xFF8B5CF6);

  const PrivacyPolicyScreen({
    super.key,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
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
                    'Administrative\nData Compliance',
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
                    'Last updated: April 2026\n\nAs an MSWD Administrator for the SEELAI system, you are bound by strict municipal and national data privacy laws. This policy outlines your administrative responsibilities regarding citizen data.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Policy Sections
                  _buildPolicySection(
                    title: '1. Elevated Data Access',
                    icon: Icons.admin_panel_settings_outlined,
                    content: 'You possess elevated access to sensitive demographic, medical diagnoses, and real-time location data of citizens. This access is granted strictly for official municipal monitoring, support coordination, and emergency dispatch purposes.',
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                  
                  _buildPolicySection(
                    title: '2. Strict Confidentiality',
                    icon: Icons.lock_outline_rounded,
                    content: 'All citizen records, SOS alert histories, and caretaker assignments are highly confidential. Unauthorized exporting, sharing, or misuse of this data outside official MSWD operations is a direct violation of data privacy regulations.',
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),

                  _buildPolicySection(
                    title: '3. Mandatory Audit Logging',
                    icon: Icons.manage_search_rounded,
                    content: 'To maintain complete transparency and systemic accountability, all administrative actions—including profile reviews, data report exports, and broadcast messaging—are permanently recorded in the system activity logs.',
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),

                  _buildPolicySection(
                    title: '4. Official Communications',
                    icon: Icons.campaign_outlined,
                    content: 'The system broadcast and direct messaging tools must be utilized exclusively for official MSWD announcements, emergency warnings, and verified community support initiatives.',
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
                        Icon(Icons.gavel_rounded, color: _primaryColor, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'By logging into the MSWD Admin Portal, you acknowledge these terms and agree to handle all citizen data ethically and legally.',
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