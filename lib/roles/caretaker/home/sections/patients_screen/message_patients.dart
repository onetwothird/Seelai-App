// File: lib/roles/caretaker/home/sections/patients_screen/message_patients.dart


import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

Future<void> messagePatient(BuildContext context, {String? patientName}) async {
  const String phoneNumber = '09385100460';

  final Uri smsUri = Uri(
    scheme: 'sms',
    path: phoneNumber,
  );

  // ✅ Get messenger BEFORE async gap
  final messenger = ScaffoldMessenger.of(context);

  try {
    final bool canLaunch = await canLaunchUrl(smsUri);

    if (!canLaunch) {
      throw 'Could not launch SMS app';
    }

    await launchUrl(smsUri);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          patientName != null
              ? 'Opening SMS for $patientName...'
              : 'Opening SMS app...',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Failed to open SMS: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

Future<void> messagePatientWithBody(
    BuildContext context, String message) async {
  const String phoneNumber = '09385100460';

  final String smsUrl =
      'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';

  final Uri uri = Uri.parse(smsUrl);

  // ✅ Extract BEFORE async gap
  final messenger = ScaffoldMessenger.of(context);

  try {
    final bool canLaunch = await canLaunchUrl(uri);

    if (!canLaunch) {
      throw 'Could not launch SMS app';
    }

    await launchUrl(uri);
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Failed to send SMS: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}