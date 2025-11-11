// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final Function(int) onItemTapped;
  final Color textColor;
  final Color subtextColor;
  final int pendingRequestsCount;

  const CustomBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.onItemTapped,
    required this.textColor,
    required this.subtextColor,
    required this.pendingRequestsCount,
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
          _buildNavItem(0, Icons.home_rounded, 'Home', isSmallScreen, isMediumScreen),
          _buildNavItem(1, Icons.people_rounded, 'Patients', isSmallScreen, isMediumScreen),
          _buildCenterTrackButton(isSmallScreen, isMediumScreen),
          _buildNavItemWithBadge(2, Icons.inbox_rounded, 'Requests', pendingRequestsCount, isSmallScreen, isMediumScreen),
          _buildNavItem(3, Icons.person_rounded, 'Profile', isSmallScreen, isMediumScreen),
        ],
      ),
    );
  }

  Widget _buildCenterTrackButton(bool isSmallScreen, bool isMediumScreen) {
    final isSelected = selectedIndex == 4;
    
    return GestureDetector(
      onTap: () => onItemTapped(4),
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
              Icons.accessibility_new_rounded,
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
                      ? subtextColor.withOpacity(0.6)
                      : grey.withOpacity(0.7)),
              letterSpacing: 0.2,
            ),
          ),
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

  Widget _buildNavItemWithBadge(
    int index,
    IconData icon,
    String label,
    int badgeCount,
    bool isSmallScreen,
    bool isMediumScreen,
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
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
                      decoration: BoxDecoration(
                        color: error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? Color(0xFF1A1F3A) : white,
                          width: 2,
                        ),
                      ),
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 18 : 20,
                        minHeight: isSmallScreen ? 18 : 20,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: TextStyle(
                            color: white,
                            fontSize: isSmallScreen ? 9 : 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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