// File: lib/roles/partially_sighted/home/widgets/bottom_navigation.dart

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 400;
    
    return Semantics(
      label: 'Bottom navigation bar',
      child: Container(
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
                ? primary.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _buildNavItem(0, Icons.home_rounded, 'Home', isSmallScreen, isMediumScreen),
            ),
            Expanded(
              child: _buildNavItem(1, Icons.contacts_rounded, 'Contacts', isSmallScreen, isMediumScreen),
            ),
            Expanded(
              child: _buildCenterScannerButton(isSmallScreen, isMediumScreen),
            ),
            Expanded(
              child: _buildNavItem(3, Icons.history_rounded, 'Recent', isSmallScreen, isMediumScreen),
            ),
            Expanded(
              child: _buildNavItem(4, Icons.person_rounded, 'Profile', isSmallScreen, isMediumScreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterScannerButton(bool isSmallScreen, bool isMediumScreen) {
    final isSelected = selectedIndex == 2;
    
    return Semantics(
      label: 'Scanner tab',
      selected: isSelected,
      button: true,
      hint: 'Double tap to open object detection scanner',
      child: GestureDetector(
        onTap: () => onItemTapped(2),
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
                Icons.qr_code_scanner_rounded,
                size: isSmallScreen ? 24 : (isMediumScreen ? 27 : 30),
                color: primary,
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            Text(
              'Scan',
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected 
                  ? (isDarkMode ? white : primary)
                  : (isDarkMode ? subtextColor.withValues(alpha: 0.6) : grey.withValues(alpha: 0.7)),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isSmallScreen, bool isMediumScreen) {
    final isSelected = selectedIndex == index;
    
    return Semantics(
      label: '$label tab',
      selected: isSelected,
      button: true,
      hint: 'Double tap to navigate to $label',
      child: GestureDetector(
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
                    : isDarkMode ? subtextColor : grey,
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
                    : (isDarkMode ? subtextColor.withValues(alpha: 0.6) : grey.withValues(alpha: 0.7)),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}