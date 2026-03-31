// File: lib/roles/caretaker/home/sections/home_screen/overview.dart

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
        
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGridCard(
                backgroundIcon: Icons.group_outlined,
                title: 'Patients',
                subtitle: 'Total registered',
                bottomLabel: 'TOTAL',
                value: totalPatients.toString(),
                baseColor: primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGridCard(
                backgroundIcon: Icons.assignment_outlined, 
                title: 'Pending',
                subtitle: 'Awaiting review',
                bottomLabel: 'REQUESTS',
                value: pendingRequests.toString(),
                baseColor: const Color(0xFFF5A623),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGridCard(
                backgroundIcon: Icons.touch_app_outlined,
                title: 'In Progress',
                subtitle: 'Active sessions',
                bottomLabel: 'ONGOING',
                value: activeRequests.toString(),
                baseColor: const Color(0xFF60A5FA),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGridCard(
                backgroundIcon: Icons.task_alt_outlined,
                title: 'Completed',
                subtitle: 'Finished tasks',
                bottomLabel: 'TOTAL',
                value: completedRequests.toString(),
                baseColor: const Color(0xFF34D399),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required IconData backgroundIcon,
    required String title,
    required String subtitle,
    required String bottomLabel,
    required String value,
    required Color baseColor,
  }) {
    return Container(
      height: 140, 
      clipBehavior: Clip.hardEdge, 
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.15), 
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -10,
            child: Icon(
              backgroundIcon,
              size: 110,
              color: baseColor.withValues(alpha: 0.12),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.subtextColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_horiz_rounded,
                      color: theme.subtextColor,
                      size: 20,
                    ),
                  ],
                ),

                // This section aligns the number to the horizontal center of the bottomLabel
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // Center the number relative to label
                  children: [
                    Text(
                      bottomLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.subtextColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2, 
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading ? '-' : value,
                      style: TextStyle(
                        fontSize: 26,
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}