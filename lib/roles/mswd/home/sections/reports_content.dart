// File: lib/roles/mswd/home/sections/mswd_reports_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class MSWDReportsContent extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;

  const MSWDReportsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Reports',
            style: h2.copyWith(
              fontSize: 26,
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacingSmall),
          Text(
            'Generate and view system reports',
            style: body.copyWith(
              color: theme.subtextColor,
              fontSize: 14,
            ),
          ),
          
          SizedBox(height: spacingXLarge),
          
          // Generate Reports Section
          Text(
            'Generate New Report',
            style: bodyBold.copyWith(
              fontSize: 18,
              color: theme.textColor,
            ),
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildReportTypeCard(
            context,
            icon: Icons.calendar_month_rounded,
            title: 'Monthly Report',
            subtitle: 'Generate monthly patient statistics',
            color: primary,
            onTap: () {
              _showGenerateDialog(context, 'Monthly Report');
            },
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildReportTypeCard(
            context,
            icon: Icons.calendar_today_rounded,
            title: 'Annual Report',
            subtitle: 'Generate yearly overview and statistics',
            color: accent,
            onTap: () {
              _showGenerateDialog(context, 'Annual Report');
            },
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildReportTypeCard(
            context,
            icon: Icons.bar_chart_rounded,
            title: 'Custom Report',
            subtitle: 'Generate custom reports with filters',
            color: Colors.purple,
            onTap: () {
              _showGenerateDialog(context, 'Custom Report');
            },
          ),
          
          SizedBox(height: spacingXLarge),
          
          // Recent Reports Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Reports',
                style: bodyBold.copyWith(
                  fontSize: 18,
                  color: theme.textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('View all reports feature coming soon'),
                      backgroundColor: primary,
                    ),
                  );
                },
                child: Text('View All'),
              ),
            ],
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildRecentReportItem(
            icon: Icons.insert_drive_file_rounded,
            iconColor: primary,
            title: 'November 2024 Monthly Report',
            date: 'Generated on Nov 30, 2024',
            size: '2.4 MB',
            onDownload: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Download feature coming soon'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onView: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('View report feature coming soon'),
                  backgroundColor: primary,
                ),
              );
            },
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildRecentReportItem(
            icon: Icons.insert_drive_file_rounded,
            iconColor: accent,
            title: '2024 Annual Report',
            date: 'Generated on Dec 1, 2024',
            size: '5.8 MB',
            onDownload: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Download feature coming soon'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onView: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('View report feature coming soon'),
                  backgroundColor: primary,
                ),
              );
            },
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildRecentReportItem(
            icon: Icons.insert_drive_file_rounded,
            iconColor: Colors.purple,
            title: 'Q4 2024 Summary Report',
            date: 'Generated on Oct 15, 2024',
            size: '3.2 MB',
            onDownload: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Download feature coming soon'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onView: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('View report feature coming soon'),
                  backgroundColor: primary,
                ),
              );
            },
          ),
          
          SizedBox(height: spacingLarge),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ]
          : softShadow,
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusLarge),
          splashColor: color.withOpacity(0.2),
          child: Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(isDarkMode ? 0.25 : 0.1), 
                  color.withOpacity(isDarkMode ? 0.15 : 0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radiusLarge),
              border: isDarkMode 
                ? Border.all(color: color.withOpacity(0.4), width: 1.5)
                : Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingMedium * 1.2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: white,
                  ),
                ),
                SizedBox(width: spacingLarge),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: bodyBold.copyWith(
                          fontSize: 16,
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: spacingXSmall),
                      Text(
                        subtitle,
                        style: caption.copyWith(
                          fontSize: 13,
                          color: theme.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReportItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String date,
    required String size,
    required VoidCallback onDownload,
    required VoidCallback onView,
  }) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: isDarkMode 
          ? Border.all(color: theme.subtextColor.withOpacity(0.2), width: 1)
          : Border.all(color: greyLighter, width: 1),
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.1),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ]
          : softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacingMedium),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: bodyBold.copyWith(
                        fontSize: 15,
                        color: theme.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      date,
                      style: caption.copyWith(
                        fontSize: 12,
                        color: theme.subtextColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      size,
                      style: caption.copyWith(
                        fontSize: 11,
                        color: theme.subtextColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacingMedium),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: Icon(Icons.visibility_rounded, size: 18),
                  label: Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacingSmall),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: Icon(Icons.download_rounded, size: 18),
                  label: Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: white,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGenerateDialog(BuildContext context, String reportType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.assessment_rounded, color: primary),
            SizedBox(width: spacingSmall),
            Text('Generate $reportType'),
          ],
        ),
        content: Text('Are you sure you want to generate a $reportType? This may take a few moments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Generating $reportType...'),
                  backgroundColor: primary,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: white,
            ),
            child: Text('Generate'),
          ),
        ],
      ),
    );
  }
}