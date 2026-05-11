// File: lib/roles/partially_sighted/home/sections/home_content.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // NEW: Imported Shimmer
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; 
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/partially_sighted/camera_service.dart';
import 'package:seelai_app/roles/partially_sighted/services/permission_service.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/location.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/announcement.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/request_caretaker.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/emergency_hotline.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/communication/quick_contact_section.dart';

class HomeContent extends StatefulWidget {
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
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // === NEW: ARTIFICIAL DELAY TO GUARANTEE SKELETON ANIMATION PLAYS ===
  bool _isSimulatingLoad = true;

  @override
  void initState() {
    super.initState();
    // Force the skeleton loader to display gracefully for exactly 400ms
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isSimulatingLoad = false;
        });
      }
    });
  }

  // === NEW: FULL PAGE SKELETON LOADER ===
  Widget _buildSkeletonHome() {
    final baseColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Contacts Skeleton
          Row(
            children: [
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
            ],
          ),
          const SizedBox(height: spacingXLarge),
          
          // Location/Map Skeleton
          Container(height: 350, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: spacingXLarge),
          
          // Announcements Title Skeleton
          Container(width: 150, height: 24, color: Colors.white),
          const SizedBox(height: spacingMedium),
          
          // Announcements List Skeletons
          Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: spacingMedium),
          Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: spacingMedium),
          
          // Help & Support Skeletons
          Container(width: 120, height: 24, color: Colors.white),
          const SizedBox(height: spacingMedium),
          Container(height: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: spacingMedium),
          Container(height: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final userId = widget.userData['uid'] as String? ?? widget.userData['userId'] as String? ?? '';

    return Padding(
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: _isSimulatingLoad 
          ? _buildSkeletonHome() 
          : _buildActualContent(userId),
    );
  }

  Widget _buildActualContent(String userId) {
    final contentWidgets = [
      QuickContactSection(
        isDarkMode: widget.isDarkMode,
        theme: widget.theme,
        userData: widget.userData,
      ),
      const SizedBox(height: spacingXLarge),
      LocationSection(
        isDarkMode: widget.isDarkMode,
        theme: widget.theme,
        userId: userId,
        userData: widget.userData,
      ),
      const SizedBox(height: spacingXLarge),
      AnnouncementSection(
        isDarkMode: widget.isDarkMode,
        theme: widget.theme,
        userId: userId,
      ),
      const SizedBox(height: spacingMedium),
      Padding(
        padding: const EdgeInsets.only(left: 4), 
        child: Text(
          'Help & Support',
          style: h3.copyWith(
            fontSize: 20,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: spacingMedium),
      RequestCaretakerButton(
        isDarkMode: widget.isDarkMode,
        theme: widget.theme,
        userData: widget.userData,
      ),
      const SizedBox(height: spacingMedium),
      EmergencyHotlineButton(
        isDarkMode: widget.isDarkMode,
        theme: widget.theme,
      ),
      const SizedBox(height: spacingXLarge),
    ];

    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 500),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: contentWidgets,
        ),
      ),
    );
  }
}