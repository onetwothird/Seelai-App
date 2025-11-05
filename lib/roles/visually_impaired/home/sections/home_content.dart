// File: lib/roles/visually_impaired/home/sections/home_content.dart
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
          SizedBox(height: spacingXLarge),
          
          // Empty center content area
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: spacingXLarge * 3),
              child: Column(
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 80,
                    color: theme.subtextColor.withOpacity(0.3),
                  ),
                  SizedBox(height: spacingLarge),
                  Text(
                    'Tap camera button below\nto start scanning',
                    textAlign: TextAlign.center,
                    style: body.copyWith(
                      color: theme.subtextColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
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