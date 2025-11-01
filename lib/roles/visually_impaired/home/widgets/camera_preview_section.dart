// File: lib/roles/visually_impaired/home/widgets/camera_preview_section.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/services/camera_service.dart';
import 'package:seelai_app/roles/visually_impaired/services/permission_service.dart';

class CameraPreviewSection extends StatelessWidget {
  final CameraService cameraService;
  final PermissionService permissionService;
  final bool isDarkMode;
  final Color cardColor;
  final Color textColor;
  final double height;

  const CameraPreviewSection({
    super.key,
    required this.cameraService,
    required this.permissionService,
    required this.isDarkMode,
    required this.cardColor,
    required this.textColor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Camera preview section',
      hint: 'Real-time camera feed for visual assistance',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(radiusXLarge),
          boxShadow: isDarkMode 
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.15),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ]
            : cardShadow,
          border: isDarkMode 
            ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
            : Border.all(color: greyLighter.withOpacity(0.5), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: cameraService.isInitialized && cameraService.controller != null
            ? _buildCameraPreview()
            : _buildPlaceholder(context),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      children: [
        CameraPreview(cameraService.controller!),
        
        // Camera overlay gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(spacingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: spacingSmall),
                  Text(
                    'Camera Active',
                    style: caption.copyWith(
                      color: white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return FutureBuilder<bool>(
      future: permissionService.hasAllPermissions(),
      builder: (context, snapshot) {
        final hasPermissions = snapshot.data ?? false;
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(spacingLarge),
                decoration: BoxDecoration(
                  gradient: hasPermissions 
                    ? primaryGradient 
                    : LinearGradient(colors: [grey, grey.withOpacity(0.8)]),
                  shape: BoxShape.circle,
                  boxShadow: hasPermissions ? glowShadow : [],
                ),
                child: Icon(
                  hasPermissions 
                    ? Icons.camera_alt_rounded 
                    : Icons.no_photography_rounded,
                  size: 48,
                  color: white,
                ),
              ),
              SizedBox(height: spacingLarge),
              Text(
                hasPermissions 
                  ? 'Initializing camera...' 
                  : 'Camera permission denied',
                textAlign: TextAlign.center,
                style: h3.copyWith(color: textColor, fontSize: 20),
              ),
              SizedBox(height: spacingMedium),
              if (!hasPermissions)
                Semantics(
                  label: 'Open settings button',
                  button: true,
                  hint: 'Double tap to open app settings and grant permissions',
                  child: TextButton.icon(
                    onPressed: () => permissionService.openSettings(),
                    icon: Icon(Icons.settings_rounded),
                    label: Text('Open Settings'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDarkMode ? primaryLight : primary,
                      textStyle: bodyBold.copyWith(fontSize: 16),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDarkMode ? primaryLight : primary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}