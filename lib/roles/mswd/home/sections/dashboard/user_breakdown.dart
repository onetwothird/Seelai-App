// File: lib/roles/mswd/home/sections/dashboard/user_breakdown.dart
// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:firebase_database/firebase_database.dart';

class UserBreakdownSection extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;

  const UserBreakdownSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<UserBreakdownSection> createState() => _UserBreakdownSectionState();
}

class _UserBreakdownSectionState extends State<UserBreakdownSection> {
  int _totalUsers = 0;
  int _visuallyImpairedUsers = 0;
  int _caretakerUsers = 0;
  int _mswdUsers = 0;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserBreakdown();
  }

  Future<void> _fetchUserBreakdown() async {
    setState(() => _isLoading = true);
    try {
      await _fetchAllUsers();
    } catch (e) {
      debugPrint('Error fetching user breakdown: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAllUsers() async {
    final viCount = await _countUsersInPath('user_info/visually_impaired');
    final ctCount = await _countUsersInPath('user_info/caretaker');
    final mswdCount = await _countUsersInPath('user_info/mswd');
    
    if (mounted) {
      setState(() {
        _visuallyImpairedUsers = viCount;
        _caretakerUsers = ctCount;
        _mswdUsers = mswdCount;
        _totalUsers = viCount + ctCount + mswdCount;
      });
    }
  }

  Future<int> _countUsersInPath(String path) async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref(path).once();
      if (!snapshot.snapshot.exists) return 0;
      final data = snapshot.snapshot.value;
      if (data is Map) return data.length;
      if (data is List) return data.length;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors for the chart segments
    final Color colVisual = Colors.purple;
    final Color colCaretaker = Colors.green;
    final Color colMSWD = Colors.teal;
    final Color colEmpty = widget.isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Breakdown',
          style: h3.copyWith(
            fontSize: 20,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),

        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: widget.isDarkMode ? [] : softShadow,
            border: widget.isDarkMode
                ? Border.all(color: Colors.white.withOpacity(0.05))
                : null,
          ),
          child: Row(
            children: [
              // --- LEFT: DONUT CHART ---
              SizedBox(
                height: 140,
                width: 140,
                child: _isLoading
                    ? CircularProgressIndicator(color: widget.theme.subtextColor)
                    : CustomPaint(
                        painter: _UserDonutChartPainter(
                          segments: [
                            ChartSegment(_visuallyImpairedUsers.toDouble(), colVisual),
                            ChartSegment(_caretakerUsers.toDouble(), colCaretaker),
                            ChartSegment(_mswdUsers.toDouble(), colMSWD),
                          ],
                          emptyColor: colEmpty,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _totalUsers.toString(),
                                style: h1.copyWith(
                                  fontSize: 28,
                                  color: widget.theme.textColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Total',
                                style: caption.copyWith(
                                  fontSize: 12,
                                  color: widget.theme.subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              
              SizedBox(width: 24),

              // --- RIGHT: LEGEND ---
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                      label: 'Visually Impaired',
                      count: _visuallyImpairedUsers,
                      color: colVisual,
                      icon: Icons.visibility_off_rounded,
                    ),
                    SizedBox(height: 16),
                    _buildLegendItem(
                      label: 'Caretakers',
                      count: _caretakerUsers,
                      color: colCaretaker,
                      icon: Icons.volunteer_activism_rounded,
                    ),
                    SizedBox(height: 16),
                    _buildLegendItem(
                      label: 'MSWD Staff',
                      count: _mswdUsers,
                      color: colMSWD,
                      icon: Icons.admin_panel_settings_rounded,
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
    required Color color,
    required IconData icon,
  }) {
    final percentage = _totalUsers > 0 
        ? ((count / _totalUsers) * 100).toStringAsFixed(1) 
        : '0.0';

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: caption.copyWith(
                  fontSize: 12,
                  color: widget.theme.subtextColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Text(
                    count.toString(),
                    style: bodyBold.copyWith(
                      fontSize: 14,
                      color: widget.theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '($percentage%)',
                    style: caption.copyWith(
                      fontSize: 11,
                      color: widget.theme.subtextColor.withOpacity(0.5),
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

// --- CUSTOM PAINTER CLASSES ---
class ChartSegment {
  final double value;
  final Color color;
  ChartSegment(this.value, this.color);
}

class _UserDonutChartPainter extends CustomPainter {
  final List<ChartSegment> segments;
  final Color emptyColor;

  _UserDonutChartPainter({required this.segments, required this.emptyColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final strokeWidth = 12.0;
    
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double total = segments.fold(0, (sum, item) => sum + item.value);

    // Draw background circle if empty
    if (total == 0) {
      paint.color = emptyColor;
      canvas.drawCircle(center, radius - strokeWidth / 2, paint);
      return;
    }

    double startAngle = -pi / 2;

    for (var segment in segments) {
      if (segment.value <= 0) continue;
      final sweepAngle = (segment.value / total) * 2 * pi;
      // Add gap only if there is more than 1 segment type present
      final gap = total > segment.value ? 0.08 : 0.0; 
      
      paint.color = segment.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + (gap / 2),
        sweepAngle - gap,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}