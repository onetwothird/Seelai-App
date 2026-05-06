// File: lib/roles/partially_sighted/home/sections/contacts_screen/message_contact.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:flutter_tts/flutter_tts.dart'; // ADDED TTS
import 'contact_model.dart';

class MessageContact {
  static Future<void> _speak(String message) async {
    final FlutterTts flutterTts = FlutterTts();
    await flutterTts.setLanguage("fil-PH");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(message);
  }

  static Future<void> message({
    required BuildContext context,
    required ContactModel contact,
    required bool isDarkMode,
    required dynamic theme,
  }) async {
    if (contact.phoneNumber == 'N/A' || contact.phoneNumber.isEmpty) {
      await _speak('Phone number not available');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number not available for ${contact.name}'),
          backgroundColor: error,
        ),
      );
      return;
    }

    String cleanPhoneNumber = contact.phoneNumber
        .replaceAll(RegExp(r'[\s\-()]'), '')
        .trim();

    if (cleanPhoneNumber.startsWith('+63')) {
      cleanPhoneNumber = '0${cleanPhoneNumber.substring(3)}';
    } else if (cleanPhoneNumber.startsWith('63') && cleanPhoneNumber.length == 12) {
      cleanPhoneNumber = '0${cleanPhoneNumber.substring(2)}';
    } else if (cleanPhoneNumber.length == 10 && !cleanPhoneNumber.startsWith('0')) {
      cleanPhoneNumber = '0$cleanPhoneNumber';
    }

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanPhoneNumber,
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await activityLogsService.logActivity(
            userId: currentUser.uid,
            action: 'Opened SMS for ${contact.name}',
            details: 'Phone: ${contact.phoneNumber}',
          );
        }

        await launchUrl(smsUri);
        
        if (!context.mounted) return;

        await _speak('Opening message for ${contact.name}');

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
        if (!context.mounted) return;

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
      
      if (!context.mounted) return;

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
    final parentContext = context;

    showDialog(
      context: parentContext,
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: body.copyWith(color: theme.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _copyPhoneNumber(parentContext, contact.phoneNumber);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary.withValues(alpha: 0.1),
              foregroundColor: primary,
            ),
            child: const Text('Copy Number'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
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
    
    if (!context.mounted) return;

    await _speak('Phone number copied to clipboard');

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
    final Uri alternativeUri = Uri.parse('sms:$phoneNumber');
    
    try {
      if (await canLaunchUrl(alternativeUri)) {
        await launchUrl(alternativeUri);
        await _speak('Opening message for ${contact.name}');
      } else {
        final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
          await _speak('Calling ${contact.name}');
        } else {
          throw Exception('Could not launch messaging app');
        }
      }
    } catch (e) {
      if (!context.mounted) return;

      await _speak('Unable to open messaging app. Please use your device SMS app.');

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