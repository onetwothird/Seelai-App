// File: lib/roles/partially_sighted/home/sections/profile_content/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Added shimmer

class PrivacyPolicyScreen extends StatefulWidget {
  final dynamic theme;
  final bool isDarkMode;

  const PrivacyPolicyScreen({
    super.key,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
  Widget _buildSkeletonPrivacy() {
    final baseColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title skeleton
            Container(width: 180, height: 32, color: Colors.white),
            const SizedBox(height: 6),
            Container(width: 150, height: 32, color: Colors.white),
            const SizedBox(height: 16),
            
            // Subtext skeleton
            Container(width: 150, height: 14, color: Colors.white),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 14, color: Colors.white),
            const SizedBox(height: 6),
            Container(width: double.infinity, height: 14, color: Colors.white),
            const SizedBox(height: 6),
            Container(width: 250, height: 14, color: Colors.white),
            const SizedBox(height: 40),

            // Policy Sections skeleton
            ...List.generate(4, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 180, height: 18, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: double.infinity, height: 12, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(width: double.infinity, height: 12, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(width: 150, height: 12, color: Colors.white),
                      ],
                    ),
                  )
                ],
              ),
            )),

            const SizedBox(height: 16),
            // Footer Box skeleton
            Container(width: double.infinity, height: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // UPDATED: Background is now pure white in light mode to match the header seamlessly
    final Color bgColor = widget.isDarkMode ? const Color(0xFF121212) : Colors.white;
    final Color headerColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF111827);
    final Color subTextColor = widget.isDarkMode ? Colors.white70 : const Color(0xFF6B7280);

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
            child: _isSimulatingLoad
              ? _buildSkeletonPrivacy()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Privacy\nMatters',
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
                        'Last updated: April 2026\n\nAt SEELAI, we are deeply committed to protecting the privacy and security of both our partially sighted users and their caretakers. This policy outlines how we handle your data.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: subTextColor,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Policy Sections
                      _buildPolicySection(
                        title: '1. Camera & Image Data',
                        icon: Icons.camera_alt_outlined,
                        content: 'SEELAI relies on your device\'s camera for object and face detection. To ensure your maximum privacy, all visual processing is performed locally on your device using TensorFlow Lite. We do not record, store, or transmit your live camera feed to external servers.',
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      
                      _buildPolicySection(
                        title: '2. Caretaker Facial Recognition',
                        icon: Icons.face_retouching_natural_rounded,
                        content: 'When registering a caretaker\'s face into the system, the facial mapping data is securely encrypted. This data is used strictly for the purpose of recognizing trusted individuals within your immediate vicinity.',
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),

                      _buildPolicySection(
                        title: '3. Location & SOS Services',
                        icon: Icons.emergency_outlined,
                        content: 'Your location data is only accessed when the SOS emergency feature is activated. Upon activation, your precise location is transmitted exclusively to your registered caretakers to facilitate immediate assistance.',
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),

                      _buildPolicySection(
                        title: '4. Data Sharing & Dashboard',
                        icon: Icons.dashboard_customize_outlined,
                        content: 'Personal and medical information (such as diagnosis and contact details) is stored securely in our Firebase backend. This information is only accessible to you and the caretakers you explicitly authorize via the web-based management dashboard. We do not sell your data to third parties.',
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
                            Icon(Icons.shield_outlined, color: _primaryColor, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'By using SEELAI, you consent to this policy. For account deletion or data removal requests, please contact your primary caretaker or system administrator.',
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
                      const SizedBox(height: 48), // Bottom padding
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // Clean, structured list item for policy rules
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