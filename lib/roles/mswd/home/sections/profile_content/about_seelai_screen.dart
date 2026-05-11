// File: lib/roles/mswd/home/sections/profile_content/about_seelai_screen.dart

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
  final Color _primaryColor = const Color(0xFF8B5CF6);
  bool _isSimulatingLoad = true;

  @override
  void initState() {
    super.initState();
    // Trigger skeleton loader
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isSimulatingLoad = false);
    });
  }

  // ==========================================
  // WIDGET: SKELETON
  // ==========================================
  Widget _buildSkeleton() {
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
            Container(width: 110, height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28.0))),
            const SizedBox(height: 16),
            Container(width: 150, height: 26, color: Colors.white),
            const SizedBox(height: 6),
            Container(width: 120, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 24),
            Container(height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 12),
            Container(height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 12),
            Container(height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              ? _buildSkeleton()
              : Padding(
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
                          boxShadow: widget.isDarkMode ? [] : [ 
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
                          'Admin Portal v1.0.0',
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
                        title: 'Municipal Command',
                        icon: Icons.account_balance_rounded,
                        content: 'SEELAI serves as the central command hub for Municipal Social Welfare and Development (MSWD) officers. We empower administrators to oversee, manage, and coordinate municipal-wide care for partially sighted individuals.',
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildSectionCard(
                        title: 'Live Emergency Dispatch',
                        icon: Icons.warning_rounded,
                        content: 'Utilize the global tracking map to monitor active users and coordinate rapid responses to live SOS emergency alerts, ensuring no citizen is left without immediate assistance during critical moments.',
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      const SizedBox(height: 12),

                      _buildSectionCard(
                        title: 'System & User Management',
                        icon: Icons.manage_accounts_rounded,
                        content: 'Securely manage the municipal directory of patients and caretakers, review system activity logs for accountability, and disseminate critical broadcasts to keep the entire community informed and safe.',
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      
                      const SizedBox(height: 32),
                      Text(
                        'Designed for governance.\nBuilt for community care.',
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