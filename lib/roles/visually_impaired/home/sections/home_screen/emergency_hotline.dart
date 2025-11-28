// File: lib/roles/visually_impaired/home/sections/home_screen/emergency_hotline.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/screens/emergency_hotlines_screen.dart';

class EmergencyHotlineButton extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;

  const EmergencyHotlineButton({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Emergency hotlines button',
      button: true,
      hint: 'Double tap to view and call emergency services',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radiusXLarge),
          boxShadow: isDarkMode
              ? [
                  BoxShadow(
                    color: error.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: error.withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyHotlinesScreen(
                    isDarkMode: isDarkMode,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(radiusXLarge),
            splashColor: error.withOpacity(0.2),
            child: Container(
              padding: EdgeInsets.all(spacingLarge * 1.2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    error.withOpacity(isDarkMode ? 0.2 : 0.12),
                    error.withOpacity(isDarkMode ? 0.1 : 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radiusXLarge),
                border: Border.all(
                  color: error.withOpacity(isDarkMode ? 0.3 : 0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [error, error.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: error.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.phone_in_talk_rounded,
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
                          'Emergency Hotlines',
                          style: bodyBold.copyWith(
                            fontSize: 17,
                            color: theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Quick access to emergency services',
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
                    color: error,
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