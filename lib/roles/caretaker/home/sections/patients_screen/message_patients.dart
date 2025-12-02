// File: lib/roles/caretaker/home/sections/patients_screen/message_patients.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'patient_model.dart';

class MessagePatient {
  static Future<void> message({
    required BuildContext context,
    required PatientModel patient,
    required bool isDarkMode,
    required dynamic theme,
  }) async {
    // Check if phone number is available
    if (patient.contactNumber == null || 
        patient.contactNumber == 'N/A' || 
        patient.contactNumber!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone number not available for ${patient.name}'),
            backgroundColor: error,
          ),
        );
      }
      return;
    }

    // Clean the phone number (remove spaces, dashes, parentheses)
    String cleanPhoneNumber = patient.contactNumber!
        .replaceAll(RegExp(r'[\s\-()]'), '')
        .trim();

    // Format for Philippines numbers
    if (cleanPhoneNumber.startsWith('+63')) {
      cleanPhoneNumber = '0${cleanPhoneNumber.substring(3)}';
    } else if (cleanPhoneNumber.startsWith('63') && cleanPhoneNumber.length == 12) {
      cleanPhoneNumber = '0${cleanPhoneNumber.substring(2)}';
    } else if (cleanPhoneNumber.length == 10 && !cleanPhoneNumber.startsWith('0')) {
      cleanPhoneNumber = '0$cleanPhoneNumber';
    }

    // Create SMS URI
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanPhoneNumber,
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        // Log the message activity
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await activityLogsService.logActivity(
            userId: currentUser.uid,
            action: 'Opened SMS for ${patient.name}',
            details: 'Phone: ${patient.contactNumber}',
          );
        }

        // Open SMS app
        await launchUrl(smsUri);
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Opening SMS for ${patient.name}'),
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
        }
      } else {
        // Fallback: Show options
        if (context.mounted) {
          _showMessageOptions(
            context: context,
            patient: patient,
            phoneNumber: cleanPhoneNumber,
            isDarkMode: isDarkMode,
            theme: theme,
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening SMS: $e');
      
      // Show fallback options
      if (context.mounted) {
        _showMessageOptions(
          context: context,
          patient: patient,
          phoneNumber: cleanPhoneNumber,
          isDarkMode: isDarkMode,
          theme: theme,
        );
      }
    }
  }

  static void _showMessageOptions({
    required BuildContext context,
    required PatientModel patient,
    required String phoneNumber,
    required bool isDarkMode,
    required dynamic theme,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Send Message to ${patient.name}',
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
            SizedBox(height: spacingSmall),
            Text(
              'SMS app could not be opened automatically.',
              style: body.copyWith(
                color: theme.subtextColor,
                fontSize: 13,
              ),
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
              await _tryAlternativeSMS(context, phoneNumber, patient);
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

  static Future<void> _tryAlternativeSMS(
    BuildContext context,
    String phoneNumber,
    PatientModel patient,
  ) async {
    // Try alternative SMS URI format
    final Uri alternativeUri = Uri.parse('sms:$phoneNumber');
    
    try {
      if (await canLaunchUrl(alternativeUri)) {
        await launchUrl(alternativeUri);
      } else {
        // Try with tel: scheme as fallback
        final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
        } else {
          throw Exception('Could not launch messaging app');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open messaging app. Please use your device\'s SMS app.'),
            backgroundColor: error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}