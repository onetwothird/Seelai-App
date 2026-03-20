// File: lib/roles/mswd/home/sections/dashboard/dashboard_stats.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:seelai_app/themes/constants.dart';

class DashboardStats extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Future<Map<String, int>> statsFuture;

  const DashboardStats({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.statsFuture,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: statsFuture, 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // FIX: Giving the loader a fixed height prevents the UI from jumping
          return Container(
            height: 350, 
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: Color(0xFF8B5CF6),
              strokeWidth: 3.5,
            ),
          );
        }

        final stats = snapshot.data ?? {
          'total': 0,
          'partially_sighted': 0,
          'caretaker': 0,
          'admin': 0,
          'active': 0,
          'inactive': 0,
        };

        final int viCount = stats['partially_sighted'] ?? 0;
        final int caretakerCount = stats['caretaker'] ?? 0;
        final int totalUsers = stats['total'] ?? 0;
        final int activeUsers = stats['active'] ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: h3.copyWith(
                fontSize: 20, 
                color: theme.textColor,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12), 

            // KPI Cards Grid - Top Row
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Total Users',
                    value: totalUsers.toString(),
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 10), 
                Expanded(
                  child: _buildKpiCard(
                    title: 'Active Now',
                    value: activeUsers.toString(),
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), 
            
            // KPI Cards Grid - Bottom Row
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Partially Sighted',
                    value: viCount.toString(),
                    icon: Icons.visibility_off_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Caretakers',
                    value: caretakerCount.toString(),
                    icon: Icons.volunteer_activism_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16), 

            // Main Line Chart 
            _buildChartContainer(
              title: 'Activity Trend',
              subtitle: '7-day user engagement',
              height: 140, 
              child: _buildLineChart(),
            ),

            const SizedBox(height: 16), 

            // Bar Chart 
            _buildChartContainer(
              title: 'Role Distribution',
              subtitle: 'Active vs total accounts',
              height: 130, 
              child: _buildBarChart(viCount, caretakerCount, stats['admin'] ?? 0),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // WIDGET: Compact KPI Card
  // ==========================================
  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), 
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14), 
        boxShadow: isDarkMode ? [] : softShadow,
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8), 
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20), 
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: h2.copyWith(
              fontSize: 24, 
              color: theme.textColor,
              fontWeight: FontWeight.w800,
              height: 1.0, 
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: caption.copyWith(
              fontSize: 11, 
              color: theme.subtextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET: Compact Chart Container
  // ==========================================
  Widget _buildChartContainer({
    required String title,
    required String subtitle,
    required double height,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? [] : softShadow,
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: bodyBold.copyWith(color: theme.textColor, fontSize: 14), 
              ),
              Text(
                subtitle,
                style: caption.copyWith(color: theme.subtextColor, fontSize: 10), 
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: theme.subtextColor.withValues(alpha: 0.1), strokeWidth: 1, dashArray: [5, 5]);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; 
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(days[value.toInt()], style: caption.copyWith(color: theme.subtextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 50,
              reservedSize: 28, 
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: caption.copyWith(color: theme.subtextColor, fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0, maxX: 6, minY: 0, maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: const [FlSpot(0, 30), FlSpot(1, 45), FlSpot(2, 35), FlSpot(3, 80), FlSpot(4, 65), FlSpot(5, 90), FlSpot(6, 75)],
            isCurved: true,
            color: const Color(0xFF3B82F6),
            barWidth: 2.5, 
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [const Color(0xFF3B82F6).withValues(alpha: 0.3), const Color(0xFF3B82F6).withValues(alpha: 0.0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(int vi, int ct, int admin) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (vi > ct ? vi : ct).toDouble() + 5,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32, 
              getTitlesWidget: (double value, TitleMeta meta) {
                final titles = ['Partially\nSighted', 'Caretaker', 'MSWD']; 
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    titles[value.toInt()], 
                    textAlign: TextAlign.center,
                    style: caption.copyWith(
                      color: theme.subtextColor, 
                      fontSize: 9, 
                      fontWeight: FontWeight.bold,
                      height: 1.1, 
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: vi.toDouble(), color: const Color(0xFF8B5CF6), width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: ct.toDouble(), color: const Color(0xFF10B981), width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: admin.toDouble(), color: const Color(0xFFF59E0B), width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
        ],
      ),
    );
  }
}