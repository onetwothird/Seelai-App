// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class OverviewSection extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final bool isLoading;
  final int totalPatients;
  final int pendingRequests;
  final int activeRequests;
  final int completedRequests;
  final VoidCallback onRefresh;

  const OverviewSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.isLoading,
    required this.totalPatients,
    required this.pendingRequests,
    required this.activeRequests,
    required this.completedRequests,
    required this.onRefresh,
  });

  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  int _currentStatIndex = 0;
  final PageController _statsController = PageController();

  @override
  void dispose() {
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'icon': Icons.people_rounded,
        'label': 'Total Patients',
        'value': widget.isLoading ? '...' : widget.totalPatients.toString(),
        'color': primary,
        'subtitle': '👥 - Under your care',
      },
      {
        'icon': Icons.pending_actions_rounded,
        'label': 'Pending Requests',
        'value': widget.isLoading ? '...' : widget.pendingRequests.toString(),
        'color': Colors.orange,
        'subtitle': '⏱ - Awaiting response',
      },
      {
        'icon': Icons.touch_app_rounded,
        'label': 'Active Requests',
        'value': widget.isLoading ? '...' : widget.activeRequests.toString(),
        'color': Colors.blue,
        'subtitle': '🔄 - In progress',
      },
      {
        'icon': Icons.check_circle_rounded,
        'label': 'Completed',
        'value': widget.isLoading ? '...' : widget.completedRequests.toString(),
        'color': Colors.green,
        'subtitle': '✅ - Total completed',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overview',
              style: h3.copyWith(
                fontSize: 20,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              )
            else
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onRefresh,
                  borderRadius: BorderRadius.circular(radiusMedium),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
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
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
            ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 16, offset: Offset(0, 6))]
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
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
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
}