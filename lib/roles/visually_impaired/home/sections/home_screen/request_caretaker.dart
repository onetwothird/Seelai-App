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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRequestCaretaker,
          borderRadius: BorderRadius.circular(radiusLarge),
          splashColor: accent.withOpacity(0.2),
          highlightColor: accent.withOpacity(0.1),
          child: Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(radiusLarge),
              boxShadow: isDarkMode
                  ? [
                      BoxShadow(
                        color: accent.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : softShadow,
              border: isDarkMode
                  ? Border.all(
                      color: accent.withOpacity(0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingSmall),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: accent,
                    size: 24,
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
                          fontSize: 15,
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
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: accent,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}