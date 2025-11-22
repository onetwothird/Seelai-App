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
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final adminName = widget.userData['name'] ?? 'Admin';
    final greeting = _getGreeting();

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeSection(adminName, greeting),
          
          SizedBox(height: spacingXLarge),
          
          // Quick Stats Grid
          _buildQuickStats(),
          
          SizedBox(height: spacingXLarge),
          
          // Quick Actions
          _buildQuickActions(),
          
          SizedBox(height: spacingXLarge),
          
          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildWelcomeSection(String name, String greeting) {
    return Container(
      padding: EdgeInsets.all(spacingLarge * 1.2),
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              color: white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wb_sunny_rounded,
              color: white,
              size: 32,
            ),
          ),
          SizedBox(width: spacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: bodyBold.copyWith(
                    color: white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  name.split(' ')[0],
                  style: h2.copyWith(
                    color: white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
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
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_rounded,
                label: 'Total Users',
                value: '1,234',
                color: primary,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildStatCard(
                icon: Icons.pending_actions_rounded,
                label: 'Pending',
                value: '45',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: spacingMedium),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle_rounded,
                label: 'Completed',
                value: '892',
                color: Colors.green,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildStatCard(
                icon: Icons.warning_rounded,
                label: 'Alerts',
                value: '12',
                color: error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
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
                  color: color.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: color.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: spacingMedium),
          Text(
            value,
            style: h1.copyWith(
              fontSize: 28,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: caption.copyWith(
              fontSize: 12,
              color: widget.theme.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: h3.copyWith(
            fontSize: 20,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.person_add_rounded,
                label: 'Add User',
                color: primary,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Add User coming soon')),
                  );
                },
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildActionCard(
                icon: Icons.campaign_rounded,
                label: 'Announcement',
                color: accent,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Send Announcement coming soon')),
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
              child: _buildActionCard(
                icon: Icons.map_rounded,
                label: 'View Map',
                color: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Location Map coming soon')),
                  );
                },
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildActionCard(
                icon: Icons.bar_chart_rounded,
                label: 'Reports',
                color: Colors.purple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reports coming soon')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: widget.theme.cardColor,
      borderRadius: BorderRadius.circular(radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusLarge),
        child: Container(
          padding: EdgeInsets.all(spacingLarge),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(radiusLarge),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              SizedBox(height: spacingSmall),
              Text(
                label,
                style: bodyBold.copyWith(
                  fontSize: 13,
                  color: widget.theme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
        'description': 'Navigation assistance completed',
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
            TextButton(
              onPressed: () {},
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
        ...activities.map((activity) => Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildActivityCard(activity),
        )),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: (activity['color'] as Color).withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(
                color: (activity['color'] as Color).withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacingMedium),
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
          SizedBox(width: spacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: bodyBold.copyWith(
                    fontSize: 15,
                    color: widget.theme.textColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  activity['description'] as String,
                  style: caption.copyWith(
                    fontSize: 13,
                    color: widget.theme.subtextColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  activity['time'] as String,
                  style: caption.copyWith(
                    fontSize: 11,
                    color: widget.theme.subtextColor.withOpacity(0.7),
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