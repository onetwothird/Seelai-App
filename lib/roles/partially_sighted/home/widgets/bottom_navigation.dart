// File: lib/roles/partially_sighted/home/widgets/bottom_navigation.dart

import 'package:flutter/material.dart';

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

  // The vibrant purple from the new design
  final Color _activeColor = const Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    // Pure white or dark card color for the navigation bar
    final bgColor = isDarkMode ? const Color(0xFF1A1F3A) : Colors.white;
    
    return Semantics(
      label: 'Bottom navigation bar',
      child: Container(
        // No margin, fills the bottom edge-to-edge
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24), 
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.04), // Very soft shadow blending upward
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false, 
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8, left: 8, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home', isSmallScreen),
                _buildNavItem(1, Icons.contacts_rounded, 'Contacts', isSmallScreen),
                _buildCenterScannerButton(isSmallScreen),
                _buildNavItem(3, Icons.history_rounded, 'Recent', isSmallScreen),
                _buildNavItem(4, Icons.person_rounded, 'Profile', isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Center Scanner Button with the large circular outline
  Widget _buildCenterScannerButton(bool isSmallScreen) {
    final isSelected = selectedIndex == 2; 
    
    return Semantics(
      label: 'Scanner tab',
      selected: isSelected,
      button: true,
      hint: 'Double tap to open object detection scanner',
      child: GestureDetector(
        onTap: () => onItemTapped(2),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isSmallScreen ? 56 : 64,
              height: isSmallScreen ? 56 : 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Solid color if selected, transparent if inactive
                color: isSelected ? _activeColor : Colors.transparent,
                border: isSelected 
                    ? null 
                    : Border.all(
                        color: _activeColor, // Thick solid border
                        width: 2.5,
                      ),
                boxShadow: isSelected && !isDarkMode ? [
                  BoxShadow(
                    color: _activeColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ] : [],
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: isSmallScreen ? 28 : 32,
                color: isSelected ? Colors.white : _activeColor, 
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Scan',
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? _activeColor : const Color(0xFF94A3B8),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Standardized Squarish Nav Items
  Widget _buildNavItem(
    int index, 
    IconData icon, 
    String label, 
    bool isSmallScreen, 
  ) {
    final isSelected = selectedIndex == index;
    
    return Semantics(
      label: '$label tab',
      selected: isSelected,
      button: true,
      hint: 'Double tap to navigate to $label',
      child: GestureDetector(
        onTap: () => onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: isSmallScreen ? 56 : 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: isSmallScreen ? 46 : 52,
                height: isSmallScreen ? 46 : 52,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? _activeColor // Solid purple when active
                      : (isDarkMode ? Colors.white10 : const Color(0xFFF1F5F9)), // Soft light grey when inactive
                  borderRadius: BorderRadius.circular(18), // Squarish rounded corners
                  boxShadow: isSelected && !isDarkMode ? [
                    BoxShadow(
                      color: _activeColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ] : [],
                ),
                child: Icon(
                  icon,
                  size: isSmallScreen ? 24 : 26,
                  color: isSelected ? Colors.white : const Color(0xFF64748B), // Slate grey icon when inactive
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? _activeColor : const Color(0xFF94A3B8), // Slate grey text when inactive
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}