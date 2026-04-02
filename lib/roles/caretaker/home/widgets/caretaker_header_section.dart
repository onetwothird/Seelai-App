// File: lib/roles/caretaker/home/widgets/header_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// The new vibrant modern purple requested
const primary = Color(0xFF7C3AED);

class HeaderSection extends StatelessWidget {
  final String caretakerName;
  final String? profileImageUrl;
  final bool isDarkMode;
  final int pendingRequestsCount;
  final VoidCallback onToggleDarkMode;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final Color textColor;
  final Color subtextColor;

  const HeaderSection({
    super.key,
    required this.caretakerName,
    this.profileImageUrl,
    required this.isDarkMode,
    required this.pendingRequestsCount,
    required this.onToggleDarkMode,
    this.onProfileTap,
    this.onNotificationTap,
    required this.textColor,
    required this.subtextColor,
  });

  // Helper to safely extract the first name
  String _getFirstName() {
    if (caretakerName.isEmpty) return 'Caretaker';
    final parts = caretakerName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'Caretaker';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Format: "TUESDAY, MARCH 17"
    final formattedDate = DateFormat('EEEE, MMMM d').format(now).toUpperCase();

    // Soft backgrounds for the buttons
    final Color buttonBgColor = isDarkMode ? Colors.white10 : const Color(0xFFF8FAFC);
    
    // Theme's primary color for the icons
    final Color iconTint = primary; 

    return Semantics(
      label: 'Header section. ${_getGreeting()}, ${_getFirstName()}. Today is $formattedDate',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ROW: Action Buttons pushed entirely to the right
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Theme Toggle
                Semantics(
                  label: isDarkMode ? 'Dark mode is on' : 'Light mode is on',
                  hint: 'Double tap to toggle theme mode',
                  button: true,
                  child: _buildActionButton(
                    icon: isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    bgColor: buttonBgColor,
                    iconColor: iconTint,
                    onTap: onToggleDarkMode,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Notifications
                Semantics(
                  label: pendingRequestsCount > 0 
                    ? 'Notifications. You have $pendingRequestsCount pending request${pendingRequestsCount > 1 ? 's' : ''}' 
                    : 'Notifications',
                  hint: 'Double tap to view notifications',
                  button: true,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildActionButton(
                        icon: Icons.notifications_none_rounded,
                        bgColor: buttonBgColor,
                        iconColor: iconTint,
                        onTap: onNotificationTap,
                      ),
                      if (pendingRequestsCount > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        top: 0, 
                        child: Container(
                          decoration: BoxDecoration(
                              color: const Color(0xFFEF4444), // Red notification badge
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                pendingRequestsCount > 9 
                                    ? '9+' 
                                    : pendingRequestsCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                
                // Profile Pill Button
                Semantics(
                  label: 'Profile',
                  hint: 'Double tap to view profile',
                  button: true,
                  child: GestureDetector(
                    onTap: onProfileTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: buttonBgColor,
                        borderRadius: BorderRadius.circular(20), // Pill shape
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 18, color: iconTint),
                          const SizedBox(width: 8),
                          Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: subtextColor.withValues(alpha: 0.9),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 24),

          // TEXT ROW: Date and Greeting
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Today\'s date is $formattedDate',
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Semantics(
                  label: 'Greeting',
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${_getGreeting()}, ',
                          style: TextStyle(
                            fontSize: 26,
                            color: textColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: '${_getFirstName()}!',
                          style: TextStyle(
                            fontSize: 26,
                            color: textColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // MASCOT & SPEECH BUBBLE SECTION
          Semantics(
            label: 'Seelai mascot with a tip for you',
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Edge-to-edge gradient background
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  top: 0, 
                  child: Container(
                    decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary.withValues(alpha: isDarkMode ? 0.25 : 0.15),
                        primary.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
                
                // Mascot and Bubble Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Mascot Figure
                      Image.asset(
                        'assets/seelai-icons/seelai1.png',
                        width: 90,
                        height: 105,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            color: primary,
                            size: 36,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      // Speech Bubble Tail (Triangle pointing left)
                      Container(
                        margin: const EdgeInsets.only(bottom: 30), // Align to mouth level
                        child: CustomPaint(
                          size: const Size(12, 16),
                          painter: _TailPainter(
                            color: isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                          ),
                        ),
                      ),

                      // Speech Bubble Body
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Seelai',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hello, ${_getFirstName()}! I\'m here to help you manage your paired users and pending requests.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
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

  // Helper for the pill/circle buttons 
  Widget _buildActionButton({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle, // Circular buttons to match the screenshot
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }
}

// Custom Painter to draw the speech bubble tail pointing to the mascot
class _TailPainter extends CustomPainter {
  final Color color;

  _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    
    // Draw a triangle pointing to the left
    path.moveTo(size.width, 0); // Top right corner
    path.lineTo(0, size.height / 2); // Pointing left (middle)
    path.lineTo(size.width, size.height); // Bottom right corner
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}