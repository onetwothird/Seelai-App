// File: lib/roles/caretaker/home/widgets/bottom_navigation.dart

import 'package:flutter/material.dart';

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

  // The vibrant purple from the new design
  final Color _activeColor = const Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    // Pure white or dark card color for the navigation bar
    final bgColor = isDarkMode ? const Color(0xFF1A1F3A) : Colors.white;
    
    return Container(
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
              _buildNavItem(1, Icons.people_alt_rounded, 'Patients', isSmallScreen),
              _buildCenterTrackButton(isSmallScreen),
              _buildNavItem(2, Icons.inbox_rounded, 'Requests', isSmallScreen, badgeCount: pendingRequestsCount),
              _buildNavItem(3, Icons.person_rounded, 'Profile', isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  // Center Track Button with the large circular outline
  Widget _buildCenterTrackButton(bool isSmallScreen) {
    final isSelected = selectedIndex == 4; // Maintained your index 4 mapping
    
    return GestureDetector(
      onTap: () => onItemTapped(4),
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
              Icons.location_on_rounded,
              size: isSmallScreen ? 28 : 32,
              color: isSelected ? Colors.white : _activeColor, 
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Track',
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? _activeColor : const Color(0xFF94A3B8),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Standardized Squarish Nav Items
  Widget _buildNavItem(
    int index, 
    IconData icon, 
    String label, 
    bool isSmallScreen, 
    {int badgeCount = 0}
  ) {
    final isSelected = selectedIndex == index;
    
    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: isSmallScreen ? 56 : 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
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
                
                // Optional Badge
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.all(badgeCount > 9 ? 3 : 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                          width: 2.0,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
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
    );
  }
}