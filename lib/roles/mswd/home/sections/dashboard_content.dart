// File: lib/roles/mswd/home/sections/dashboard_content.dart
// ignore_for_file: deprecated_member_use, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/admin_service.dart';

class DashboardContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final ScrollController scrollController;

  const DashboardContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.scrollController,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool _isLoading = true;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await adminService.getUserStatistics();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      color: primary,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: width * 0.05,
          right: width * 0.05,
          top: spacingMedium,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Grid
            _buildStatisticsSection(),
            
            SizedBox(height: spacingXLarge),
            
            // Emergency & Monitoring Section
            _buildEmergencyMonitoringSection(),
            
            SizedBox(height: spacingXLarge),
            
            // Request Management
            _buildRequestManagementSection(),
            
            SizedBox(height: spacingXLarge),
            
            // Recent Activity
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );
  }

  

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'User Statistics',
            style: h3.copyWith(
              fontSize: 20,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: spacingMedium),
        if (_isLoading)
          _buildLoadingGrid()
        else
          _buildStatisticsGrid(),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: spacingMedium,
      crossAxisSpacing: spacingMedium,
      childAspectRatio: 1.4,
      children: List.generate(4, (index) {
        return Container(
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: spacingMedium,
      crossAxisSpacing: spacingMedium,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          icon: Icons.visibility_off_rounded,
          label: 'VI Users',
          value: '${_stats['visually_impaired'] ?? 0}',
          color: primary,
        ),
        _buildStatCard(
          icon: Icons.favorite_rounded,
          label: 'Caretakers',
          value: '${_stats['caretaker'] ?? 0}',
          color: accent,
        ),
        _buildStatCard(
          icon: Icons.people_rounded,
          label: 'Total Users',
          value: '${_stats['total'] ?? 0}',
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.check_circle_rounded,
          label: 'Active Today',
          value: '${_stats['active'] ?? 0}',
          color: Colors.green,
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
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
        color: widget.theme.cardColor,
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
            border: widget.isDarkMode
                ? Border.all(color: color.withOpacity(0.2), width: 1)
                : Border.all(color: color.withOpacity(0.15), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyMonitoringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Emergency & Monitoring',
            style: h3.copyWith(
              fontSize: 20,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: spacingMedium),
        Row(
          children: [
            Expanded(
              child: _buildMonitoringCard(
                icon: Icons.emergency_rounded,
                title: 'Active Alerts',
                value: '2',
                subtitle: 'Immediate attention',
                color: error,
                isUrgent: true,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildMonitoringCard(
                icon: Icons.location_on_rounded,
                title: 'Live Tracking',
                value: '8',
                subtitle: 'Users tracked',
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonitoringCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    bool isUrgent = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
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
        color: widget.theme.cardColor,
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
              color: color.withOpacity(isUrgent ? 0.3 : 0.2),
              width: isUrgent ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (isUrgent)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(radiusSmall),
                      ),
                      child: Text(
                        'URGENT',
                        style: TextStyle(
                          color: error,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
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
                title,
                style: bodyBold.copyWith(
                  fontSize: 13,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: caption.copyWith(
                  fontSize: 11,
                  color: widget.theme.subtextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestManagementSection() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
        border: widget.isDarkMode
            ? Border.all(color: Colors.orange.withOpacity(0.2), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.orange.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  child: Icon(
                    Icons.assignment_rounded,
                    color: white,
                    size: 20,
                  ),
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request Management',
                        style: bodyBold.copyWith(
                          fontSize: 16,
                          color: widget.theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Track all requests',
                        style: caption.copyWith(
                          fontSize: 12,
                          color: widget.theme.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacingLarge),
            child: Divider(height: 1),
          ),
          Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Column(
              children: [
                _buildRequestRow(
                  'Pending',
                  '12',
                  Colors.orange,
                  Icons.pending_actions_rounded,
                ),
                SizedBox(height: spacingMedium),
                _buildRequestRow(
                  'Active',
                  '5',
                  Colors.blue,
                  Icons.hourglass_empty_rounded,
                ),
                SizedBox(height: spacingMedium),
                _buildRequestRow(
                  'Completed Today',
                  '28',
                  Colors.green,
                  Icons.check_circle_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestRow(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: Text(
            label,
            style: body.copyWith(
              fontSize: 14,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          child: Text(
            value,
            style: h2.copyWith(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    final activities = [
      {
        'title': 'Emergency Alert',
        'description': 'Maria Santos triggered SOS alert',
        'time': '2 min ago',
        'icon': Icons.emergency_rounded,
        'color': error,
        'isUrgent': true,
      },
      {
        'title': 'New Registration',
        'description': 'Juan Cruz registered as caretaker',
        'time': '15 min ago',
        'icon': Icons.person_add_rounded,
        'color': Colors.green,
        'isUrgent': false,
      },
      {
        'title': 'Request Completed',
        'description': 'Navigation assistance completed',
        'time': '1 hour ago',
        'icon': Icons.check_circle_rounded,
        'color': Colors.blue,
        'isUrgent': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Recent Activity',
                style: h3.copyWith(
                  fontSize: 20,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: bodyBold.copyWith(
                  fontSize: 13,
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacingSmall),
        ...activities.map((activity) {
          return Padding(
            padding: EdgeInsets.only(bottom: spacingMedium),
            child: _buildActivityCard(activity),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final color = activity['color'] as Color;
    final isUrgent = activity['isUrgent'] as bool;

    return Container(
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
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
        border: Border.all(
          color: color.withOpacity(isUrgent ? 0.3 : 0.2),
          width: isUrgent ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacingLarge),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(radiusMedium),
              ),
              child: Icon(
                activity['icon'] as IconData,
                color: color,
                size: 20,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity['title'] as String,
                          style: bodyBold.copyWith(
                            fontSize: 14,
                            color: widget.theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isUrgent)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(radiusSmall),
                          ),
                          child: Text(
                            'URGENT',
                            style: TextStyle(
                              color: error,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    activity['description'] as String,
                    style: body.copyWith(
                      fontSize: 13,
                      color: widget.theme.subtextColor,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: widget.theme.subtextColor.withOpacity(0.7),
                      ),
                      SizedBox(width: 4),
                      Text(
                        activity['time'] as String,
                        style: caption.copyWith(
                          fontSize: 11,
                          color: widget.theme.subtextColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}