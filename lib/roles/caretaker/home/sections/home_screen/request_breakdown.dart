// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class RequestBreakdownSection extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final bool isLoading;
  final int pendingRequests;
  final int activeRequests;
  final int completedRequests;

  const RequestBreakdownSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.isLoading,
    required this.pendingRequests,
    required this.activeRequests,
    required this.completedRequests,
  });

  @override
  Widget build(BuildContext context) {
    final totalRequests = pendingRequests + activeRequests + completedRequests;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Breakdown',
          style: h3.copyWith(
            fontSize: 20,
            color: theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildBreakdownCard(
          icon: Icons.hourglass_empty_rounded,
          label: 'Pending Requests',
          value: isLoading ? '...' : pendingRequests.toString(),
          color: Colors.orange,
          percentage: totalRequests > 0 
              ? ((pendingRequests / totalRequests) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
        SizedBox(height: spacingMedium),
        _buildBreakdownCard(
          icon: Icons.loop_rounded,
          label: 'Active Requests',
          value: isLoading ? '...' : activeRequests.toString(),
          color: Colors.blue,
          percentage: totalRequests > 0 
              ? ((activeRequests / totalRequests) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
        SizedBox(height: spacingMedium),
        _buildBreakdownCard(
          icon: Icons.task_alt_rounded,
          label: 'Completed Requests',
          value: isLoading ? '...' : completedRequests.toString(),
          color: Colors.green,
          percentage: totalRequests > 0 
              ? ((completedRequests / totalRequests) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
      ],
    );
  }

  Widget _buildBreakdownCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String percentage,
  }) {
    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: isDarkMode
            ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: Offset(0, 4))]
            : softShadow,
        border: isDarkMode ? Border.all(color: color.withOpacity(0.2), width: 1) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacingSmall),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: bodyBold.copyWith(
                    fontSize: 15,
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$percentage% of total',
                  style: caption.copyWith(
                    fontSize: 12,
                    color: theme.subtextColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: h2.copyWith(
              fontSize: 28,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}