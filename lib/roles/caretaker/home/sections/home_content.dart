import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/services/request_service.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';

class HomeContent extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final Function(String) onNotificationUpdate;
  final RequestService requestService;
  final LocationService locationService;

  const HomeContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.onNotificationUpdate,
    required this.requestService,
    required this.locationService,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: spacingMedium),
          
          // Quick Stats Cards
          _buildQuickStats(context),
          
          SizedBox(height: spacingXLarge),
          
          // Recent Activity
          Text(
            'Recent Activity',
            style: bodyBold.copyWith(
              fontSize: 18,
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacingMedium),
          
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.people_rounded,
            label: 'Patients',
            value: '5',
            color: primary,
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.pending_actions_rounded,
            label: 'Requests',
            value: '3',
            color: accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: spacingLarge * 1.2,
        horizontal: spacingMedium,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            // ignore: deprecated_member_use
            color.withOpacity(isDarkMode ? 0.3 : 0.12),
            // ignore: deprecated_member_use
            color.withOpacity(isDarkMode ? 0.2 : 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          // ignore: deprecated_member_use
          color: color.withOpacity(isDarkMode ? 0.5 : 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: color.withOpacity(isDarkMode ? 0.25 : 0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(spacingMedium * 1.3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  // ignore: deprecated_member_use
                  color.withOpacity(0.3),
                  // ignore: deprecated_member_use
                  color.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                // ignore: deprecated_member_use
                color: color.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          SizedBox(height: spacingMedium * 1.3),
          Text(
            value,
            style: h1.copyWith(
              fontSize: 36,
              color: theme.textColor,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: spacingSmall),
          Text(
            label,
            style: bodyBold.copyWith(
              fontSize: 15,
              color: theme.subtextColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final activities = [
      {
        'title': 'Request Completed',
        'description': 'Navigation help for Maria Santos',
        'time': '10 minutes ago',
        'icon': Icons.check_circle_rounded,
        'color': Colors.green,
      },
      {
        'title': 'New Request',
        'description': 'Reading assistance needed',
        'time': '1 hour ago',
        'icon': Icons.notifications_active_rounded,
        'color': accent,
      },
      {
        'title': 'Patient Check-in',
        'description': 'Juan Dela Cruz location updated',
        'time': '2 hours ago',
        'icon': Icons.location_on_rounded,
        'color': primary,
      },
    ];

    return Column(
      children: activities.map((activity) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildActivityCard(context, activity),
        );
      }).toList(),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    Map<String, dynamic> activity,
  ) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: isDarkMode
            ? [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: (activity['color'] as Color).withOpacity(0.15),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        border: isDarkMode
            ? Border.all(
                // ignore: deprecated_member_use
                color: (activity['color'] as Color).withOpacity(0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: (activity['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 24,
            ),
          ),
          SizedBox(width: spacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: bodyBold.copyWith(
                    fontSize: 16,
                    color: theme.textColor,
                  ),
                ),
                SizedBox(height: spacingXSmall),
                Text(
                  activity['description'] as String,
                  style: caption.copyWith(
                    fontSize: 14,
                    color: theme.subtextColor,
                  ),
                ),
                SizedBox(height: spacingXSmall),
                Text(
                  activity['time'] as String,
                  style: caption.copyWith(
                    fontSize: 12,
                    color: theme.subtextColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}