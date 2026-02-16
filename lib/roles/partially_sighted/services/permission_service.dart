// File: lib/roles/visually_impaired/services/permission_service.dart
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionResult {
  final bool hasAllPermissions;
  final String message;
  final PermissionStatus cameraStatus;
  final PermissionStatus storageStatus;

  PermissionResult({
    required this.hasAllPermissions,
    required this.message,
    required this.cameraStatus,
    required this.storageStatus,
  });
}

class PermissionService {
  /// Request all required permissions for the app
  Future<PermissionResult> requestAllPermissions() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      
      // Request storage permissions based on Android version
      PermissionStatus storageStatus;
      if (await _isAndroid13OrHigher()) {
        // For Android 13+, request media permissions
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        storageStatus = (photos.isGranted && videos.isGranted) 
          ? PermissionStatus.granted 
          : PermissionStatus.denied;
      } else {
        // For Android 12 and below
        storageStatus = await Permission.storage.request();
      }

      final hasAll = cameraStatus.isGranted && storageStatus.isGranted;
      
      return PermissionResult(
        hasAllPermissions: hasAll,
        message: hasAll 
          ? 'Camera and storage access enabled'
          : _getPermissionDeniedMessage(cameraStatus, storageStatus),
        cameraStatus: cameraStatus,
        storageStatus: storageStatus,
      );
    } catch (e) {
      debugPrint('Permission request error: $e');
      return PermissionResult(
        hasAllPermissions: false,
        message: 'Unable to request permissions',
        cameraStatus: PermissionStatus.denied,
        storageStatus: PermissionStatus.denied,
      );
    }
  }

  /// Check if Android version is 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    // This is a simple check, you might want to use a platform-specific plugin
    // for more accurate version detection
    return false; // Default to false for iOS and older Android
  }

  /// Get detailed permission denial message
  String _getPermissionDeniedMessage(
    PermissionStatus camera, 
    PermissionStatus storage
  ) {
    List<String> denied = [];
    
    if (!camera.isGranted) denied.add('Camera');
    if (!storage.isGranted) denied.add('Storage');
    
    if (denied.isEmpty) return 'All permissions granted';
    
    return '${denied.join(' and ')} permission${denied.length > 1 ? 's' : ''} denied';
  }

  /// Check if all required permissions are granted
  Future<bool> hasAllPermissions() async {
    final camera = await Permission.camera.status;
    final storage = await Permission.storage.status;
    return camera.isGranted && storage.isGranted;
  }

  /// Open app settings for manual permission grant
  Future<void> openSettings() async {
    await openAppSettings();
  }
}