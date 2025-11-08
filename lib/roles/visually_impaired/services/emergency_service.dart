// File: lib/roles/visually_impaired/services/emergency_service.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seelai_app/roles/visually_impaired/models/emergency_hotline_model.dart';

class EmergencyService {
  // Make emergency call
  Future<bool> makeEmergencyCall(String phoneNumber) async {
    try {
      final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
      
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
        debugPrint('Emergency call initiated to: $phoneNumber');
        return true;
      } else {
        debugPrint('Cannot launch phone dialer');
        return false;
      }
    } catch (e) {
      debugPrint('Error making emergency call: $e');
      return false;
    }
  }

  // Send SMS to emergency contact
  Future<bool> sendEmergencySMS(String phoneNumber, String message) async {
    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        debugPrint('SMS sent to: $phoneNumber');
        return true;
      } else {
        debugPrint('Cannot launch SMS app');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return false;
    }
  }

  // Open location in maps
  Future<bool> openLocation(String address) async {
    try {
      // Google Maps URL with the address
      final Uri mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}'
      );
      
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
        debugPrint('Opening location: $address');
        return true;
      } else {
        debugPrint('Cannot open maps');
        return false;
      }
    } catch (e) {
      debugPrint('Error opening location: $e');
      return false;
    }
  }

  // Get sample/default emergency hotlines
  List<EmergencyHotline> getDefaultHotlines() {
    return [
      EmergencyHotline(
        id: 'hotline_1',
        departmentName: 'Police Station',
        phoneNumber: '911',
        address: 'Local Police Headquarters',
        description: 'Emergency police assistance',
        icon: Icons.local_police_rounded,
        color: Colors.blue,
      ),
      EmergencyHotline(
        id: 'hotline_2',
        departmentName: 'Fire Station',
        phoneNumber: '911',
        address: 'Local Fire Department',
        description: 'Fire and rescue services',
        icon: Icons.local_fire_department_rounded,
        color: Colors.red,
      ),
      EmergencyHotline(
        id: 'hotline_3',
        departmentName: 'Hospital/Ambulance',
        phoneNumber: '911',
        address: 'Emergency Medical Services',
        description: 'Medical emergency services',
        icon: Icons.local_hospital_rounded,
        color: Colors.green,
      ),
    ];
  }
}