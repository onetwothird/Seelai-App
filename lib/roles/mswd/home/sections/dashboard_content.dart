// File: lib/roles/mswd/home/sections/mswd_dashboard_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class MSWDDashboardContent extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final Function(String) onNotificationUpdate;

  const MSWDDashboardContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.onNotificationUpdate,
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
          SizedBox(height: spacingMedium),
          
          // Statistics Cards Row
          Text(
            'Overview',
            style: h2.copyWith(
              fontSize: 22,
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          SizedBox(height: spacingMedium),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people_rounded,
                  title: 'Total Patients',
                  value: '248',
                  color: primary,
                  trend: '+12',
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.person_add_rounded,
                  title: 'New This Month',
                  value: '24',
                  color: accent,
                  trend: '+5',
                ),
              ),
            ],
          ),
          
          SizedBox(height: spacingMedium),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.verified_rounded,
                  title: 'Verified',
                  value: '186',
                  color: Colors.green,
                  trend: '+8',
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pending_rounded,
                  title: 'Pending',
                  value: '62',
                  color: Colors.orange,
                  trend: '+4',
                ),
              ),
            ],
          ),
          
          SizedBox(height: spacingXLarge),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: h2.copyWith(
              fontSize: 22,
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildActionButton(
            context,
            icon: Icons.person_add_rounded,
            title: 'Register New Patient',
            subtitle: 'Add a new patient to the system',
            color: primary,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Register patient feature coming soon'),
                  backgroundColor: primary,
                ),
              );
            },
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildActionButton(
            context,
            icon: Icons.assessment_rounded,
            title: 'Generate Report',
            subtitle: 'Create monthly or annual reports',
            color: accent,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Generate report feature coming soon'),
                  backgroundColor: accent,
                ),
              );
            },
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildActionButton(
            context,
            icon: Icons.verified_user_rounded,
            title: 'Verify Patients',
            subtitle: 'Review and verify pending registrations',
            color: Colors.green,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verify patients feature coming soon'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          
          SizedBox(height: spacingXLarge),
          
          // Recent Activity
          Text(
            'Recent Activity',
            style: h2.copyWith(
              fontSize: 22,
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildActivityItem(
            icon: Icons.person_add_rounded,
            iconColor: primary,
            title: 'New patient registered',
            subtitle: 'Juan Dela Cruz • Visual Impairment',
            time: '5 minutes ago',
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildActivityItem(
            icon: Icons.verified_rounded,
            iconColor: Colors.green,
            title: 'Patient verified',
            subtitle: 'Maria Santos • Hearing Impairment',
            time: '1 hour ago',
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildActivityItem(
            icon: Icons.update_rounded,
            iconColor: accent,
            title: 'Profile updated',
            subtitle: 'Pedro Garcia updated contact information',
            time: '3 hours ago',
          ),
          
          SizedBox(height: spacingLarge),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
        gradient: LinearGradient(
          colors: [
            color.withOpacity(isDarkMode ? 0.2 : 0.08),
            color.withOpacity(isDarkMode ? 0.1 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: color.withOpacity(isDarkMode ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ]
          : softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(spacingSmall),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: spacingMedium),
          Text(
            value,
            style: h1.copyWith(
              fontSize: 28,
              color: theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: spacingXSmall),
          Text(
            title,
            style: caption.copyWith(
              fontSize: 12,
              color: theme.subtextColor,
            ),
          ),
          SizedBox(height: spacingSmall),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: Colors.green,
                size: 14,
              ),
              SizedBox(width: 4),
              Text(
                trend,
                style: caption.copyWith(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
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

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Icon(icon, color: iconColor, size: 24),
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
                  subtitle,
                  style: caption.copyWith(
                    fontSize: 13,
                    color: theme.subtextColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  time,
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
    );
  }
}