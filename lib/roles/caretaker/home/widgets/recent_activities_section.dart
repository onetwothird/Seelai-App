// File: lib/roles/caretaker/home/widgets/recent_activities_section.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/models/activity_model.dart';

class RecentActivitiesSection extends StatelessWidget {
  final List<ActivityModel> activities;
  final bool isDarkMode;
  final dynamic theme;
  final Function(ActivityModel) onActivityTap;

  const RecentActivitiesSection({
    super.key,
    required this.activities,
    required this.isDarkMode,
    required this.theme,
    required this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: h2.copyWith(
            fontSize: 24,
            color: theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        Text(
          'Latest updates from your patients',
          style: body.copyWith(
            color: theme.subtextColor,
            fontSize: 14,
          ),
        ),
        SizedBox(height: spacingLarge),
        
        if (activities.isEmpty)
          _buildEmptyState()
        else
          ...activities.map((activity) => Padding(
            padding: EdgeInsets.only(bottom: spacingMedium),
            child: _buildActivityCard(activity),
          )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(spacingXLarge * 1.5),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.15),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ]
          : cardShadow,
        border: isDarkMode 
          ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
          : Border.all(color: greyLighter.withOpacity(0.5), width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: theme.subtextColor.withOpacity(0.5),
            ),
            SizedBox(height: spacingMedium),
            Text(
              'No recent activities',
              style: body.copyWith(
                color: theme.subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    Color accentColor = primary;
    if (activity.isEmergency) {
      accentColor = error;
    } else if (activity.isPending) {
      accentColor = accent;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ]
          : softShadow,
        border: isDarkMode 
          ? Border.all(
              color: accentColor.withOpacity(0.4),
              width: 1.5,
            )
          : Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1.5,
            ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onActivityTap(activity),
          borderRadius: BorderRadius.circular(radiusLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.patientName,
                              style: bodyBold.copyWith(
                                fontSize: 15,
                                color: theme.textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (activity.isPending)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(radiusSmall),
                              ),
                              child: Text(
                                'PENDING',
                                style: caption.copyWith(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: spacingXSmall),
                      Text(
                        activity.action,
                        style: bodyBold.copyWith(
                          fontSize: 16,
                          color: theme.textColor,
                          fontWeight: FontWeight.w600,
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
                      SizedBox(height: spacingXSmall),
                      Text(
                        activity.getTimeAgo(),
                        style: caption.copyWith(
                          fontSize: 12,
                          color: theme.subtextColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (activity.isPending) ...[
                  SizedBox(width: spacingSmall),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.subtextColor,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}