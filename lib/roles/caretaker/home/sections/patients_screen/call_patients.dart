// File: lib/roles/caretaker/home/sections/patients_screen/call_patients.dart


import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

Future<void> callPatient(BuildContext context, {String? patientName}) async {
  const String phoneNumber = '09385100460';

  final messenger = ScaffoldMessenger.of(context);

  try {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    final bool canLaunch = await canLaunchUrl(phoneUri);

    if (!canLaunch) {
      throw 'Could not launch phone dialer';
    }

    await launchUrl(phoneUri);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          patientName != null
              ? 'Calling $patientName...'
              : 'Initiating phone call...',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Failed to make call: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

Future<void> callPatientAlt(BuildContext context) async {
  const String phoneNumber = '09385100460';
  final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

  final messenger = ScaffoldMessenger.of(context);

  try {
    final bool canLaunch = await canLaunchUrl(phoneUri);

    if (!canLaunch) {
      throw 'Could not launch phone dialer';
    }

    await launchUrl(phoneUri);
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Failed to make call: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}