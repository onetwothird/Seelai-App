// File: lib/roles/mswd/home/sections/analytics_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/admin_service.dart';

class AnalyticsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;

  const AnalyticsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
  });

  @override
  State<AnalyticsContent> createState() => _AnalyticsContentState();
}

class _AnalyticsContentState extends State<AnalyticsContent> {
  bool _isLoading = true;
  Map<String, int> _stats = {};
  String _selectedPeriod = 'week'; // week, month, year

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
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
          // Header
          _buildHeader(),
          
          SizedBox(height: spacingLarge),
          
          // Period Selector
          _buildPeriodSelector(),
          
          SizedBox(height: spacingXLarge),
          
          // Key Metrics
          _isLoading ? _buildLoadingState() : _buildKeyMetrics(),
          
          SizedBox(height: spacingXLarge),
          
          // User Growth Chart
          _buildUserGrowthChart(),
          
          SizedBox(height: spacingXLarge),
          
          // Activity Distribution
          _buildActivityDistribution(),
          
          SizedBox(height: spacingXLarge),
          
          // Requests Overview
          _buildRequestsOverview(),
          
          SizedBox(height: spacingXLarge),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: h2.copyWith(
                fontSize: 26,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Insights and statistics',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        // Export Button
        Container(
          decoration: BoxDecoration(
            gradient: primaryGradient,
            borderRadius: BorderRadius.circular(radiusLarge),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Export feature coming soon'),
                    backgroundColor: primary,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(radiusLarge),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacingMedium,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.file_download_rounded, color: white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Export',
                      style: bodyBold.copyWith(
                        color: white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
        border: widget.isDarkMode
            ? Border.all(color: primary.withOpacity(0.2), width: 1)
            : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Row(
        children: [
          _buildPeriodTab('week', 'Week'),
          _buildPeriodTab('month', 'Month'),
          _buildPeriodTab('year', 'Year'),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String value, String label) {
    final isSelected = _selectedPeriod == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(vertical: spacingMedium),
          decoration: BoxDecoration(
            gradient: isSelected ? primaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? white : widget.theme.subtextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primary),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: h3.copyWith(
            fontSize: 20,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: spacingMedium,
          crossAxisSpacing: spacingMedium,
          childAspectRatio: 1.3,
          children: [
            _buildMetricCard(
              icon: Icons.trending_up_rounded,
              label: 'Growth Rate',
              value: '+12%',
              subtitle: 'vs last month',
              color: Colors.green,
            ),
            _buildMetricCard(
              icon: Icons.people_rounded,
              label: 'Active Users',
              value: '${_stats['active'] ?? 0}',
              subtitle: 'Currently active',
              color: primary,
            ),
            _buildMetricCard(
              icon: Icons.check_circle_rounded,
              label: 'Completion',
              value: '87%',
              subtitle: 'Request rate',
              color: Colors.blue,
            ),
            _buildMetricCard(
              icon: Icons.access_time_rounded,
              label: 'Avg Response',
              value: '5.2 min',
              subtitle: 'Response time',
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
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
        borderRadius: BorderRadius.circular(radiusXLarge),
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
          color: widget.isDarkMode
              ? color.withOpacity(0.2)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
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
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: h2.copyWith(
                  fontSize: 24,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: bodyBold.copyWith(
                  fontSize: 12,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: caption.copyWith(
                  fontSize: 10,
                  color: widget.theme.subtextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
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
            ? Border.all(color: primary.withOpacity(0.2), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Growth',
                style: h3.copyWith(
                  fontSize: 18,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.show_chart_rounded,
                color: primary,
                size: 24,
              ),
            ],
          ),
          SizedBox(height: spacingLarge),
          
          // Chart Placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primary.withOpacity(0.1),
                  primary.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    size: 48,
                    color: primary.withOpacity(0.3),
                  ),
                  SizedBox(height: spacingMedium),
                  Text(
                    'Chart Visualization',
                    style: bodyBold.copyWith(
                      fontSize: 14,
                      color: widget.theme.textColor,
                    ),
                  ),
                  Text(
                    'Growth trends coming soon',
                    style: caption.copyWith(
                      fontSize: 12,
                      color: widget.theme.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Distribution',
          style: h3.copyWith(
            fontSize: 20,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        
        Container(
          padding: EdgeInsets.all(spacingLarge),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusXLarge),
            boxShadow: widget.isDarkMode
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.1),
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
                ? Border.all(color: primary.withOpacity(0.2), width: 1)
                : null,
          ),
          child: Column(
            children: [
              _buildDistributionBar(
                'VI Users',
                _stats['visually_impaired'] ?? 0,
                _stats['total'] ?? 1,
                accent,
              ),
              SizedBox(height: spacingMedium),
              _buildDistributionBar(
                'Caretakers',
                _stats['caretaker'] ?? 0,
                _stats['total'] ?? 1,
                Colors.green,
              ),
              SizedBox(height: spacingMedium),
              _buildDistributionBar(
                'Admins',
                _stats['admin'] ?? 0,
                _stats['total'] ?? 1,
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionBar(
    String label,
    int value,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: bodyBold.copyWith(
                fontSize: 14,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$value ($percentage%)',
              style: bodyBold.copyWith(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: spacingSmall),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: total > 0 ? value / total : 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsOverview() {
    final requests = [
      {
        'type': 'Navigation',
        'count': 45,
        'color': primary,
        'icon': Icons.navigation_rounded,
      },
      {
        'type': 'Reading',
        'count': 32,
        'color': Colors.blue,
        'icon': Icons.book_rounded,
      },
      {
        'type': 'Emergency',
        'count': 8,
        'color': error,
        'icon': Icons.warning_rounded,
      },
      {
        'type': 'General',
        'count': 21,
        'color': Colors.green,
        'icon': Icons.help_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Types',
          style: h3.copyWith(
            fontSize: 20,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: spacingMedium,
          crossAxisSpacing: spacingMedium,
          childAspectRatio: 1.5,
          children: requests.map((request) {
            return Container(
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                color: widget.theme.cardColor,
                borderRadius: BorderRadius.circular(radiusLarge),
                boxShadow: widget.isDarkMode
                    ? [
                        BoxShadow(
                          color: (request['color'] as Color).withOpacity(0.1),
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
                  color: widget.isDarkMode
                      ? (request['color'] as Color).withOpacity(0.2)
                      : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (request['color'] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    child: Icon(
                      request['icon'] as IconData,
                      color: request['color'] as Color,
                      size: 20,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request['count']}',
                        style: h1.copyWith(
                          fontSize: 28,
                          color: widget.theme.textColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        request['type'] as String,
                        style: caption.copyWith(
                          fontSize: 12,
                          color: widget.theme.subtextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}