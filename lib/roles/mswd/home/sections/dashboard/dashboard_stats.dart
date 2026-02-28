// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/admin_service.dart';

class DashboardStats extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;

  const DashboardStats({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: adminService.getUserStatistics(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {
          'visually_impaired': 0,
          'caretaker': 0,
          'active': 0,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: h3.copyWith(
                fontSize: 20,
                color: theme.textColor,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Visually Impaired',
                    count: stats['visually_impaired'].toString(),
                    icon: Icons.visibility_off_rounded,
                    color: const Color(0xFF8B5CF6), // Purple
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Caretakers',
                    count: stats['caretaker'].toString(),
                    icon: Icons.volunteer_activism_rounded,
                    color: const Color(0xFF10B981), // Emerald
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildWideStatCard(
              title: 'Total Active Users Today',
              count: stats['active'].toString(),
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF3B82F6), // Blue
            ),
          ],
        );
      },
    );
  }

Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDarkMode
        ? [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
        : softShadow,
        border: isDarkMode
        ? Border.all(color: color.withValues(alpha: 0.2), width: 1)
        : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
         Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            count,
            style: h2.copyWith(
              fontSize: 32,
              color: theme.textColor,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: caption.copyWith(
              fontSize: 13,
              color: theme.subtextColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWideStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity, // Ensures the card takes up all available horizontal space
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // Slightly more generous padding
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDarkMode
            ? [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
            : softShadow,
        border: isDarkMode ? Border.all(color: color.withValues(alpha: 0.2), width: 1) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Text and Number Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Left-aligned for better structure on wide cards
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: caption.copyWith(
                    fontSize: 14,
                    color: theme.subtextColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1, // Protects against overflow on smaller screens
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6), // Slightly tighter spacing between title and count
                Padding(
                  padding: const EdgeInsets.only(left: 70.0), // <--- Padding goes here, outside the Text!
                  child: Text(
                    count,
                    style: h2.copyWith(
                      fontSize: 32,
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                      // Make sure you delete the padding line from inside here
                    ),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(width: 16), // Breathing room
          
          // 2. Icon stays on the far right
          Container(
            padding: const EdgeInsets.all(14), // Slightly scaled up for the wide card
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30), 
          ),
        ],
      ),
    );
  }
}