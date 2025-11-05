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
    return Container(
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
          _buildNavItem(1, Icons.people_rounded, 'Patients'),
          _buildCenterTrackButton(),
          _buildNavItemWithBadge(2, Icons.inbox_rounded, 'Requests', pendingRequestsCount),
          _buildNavItem(3, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildCenterTrackButton() {
    final isSelected = selectedIndex == 4; // Empty index for now
    
    return GestureDetector(
      onTap: () => onItemTapped(4), // Will do nothing for now
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
              Icons.accessibility_new_rounded,
              size: 30,
              color: white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Track',
            style: TextStyle(
              fontSize: 11,
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

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    
    return GestureDetector(
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
                    : isDarkMode
                        ? subtextColor
                        : grey,
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
  ) {
    final isSelected = selectedIndex == index;
    
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
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
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? Color(0xFF1A1F3A) : white,
                          width: 2,
                        ),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: TextStyle(
                            color: white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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