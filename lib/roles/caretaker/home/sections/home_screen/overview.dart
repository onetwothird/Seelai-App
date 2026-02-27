// File: lib/roles/caretaker/home/sections/home_screen/overview.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class OverviewSection extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final bool isLoading;
  final int totalPatients;
  final int pendingRequests;
  final int activeRequests;
  final int completedRequests;

  const OverviewSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.isLoading,
    required this.totalPatients,
    required this.pendingRequests,
    required this.activeRequests,
    required this.completedRequests,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            color: theme.textColor,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGridCard(
                icon: Icons.people_rounded,
                label: 'Patients',
                value: totalPatients.toString(),
                baseColor: primary, // Your brand color
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGridCard(
                icon: Icons.pending_actions_rounded,
                label: 'Pending',
                value: pendingRequests.toString(),
                baseColor: const Color(0xFFF59E0B), // Orange
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGridCard(
                icon: Icons.touch_app_rounded,
                label: 'In Progress',
                value: activeRequests.toString(),
                baseColor: const Color(0xFF3B82F6), // Blue
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGridCard(
                icon: Icons.check_circle_rounded,
                label: 'Completed',
                value: completedRequests.toString(),
                baseColor: const Color(0xFF10B981), // Green
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required IconData icon,
    required String label,
    required String value,
    required Color baseColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode 
              ? baseColor.withOpacity(0.2) 
              : Colors.black.withOpacity(0.03),
        ),
        boxShadow: isDarkMode ? [] : [
          BoxShadow(
            color: baseColor.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        // Main alignment to center items within the Column
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            // Also center the icon container horizontally
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: baseColor, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Wrap the text in Center to be doubly sure, and set textAlign
          Center(
            child: Text(
              isLoading ? '-' : value,
              textAlign: TextAlign.center, // Center numerical alignment
              style: TextStyle(
                fontSize: 28,
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              label,
              textAlign: TextAlign.center, // Center label alignment
              style: TextStyle(
                fontSize: 13,
                color: theme.subtextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}