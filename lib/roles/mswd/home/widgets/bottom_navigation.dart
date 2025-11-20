// File: lib/roles/mswd/home/widgets/bottom_navigation.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class MSWDBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final Function(int) onItemTapped;
  final Color textColor;
  final Color subtextColor;

  const MSWDBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.onItemTapped,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 400;
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 8 : 12, 
        horizontal: isSmallScreen ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1A1F3A) : white,
        borderRadius: BorderRadius.circular(24),
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
          _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard', isSmallScreen, isMediumScreen),
          _buildNavItem(1, Icons.people_rounded, 'Users', isSmallScreen, isMediumScreen),
          _buildNavItem(2, Icons.map_rounded, 'Tracking', isSmallScreen, isMediumScreen),
          _buildNavItem(3, Icons.bar_chart_rounded, 'Analytics', isSmallScreen, isMediumScreen),
          _buildNavItem(4, Icons.person_rounded, 'Profile', isSmallScreen, isMediumScreen),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isSmallScreen, bool isMediumScreen) {
    final isSelected = selectedIndex == index;
    
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : (isMediumScreen ? 10 : spacingMedium),
          vertical: isSmallScreen ? 4 : spacingSmall,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                gradient: isSelected ? primaryGradient : null,
                color: isSelected
                    ? null
                    : (isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(14),
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
              child: Icon(
                icon,
                size: isSmallScreen ? 20 : (isMediumScreen ? 22 : 24),
                color: isSelected
                    ? white
                    : isDarkMode
                        ? subtextColor
                        : grey,
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 9 : (isMediumScreen ? 10 : 11),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDarkMode ? white : primary)
                    : (isDarkMode
                        ? subtextColor.withOpacity(0.6)
                        : grey.withOpacity(0.7)),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}