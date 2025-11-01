// File: lib/roles/visually_impaired/home/widgets/bottom_navigation.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final Function(int) onItemTapped;
  final Color textColor;
  final Color subtextColor;

  const CustomBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.onItemTapped,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bottom navigation bar',
      child: Container(
        margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isDarkMode
            ? LinearGradient(
                colors: [
                  Color(0xFF1A1F3A).withOpacity(0.95),
                  Color(0xFF2A2F4A).withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  white.withOpacity(0.95),
                  white.withOpacity(0.90),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode 
              ? primary.withOpacity(0.3)
              : greyLighter.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                ? primary.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.person_rounded, 'Profile'),
            _buildNavItem(2, Icons.history_rounded, 'Recent'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    
    return Semantics(
      label: '$label tab',
      selected: isSelected,
      button: true,
      hint: 'Double tap to navigate to $label',
      child: GestureDetector(
        onTap: () => onItemTapped(index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? spacingLarge * 1.5 : spacingMedium,
            vertical: spacingMedium,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? primaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ]
              : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected 
                  ? white 
                  : isDarkMode ? subtextColor : grey,
              ),
              if (isSelected) ...[
                SizedBox(width: 8),
                Text(
                  label,
                  style: caption.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}