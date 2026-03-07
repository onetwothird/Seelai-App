// File: lib/roles/visually_impaired/home/widgets/icon_button.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final bool isDarkMode;
  final bool isSpecial;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 28,
    required this.isDarkMode,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: (isSpecial ? accent : primary).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ]
          : softShadow,
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      child: Material(
        color: isDarkMode 
          ? (isSpecial ? accent.withValues(alpha: 0.25) : primary.withValues(alpha: 0.2))
          : primaryLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radiusMedium),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radiusMedium),
          splashColor: primary.withValues(alpha: 0.3),
          child: Container(
            padding: EdgeInsets.all(spacingMedium),
            child: Icon(
              icon,
              size: size,
              color: isDarkMode 
                ? (isSpecial ? accent : primaryLight)
                : primary,
            ),
          ),
        ),
      ),
    );
  }
}