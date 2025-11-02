// File: lib/roles/caretaker/home/widgets/quick_stats_section.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class QuickStatsSection extends StatelessWidget {
  final int totalPatients;
  final int activeAlerts;
  final int pendingRequests;
  final bool isDarkMode;
  final dynamic theme;

  const QuickStatsSection({
    super.key,
    required this.totalPatients,
    required this.activeAlerts,
    required this.pendingRequests,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Patients',
            value: totalPatients.toString(),
            icon: Icons.people_rounded,
            gradient: LinearGradient(
              colors: [primary, primary.withOpacity(0.8)],
            ),
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: _buildStatCard(
            label: 'Alerts',
            value: activeAlerts.toString(),
            icon: Icons.warning_rounded,
            gradient: LinearGradient(
              colors: [error, error.withOpacity(0.8)],
            ),
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: _buildStatCard(
            label: 'Requests',
            value: pendingRequests.toString(),
            icon: Icons.pending_actions_rounded,
            gradient: LinearGradient(
              colors: [accent, accent.withOpacity(0.8)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.15),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ]
          : cardShadow,
        border: isDarkMode 
          ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
          : Border.all(color: greyLighter.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.4),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: white, size: 24),
          ),
          SizedBox(height: spacingMedium),
          Text(
            value,
            style: h2.copyWith(
              fontSize: 28,
              color: theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: spacingXSmall),
          Text(
            label,
            style: caption.copyWith(
              fontSize: 13,
              color: theme.subtextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}