// File: lib/roles/mswd/home/sections/dashboard/dashboard_stats.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardStats extends StatefulWidget {
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
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats> {
  // 0 = Activity Trend, 1 = Role Distribution
  int _selectedChartIndex = 0; 

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: widget.statsFuture, 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
           
            const SizedBox(height: 8), 

            // KPI Cards Grid - Top Row
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Total Users',
                    subtitle: 'All registered',
                    bottomLabel: 'TOTAL',
                    value: totalUsers.toString(),
                    backgroundIcon: Icons.people_outline_rounded,
                    color: const Color(0xFF60A5FA), // Soft Sky Blue
                  ),
                ),
                const SizedBox(width: 12), 
                Expanded(
                  child: _buildKpiCard(
                    title: 'Active Now',
                    subtitle: 'Currently online',
                    bottomLabel: 'ONLINE',
                    value: activeUsers.toString(),
                    backgroundIcon: Icons.local_fire_department_outlined,
                    color: const Color(0xFF34D399), // Soft Mint Green
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), 
            
            // KPI Cards Grid - Bottom Row
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Visually Impaired',
                    subtitle: 'Registered clients',
                    bottomLabel: 'USERS',
                    value: viCount.toString(),
                    backgroundIcon: Icons.visibility_off_outlined,
                    color: const Color(0xFF8B5CF6), // Primary Purple
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Caretakers',
                    subtitle: 'Assigned helpers',
                    bottomLabel: 'USERS',
                    value: caretakerCount.toString(),
                    backgroundIcon: Icons.volunteer_activism_outlined,
                    color: const Color(0xFFF5A623), // Soft Peach/Orange
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16), 

            // Tabbed Charts Section (Saves a ton of space!)
            _buildTabbedChartContainer(viCount, caretakerCount, stats['admin'] ?? 0),
          ],
        );
      },
    );
  }

  // ==========================================
  // WIDGET: Compact KPI Card (Updated Design)
  // ==========================================
  Widget _buildKpiCard({
    required String title,
    required String subtitle,
    required String bottomLabel,
    required String value,
    required IconData backgroundIcon,
    required Color color,
  }) {
    return Container(
      height: 140, // Fixed height to ensure consistency across the grid
      clipBehavior: Clip.hardEdge, 
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05), // Extremely subtle background tint
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.15), // Very light border to define the card
        ),
      ),
      child: Stack(
        children: [
          // Large watermark icon, pushed slightly off-screen
          Positioned(
            right: -15,
            bottom: -10,
            child: Icon(
              backgroundIcon,
              size: 110,
              color: color.withValues(alpha: 0.12),
            ),
          ),
          
          // Foreground Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top section: Title, Subtitle, and Ellipsis
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
                              fontSize: 15,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // Prevents text overflow if device is narrow
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.theme.subtextColor,
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
                      color: widget.theme.subtextColor,
                      size: 20,
                    ),
                  ],
                ),

                // Bottom section: Label and Main Value (Centered relative to each other)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // <-- Changed to center here
                  children: [
                    Text(
                      bottomLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.theme.subtextColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2, 
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 26,
                        color: widget.theme.textColor,
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

  // ==========================================
  // WIDGET: Tabbed Chart Container
  // ==========================================
  Widget _buildTabbedChartContainer(int viCount, int caretakerCount, int adminCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(20), // Matched to 20 for consistency
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Control (Tabs)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.theme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTabButton(0, 'Activity Trend')),
                Expanded(child: _buildTabButton(1, 'Roles')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Dynamic Chart Display
          SizedBox(
            height: 140, // Fixed height so the container doesn't jump
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedChartIndex == 0
                  ? _buildLineChart(key: const ValueKey('line'))
                  : _buildBarChart(viCount, caretakerCount, adminCount, key: const ValueKey('bar')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedChartIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.theme.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected && !widget.isDarkMode
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? widget.theme.textColor : widget.theme.subtextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart({Key? key}) {
    return LineChart(
      key: key,
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
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; 
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(days[value.toInt()], style: TextStyle(color: widget.theme.subtextColor, fontSize: 10, fontWeight: FontWeight.bold)),
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
                return Text(value.toInt().toString(), style: TextStyle(color: widget.theme.subtextColor, fontSize: 10));
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
            color: const Color(0xFF60A5FA), // Matched to pastel blue
            barWidth: 2.5, 
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [const Color(0xFF60A5FA).withValues(alpha: 0.3), const Color(0xFF60A5FA).withValues(alpha: 0.0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(int vi, int ct, int admin, {Key? key}) {
    return BarChart(
      key: key,
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
                    style: TextStyle(
                      color: widget.theme.subtextColor, 
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
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: ct.toDouble(), color: const Color(0xFFF5A623), width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: admin.toDouble(), color: const Color(0xFF60A5FA), width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
        ],
      ),
    );
  }
}