// File: lib/roles/partially_sighted/home/sections/contacts_screen/call_contact.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:flutter_tts/flutter_tts.dart'; // ADDED TTS
import 'contact_model.dart';

class CallContact {
  static Future<void> _speak(String message) async {
    final FlutterTts flutterTts = FlutterTts();
    await flutterTts.setLanguage("fil-PH");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(message);
  }

  static Future<void> call({
    required BuildContext context,
    required ContactModel contact,
    required bool isDarkMode,
    required dynamic theme,
  }) async {
    String cleanPhoneNumber = contact.phoneNumber
        .replaceAll(RegExp(r'[\s\-()]'), '')
        .trim();

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
          await activityLogsService.logActivity(
            userId: currentUser.uid,
            action: 'Called ${contact.name}',
            details: 'Phone: ${contact.phoneNumber}',
          );
        }

        await launchUrl(telUri);
        
        if (!context.mounted) return;
        
        await _speak('Calling ${contact.name}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling ${contact.name}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      debugPrint('Error making call: $e');
      if (!context.mounted) return;
      
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
    final parentContext = context;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
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
              await _tryAlternativeCall(parentContext, phoneNumber, contact);
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

  static Future<void> _tryAlternativeCall(
    BuildContext context,
    String phoneNumber,
    ContactModel contact,
  ) async {
    final Uri alternativeUri = Uri.parse('tel://$phoneNumber');
    
    try {
      if (await canLaunchUrl(alternativeUri)) {
        await launchUrl(alternativeUri);
        await _speak('Calling ${contact.name}');
      } else {
        throw Exception('Could not launch phone dialer');
      }
    } catch (e) {
      if (!context.mounted) return;
      
      await _speak('Unable to make call. Please use your phone dialer.');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to make call. Please use your phone dialer.'),
          backgroundColor: error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}