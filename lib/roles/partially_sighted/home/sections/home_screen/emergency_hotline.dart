// File: lib/roles/visually_impaired/home/sections/home_screen/emergency_hotline.dart


import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/screens/emergency_hotlines_screen.dart';

class EmergencyHotlineButton extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;

  const EmergencyHotlineButton({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<EmergencyHotlineButton> createState() => _EmergencyHotlineButtonState();
}

class _EmergencyHotlineButtonState extends State<EmergencyHotlineButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
      label: 'Emergency hotlines button',
      button: true,
      hint: 'Double tap to view and call emergency services',
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _animationController.forward().then((_) {
                _animationController.reverse();
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyHotlinesScreen(
                    isDarkMode: widget.isDarkMode,
                    theme: widget.theme,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(radiusLarge),
            splashColor: error.withValues(alpha: 0.2),
            highlightColor: error.withValues(alpha: 0.1),
            child: Container(
              padding: EdgeInsets.all(spacingMedium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isDarkMode
                      ? [Color(0xFF1A1F3A), Color(0xFF2A2F4A)]
                      : [white, white.withValues(alpha: 0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radiusLarge),
                boxShadow: widget.isDarkMode
                    ? [
                        BoxShadow(
                          color: error.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: error.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                border: widget.isDarkMode
                    ? Border.all(
                        color: error.withValues(alpha: 0.3),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacingMedium),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [error, error.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: error.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.phone_in_talk_rounded,
                      color: white,
                      size: 26,
                    ),
                  ),
                  SizedBox(width: spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Hotlines',
                          style: bodyBold.copyWith(
                            fontSize: 16,
                            color: widget.theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Quick access to emergency services',
                          style: caption.copyWith(
                            fontSize: 13,
                            color: widget.theme.subtextColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(spacingXSmall),
                    decoration: BoxDecoration(
                      color: error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(radiusSmall),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: error,
                      size: 18,
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