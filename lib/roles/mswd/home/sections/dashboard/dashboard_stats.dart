// File: lib/roles/mswd/home/sections/dashboard/dashboard_stats.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/admin_service.dart';

class DashboardStats extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;

  const DashboardStats({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats> {
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = adminService.getUserStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _statsFuture, 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
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
                fontSize: 20, // Slightly smaller header
                color: widget.theme.textColor,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12), // Reduced gap

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
                const SizedBox(width: 10), // Tighter gap between cards
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
            const SizedBox(height: 10), // Tighter gap between rows
            
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

            const SizedBox(height: 16), // Reduced gap

            // Main Line Chart - Dramatically reduced height
            _buildChartContainer(
              title: 'Activity Trend',
              subtitle: '7-day user engagement',
              height: 140, // Reduced from 280
              child: _buildLineChart(),
            ),

            const SizedBox(height: 16), // Reduced gap

            // Bar Chart - Dramatically reduced height
            _buildChartContainer(
              title: 'Role Distribution',
              subtitle: 'Active vs total accounts',
              height: 130, // Reduced from 220
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), // Tighter padding
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(14), // Slightly smaller radius
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: Border.all(
          color: widget.isDarkMode
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
            padding: const EdgeInsets.all(8), // Smaller icon background
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20), // Smaller icon
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: h2.copyWith(
              fontSize: 24, // Smaller font (was 32)
              color: widget.theme.textColor,
              fontWeight: FontWeight.w800,
              height: 1.0, 
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: caption.copyWith(
              fontSize: 11, // Smaller font (was 13)
              color: widget.theme.subtextColor,
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
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: Border.all(
          color: widget.isDarkMode
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
                style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 14), // Smaller title
              ),
              Text(
                subtitle,
                style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 10), // Smaller subtitle moved to row
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }

  // Charts remain exactly the same structurally, but will inherit the smaller container constraints
  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: widget.theme.subtextColor.withValues(alpha: 0.1), strokeWidth: 1, dashArray: [5, 5]);
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
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; // Abbreviated to save space
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(days[value.toInt()], style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 10, fontWeight: FontWeight.bold)),
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
              reservedSize: 28, // Smaller reserve space
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 10));
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
            barWidth: 2.5, // Thinner line
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
              reservedSize: 32, // Increased to fit the two-line text
              getTitlesWidget: (double value, TitleMeta meta) {
                // Using \n to stack "Partially Sighted" so it doesn't overlap
                final titles = ['Partially\nSighted', 'Caretaker', 'MSWD']; 
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    titles[value.toInt()], 
                    textAlign: TextAlign.center,
                    style: caption.copyWith(
                      color: widget.theme.subtextColor, 
                      fontSize: 9, // Slightly smaller to ensure it fits
                      fontWeight: FontWeight.bold,
                      height: 1.1, // Tighter line height
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