// File: lib/roles/caretaker/home/sections/patients_screen/message_patients.dart

// ignore_for_file: use_build_context_synchronously

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

/// Function to open SMS app with the fixed number
Future<void> messagePatient(BuildContext context, {String? patientName}) async {
  const String phoneNumber = '09385100460'; // Fixed phone number as requested
  
  // The number is already in the correct format (09385100460)
  // No cleaning needed, use it directly
  final String cleanPhoneNumber = phoneNumber;
  
  try {
    // Create the URL for sending an SMS
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanPhoneNumber,
      // You can optionally add a pre-filled message
      // queryParameters: {'body': 'Hello from SeelAI Caretaker'},
    );
    
    // Check if the device can launch the URL
    if (await canLaunchUrl(smsUri)) {
      // Launch the SMS app
      await launchUrl(smsUri);
      
      // Show success message (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            patientName != null 
              ? 'Opening SMS for $patientName...'
              : 'Opening SMS app...',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // If unable to launch, show error
      throw 'Could not launch SMS app';
    }
  } catch (e) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to open SMS: $e'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

/// Alternative: Using launch with string and pre-filled message
Future<void> messagePatientWithBody(BuildContext context, String message) async {
  const String phoneNumber = '09385100460';
  
  // The number is already in the correct format (09385100460)
  // No cleaning needed, use it directly
  final String cleanPhoneNumber = phoneNumber;
  
  final String smsUrl = 'sms:$cleanPhoneNumber?body=${Uri.encodeComponent(message)}';
  
  try {
    final Uri uri = Uri.parse(smsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch SMS app';
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to send SMS: $e'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}