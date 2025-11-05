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
        margin: EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.contacts_rounded, 'Contacts'),
            _buildCenterScannerButton(),
            _buildNavItem(3, Icons.history_rounded, 'Recent'),
            _buildNavItem(4, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterScannerButton() {
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
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(isSelected ? 0.6 : 0.5),
                    blurRadius: isSelected ? 24 : 18,
                    offset: Offset(0, isSelected ? 6 : 4),
                    spreadRadius: isSelected ? 3 : 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 30,
                color: white,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Scan',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected 
                  ? (isDarkMode ? white : primary)
                  : (isDarkMode ? subtextColor.withOpacity(0.6) : grey.withOpacity(0.7)),
                letterSpacing: 0.2,
              ),
            ),
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
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                padding: EdgeInsets.all(10),
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
                  size: 24,
                  color: isSelected 
                    ? white 
                    : isDarkMode ? subtextColor : grey,
                ),
              ),
              SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected 
                    ? (isDarkMode ? white : primary)
                    : (isDarkMode ? subtextColor.withOpacity(0.6) : grey.withOpacity(0.7)),
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