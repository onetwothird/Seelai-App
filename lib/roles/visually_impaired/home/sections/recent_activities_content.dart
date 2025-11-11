// File: lib/roles/visually_impaired/home/sections/recent_activities_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/models/activity_model.dart';
import 'package:seelai_app/firebase/visually_impaired/user_activity_service.dart';

class RecentActivitiesContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final String userId;

  const RecentActivitiesContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userId,
  });

  @override
  State<RecentActivitiesContent> createState() => _RecentActivitiesContentState();
}

class _RecentActivitiesContentState extends State<RecentActivitiesContent> {
  final UserActivityService _activityService = userActivityService;
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _activityService.streamRecentActivities(widget.userId),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(width);
        }

        // Error state
        if (snapshot.hasError) {
          return _buildErrorState(width, snapshot.error.toString());
        }

        // Get activities
        final activities = snapshot.data ?? [];

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Activities',
                            style: h2.copyWith(
                              fontSize: 26,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: spacingSmall),
                          Text(
                            activities.isEmpty
                                ? 'No activities yet'
                                : 'Your latest interactions with SeelAI',
                            style: body.copyWith(
                              color: widget.theme.subtextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (activities.isNotEmpty)
                      IconButton(
                        onPressed: () => _showClearDialog(),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: widget.theme.subtextColor,
                        ),
                        tooltip: 'Clear all activities',
                      ),
                  ],
                ),
                SizedBox(height: spacingLarge),
                
                // Activities list
                if (activities.isEmpty)
                  _buildEmptyState()
                else
                  ...activities.map((activityData) {
                    final activity = _mapToActivityModel(activityData);
                    return Padding(
                      padding: EdgeInsets.only(bottom: spacingMedium),
                      child: _buildActivityCard(activity, activityData['activityId']),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: h2.copyWith(
              fontSize: 26,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacingLarge),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primary),
                SizedBox(height: spacingMedium),
                Text(
                  'Loading activities...',
                  style: body.copyWith(color: widget.theme.subtextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(double width, String errorMsg) {
    final errorColor = widget.isDarkMode ? Colors.red.shade400 : Colors.red.shade700;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: h2.copyWith(
              fontSize: 26,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacingLarge),
          Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(color: errorColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: errorColor),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: Text(
                    'Unable to load activities',
                    style: body.copyWith(color: widget.theme.textColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(spacingXLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: widget.isDarkMode 
            ? primary.withOpacity(0.2)
            : greyLighter,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: widget.theme.subtextColor.withOpacity(0.5),
          ),
          SizedBox(height: spacingMedium),
          Text(
            'No Activities Yet',
            style: bodyBold.copyWith(
              fontSize: 18,
              color: widget.theme.textColor,
            ),
          ),
          SizedBox(height: spacingSmall),
          Text(
            'Your activities will appear here as you use SeelAI features',
            textAlign: TextAlign.center,
            style: body.copyWith(
              color: widget.theme.subtextColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  ActivityModel _mapToActivityModel(Map<String, dynamic> data) {
    return ActivityModel(
      title: data['title'] as String,
      description: data['description'] as String,
      icon: IconData(
        data['iconCode'] as int,
        fontFamily: 'MaterialIcons',
      ),
      isEmergency: data['isEmergency'] as bool? ?? false,
      timestamp: DateTime.parse(data['timestamp'] as String),
    );
  }

  Widget _buildActivityCard(ActivityModel activity, String activityId) {
    final cardErrorColor = widget.isDarkMode ? Colors.red.shade400 : Colors.red.shade700;
    
    return Dismissible(
      key: Key(activityId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: spacingLarge),
        decoration: BoxDecoration(
          color: cardErrorColor,
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        child: Icon(Icons.delete_rounded, color: white, size: 28),
      ),
      confirmDismiss: (direction) => _confirmDelete(activity.title),
      onDismissed: (direction) {
        _activityService.deleteActivity(widget.userId, activityId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activity deleted'),
            backgroundColor: widget.theme.cardColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Semantics(
        label: '${activity.title}, ${activity.description}',
        child: Container(
          padding: EdgeInsets.all(spacingLarge),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusLarge),
            boxShadow: widget.isDarkMode 
              ? [
                  BoxShadow(
                    color: (activity.isEmergency ? cardErrorColor : primary).withOpacity(0.15),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : softShadow,
            border: widget.isDarkMode 
              ? Border.all(
                  color: activity.isEmergency 
                    ? cardErrorColor.withOpacity(0.4)
                    : primary.withOpacity(0.3),
                  width: 1.5,
                )
              : Border.all(
                  color: activity.isEmergency 
                    ? cardErrorColor.withOpacity(0.3)
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
                    ? LinearGradient(colors: [cardErrorColor, cardErrorColor.withOpacity(0.8)])
                    : primaryGradient,
                  borderRadius: BorderRadius.circular(radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: (activity.isEmergency ? cardErrorColor : primary).withOpacity(0.3),
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
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: spacingXSmall),
                    Text(
                      activity.description,
                      style: caption.copyWith(
                        fontSize: 14,
                        color: widget.theme.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: widget.theme.subtextColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(String title) {
    final deleteErrorColor = widget.isDarkMode ? Colors.red.shade400 : Colors.red.shade700;
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Activity'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: deleteErrorColor),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDialog() async {
    final clearErrorColor = widget.isDarkMode ? Colors.red.shade400 : Colors.red.shade700;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Activities'),
        content: Text('Are you sure you want to clear all recent activities? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: clearErrorColor),
            child: Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _activityService.clearAllActivities(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? 'All activities cleared' 
                : 'Failed to clear activities'
            ),
            backgroundColor: success ? Colors.green : clearErrorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}