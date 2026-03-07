// File: lib/roles/partially_sighted/home/sections/home_screen/quick_contact_section.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class QuickContactSection extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;

  const QuickContactSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactAction(
            title: 'Voice Call',
            icon: Icons.call_rounded,
            primaryColor: const Color(0xFF10B981), // Emerald Green
            isDarkMode: isDarkMode,
            theme: theme,
            onTap: () {
              _showComingSoon(context);
            },
          ),
        ),
        const SizedBox(width: 12), // Nice, tight spacing between buttons
        Expanded(
          child: _ContactAction(
            title: 'Video Call',
            icon: Icons.videocam_rounded,
            primaryColor: const Color(0xFF3B82F6), // Azure Blue
            isDarkMode: isDarkMode,
            theme: theme,
            onTap: () {
              _showComingSoon(context);
            },
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Call feature coming soon!',
          style: bodyBold.copyWith(color: Colors.white),
        ),
        backgroundColor: theme.cardColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ContactAction extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color primaryColor;
  final bool isDarkMode;
  final dynamic theme;
  final VoidCallback onTap;

  const _ContactAction({
    required this.title,
    required this.icon,
    required this.primaryColor,
    required this.isDarkMode,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_ContactAction> createState() => _ContactActionState();
}

class _ContactActionState extends State<_ContactAction> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.title} button',
      button: true,
      hint: 'Double tap to start a ${widget.title.toLowerCase()}',
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _animationController.forward().then((_) {
                _animationController.reverse();
              });
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: widget.primaryColor.withValues(alpha: 0.1),
            highlightColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? widget.theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  // A clean, flat border instead of a shadow
                  color: widget.isDarkMode 
                      ? widget.primaryColor.withValues(alpha: 0.3) 
                      : Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 20,
                      color: widget.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.title,
                      style: bodyBold.copyWith(
                        fontSize: 14,
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}