// File: lib/roles/partially_sighted/home/widgets/header_section.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final int currentStreak; 

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
    this.currentStreak = 0, 
  });

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> with SingleTickerProviderStateMixin {
  bool _showDoubleCheck = false;
  Timer? _messageTimer;
  int _currentMessageIndex = 0;

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

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _topRowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _topRowSlide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
    );
    _textSlide = Tween<Offset>(begin: const Offset(-0.15, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic)),
    );
    _mascotScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack)),
    );
    _bubbleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack)),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  void _startMessageTimer() {
    _messageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        final messagesCount = _getMascotMessages().length;
        if (messagesCount > 1) {
          setState(() {
            _currentMessageIndex = (_currentMessageIndex + 1) % messagesCount;
          });
        }
      }
    });
  }

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

  List<String> _getMascotMessages() {
    List<String> messages = [];
    
    if (widget.currentStreak > 2) {
      messages.add('Awesome! You are on a ${widget.currentStreak}-day streak! 🔥 Keep exploring your world!');
    }

    if (widget.unreadNotificationCount == 0) {
      messages.add('Hello, ${_getFirstName()}! You\'re all caught up. Tap the scanner whenever you\'re ready.');
      messages.add('Did you know? You can double tap the moon icon in the top right to toggle dark mode.');
    } else {
      messages.add('Hello, ${_getFirstName()}! You have ${widget.unreadNotificationCount} unread notification${widget.unreadNotificationCount > 1 ? 's' : ''}.');
      messages.add('Don\'t forget to review your latest alerts!');
    }
    return messages;
  }

  void _handleNotificationTap() {
    if (widget.unreadNotificationCount > 0) {
      setState(() { _showDoubleCheck = true; });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() { _showDoubleCheck = false; });
      });
    }
    widget.onNotificationTap();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(now).toUpperCase();

    final Color buttonBgColor = widget.isDarkMode ? Colors.white10 : const Color(0xFFF8FAFC);
    final Color iconTint = primary; 

    final messages = _getMascotMessages();
    final displayMessage = messages[_currentMessageIndex % messages.length];
    final longestMessage = messages.reduce((a, b) => a.length > b.length ? a : b);

    final screenWidth = MediaQuery.of(context).size.width;
    final double mascotSize = (screenWidth * 0.32).clamp(100.0, 140.0);
    final double tailBottomMargin = mascotSize * 0.214; 
    final double bubbleBottomMargin = mascotSize * 0.128;

    return Semantics(
      label: 'Header section',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _topRowOpacity,
            child: SlideTransition(
              position: _topRowSlide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PremiumThemeToggle(
                      isDarkMode: widget.isDarkMode,
                      onToggle: widget.onToggleDarkMode,
                      buttonBgColor: buttonBgColor,
                      iconColor: iconTint,
                    ),
                    const SizedBox(width: 8),
                    
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildActionButton(
                          icon: _showDoubleCheck 
                              ? Icons.done_all_rounded 
                              : (widget.unreadNotificationCount > 0 
                                  ? Icons.notifications_active_rounded 
                                  : Icons.notifications_none_rounded), 
                          bgColor: buttonBgColor,
                          iconColor: _showDoubleCheck ? Colors.green : iconTint,
                          onTap: _handleNotificationTap,
                        ),
                        if (widget.unreadNotificationCount > 0 && !_showDoubleCheck)
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
                              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                              child: Center(
                                child: Text(
                                  widget.unreadNotificationCount > 9 ? '9+' : widget.unreadNotificationCount.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, height: 1),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    
                    GestureDetector(
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
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: widget.subtextColor.withValues(alpha: 0.9)),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          FadeTransition(
            opacity: _textOpacity,
            child: SlideTransition(
              position: _textSlide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === NEW STREAK UI PLACEMENT (Slightly larger container) ===
                    if (widget.currentStreak > 0) ...[
                      Semantics(
                        label: 'Current streak: ${widget.currentStreak} days',
                        child: Container(
                          // Increased padding from 12,6 to 16,8
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? Colors.orange.withValues(alpha: 0.15) : const Color(0xFFFFF0E5),
                            borderRadius: BorderRadius.circular(18), // Slightly rounder to match size
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Increased icon size to 20
                              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7A00), size: 20),
                              const SizedBox(width: 8), // Slightly more spacing
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'x${widget.currentStreak} ',
                                      style: TextStyle(
                                        fontSize: 14, // Increased from 13 to 14
                                        fontWeight: FontWeight.w900, 
                                        color: widget.isDarkMode ? Colors.orange.shade200 : const Color(0xFF333333),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'day streak!',
                                      style: TextStyle(
                                        fontSize: 14, // Increased from 13 to 14
                                        fontWeight: FontWeight.w600, 
                                        color: widget.isDarkMode ? Colors.orange.shade200 : const Color(0xFF333333),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // ===============================

                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, color: widget.subtextColor.withValues(alpha: 0.8), fontWeight: FontWeight.w800, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${_getGreeting()}, ',
                            style: TextStyle(fontSize: 26, color: widget.textColor.withValues(alpha: 0.9), fontWeight: FontWeight.w500, letterSpacing: -0.5),
                          ),
                          TextSpan(
                            text: '${_getFirstName()}!',
                            style: TextStyle(fontSize: 26, color: widget.textColor, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary.withValues(alpha: widget.isDarkMode ? 0.25 : 0.15), primary.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ScaleTransition(
                      scale: _mascotScale,
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/seelai-icons/seelai0.png',
                        height: mascotSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: mascotSize * 0.7,
                          height: mascotSize * 0.65,
                          decoration: BoxDecoration(color: primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.smart_toy_outlined, color: primary, size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      margin: EdgeInsets.only(bottom: tailBottomMargin),
                      child: ScaleTransition(
                        scale: _bubbleScale,
                        alignment: Alignment.bottomRight,
                        child: CustomPaint(
                          size: const Size(12, 16),
                          painter: _TailPainter(color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(bottom: bubbleBottomMargin),
                        child: ScaleTransition(
                          scale: _bubbleScale,
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            padding: const EdgeInsets.all(21),
                            decoration: BoxDecoration(
                              color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Seelai', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primary, letterSpacing: 0.5)),
                                const SizedBox(height: 6),
                                Stack(
                                  children: [
                                    Text(longestMessage, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.transparent, height: 1.4)),
                                    Positioned.fill(
                                      child: TypewriterText(
                                        text: displayMessage,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.black87, height: 1.4),
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
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color bgColor, required Color iconColor, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}

class PremiumThemeToggle extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggle;
  final Color buttonBgColor;
  final Color iconColor;

  const PremiumThemeToggle({super.key, required this.isDarkMode, required this.onToggle, required this.buttonBgColor, required this.iconColor});

  @override
  State<PremiumThemeToggle> createState() => _PremiumThemeToggleState();
}

class _PremiumThemeToggleState extends State<PremiumThemeToggle> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.7).chain(CurveTween(curve: Curves.easeOutQuad)), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 70),
    ]).animate(_controller);
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double glowOpacity = _controller.isAnimating ? (1.0 - _controller.value).clamp(0.0, 0.4) : 0.0;
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: RotationTransition(
              turns: _rotationAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.buttonBgColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: widget.iconColor.withValues(alpha: glowOpacity), blurRadius: 20 * _controller.value, spreadRadius: 8 * _controller.value)],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                  child: Icon(widget.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, key: ValueKey<bool>(widget.isDarkMode), size: 20, color: widget.iconColor),
                ),
              ),
            ),
          );
        },
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

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const TypewriterText({super.key, required this.text, required this.style});
  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: widget.text.length * 40));
    _setupAnimation();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.duration = Duration(milliseconds: widget.text.length * 40);
      _setupAnimation();
      _controller.reset();
      _controller.forward();
    }
  }

  void _setupAnimation() {
    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
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
        return Text(widget.text.substring(0, end), style: widget.style);
      },
    );
  }
}