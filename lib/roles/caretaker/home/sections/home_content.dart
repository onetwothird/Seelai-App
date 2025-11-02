// File: lib/roles/caretaker/home/sections/home_content.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/patients_list_section.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/quick_stats_section.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/recent_activities_section.dart';
import 'package:seelai_app/roles/caretaker/models/activity_model.dart';

class HomeContent extends StatelessWidget {
  final Map<String, dynamic> userData;
  final List<Map<String, dynamic>> assignedPatients;
  final bool isLoadingPatients;
  final bool isDarkMode;
  final dynamic theme;
  final Function(String) onNotificationUpdate;
  final VoidCallback onRefresh;

  const HomeContent({
    super.key,
    required this.userData,
    required this.assignedPatients,
    required this.isLoadingPatients,
    required this.isDarkMode,
    required this.theme,
    required this.onNotificationUpdate,
    required this.onRefresh,
  });

  // Sample recent activities
  List<ActivityModel> get _recentActivities => [
    ActivityModel(
      patientName: 'John Doe',
      action: 'Permission Request',
      description: 'Requested to go to the store',
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      icon: Icons.help_outline_rounded,
      isPending: true,
    ),
    ActivityModel(
      patientName: 'Jane Smith',
      action: 'Emergency Alert',
      description: 'Fall detected - Emergency services notified',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      icon: Icons.emergency_rounded,
      isEmergency: true,
    ),
    ActivityModel(
      patientName: 'John Doe',
      action: 'Location Update',
      description: 'Arrived at destination safely',
      timestamp: DateTime.now().subtract(Duration(hours: 4)),
      icon: Icons.location_on_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        await Future.delayed(Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: width * 0.06,
          right: width * 0.06,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            QuickStatsSection(
              totalPatients: assignedPatients.length,
              activeAlerts: _recentActivities.where((a) => a.isEmergency).length,
              pendingRequests: _recentActivities.where((a) => a.isPending).length,
              isDarkMode: isDarkMode,
              theme: theme,
            ),
            
            SizedBox(height: spacingXLarge),
            
            // Assigned Patients
            PatientsListSection(
              patients: assignedPatients,
              isLoading: isLoadingPatients,
              isDarkMode: isDarkMode,
              theme: theme,
              onPatientTap: (patient) {
                onNotificationUpdate('Viewing ${patient['name']}\'s details');
              },
            ),
            
            SizedBox(height: spacingXLarge),
            
            // Recent Activities
            RecentActivitiesSection(
              activities: _recentActivities,
              isDarkMode: isDarkMode,
              theme: theme,
              onActivityTap: (activity) {
                if (activity.isPending) {
                  _showPermissionDialog(context, activity);
                }
              },
            ),
            
            SizedBox(height: spacingXLarge),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog(BuildContext context, ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${activity.patientName}'),
            SizedBox(height: 8),
            Text(activity.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onNotificationUpdate('Permission denied for ${activity.patientName}');
            },
            child: Text('Deny', style: TextStyle(color: error)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onNotificationUpdate('Permission granted for ${activity.patientName}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: success,
            ),
            child: Text('Approve'),
          ),
        ],
      ),
    );
  }
}