// File: lib/roles/mswd/home/widgets/mswd_header_section.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const primary = Color(0xFF7C3AED);

class HeaderSection extends StatefulWidget {
  final String adminName;
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
    required this.adminName,
    this.profileImageUrl,
    required this.isDarkMode,
    required this.pendingRequestsCount, 
    required this.onToggleDarkMode,
    this.onProfileTap,
    this.onNotificationTap, 
    required this.textColor,
    required this.subtextColor,
  });

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

// === CHANGED: Added SingleTickerProviderStateMixin for the entry animation ===
class _HeaderSectionState extends State<HeaderSection> with SingleTickerProviderStateMixin {
  bool _showDoubleCheck = false;
  
  // Animation State
  Timer? _messageTimer;
  int _currentMessageIndex = 0;

  // === NEW: Animation Controllers & Tweens ===
  late AnimationController _entryController;
  late Animation<double> _topRowOpacity;
  late Animation<Offset> _topRowSlide;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _mascotScale;
  late Animation<double> _bubbleScale;

  @override
  void initState() {
    super.initState();
    _startMessageTimer();

    // === NEW: Initialize the staggered entry animation ===
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 1. Top Row (Buttons) - Fades & slides down early
    _topRowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _topRowSlide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );

    // 2. Text Row (Greeting) - Fades & slides in from left
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
    );
    _textSlide = Tween<Offset>(begin: const Offset(-0.15, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic)),
    );

    // 3. Mascot - Pops up playfully
    _mascotScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack)),
    );

    // 4. Speech Bubble - Pops out from the mascot
    _bubbleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack)),
    );

    // Start the animation immediately when the header loads
    _entryController.forward();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _entryController.dispose(); // === NEW: Dispose controller ===
    super.dispose();
  }

  void _startMessageTimer() {
    _messageTimer?.cancel(); 
    _messageTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex++;
        });
      }
    });
  }

  String _getFirstName() {
    if (widget.adminName.isEmpty) return 'Admin';
    final parts = widget.adminName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'Admin';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<String> _getMascotMessages() {
    if (widget.pendingRequestsCount == 0) {
      return [
        'Hello, ${_getFirstName()}! You\'re all caught up. The dashboard is looking great.',
        'Did you know? You can double tap the moon icon to toggle dark mode.'
      ];
    } else if (widget.pendingRequestsCount == 1) {
      return [
        'Hello, ${_getFirstName()}! You have 1 pending request awaiting approval.',
        'Tap the bell icon in the top right to check it out and respond.'
      ];
    } else {
      return [
        'Hello, ${_getFirstName()}! You have ${widget.pendingRequestsCount} pending requests awaiting approval.',
        'Tap the bell icon in the top right to review the alerts.'
      ];
    }
  }

  void _handleNotificationTap() {
    if (widget.pendingRequestsCount > 0) {
      setState(() {
        _showDoubleCheck = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showDoubleCheck = false;
          });
        }
      });
    }
    
    if (widget.onNotificationTap != null) {
      widget.onNotificationTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(now).toUpperCase();

    final Color buttonBgColor = widget.isDarkMode ? Colors.white10 : const Color(0xFFF8FAFC);
    final Color iconTint = primary; 

    final messages = _getMascotMessages();
    final safeIndex = _currentMessageIndex % messages.length;
    final displayMessage = messages[safeIndex];
    
    final longestMessage = messages.isNotEmpty 
        ? messages.reduce((a, b) => a.length > b.length ? a : b) 
        : '';

    final screenWidth = MediaQuery.of(context).size.width;
    
    final double mascotSize = (screenWidth * 0.32).clamp(90.0, 130.0);
    
    final double tailBottomMargin = mascotSize * 0.25; 
    final double bubbleBottomMargin = mascotSize * 0.133; 

    return Semantics(
      label: 'Header section. ${_getGreeting()}, ${_getFirstName()}. Today is $formattedDate',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === WRAPPED IN FADE & SLIDE ANIMATION (TOP ROW) ===
          FadeTransition(
            opacity: _topRowOpacity,
            child: SlideTransition(
              position: _topRowSlide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                    
                    Semantics(
                      label: widget.pendingRequestsCount > 0 
                        ? 'Notifications. You have ${widget.pendingRequestsCount} pending request${widget.pendingRequestsCount > 1 ? 's' : ''}' 
                        : 'Notifications',
                      hint: 'Double tap to view notifications',
                      button: true,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildActionButton(
                            icon: _showDoubleCheck 
                                ? Icons.done_all_rounded 
                                : (widget.pendingRequestsCount > 0 
                                    ? Icons.notifications_active_rounded 
                                    : Icons.notifications_none_rounded),
                            bgColor: buttonBgColor,
                            iconColor: _showDoubleCheck ? Colors.green : iconTint,
                            onTap: _handleNotificationTap,
                          ),
                          
                          if (widget.pendingRequestsCount > 0 && !_showDoubleCheck)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
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
                                    widget.pendingRequestsCount > 9 
                                        ? '9+' 
                                        : widget.pendingRequestsCount.toString(),
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
                            borderRadius: BorderRadius.circular(20),
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
            ),
          ),

          const SizedBox(height: 24),

          // === WRAPPED IN FADE & SLIDE ANIMATION (TEXT ROW) ===
          FadeTransition(
            opacity: _textOpacity,
            child: SlideTransition(
              position: _textSlide,
              child: Padding(
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
            ),
          ),

          const SizedBox(height: 20),

          // MASCOT & SPEECH BUBBLE SECTION
          Semantics(
            label: 'Seelai mascot with a tip for you',
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // === FADE IN GRADIENT BACKGROUND ===
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  top: 0, 
                  child: FadeTransition(
                    opacity: _textOpacity,
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
                ),
                
                // Mascot and Bubble Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // === SCALE ANIMATION FOR MASCOT ===
                      ScaleTransition(
                        scale: _mascotScale,
                        alignment: Alignment.bottomCenter, // Pops up from the bottom
                        child: Image.asset(
                          'assets/seelai-icons/seelai0.png',
                          height: mascotSize, // Dynamic height applied here
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: mascotSize * 0.75,
                            height: mascotSize * 0.75,
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.smart_toy_outlined,
                              color: primary,
                              size: mascotSize * 0.3, // Scale error icon dynamically too
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      // === SCALE ANIMATION FOR TAIL ===
                      Container(
                        margin: EdgeInsets.only(bottom: tailBottomMargin), // Dynamically stays at mouth level
                        child: ScaleTransition(
                          scale: _bubbleScale,
                          alignment: Alignment.bottomRight, // Grows out from the bubble
                          child: CustomPaint(
                            size: const Size(12, 16),
                            painter: _TailPainter(
                              color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // === SCALE ANIMATION FOR BUBBLE ===
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(bottom: bubbleBottomMargin), // Dynamic bottom margin
                          child: ScaleTransition(
                            scale: _bubbleScale,
                            alignment: Alignment.bottomLeft, // Grows out from the tail
                            child: Container(
                              padding: const EdgeInsets.all(21),
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
                                  
                                  // THE STACK TRICK
                                  Stack(
                                    children: [
                                      // 1. Invisible text uses the LONGEST message to lock bubble size
                                      Text(
                                        longestMessage,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.transparent, 
                                          height: 1.4,
                                        ),
                                      ),
                                      // 2. Typewriter text types out the current message
                                      Positioned.fill(
                                        child: TypewriterText(
                                          key: ValueKey(displayMessage),
                                          text: displayMessage,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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

class _TailPainter extends CustomPainter {
  final Color color;

  _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    
    path.moveTo(size.width, 0); 
    path.lineTo(0, size.height / 2); 
    path.lineTo(size.width, size.height); 
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// TYPEWRITER ANIMATION WIDGET (DYNAMIC SPEED)
// ==========================================
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    int msDuration = widget.text.length * 40; 
    _controller = AnimationController(
      vsync: this, 
      duration: Duration(milliseconds: msDuration),
    );
    _setupAnimation();
    
    // === NEW: Added 600ms delay to match the bubble pop-in animation ===
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      int msDuration = widget.text.length * 40; 
      _controller.duration = Duration(milliseconds: msDuration);
      _setupAnimation();
      _controller.reset();
      _controller.forward();
    }
  }

  void _setupAnimation() {
    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        int end = _characterCount.value;
        if (end > widget.text.length) end = widget.text.length;
        if (end < 0) end = 0;
        
        return Text(
          widget.text.substring(0, end),
          style: widget.style,
        );
      },
    );
  }
}