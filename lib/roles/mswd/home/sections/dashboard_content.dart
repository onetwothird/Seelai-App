// File: lib/roles/mswd/home/sections/dashboard_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class DashboardContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final ScrollController? scrollController;

  const DashboardContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    this.scrollController,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  int _currentStatIndex = 0;
  final PageController _statsController = PageController();

  @override
  void dispose() {
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Grid - Swipeable
          _buildQuickStatsSection(),

          SizedBox(height: spacingXLarge),

          // Recent Activity
          _buildRecentActivity(),

          SizedBox(height: spacingXLarge),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    final stats = [
      {
        'icon': Icons.people_rounded,
        'label': 'Total Users',
        'value': '1,234',
        'color': primary,
        'subtitle': '↑ 12 this week',
      },
      {
        'icon': Icons.pending_actions_rounded,
        'label': 'Pending Verifications',
        'value': '45',
        'color': Colors.orange,
        'subtitle': '⏱ Awaiting approval',
      },
      {
        'icon': Icons.touch_app_rounded,
        'label': 'Active Requests',
        'value': '28',
        'color': Colors.blue,
        'subtitle': '🔄 In progress',
      },
      {
        'icon': Icons.warning_rounded,
        'label': 'Emergency Alerts',
        'value': '3',
        'color': error,
        'subtitle': '🚨 Today',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: h3.copyWith(
            fontSize: 20,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _statsController,
            onPageChanged: (index) {
              setState(() => _currentStatIndex = index % stats.length);
            },
            itemBuilder: (context, index) {
              final stat = stats[index % stats.length];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: _buildStatCard(
                  icon: stat['icon'] as IconData,
                  label: stat['label'] as String,
                  value: stat['value'] as String,
                  subtitle: stat['subtitle'] as String,
                  color: stat['color'] as Color,
                ),
              );
            },
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildPageIndicator(stats.length),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: color.withOpacity(0.3), width: 1.5)
            : Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(spacingMedium),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(radiusSmall),
                ),
                child: Text(
                  subtitle,
                  style: caption.copyWith(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: h1.copyWith(
                  fontSize: 32,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: caption.copyWith(
                  fontSize: 13,
                  color: widget.theme.subtextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int itemCount) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          itemCount,
          (index) => AnimatedContainer(
            duration: Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: 4),
            width: _currentStatIndex == index ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentStatIndex == index
                  ? primary
                  : widget.theme.subtextColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {
        'title': 'New User Registration',
        'description': 'Maria Santos registered as Visually Impaired',
        'time': '5 mins ago',
        'icon': Icons.person_add_rounded,
        'color': Colors.green,
      },
      {
        'title': 'Request Completed',
        'description': 'Navigation assistance completed for Juan',
        'time': '15 mins ago',
        'icon': Icons.check_circle_rounded,
        'color': Colors.blue,
      },
      {
        'title': 'Emergency Alert',
        'description': 'SOS activated by Juan Dela Cruz',
        'time': '1 hour ago',
        'icon': Icons.warning_rounded,
        'color': error,
      },
      {
        'title': 'Verification Approved',
        'description': 'Anna Reyes verified as Community Helper',
        'time': '2 hours ago',
        'icon': Icons.verified_rounded,
        'color': Colors.purple,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: h3.copyWith(
                fontSize: 20,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Activity Log coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(radiusMedium),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'View All',
                    style: bodyBold.copyWith(
                      fontSize: 14,
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacingMedium),
        ...activities.map(
          (activity) => Padding(
            padding: EdgeInsets.only(bottom: spacingMedium),
            child: _buildActivityCard(activity),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color:
                      (activity['color'] as Color).withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(
                color: (activity['color'] as Color)
                    .withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacingSmall),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 24,
            ),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: bodyBold.copyWith(
                    fontSize: 15,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  activity['description'] as String,
                  style: caption.copyWith(
                    fontSize: 13,
                    color: widget.theme.subtextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Text(
                  activity['time'] as String,
                  style: caption.copyWith(
                    fontSize: 11,
                    color: widget.theme.subtextColor
                        .withOpacity(0.7),
                    fontWeight: FontWeight.w500,
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