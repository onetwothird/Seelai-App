// File: lib/roles/visually_impaired/home/widgets/quick_actions_section.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/home/widgets/action_button.dart';

class QuickActionsSection extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final Color subtextColor;
  final Function(String) onAction;
  final VoidCallback onEmergencyHotlines;

  const QuickActionsSection({
    super.key,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
    required this.onAction,
    required this.onEmergencyHotlines,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quick actions section',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: h2.copyWith(
              fontSize: 24,
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacingMedium),
          Text(
            'Tap any button to activate assistance',
            style: body.copyWith(
              color: subtextColor,
              fontSize: 14,
            ),
          ),
          SizedBox(height: spacingLarge),
          
          // Action buttons grid
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: 'Scan Object',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: () => onAction('Object scanning started'),
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: ActionButton(
                  label: 'Read Text',
                  icon: Icons.text_fields_rounded,
                  onPressed: () => onAction('Text reading activated'),
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: spacingMedium),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: 'Detect Colors',
                  icon: Icons.palette_rounded,
                  onPressed: () => onAction('Color detection started'),
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: ActionButton(
                  label: 'Emergency',
                  icon: Icons.phone_in_talk_rounded,
                  onPressed: onEmergencyHotlines,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  isEmergency: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}