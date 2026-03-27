import 'package:flutter/material.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/communication/screens/video_call_screen.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/communication/screens/voice_call_screen.dart';
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
            subtitle: 'Tap to start',
            icon: Icons.call_rounded,
            primaryColor: const Color.fromARGB(255, 124, 58, 237),
            isDarkMode: isDarkMode,
            theme: theme,
            onTap: () {
              VoiceCallScreen.startCall(context, userData);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ContactAction(
            title: 'Video Call',
            subtitle: 'Tap to start',
            icon: Icons.videocam_rounded,
            primaryColor: const Color.fromARGB(255, 124, 58, 237),
            isDarkMode: isDarkMode,
            theme: theme,
            onTap: () {
              VideoCallScreen.startCall(context, userData);
            },
          ),
        ),
      ],
    );
  }
}

class _ContactAction extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final bool isDarkMode;
  final dynamic theme;
  final VoidCallback onTap;

  const _ContactAction({
    required this.title,
    required this.subtitle,
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
            borderRadius: BorderRadius.circular(20),
            splashColor: widget.primaryColor.withValues(alpha: 0.1),
            highlightColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                // Clean white background for light mode, standard card color for dark mode
                color: widget.isDarkMode 
                    ? const Color(0xFF1A1F3A) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(20), 
                // Subtle border to define the shape just like the reference image
                border: Border.all(
                  color: widget.isDarkMode 
                      ? Colors.white12 
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Icon(
                    widget.icon,
                    size: 24, 
                    color: widget.primaryColor,
                  ),
                  const SizedBox(width: 8), 
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: bodyBold.copyWith(
                            fontSize: 15,
                            color: widget.theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2), 
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.theme.textColor.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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