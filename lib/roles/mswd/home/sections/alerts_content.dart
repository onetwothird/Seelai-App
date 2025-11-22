// File: lib/roles/mswd/home/sections/alerts_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class AlertsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final Function(int) onAlertsCountChanged;

  const AlertsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.onAlertsCountChanged,
  });

  @override
  State<AlertsContent> createState() => _AlertsContentState();
}

class _AlertsContentState extends State<AlertsContent> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    
    // Update badge count
    _updateAlertsCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateAlertsCount() {
    // Count emergency alerts (mock data)
    final emergencyCount = 3; // Replace with actual count from Firebase
    widget.onAlertsCountChanged(emergencyCount);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          
          SizedBox(height: spacingLarge),
          
          // Tab Bar
          _buildTabBar(),
          
          SizedBox(height: spacingLarge),
          
          // Tab Content
          Expanded(
            child: _buildCurrentTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(spacingMedium),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [error, error.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: [
              BoxShadow(
                color: error.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_active_rounded,
            color: white,
            size: 24,
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alerts & Notifications',
                style: h2.copyWith(
                  fontSize: 24,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Monitor system alerts',
                style: body.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
        border: widget.isDarkMode
            ? Border.all(color: primary.withOpacity(0.2), width: 1)
            : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.warning_rounded, 'Emergency', error),
          _buildTab(1, Icons.notifications_rounded, 'Notifications', primary),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label, Color color) {
    final isSelected = _tabController.index == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(vertical: spacingMedium),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? white : widget.theme.subtextColor,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? white : widget.theme.subtextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    if (_selectedTab == 0) {
      return _buildEmergencyAlerts();
    } else {
      return _buildNotifications();
    }
  }

  Widget _buildEmergencyAlerts() {
    // Mock data - replace with actual Firebase data
    final alerts = [
      {
        'title': 'SOS Activated',
        'user': 'Maria Santos',
        'location': 'Makati City',
        'time': '2 mins ago',
        'type': 'emergency',
      },
      {
        'title': 'Location Alert',
        'user': 'Juan Dela Cruz',
        'location': 'Outside safe zone',
        'time': '15 mins ago',
        'type': 'warning',
      },
      {
        'title': 'Emergency Call',
        'user': 'Pedro Garcia',
        'location': 'Quezon City',
        'time': '1 hour ago',
        'type': 'emergency',
      },
    ];

    if (alerts.isEmpty) {
      return _buildEmptyState('No emergency alerts', Icons.check_circle_rounded);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildAlertCard(alert),
        );
      },
    );
  }

  Widget _buildNotifications() {
    // Mock data
    final notifications = [
      {
        'title': 'New User Registration',
        'description': 'Rosa Martinez registered as Caretaker',
        'time': '30 mins ago',
        'icon': Icons.person_add_rounded,
        'color': Colors.green,
      },
      {
        'title': 'Verification Required',
        'description': '5 new documents pending verification',
        'time': '1 hour ago',
        'icon': Icons.verified_user_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'System Update',
        'description': 'New features available in v2.1.0',
        'time': '2 hours ago',
        'icon': Icons.system_update_rounded,
        'color': primary,
      },
    ];

    if (notifications.isEmpty) {
      return _buildEmptyState('No notifications', Icons.notifications_none_rounded);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildNotificationCard(notification),
        );
      },
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isEmergency = alert['type'] == 'emergency';
    final alertColor = isEmergency ? error : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: alertColor.withOpacity(0.2),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        border: Border.all(
          color: alertColor.withOpacity(widget.isDarkMode ? 0.4 : 0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('View alert details')),
            );
          },
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                // Alert Icon
                Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [alertColor, alertColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: alertColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isEmergency ? Icons.emergency_rounded : Icons.warning_rounded,
                    color: white,
                    size: 28,
                  ),
                ),
                
                SizedBox(width: spacingMedium),
                
                // Alert Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert['title'],
                        style: bodyBold.copyWith(
                          fontSize: 16,
                          color: widget.theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: widget.theme.subtextColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            alert['user'],
                            style: caption.copyWith(
                              fontSize: 13,
                              color: widget.theme.subtextColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: widget.theme.subtextColor,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              alert['location'],
                              style: caption.copyWith(
                                fontSize: 13,
                                color: widget.theme.subtextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        alert['time'],
                        style: caption.copyWith(
                          fontSize: 11,
                          color: widget.theme.subtextColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: alertColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final notificationColor = notification['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: notificationColor.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: notificationColor.withOpacity(0.2), width: 1)
            : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('View notification details')),
            );
          },
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    color: notificationColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  child: Icon(
                    notification['icon'] as IconData,
                    color: notificationColor,
                    size: 24,
                  ),
                ),
                
                SizedBox(width: spacingMedium),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'],
                        style: bodyBold.copyWith(
                          fontSize: 15,
                          color: widget.theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        notification['description'],
                        style: caption.copyWith(
                          fontSize: 13,
                          color: widget.theme.subtextColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        notification['time'],
                        style: caption.copyWith(
                          fontSize: 11,
                          color: widget.theme.subtextColor.withOpacity(0.7),
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
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(spacingXLarge),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? primary.withOpacity(0.1)
                  : primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: primary.withOpacity(0.5),
            ),
          ),
          SizedBox(height: spacingLarge),
          Text(
            message,
            style: body.copyWith(
              color: widget.theme.subtextColor,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}