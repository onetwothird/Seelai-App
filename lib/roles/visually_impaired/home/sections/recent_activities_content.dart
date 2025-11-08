// File: lib/roles/visually_impaired/home/sections/recent_activities_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/models/activity_model.dart';

class RecentActivitiesContent extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;

  const RecentActivitiesContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  // Sample activities data
  List<ActivityModel> get _sampleActivities => [
    ActivityModel(
      title: 'Object Scanned',
      description: 'Water Bottle - 2 minutes ago',
      icon: Icons.qr_code_scanner_rounded,
      isEmergency: false,
    ),
    ActivityModel(
      title: 'Text Read',
      description: 'Product Label - 15 minutes ago',
      icon: Icons.text_fields_rounded,
      isEmergency: false,
    ),
    ActivityModel(
      title: 'Color Detected',
      description: 'Blue Fabric - 1 hour ago',
      icon: Icons.palette_rounded,
      isEmergency: false,
    ),
    ActivityModel(
      title: 'Emergency Called',
      description: 'Contact alerted - 2 hours ago',
      icon: Icons.emergency_rounded,
      isEmergency: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        bottom: 100,
      ),
      child: Semantics(
        label: 'Recent activities section',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activities',
              style: h2.copyWith(
                fontSize: 26,
                color: theme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              'Your latest interactions with SeelAI',
              style: body.copyWith(
                color: theme.subtextColor,
                fontSize: 14,
              ),
            ),
            SizedBox(height: spacingLarge),
            
            // Activities list
            ..._sampleActivities.map((activity) => Padding(
              padding: EdgeInsets.only(bottom: spacingMedium),
              child: _buildActivityCard(activity),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    return Semantics(
      label: '${activity.title}, ${activity.description}',
      child: Container(
        padding: EdgeInsets.all(spacingLarge),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: isDarkMode 
            ? [
                BoxShadow(
                  color: (activity.isEmergency ? error : primary).withOpacity(0.15),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
          border: isDarkMode 
            ? Border.all(
                color: activity.isEmergency 
                  ? error.withOpacity(0.4)
                  : primary.withOpacity(0.3),
                width: 1.5,
              )
            : Border.all(
                color: activity.isEmergency 
                  ? error.withOpacity(0.3)
                  : greyLighter,
                width: 1.5,
              ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(spacingMedium),
              decoration: BoxDecoration(
                gradient: activity.isEmergency 
                  ? LinearGradient(colors: [error, error.withOpacity(0.8)])
                  : primaryGradient,
                borderRadius: BorderRadius.circular(radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: (activity.isEmergency ? error : primary).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(activity.icon, color: white, size: 24),
            ),
            SizedBox(width: spacingLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: bodyBold.copyWith(
                      fontSize: 17,
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: spacingXSmall),
                  Text(
                    activity.description,
                    style: caption.copyWith(
                      fontSize: 14,
                      color: theme.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.subtextColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}