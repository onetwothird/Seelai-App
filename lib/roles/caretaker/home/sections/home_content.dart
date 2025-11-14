// ignore_for_file: deprecated_member_use

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
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          
          SizedBox(height: spacingXLarge),
          
          // Quick Stats Cards
          _buildQuickStats(context),
          
          SizedBox(height: spacingXLarge),
          
          // Quick Actions Section
          _buildQuickActionsSection(context),
          
          SizedBox(height: spacingXLarge),
          
          // Recent Activity Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: h3.copyWith(
                  fontSize: 20,
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  // View all activity
                },
                child: Text(
                  'View All',
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: primary,
                  ),
                ),
              ),
            ],
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
            subtitle: 'Active patients',
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
            subtitle: 'Pending',
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
    required String subtitle,
  }) {
    return Semantics(
      label: '$label: $value $subtitle',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radiusXLarge),
          boxShadow: isDarkMode
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: InkWell(
            onTap: () {
              // Navigate to respective section
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('View all $label'),
                  backgroundColor: color,
                ),
              );
            },
            borderRadius: BorderRadius.circular(radiusXLarge),
            child: Container(
              padding: EdgeInsets.all(spacingLarge * 1.2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(isDarkMode ? 0.2 : 0.12),
                    color.withOpacity(isDarkMode ? 0.1 : 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radiusXLarge),
                border: Border.all(
                  color: color.withOpacity(isDarkMode ? 0.3 : 0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(radiusLarge),
                      border: Border.all(
                        color: color.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
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
                  SizedBox(height: spacingLarge),
                  Text(
                    value,
                    style: h1.copyWith(
                      fontSize: 40,
                      color: theme.textColor,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: spacingXSmall),
                  Text(
                    label,
                    style: bodyBold.copyWith(
                      fontSize: 16,
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: caption.copyWith(
                      fontSize: 12,
                      color: theme.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: h3.copyWith(
            fontSize: 20,
            color: theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.location_on_rounded,
                title: 'Track Patients',
                subtitle: 'View locations',
                iconColor: Colors.blue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Track Patients coming soon'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.notifications_active_rounded,
                title: 'Alerts',
                subtitle: '2 new alerts',
                iconColor: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('View Alerts coming soon'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: spacingMedium),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.schedule_rounded,
                title: 'Schedule',
                subtitle: 'Today\'s tasks',
                iconColor: Colors.purple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Schedule coming soon'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.analytics_rounded,
                title: 'Reports',
                subtitle: 'View insights',
                iconColor: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reports coming soon'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: '$title. $subtitle',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: isDarkMode
              ? [
                  BoxShadow(
                    color: iconColor.withOpacity(0.1),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radiusLarge),
            child: Container(
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                    iconColor.withOpacity(isDarkMode ? 0.08 : 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radiusLarge),
                border: Border.all(
                  color: iconColor.withOpacity(isDarkMode ? 0.2 : 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: iconColor,
                    ),
                  ),
                  SizedBox(height: spacingMedium),
                  Text(
                    title,
                    style: bodyBold.copyWith(
                      fontSize: 15,
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: caption.copyWith(
                      fontSize: 12,
                      color: theme.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
    return Semantics(
      label: '${activity['title']}: ${activity['description']}, ${activity['time']}',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radiusXLarge),
          boxShadow: isDarkMode
              ? [
                  BoxShadow(
                    color: (activity['color'] as Color).withOpacity(0.1),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('View activity details'),
                  backgroundColor: activity['color'] as Color,
                ),
              );
            },
            borderRadius: BorderRadius.circular(radiusXLarge),
            child: Container(
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radiusXLarge),
                border: isDarkMode
                    ? Border.all(
                        color: (activity['color'] as Color).withOpacity(0.2),
                        width: 1,
                      )
                    : Border.all(
                        color: Colors.black.withOpacity(0.06),
                        width: 1,
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacingMedium),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (activity['color'] as Color).withOpacity(0.2),
                          (activity['color'] as Color).withOpacity(0.1),
                        ],
                      ),
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: spacingXSmall),
                        Text(
                          activity['description'] as String,
                          style: body.copyWith(
                            fontSize: 14,
                            color: theme.subtextColor,
                          ),
                        ),
                        SizedBox(height: spacingXSmall),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: theme.subtextColor.withOpacity(0.7),
                            ),
                            SizedBox(width: 4),
                            Text(
                              activity['time'] as String,
                              style: caption.copyWith(
                                fontSize: 12,
                                color: theme.subtextColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.subtextColor.withOpacity(0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}