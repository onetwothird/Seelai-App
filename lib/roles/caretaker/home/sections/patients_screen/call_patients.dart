// File: lib/roles/caretaker/home/sections/patients_screen/call_patients.dart

// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

/// Function to initiate a direct phone call to the fixed number
Future<void> callPatient(BuildContext context, {String? patientName}) async {
  const String phoneNumber = '09385100460'; // Fixed phone number as requested
  
  try {
    // Create the URL for making a phone call
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    // Check if the device can launch the URL
    if (await canLaunchUrl(phoneUri)) {
      // Launch the phone dialer
      await launchUrl(phoneUri);
      
      // Show success message (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            patientName != null 
              ? 'Calling $patientName...'
              : 'Initiating phone call...',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // If unable to launch, show error
      throw 'Could not launch phone dialer';
    }
  } catch (e) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to make call: $e'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

/// Alternative: Using launch with string (for older versions)
Future<void> callPatientAlt(BuildContext context) async {
  const String phoneNumber = '09385100460';
  final String phoneUrl = 'tel:$phoneNumber';
  
  try {
    if (await canLaunch(phoneUrl)) {
      await launch(phoneUrl);
    } else {
      throw 'Could not launch phone dialer';
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to make call: $e'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}