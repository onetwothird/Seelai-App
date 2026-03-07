// File: lib/roles/visually_impaired/home/sections/home_screen/request_caretaker.dart


import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'request_caretaker_form.dart';

class RequestCaretakerButton extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;

  const RequestCaretakerButton({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
  });

  @override
  State<RequestCaretakerButton> createState() => _RequestCaretakerButtonState();
}

class _RequestCaretakerButtonState extends State<RequestCaretakerButton> with SingleTickerProviderStateMixin {
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
      label: 'Request caretaker assistance button',
      button: true,
      hint: 'Double tap to send a request to your caretaker',
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _animationController.forward().then((_) {
                _animationController.reverse();
              });
              _navigateToRequestForm(context);
            },
            borderRadius: BorderRadius.circular(radiusLarge),
            splashColor: accent.withValues(alpha: 0.2),
            highlightColor: accent.withValues(alpha: 0.1),
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
                          color: accent.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                border: widget.isDarkMode
                    ? Border.all(
                        color: accent.withValues(alpha: 0.3),
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
                        colors: [accent, accent.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.support_agent_rounded,
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
                          'Request Caretaker',
                          style: bodyBold.copyWith(
                            fontSize: 16,
                            color: widget.theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Get assistance from your caretaker',
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
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(radiusSmall),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: accent,
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

  void _navigateToRequestForm(BuildContext context) {
    final userName = widget.userData['name'] ?? 'User';
    final userId = widget.userData['uid'] ?? '';
    
    // Get assigned caretakers
    final assignedCaretakers = widget.userData['assignedCaretakers'] as Map<dynamic, dynamic>?;
    
    if (assignedCaretakers == null || assignedCaretakers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: white),
              SizedBox(width: spacingSmall),
              Expanded(
                child: Text(
                  'No caretaker assigned. Please assign a caretaker first.',
                  style: bodyBold.copyWith(color: white),
                ),
              ),
            ],
          ),
          backgroundColor: error,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      );
      return;
    }
    
    // Get first caretaker ID
    final caretakerId = assignedCaretakers.keys.first.toString();
    
    // Navigate to full screen form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestCaretakerForm(
          userName: userName,
          userId: userId,
          caretakerId: caretakerId,
          isDarkMode: widget.isDarkMode,
          theme: widget.theme,
        ),
      ),
    );
  }
}