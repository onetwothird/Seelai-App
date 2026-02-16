// File: lib/roles/caretaker/home/sections/home_screen/request_breakdown.dart
// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class RequestBreakdownSection extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final bool isLoading;
  final int pendingRequests;
  final int activeRequests;
  final int completedRequests;

  const RequestBreakdownSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.isLoading,
    required this.pendingRequests,
    required this.activeRequests,
    required this.completedRequests,
  });

  @override
  Widget build(BuildContext context) {
    final totalRequests = pendingRequests + activeRequests + completedRequests;

    // Define colors to match the previous semantic meanings
    final Color colPending = Colors.orange;
    final Color colActive = Colors.blue;
    final Color colCompleted = Colors.green;
    final Color colEmpty = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Breakdown',
          style: h3.copyWith(
            fontSize: 20,
            color: theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDarkMode ? [] : softShadow,
            border: isDarkMode
                ? Border.all(color: Colors.white.withOpacity(0.05))
                : null,
          ),
          child: Row(
            children: [
              // --- LEFT: DONUT CHART ---
              SizedBox(
                height: 140,
                width: 140,
                child: isLoading
                    ? CircularProgressIndicator(color: theme.subtextColor)
                    : CustomPaint(
                        painter: _DonutChartPainter(
                          pending: pendingRequests.toDouble(),
                          active: activeRequests.toDouble(),
                          completed: completedRequests.toDouble(),
                          pendingColor: colPending,
                          activeColor: colActive,
                          completedColor: colCompleted,
                          emptyColor: colEmpty,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                totalRequests.toString(),
                                style: h1.copyWith(
                                  fontSize: 28,
                                  color: theme.textColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Total',
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
              
              SizedBox(width: 24),

              // --- RIGHT: COMPACT LEGEND ---
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                      label: 'Pending',
                      count: pendingRequests,
                      total: totalRequests,
                      color: colPending,
                      icon: Icons.hourglass_empty_rounded,
                    ),
                    SizedBox(height: 16),
                    _buildLegendItem(
                      label: 'Active',
                      count: activeRequests,
                      total: totalRequests,
                      color: colActive,
                      icon: Icons.loop_rounded,
                    ),
                    SizedBox(height: 16),
                    _buildLegendItem(
                      label: 'Completed',
                      count: completedRequests,
                      total: totalRequests,
                      color: colCompleted,
                      icon: Icons.task_alt_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required String label,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final percentage = total > 0 
        ? ((count / total) * 100).toStringAsFixed(1) 
        : '0.0';

    return Row(
      children: [
        // Small Color/Icon Indicator
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        SizedBox(width: 12),
        // Text Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: caption.copyWith(
                  fontSize: 12,
                  color: theme.subtextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text(
                    count.toString(),
                    style: bodyBold.copyWith(
                      fontSize: 14,
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '($percentage%)',
                    style: caption.copyWith(
                      fontSize: 11,
                      color: theme.subtextColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- CUSTOM PAINTER FOR THE DONUT CHART ---
class _DonutChartPainter extends CustomPainter {
  final double pending;
  final double active;
  final double completed;
  final Color pendingColor;
  final Color activeColor;
  final Color completedColor;
  final Color emptyColor;

  _DonutChartPainter({
    required this.pending,
    required this.active,
    required this.completed,
    required this.pendingColor,
    required this.activeColor,
    required this.completedColor,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final strokeWidth = 12.0;
    
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double total = pending + active + completed;

    // Draw background circle (if empty or as base)
    if (total == 0) {
      paint.color = emptyColor;
      canvas.drawCircle(center, radius - strokeWidth / 2, paint);
      return;
    }

    double startAngle = -pi / 2; // Start from top

    // Function to draw arc
    void drawSegment(double value, Color color) {
      if (value <= 0) return;
      final sweepAngle = (value / total) * 2 * pi;
      // Add a tiny gap between segments if multiple exist
      final gap = total > value ? 0.08 : 0.0; 
      
      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + (gap / 2),
        sweepAngle - gap,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    drawSegment(pending, pendingColor);
    drawSegment(active, activeColor);
    drawSegment(completed, completedColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}