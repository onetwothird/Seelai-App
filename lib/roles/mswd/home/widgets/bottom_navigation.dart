// File: lib/roles/mswd/home/widgets/bottom_navigation.dart

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
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? primary.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Home', isSmallScreen, isMediumScreen),
          _buildNavItem(1, Icons.people_rounded, 'Users', isSmallScreen, isMediumScreen),
          _buildCenterTrackButton(isSmallScreen, isMediumScreen),
          _buildNavItem(2, Icons.assignment_rounded, 'Requests', isSmallScreen, isMediumScreen),
          _buildNavItem(4, Icons.menu_rounded, 'More', isSmallScreen, isMediumScreen),
        ],
      ),
    );
  }

  Widget _buildCenterTrackButton(bool isSmallScreen, bool isMediumScreen) {
    final isSelected = selectedIndex == 3;
    
    return GestureDetector(
      onTap: () => onItemTapped(3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.all(isSmallScreen ? 12 : (isMediumScreen ? 14 : 16)),
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF1A1F3A) : white,
              shape: BoxShape.circle,
              border: Border.all(
                width: isSmallScreen ? 2.5 : 3,
                color: primary,
              ),
            ),
            child: Icon(
              Icons.location_pin,
              size: isSmallScreen ? 24 : (isMediumScreen ? 27 : 30),
              color: primary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            'Track',
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDarkMode ? white : primary)
                  : (isDarkMode
                      ? subtextColor.withValues(alpha: 0.6)
                      : grey.withValues(alpha: 0.7)),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index, 
    IconData icon, 
    String label, 
    bool isSmallScreen, 
    bool isMediumScreen,
    {int badgeCount = 0}
  ) {
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
            Stack(
              clipBehavior: Clip.none,
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
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.4),
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
                
                // Badge
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.all(badgeCount > 9 ? 4 : 6),
                      decoration: BoxDecoration(
                        color: error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? Color(0xFF1A1F3A) : white,
                          width: 2,
                        ),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: TextStyle(
                          color: white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
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
                        ? subtextColor.withValues(alpha: 0.6)
                        : grey.withValues(alpha: 0.7)),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}