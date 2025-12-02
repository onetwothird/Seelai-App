// File: lib/roles/caretaker/home/sections/patients_screen/call_patients.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'patient_model.dart';

class CallPatient {
  static Future<void> call({
    required BuildContext context,
    required PatientModel patient,
    required bool isDarkMode,
    required dynamic theme,
  }) async {
    // Clean the phone number (remove spaces, dashes, etc.)
    String cleanPhoneNumber = patient.contactNumber!
        .replaceAll(RegExp(r'[\s\-()]'), '')
        .trim();

    // Format for Philippines numbers
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
        // Log the call activity
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await activityLogsService.logActivity(
            userId: currentUser.uid,
            action: 'Called ${patient.name}',
            details: 'Phone: ${patient.contactNumber}',
          );
        }

        await launchUrl(telUri);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling ${patient.name}...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      debugPrint('Error making call: $e');
      
      // Show fallback options
      if (context.mounted) {
        _showCallOptions(context, patient, cleanPhoneNumber, isDarkMode, theme);
      }
    }
  }

  static void _showCallOptions(
    BuildContext context,
    PatientModel patient,
    String phoneNumber,
    bool isDarkMode,
    dynamic theme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Call ${patient.name}',
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
              patient.contactNumber ?? 'N/A',
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
              _copyPhoneNumber(context, patient.contactNumber ?? '');
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
              await _tryAlternativeCall(context, phoneNumber, patient);
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
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number copied to clipboard'),
          backgroundColor: success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  static Future<void> _tryAlternativeCall(
    BuildContext context,
    String phoneNumber,
    PatientModel patient,
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
      if (context.mounted) {
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
}