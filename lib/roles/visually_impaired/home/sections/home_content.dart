// File: lib/roles/visually_impaired/home/sections/home_content.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/services/camera_service.dart';
import 'package:seelai_app/roles/visually_impaired/services/permission_service.dart';
import 'package:seelai_app/roles/visually_impaired/home/widgets/camera_preview_section.dart';
import 'package:seelai_app/roles/visually_impaired/home/widgets/quick_actions_section.dart';

class HomeContent extends StatelessWidget {
  final CameraService cameraService;
  final PermissionService permissionService;
  final bool isDarkMode;
  final dynamic theme;
  final Function(String) onNotificationUpdate;

  const HomeContent({
    super.key,
    required this.cameraService,
    required this.permissionService,
    required this.isDarkMode,
    required this.theme,
    required this.onNotificationUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CameraPreviewSection(
            cameraService: cameraService,
            permissionService: permissionService,
            isDarkMode: isDarkMode,
            cardColor: theme.cardColor,
            textColor: theme.textColor,
            height: height * 0.38,
          ),
          
          SizedBox(height: spacingXLarge),
          
          QuickActionsSection(
            isDarkMode: isDarkMode,
            cardColor: theme.cardColor,
            textColor: theme.textColor,
            subtextColor: theme.subtextColor,
            onAction: onNotificationUpdate,
          ),
          
          SizedBox(height: spacingXLarge),
        ],
      ),
    );
  }
}