// File: lib/roles/visually_impaired/home/sections/home_screen/request_caretaker.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class RequestCaretakerButton extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final VoidCallback onRequestCaretaker;

  const RequestCaretakerButton({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.onRequestCaretaker,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Request caretaker assistance button',
      button: true,
      hint: 'Double tap to send a request to your caretaker',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radiusXLarge),
          boxShadow: isDarkMode
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: accent.withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: InkWell(
            onTap: onRequestCaretaker,
            borderRadius: BorderRadius.circular(radiusXLarge),
            splashColor: accent.withOpacity(0.2),
            child: Container(
              padding: EdgeInsets.all(spacingLarge * 1.2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(isDarkMode ? 0.2 : 0.12),
                    accent.withOpacity(isDarkMode ? 0.1 : 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radiusXLarge),
                border: Border.all(
                  color: accent.withOpacity(isDarkMode ? 0.3 : 0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.support_agent_rounded,
                      size: 32,
                      color: white,
                    ),
                  ),
                  SizedBox(width: spacingLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Caretaker',
                          style: bodyBold.copyWith(
                            fontSize: 17,
                            color: theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Get assistance from your caretaker',
                          style: caption.copyWith(
                            fontSize: 13,
                            color: theme.subtextColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: accent,
                    size: 20,
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