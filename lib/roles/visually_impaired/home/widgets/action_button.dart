// File: lib/roles/visually_impaired/home/widgets/action_button.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final bool isEmergency;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label button',
      button: true,
      hint: 'Double tap to activate $label',
      child: Container(
        decoration: BoxDecoration(
          boxShadow: isDarkMode 
            ? [
                BoxShadow(
                  color: (isEmergency ? error : primary).withOpacity(0.2),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        child: Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(radiusLarge),
            splashColor: primary.withOpacity(0.2),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: spacingLarge * 1.2),
              decoration: BoxDecoration(
                gradient: isEmergency
                  ? LinearGradient(
                      colors: [
                        error.withOpacity(isDarkMode ? 0.25 : 0.1), 
                        error.withOpacity(isDarkMode ? 0.15 : 0.05)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                borderRadius: BorderRadius.circular(radiusLarge),
                border: isDarkMode 
                  ? Border.all(
                      color: isEmergency 
                        ? error.withOpacity(0.4)
                        : primary.withOpacity(0.3), 
                      width: 1.5
                    )
                  : Border.all(
                      color: isEmergency 
                        ? error.withOpacity(0.3)
                        : greyLighter,
                      width: 1.5,
                    ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacingMedium * 1.2),
                    decoration: BoxDecoration(
                      gradient: isEmergency 
                        ? LinearGradient(colors: [error, error.withOpacity(0.8)])
                        : primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isEmergency ? error : primary).withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 28, color: white),
                  ),
                  SizedBox(height: spacingMedium),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: bodyBold.copyWith(
                      fontSize: 15,
                      color: textColor,
                      fontWeight: FontWeight.w700,
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