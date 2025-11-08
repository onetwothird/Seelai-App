// File: lib/roles/visually_impaired/home/sections/home_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/services/camera_service.dart';
import 'package:seelai_app/roles/visually_impaired/services/permission_service.dart';
import 'package:seelai_app/roles/visually_impaired/screens/emergency_hotlines_screen.dart';

class HomeContent extends StatelessWidget {
  final CameraService cameraService;
  final PermissionService permissionService;
  final bool isDarkMode;
  final dynamic theme;
  final Function(String) onNotificationUpdate;
  final VoidCallback onRequestCaretaker;

  const HomeContent({
    super.key,
    required this.cameraService,
    required this.permissionService,
    required this.isDarkMode,
    required this.theme,
    required this.onNotificationUpdate,
    required this.onRequestCaretaker,
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
          
          // Contextual Voice Cards - Compact Row
          Row(
            children: [
              Expanded(
                child: _buildCompactContextualCard(
                  context,
                  icon: Icons.wb_sunny_rounded,
                  title: 'Good Morning',
                  subtitle: '2 reminders',
                  iconColor: Colors.orange,
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: _buildCompactContextualCard(
                  context,
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Quick Help',
                  subtitle: 'Tap to assist',
                  iconColor: accent,
                ),
              ),
            ],
          ),
          
          SizedBox(height: spacingLarge),
          
          // Caretaker Request Button
          _buildCaretakerRequestButton(context),
          
          SizedBox(height: spacingMedium),
          
          // Emergency Hotlines Button
          _buildEmergencyHotlinesButton(context),
          
          SizedBox(height: spacingXLarge),
        ],
      ),
    );
  }

  Widget _buildCompactContextualCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Semantics(
      label: '$title. $subtitle',
      readOnly: true,
      child: Container(
        padding: EdgeInsets.all(spacingMedium),
        decoration: BoxDecoration(
          color: theme.cardColor,
          gradient: LinearGradient(
            colors: [
              iconColor.withOpacity(isDarkMode ? 0.2 : 0.08),
              iconColor.withOpacity(isDarkMode ? 0.1 : 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(radiusMedium),
          border: Border.all(
            color: iconColor.withOpacity(isDarkMode ? 0.3 : 0.2),
            width: 1.2,
          ),
          boxShadow: isDarkMode 
            ? [
                BoxShadow(
                  color: iconColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(spacingSmall),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: iconColor,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              title,
              style: bodyBold.copyWith(
                fontSize: 14,
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2),
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
    );
  }


  Widget _buildCaretakerRequestButton(BuildContext context) {
    return Semantics(
      label: 'Request caretaker assistance button',
      button: true,
      hint: 'Double tap to send a request to your caretaker',
      child: Container(
        decoration: BoxDecoration(
          boxShadow: isDarkMode 
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.2),
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
            onTap: onRequestCaretaker,
            borderRadius: BorderRadius.circular(radiusLarge),
            splashColor: accent.withOpacity(0.2),
            child: Container(
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(isDarkMode ? 0.25 : 0.1), 
                    accent.withOpacity(isDarkMode ? 0.15 : 0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radiusLarge),
                border: isDarkMode 
                  ? Border.all(color: accent.withOpacity(0.4), width: 1.5)
                  : Border.all(color: accent.withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacingMedium * 1.2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.4),
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
                            fontSize: 18,
                            color: theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: spacingXSmall),
                        Text(
                          'Get assistance from your caretaker',
                          style: caption.copyWith(
                            fontSize: 14,
                            color: theme.subtextColor,
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
          boxShadow: isDarkMode 
            ? [
                BoxShadow(
                  color: error.withOpacity(0.2),
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
            borderRadius: BorderRadius.circular(radiusLarge),
            splashColor: error.withOpacity(0.2),
            child: Container(
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    error.withOpacity(isDarkMode ? 0.25 : 0.1), 
                    error.withOpacity(isDarkMode ? 0.15 : 0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radiusLarge),
                border: isDarkMode 
                  ? Border.all(color: error.withOpacity(0.4), width: 1.5)
                  : Border.all(color: error.withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacingMedium * 1.2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [error, error.withOpacity(0.8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: error.withOpacity(0.4),
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
                            fontSize: 18,
                            color: theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: spacingXSmall),
                        Text(
                          'Quick access to emergency services',
                          style: caption.copyWith(
                            fontSize: 14,
                            color: theme.subtextColor,
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