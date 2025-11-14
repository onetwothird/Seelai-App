// File: lib/roles/visually_impaired/home/sections/home_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/services/camera_service.dart';
import 'package:seelai_app/roles/visually_impaired/services/permission_service.dart';
import 'package:seelai_app/roles/visually_impaired/screens/emergency_hotlines_screen.dart';
import 'package:seelai_app/roles/visually_impaired/widgets/location_map_widget.dart';

class HomeContent extends StatelessWidget {
  final CameraService cameraService;
  final PermissionService permissionService;
  final bool isDarkMode;
  final dynamic theme;
  final Function(String) onNotificationUpdate;
  final VoidCallback onRequestCaretaker;
  final Map<String, dynamic> userData;

  const HomeContent({
    super.key,
    required this.cameraService,
    required this.permissionService,
    required this.isDarkMode,
    required this.theme,
    required this.onNotificationUpdate,
    required this.onRequestCaretaker,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final userId = userData['uid'] as String? ?? '';

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
          // Location Map Section with better design
          if (userId.isNotEmpty)
            _buildLocationSection(userId)
          else
            _buildLocationUnavailable(),
          
          SizedBox(height: spacingXLarge),
          
          // Quick Actions Grid
          _buildQuickActionsGrid(context),
          
          SizedBox(height: spacingXLarge),
          
          // Primary Actions
          _buildCaretakerRequestButton(context),
          
          SizedBox(height: spacingMedium),
          
          _buildEmergencyHotlinesButton(context),
          
          SizedBox(height: spacingXLarge),
        ],
      ),
    );
  }

  Widget _buildLocationSection(String userId) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
        border: isDarkMode
            ? Border.all(color: primary.withOpacity(0.2), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: white,
                    size: 20,
                  ),
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Location',
                        style: bodyBold.copyWith(
                          fontSize: 16,
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Share with caretaker',
                        style: caption.copyWith(
                          fontSize: 12,
                          color: theme.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(radiusXLarge),
              bottomRight: Radius.circular(radiusXLarge),
            ),
            child: LocationMapWidget(
              isDarkMode: isDarkMode,
              theme: theme,
              userId: userId,
              userData: userData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationUnavailable() {
    return Container(
      padding: EdgeInsets.all(spacingXLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: isDarkMode
            ? [
                BoxShadow(
                  color: error.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
        border: isDarkMode
            ? Border.all(color: error.withOpacity(0.2), width: 1)
            : Border.all(color: error.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              color: error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_rounded,
              size: 48,
              color: error,
            ),
          ),
          SizedBox(height: spacingLarge),
          Text(
            'Location Unavailable',
            style: bodyBold.copyWith(
              fontSize: 16,
              color: theme.textColor,
            ),
          ),
          SizedBox(height: spacingSmall),
          Text(
            'Please log in to use location tracking',
            style: body.copyWith(
              fontSize: 13,
              color: theme.subtextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Quick Actions',
            style: h3.copyWith(
              fontSize: 20,
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: spacingMedium),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.wb_sunny_rounded,
                title: 'Good Morning',
                subtitle: '2 reminders',
                iconColor: Colors.orange,
                gradientColors: [
                  Colors.orange.withOpacity(0.15),
                  Colors.orange.withOpacity(0.05),
                ],
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.tips_and_updates_rounded,
                title: 'Quick Tips',
                subtitle: 'Tap for help',
                iconColor: accent,
                gradientColors: [
                  accent.withOpacity(0.15),
                  accent.withOpacity(0.05),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required List<Color> gradientColors,
  }) {
    return Semantics(
      label: '$title. $subtitle',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: isDarkMode
              ? [
                  BoxShadow(
                    color: iconColor.withOpacity(0.1),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title coming soon'),
                  backgroundColor: iconColor,
                ),
              );
            },
            borderRadius: BorderRadius.circular(radiusLarge),
            child: Container(
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radiusLarge),
                border: isDarkMode
                    ? Border.all(color: iconColor.withOpacity(0.2), width: 1)
                    : Border.all(color: iconColor.withOpacity(0.15), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: iconColor,
                    ),
                  ),
                  SizedBox(height: spacingMedium),
                  Text(
                    title,
                    style: bodyBold.copyWith(
                      fontSize: 15,
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
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
      ),
    );
  }

  Widget _buildCaretakerRequestButton(BuildContext context) {
    return Semantics(
      label: 'Request caretaker assistance button',
      button: true,
      hint: 'Double tap to send a request to your caretaker',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radiusXLarge),
          boxShadow: isDarkMode
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: accent.withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: InkWell(
            onTap: onRequestCaretaker,
            borderRadius: BorderRadius.circular(radiusXLarge),
            splashColor: accent.withOpacity(0.2),
            child: Container(
              padding: EdgeInsets.all(spacingLarge * 1.2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(isDarkMode ? 0.2 : 0.12),
                    accent.withOpacity(isDarkMode ? 0.1 : 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radiusXLarge),
                border: Border.all(
                  color: accent.withOpacity(isDarkMode ? 0.3 : 0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.support_agent_rounded,
                      size: 32,
                      color: white,
                    ),
                  ),
                  SizedBox(width: spacingLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Caretaker',
                          style: bodyBold.copyWith(
                            fontSize: 17,
                            color: theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Get assistance from your caretaker',
                          style: caption.copyWith(
                            fontSize: 13,
                            color: theme.subtextColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: accent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyHotlinesButton(BuildContext context) {
    return Semantics(
      label: 'Emergency hotlines button',
      button: true,
      hint: 'Double tap to view and call emergency services',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radiusXLarge),
          boxShadow: isDarkMode
              ? [
                  BoxShadow(
                    color: error.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: error.withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyHotlinesScreen(
                    isDarkMode: isDarkMode,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(radiusXLarge),
            splashColor: error.withOpacity(0.2),
            child: Container(
              padding: EdgeInsets.all(spacingLarge * 1.2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    error.withOpacity(isDarkMode ? 0.2 : 0.12),
                    error.withOpacity(isDarkMode ? 0.1 : 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radiusXLarge),
                border: Border.all(
                  color: error.withOpacity(isDarkMode ? 0.3 : 0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [error, error.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: error.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.phone_in_talk_rounded,
                      size: 32,
                      color: white,
                    ),
                  ),
                  SizedBox(width: spacingLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Hotlines',
                          style: bodyBold.copyWith(
                            fontSize: 17,
                            color: theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Quick access to emergency services',
                          style: caption.copyWith(
                            fontSize: 13,
                            color: theme.subtextColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: error,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}