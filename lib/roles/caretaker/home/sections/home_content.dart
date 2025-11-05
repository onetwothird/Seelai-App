import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/services/request_service.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/roles/caretaker/screens/patient_location_screen.dart';

class HomeContent extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final Function(String) onNotificationUpdate;
  final RequestService requestService;
  final LocationService locationService;

  const HomeContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.onNotificationUpdate,
    required this.requestService,
    required this.locationService,
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
          SizedBox(height: spacingLarge),
          
          // Quick Stats Cards
          _buildQuickStats(context),
          
          SizedBox(height: spacingXLarge),
          
          // Quick Actions Section
          Text(
            'Quick Actions',
            style: bodyBold.copyWith(
              fontSize: 18,
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacingMedium),
          
          _buildQuickActionsGrid(context),
          
          SizedBox(height: spacingXLarge),
          
          // Recent Activity
          Text(
            'Recent Activity',
            style: bodyBold.copyWith(
              fontSize: 18,
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacingMedium),
          
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.people_rounded,
            label: 'Patients',
            value: '5',
            color: primary,
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.pending_actions_rounded,
            label: 'Requests',
            value: '3',
            color: accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(isDarkMode ? 0.25 : 0.1),
            color.withOpacity(isDarkMode ? 0.15 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: isDarkMode
            ? Border.all(color: color.withOpacity(0.4), width: 1.5)
            : Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: isDarkMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: spacingMedium),
          Text(
            value,
            style: h1.copyWith(
              fontSize: 32,
              color: theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: spacingXSmall),
          Text(
            label,
            style: caption.copyWith(
              fontSize: 14,
              color: theme.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacingMedium,
      crossAxisSpacing: spacingMedium,
      childAspectRatio: 1.3,
      children: [
        _buildActionCard(
          context,
          icon: Icons.location_on_rounded,
          label: 'Track Location',
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientLocationScreen(
                  isDarkMode: isDarkMode,
                  locationService: locationService,
                ),
              ),
            );
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.chat_rounded,
          label: 'Send Message',
          color: Colors.blue,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Message feature coming soon')),
            );
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.phone_rounded,
          label: 'Quick Call',
          color: Colors.orange,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Call feature coming soon')),
            );
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.emergency_rounded,
          label: 'Emergency',
          color: error,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Emergency protocol activated'),
                backgroundColor: error,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
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
          child: Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radiusLarge),
              border: isDarkMode
                  ? Border.all(color: color.withOpacity(0.4), width: 1.5)
                  : Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(spacingMedium),
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
                  child: Icon(icon, color: white, size: 28),
                ),
                SizedBox(height: spacingMedium),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: bodyBold.copyWith(
                    fontSize: 15,
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final activities = [
      {
        'title': 'Request Completed',
        'description': 'Navigation help for Maria Santos',
        'time': '10 minutes ago',
        'icon': Icons.check_circle_rounded,
        'color': Colors.green,
      },
      {
        'title': 'New Request',
        'description': 'Reading assistance needed',
        'time': '1 hour ago',
        'icon': Icons.notifications_active_rounded,
        'color': accent,
      },
      {
        'title': 'Patient Check-in',
        'description': 'Juan Dela Cruz location updated',
        'time': '2 hours ago',
        'icon': Icons.location_on_rounded,
        'color': primary,
      },
    ];

    return Column(
      children: activities.map((activity) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildActivityCard(context, activity),
        );
      }).toList(),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    Map<String, dynamic> activity,
  ) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: isDarkMode
            ? [
                BoxShadow(
                  color: (activity['color'] as Color).withOpacity(0.15),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        border: isDarkMode
            ? Border.all(
                color: (activity['color'] as Color).withOpacity(0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 24,
            ),
          ),
          SizedBox(width: spacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: bodyBold.copyWith(
                    fontSize: 16,
                    color: theme.textColor,
                  ),
                ),
                SizedBox(height: spacingXSmall),
                Text(
                  activity['description'] as String,
                  style: caption.copyWith(
                    fontSize: 14,
                    color: theme.subtextColor,
                  ),
                ),
                SizedBox(height: spacingXSmall),
                Text(
                  activity['time'] as String,
                  style: caption.copyWith(
                    fontSize: 12,
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