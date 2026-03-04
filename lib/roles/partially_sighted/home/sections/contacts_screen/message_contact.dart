// File: lib/roles/visually_impaired/home/sections/contacts_screen/message_contact.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'contact_model.dart';

class MessageContact {
  static Future<void> message({
    required BuildContext context,
    required ContactModel contact,
    required bool isDarkMode,
    required dynamic theme,
  }) async {
    // Check if phone number is available
    if (contact.phoneNumber == 'N/A' || contact.phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number not available for ${contact.name}'),
          backgroundColor: error,
        ),
      );
      return;
    }

    // Clean the phone number (remove spaces, dashes, parentheses)
    String cleanPhoneNumber = contact.phoneNumber
        .replaceAll(RegExp(r'[\s\-()]'), '')
        .trim();

    // Format for Philippines numbers
    if (cleanPhoneNumber.startsWith('+63')) {
      // Convert +63 to 0 format
      cleanPhoneNumber = '0${cleanPhoneNumber.substring(3)}';
    } else if (cleanPhoneNumber.startsWith('63') && cleanPhoneNumber.length == 12) {
      // Convert 63 to 0 format (if it's a full PH number without +)
      cleanPhoneNumber = '0${cleanPhoneNumber.substring(2)}';
    } else if (cleanPhoneNumber.length == 10 && !cleanPhoneNumber.startsWith('0')) {
      // Add leading 0 if missing
      cleanPhoneNumber = '0$cleanPhoneNumber';
    }
    // else: already in correct format (starts with 0)

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
            action: 'Opened SMS for ${contact.name}',
            details: 'Phone: ${contact.phoneNumber}',
          );
        }

        // Open SMS app
        await launchUrl(smsUri);
        
        // GUARD: Check if context is mounted
        if (!context.mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Opening SMS for ${contact.name}'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
          ),
        );
      } else {
        // GUARD: Check if context is mounted before showing options
        if (!context.mounted) return;

        // Fallback: Show options
        _showMessageOptions(
          context: context,
          contact: contact,
          phoneNumber: cleanPhoneNumber,
          isDarkMode: isDarkMode,
          theme: theme,
        );
      }
    } catch (e) {
      debugPrint('Error opening SMS: $e');
      
      // GUARD: Check if context is mounted
      if (!context.mounted) return;

      // Show fallback options
      _showMessageOptions(
        context: context,
        contact: contact,
        phoneNumber: cleanPhoneNumber,
        isDarkMode: isDarkMode,
        theme: theme,
      );
    }
  }

  static void _showMessageOptions({
    required BuildContext context,
    required ContactModel contact,
    required String phoneNumber,
    required bool isDarkMode,
    required dynamic theme,
  }) {
    // 1. Capture the parent context
    final parentContext = context;

    showDialog(
      context: parentContext,
      // 2. Rename to dialogContext to avoid shadowing
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Send Message to ${contact.name}',
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
            const SizedBox(height: 4),
            Text(
              contact.phoneNumber,
              style: body.copyWith(color: theme.subtextColor),
            ),
            const SizedBox(height: spacingMedium),
            Text(
              'Choose an option:',
              style: bodyBold.copyWith(color: theme.textColor),
            ),
            const SizedBox(height: spacingSmall),
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
            // Use dialogContext to pop the dialog
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: body.copyWith(color: theme.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Pass the parent context down
              _copyPhoneNumber(parentContext, contact.phoneNumber);
            },
            style: ElevatedButton.styleFrom(
              // Fixed deprecation and removed ignore comment
              backgroundColor: primary.withValues(alpha: 0.1),
              foregroundColor: primary,
            ),
            child: const Text('Copy Number'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Pass the parent context down
              await _tryAlternativeSMS(parentContext, phoneNumber, contact);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  static Future<void> _copyPhoneNumber(BuildContext context, String phoneNumber) async {
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    
    // GUARD: Check if context is mounted
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone number copied to clipboard'),
        backgroundColor: success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  static Future<void> _tryAlternativeSMS(
    BuildContext context,
    String phoneNumber,
    ContactModel contact,
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
      // GUARD: Check if context is mounted
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open messaging app. Please use your device\'s SMS app.'),
          backgroundColor: error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}