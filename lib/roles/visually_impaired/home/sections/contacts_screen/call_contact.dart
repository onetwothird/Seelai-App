// File: lib/roles/visually_impaired/home/sections/contacts_screen/call_contact.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'contact_model.dart';

class CallContact {
  static Future<void> call({
    required BuildContext context,
    required ContactModel contact,
    required bool isDarkMode,
    required dynamic theme,
  }) async {
    // Clean the phone number (remove spaces, dashes, etc.)
    String cleanPhoneNumber = contact.phoneNumber
        .replaceAll(RegExp(r'[\s\-()]'), '')
        .trim();

    // Ensure the phone number has the correct format
  // Clean number for PH format without +63
    if (cleanPhoneNumber.startsWith('+63')) {
      cleanPhoneNumber = '0${cleanPhoneNumber.substring(3)}';
    } else if (cleanPhoneNumber.startsWith('63')) {
      cleanPhoneNumber = '0${cleanPhoneNumber.substring(2)}';
    } else if (cleanPhoneNumber.length == 10 && !cleanPhoneNumber.startsWith('0')) {
      cleanPhoneNumber = '0$cleanPhoneNumber'; 
    }
    // else: already correct (starts with 0)


    final Uri telUri = Uri(scheme: 'tel', path: cleanPhoneNumber);
    
    try {
      if (await canLaunchUrl(telUri)) {
        // Log the call activity
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await activityLogsService.logActivity(
            userId: currentUser.uid,
            action: 'Called ${contact.name}',
            details: 'Phone: ${contact.phoneNumber}',
          );
        }

        await launchUrl(telUri);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling ${contact.name}...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      debugPrint('Error making call: $e');
      
      // Show fallback options
      _showCallOptions(context, contact, cleanPhoneNumber, isDarkMode, theme);
    }
  }

  static void _showCallOptions(
    BuildContext context,
    ContactModel contact,
    String phoneNumber,
    bool isDarkMode,
    dynamic theme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Call ${contact.name}',
          style: h3.copyWith(color: theme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phone number:',
              style: bodyBold.copyWith(color: theme.textColor),
            ),
            SizedBox(height: 4),
            Text(
              contact.phoneNumber,
              style: body.copyWith(color: theme.subtextColor),
            ),
            SizedBox(height: spacingMedium),
            Text(
              'Choose an option:',
              style: bodyBold.copyWith(color: theme.textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: body.copyWith(color: theme.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _copyPhoneNumber(context, contact.phoneNumber);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary.withOpacity(0.1),
              foregroundColor: primary,
            ),
            child: Text('Copy Number'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _tryAlternativeCall(context, phoneNumber, contact);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: white,
            ),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  static Future<void> _copyPhoneNumber(BuildContext context, String phoneNumber) async {
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Phone number copied to clipboard'),
        backgroundColor: success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  static Future<void> _tryAlternativeCall(
    BuildContext context,
    String phoneNumber,
    ContactModel contact,
  ) async {
    // Try alternative method
    final Uri alternativeUri = Uri.parse('tel://$phoneNumber');
    
    try {
      if (await canLaunchUrl(alternativeUri)) {
        await launchUrl(alternativeUri);
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to make call. Please use your phone dialer.'),
          backgroundColor: error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}