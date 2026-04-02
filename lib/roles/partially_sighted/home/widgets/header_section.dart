// File: lib/roles/partially_sighted/home/widgets/header_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// The new vibrant modern purple requested
const primary = Color(0xFF7C3AED);

class HeaderSection extends StatefulWidget {
  final String userName;
  final String? profileImageUrl;
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;
  final VoidCallback onNotificationTap;
  final VoidCallback? onProfileTap;
  final Color textColor;
  final Color subtextColor;
  final int unreadNotificationCount;

  const HeaderSection({
    super.key,
    required this.userName,
    this.profileImageUrl,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.onNotificationTap,
    this.onProfileTap,
    required this.textColor,
    required this.subtextColor,
    this.unreadNotificationCount = 0,
  });

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  // State to handle the temporary "mark as read" double check animation
  bool _showDoubleCheck = false;

  // Helper to safely extract the first name
  String _getFirstName() {
    if (widget.userName.isEmpty) return 'User';
    final parts = widget.userName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'User';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // Helper to generate the dynamic mascot message
  String _getMascotMessage() {
    if (widget.unreadNotificationCount == 0) {
      return 'Hello, ${_getFirstName()}! You\'re all caught up. Tap the scanner whenever you\'re ready.';
    } else if (widget.unreadNotificationCount == 1) {
      return 'Hello, ${_getFirstName()}! You have 1 unread notification. Tap the bell icon to check it out.';
    } else {
      return 'Hello, ${_getFirstName()}! You have ${widget.unreadNotificationCount} unread notifications. Tap the bell icon to check them out.';
    }
  }

  void _handleNotificationTap() {
    // Show the double check animation if there were unread notifications
    if (widget.unreadNotificationCount > 0) {
      setState(() {
        _showDoubleCheck = true;
      });

      // Revert back to the normal bell after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showDoubleCheck = false;
          });
        }
      });
    }
    
    // Trigger your parent screen's callback so it actually resets the count to 0 in your database/state
    widget.onNotificationTap();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Format: "TUESDAY, MARCH 17"
    final formattedDate = DateFormat('EEEE, MMMM d').format(now).toUpperCase();

    // Soft backgrounds for the buttons
    final Color buttonBgColor = widget.isDarkMode ? Colors.white10 : const Color(0xFFF8FAFC);
    
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
                  label: widget.isDarkMode ? 'Dark mode is on' : 'Light mode is on',
                  hint: 'Double tap to toggle theme mode',
                  button: true,
                  child: _buildActionButton(
                    icon: widget.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    bgColor: buttonBgColor,
                    iconColor: iconTint,
                    onTap: widget.onToggleDarkMode,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Notifications
                Semantics(
                  label: widget.unreadNotificationCount > 0 
                    ? 'Notifications. You have ${widget.unreadNotificationCount} unread notification${widget.unreadNotificationCount > 1 ? 's' : ''}' 
                    : 'Notifications',
                  hint: 'Double tap to view notifications',
                  button: true,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // The Bell (or Double Check) Button
                      _buildActionButton(
                        icon: _showDoubleCheck 
                            ? Icons.done_all_rounded // Double check icon
                            : (widget.unreadNotificationCount > 0 
                                ? Icons.notifications_active_rounded // Ringing bell
                                : Icons.notifications_none_rounded), // Empty bell
                        bgColor: buttonBgColor,
                        iconColor: _showDoubleCheck ? Colors.green : iconTint,
                        onTap: _handleNotificationTap,
                      ),
                      
                      // The proper top-right Notification Badge
                      if (widget.unreadNotificationCount > 0 && !_showDoubleCheck)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444), // Red badge
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Center(
                              child: Text(
                                widget.unreadNotificationCount > 9 
                                    ? '9+' 
                                    : widget.unreadNotificationCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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
                    onTap: widget.onProfileTap,
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
                              color: widget.subtextColor.withValues(alpha: 0.9),
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
                      color: widget.subtextColor.withValues(alpha: 0.8),
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
                            color: widget.textColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: '${_getFirstName()}!',
                          style: TextStyle(
                            fontSize: 26,
                            color: widget.textColor,
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
                          primary.withValues(alpha: widget.isDarkMode ? 0.25 : 0.15),
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
                          child: Icon(
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
                            color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                          ),
                        ),
                      ),

                      // Speech Bubble Body
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
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
                                _getMascotMessage(), 
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: widget.isDarkMode
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
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