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
      child: Material(
        color: Colors.transparent,
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
          borderRadius: BorderRadius.circular(radiusLarge),
          splashColor: error.withOpacity(0.2),
          highlightColor: error.withOpacity(0.1),
          child: Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(radiusLarge),
              boxShadow: isDarkMode
                  ? [
                      BoxShadow(
                        color: error.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : softShadow,
              border: isDarkMode
                  ? Border.all(
                      color: error.withOpacity(0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingSmall),
                  decoration: BoxDecoration(
                    color: error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  child: Icon(
                    Icons.phone_in_talk_rounded,
                    color: error,
                    size: 24,
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
                          fontSize: 15,
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
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: error,
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