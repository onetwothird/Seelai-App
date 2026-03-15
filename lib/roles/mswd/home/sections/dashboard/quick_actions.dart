// File: lib/roles/mswd/home/sections/dashboard/quick_actions.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/add_announcement.dart';

class QuickActions extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Function(int) onNavigateToTab;

  const QuickActions({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Command Center',
          style: h3.copyWith(
            fontSize: 20,
            color: theme.textColor,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(
              context,
              icon: Icons.map_rounded,
              label: 'Live Map',
              color: const Color(0xFF3B82F6), // Blue
              onTap: () {
                // Navigate to Location Tab (Index 3)
                onNavigateToTab(3);
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.campaign_rounded,
              label: 'Broadcast',
              color: const Color(0xFFF59E0B), // Orange
              onTap: () {
                // Open Add Announcement Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddAnnouncementPage(
                      isDarkMode: isDarkMode,
                      theme: theme,
                    ),
                  ),
                );
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.contact_phone_rounded,
              label: 'Directory',
              color: const Color(0xFF10B981), // Green
              onTap: () {
                // Navigate to Users Tab (Index 1) for calling/dispatch
                onNavigateToTab(1);
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.assignment_late_rounded,
              label: 'Requests',
              color: const Color(0xFFEF4444), // Red
              onTap: () {
                // Navigate to Requests Tab (Index 2)
                onNavigateToTab(2);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              // Replaced colorful border with a subtle neutral one
              border: Border.all(
                color: isDarkMode 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
              // Removed colored shadows in favor of a clean, plain shadow
              boxShadow: isDarkMode 
                  ? [] 
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
        ],
      ),
    );
  }
}