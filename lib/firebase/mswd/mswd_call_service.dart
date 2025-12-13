// File: lib/firebase/mswd/mswd_call_service.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class MswdCallService {
  /// Call a user or caretaker
  static Future<void> call({
    required BuildContext context,
    required Map<String, dynamic> user,
    required bool isDarkMode,
    required dynamic theme,
  }) async {
    final phoneNumber = user['contactNumber'] as String?;
    
    if (phoneNumber == null || phoneNumber.isEmpty || phoneNumber == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number not available for ${user['name'] ?? 'this user'}'),
          backgroundColor: error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Clean the phone number (remove spaces, dashes, etc.)
    String cleanPhoneNumber = phoneNumber
        .replaceAll(RegExp(r'[\s\-()]'), '')
        .trim();

    // Ensure the phone number has the correct format for PH
    if (cleanPhoneNumber.startsWith('+63')) {
      cleanPhoneNumber = '0${cleanPhoneNumber.substring(3)}';
    } else if (cleanPhoneNumber.startsWith('63')) {
      cleanPhoneNumber = '0${cleanPhoneNumber.substring(2)}';
    } else if (cleanPhoneNumber.length == 10 && !cleanPhoneNumber.startsWith('0')) {
      cleanPhoneNumber = '0$cleanPhoneNumber'; 
    }

    final Uri telUri = Uri(scheme: 'tel', path: cleanPhoneNumber);
    
    try {
      if (await canLaunchUrl(telUri)) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userRole = user['role'] ?? 'Unknown';
          final userName = user['name'] ?? 'Unknown User';
          final userId = user['userId'] ?? 'N/A';
          final timestamp = DateTime.now().millisecondsSinceEpoch;

          // 1. Log to activity_logs (existing)
          await activityLogsService.logActivity(
            userId: currentUser.uid,
            action: 'Called $userName',
            details: 'Phone: $phoneNumber, Role: $userRole, User ID: $userId',
          );

          // 2. Store in mswd_communication/calls
          final callsRef = FirebaseDatabase.instance.ref('mswd_communication/calls');
          final newCallRef = callsRef.push();
          await newCallRef.set({
            'callerId': currentUser.uid,
            'receiverId': userId,
            'timestamp': timestamp,
            'userRole': userRole,
            'userName': userName,
            'phoneNumber': phoneNumber,
            'status': 'initiated',
          });

          // 3. Store in mswd_communication/call_logs
          final callLogsRef = FirebaseDatabase.instance.ref('mswd_communication/call_logs');
          final newLogRef = callLogsRef.push();
          await newLogRef.set({
            'mswdId': currentUser.uid,
            'userId': userId,
            'userName': userName,
            'userRole': userRole,
            'phoneNumber': phoneNumber,
            'timestamp': timestamp,
            'callType': 'outgoing',
            'duration': 0, // Will be updated when call ends
          });
        }

        await launchUrl(telUri);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.phone_rounded, color: white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Calling ${user['name'] ?? 'user'}...'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
          ),
        );
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      debugPrint('Error making call: $e');
      
      // Show fallback options
      _showCallOptions(context, user, cleanPhoneNumber, phoneNumber, isDarkMode, theme);
    }
  }

  static void _showCallOptions(
    BuildContext context,
    Map<String, dynamic> user,
    String cleanPhoneNumber,
    String originalPhoneNumber,
    bool isDarkMode,
    dynamic theme,
  ) {
    final userName = user['name'] ?? 'User';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.phone_rounded, color: primary, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Call $userName',
                style: h3.copyWith(color: theme.textColor),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phone number:',
              style: bodyBold.copyWith(
                color: theme.textColor,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacingMedium,
                vertical: spacingSmall,
              ),
              decoration: BoxDecoration(
                color: theme.isDarkMode 
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(radiusMedium),
                border: Border.all(
                  color: theme.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_rounded,
                    size: 16,
                    color: primary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      originalPhoneNumber,
                      style: body.copyWith(
                        color: theme.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'Choose an option:',
              style: bodyBold.copyWith(
                color: theme.subtextColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: theme.subtextColor,
              padding: EdgeInsets.symmetric(
                horizontal: spacingLarge,
                vertical: spacingSmall,
              ),
            ),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _copyPhoneNumber(context, originalPhoneNumber);
            },
            icon: Icon(Icons.copy_rounded, size: 18),
            label: Text('Copy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary.withOpacity(0.1),
              foregroundColor: primary,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: spacingLarge,
                vertical: spacingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _tryAlternativeCall(context, cleanPhoneNumber, user);
            },
            icon: Icon(Icons.phone_rounded, size: 18),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: spacingLarge,
                vertical: spacingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _copyPhoneNumber(
    BuildContext context,
    String phoneNumber,
  ) async {
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: white, size: 20),
            SizedBox(width: 8),
            Text('Phone number copied to clipboard'),
          ],
        ),
        backgroundColor: success,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    );
  }

  static Future<void> _tryAlternativeCall(
    BuildContext context,
    String phoneNumber,
    Map<String, dynamic> user,
  ) async {
    // Try alternative method
    final Uri alternativeUri = Uri.parse('tel://$phoneNumber');
    
    try {
      if (await canLaunchUrl(alternativeUri)) {
        await launchUrl(alternativeUri);
        
        // Log the call activity
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userRole = user['role'] ?? 'Unknown';
          final userName = user['name'] ?? 'Unknown User';
          final userId = user['userId'] ?? 'N/A';
          final timestamp = DateTime.now().millisecondsSinceEpoch;

          // Log to activity_logs
          await activityLogsService.logActivity(
            userId: currentUser.uid,
            action: 'Called $userName (Alternative)',
            details: 'Phone: $phoneNumber, User ID: $userId',
          );

          // Store in mswd_communication/calls
          final callsRef = FirebaseDatabase.instance.ref('mswd_communication/calls');
          final newCallRef = callsRef.push();
          await newCallRef.set({
            'callerId': currentUser.uid,
            'receiverId': userId,
            'timestamp': timestamp,
            'userRole': userRole,
            'userName': userName,
            'phoneNumber': phoneNumber,
            'status': 'initiated',
            'method': 'alternative',
          });

          // Store in mswd_communication/call_logs
          final callLogsRef = FirebaseDatabase.instance.ref('mswd_communication/call_logs');
          final newLogRef = callLogsRef.push();
          await newLogRef.set({
            'mswdId': currentUser.uid,
            'userId': userId,
            'userName': userName,
            'userRole': userRole,
            'phoneNumber': phoneNumber,
            'timestamp': timestamp,
            'callType': 'outgoing',
            'duration': 0,
          });
        }
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      debugPrint('Alternative call failed: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Unable to make call. Please use your phone dialer.'),
              ),
            ],
          ),
          backgroundColor: error,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          action: SnackBarAction(
            label: 'Copy Number',
            textColor: white,
            onPressed: () => _copyPhoneNumber(context, phoneNumber),
          ),
        ),
      );
    }
  }
}