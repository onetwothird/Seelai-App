// File: lib/roles/visually_impaired/home/sections/home_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/partially_sighted/camera_service.dart';
import 'package:seelai_app/roles/partially_sighted/services/permission_service.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/location.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/announcement.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/request_caretaker.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/emergency_hotline.dart';

class HomeContent extends StatelessWidget {
  final CameraService cameraService;
  final PermissionService permissionService;
  final bool isDarkMode;
  final dynamic theme;
  final Function(String) onNotificationUpdate;
  final Map<String, dynamic> userData;

  const HomeContent({
    super.key,
    required this.cameraService,
    required this.permissionService,
    required this.isDarkMode,
    required this.theme,
    required this.onNotificationUpdate,
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
          // Location Map Section
          LocationSection(
            isDarkMode: isDarkMode,
            theme: theme,
            userId: userId,
            userData: userData,
          ),
          
          SizedBox(height: spacingXLarge),
          
          // Announcements Section
          AnnouncementSection(
            isDarkMode: isDarkMode,
            theme: theme,
            userId: userId,
          ),
          
          SizedBox(height: spacingMedium),
          
          // === NEW: Features Section Title ===
          Padding(
            padding: const EdgeInsets.only(left: 4), // Aligns perfectly with Announcement title
            child: Text(
              'Help & Support',
              style: h3.copyWith(
                fontSize: 20,
                color: theme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          
          SizedBox(height: spacingMedium),
          
          // Request Caretaker Button
          RequestCaretakerButton(
            isDarkMode: isDarkMode,
            theme: theme,
            userData: userData,
          ),
          
          SizedBox(height: spacingMedium),
          
          // Emergency Hotlines Button
          EmergencyHotlineButton(
            isDarkMode: isDarkMode,
            theme: theme,
          ),
          
          SizedBox(height: spacingXLarge),
        ],
      ),
    );
  }
}