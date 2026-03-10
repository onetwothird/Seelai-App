// File: lib/firebase/cloudinary_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  // Your Cloudinary credentials
  static const String cloudName = 'dpkko2k4u';
  static const String apiKey = '473668786762914';
  static const String apiSecret = 'Kt4OIMrujtPtb2kGmn6nolTe4kc';
  
  static const String uploadPresetProfile = 'profile_images'; 
  static const String uploadPresetDetections = 'detection_images'; // Create this in Cloudinary!
  
  /// Upload profile image to Cloudinary
  Future<String?> uploadProfileImage(File imageFile, String userId, String role) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );
      
      request.fields['upload_preset'] = uploadPresetProfile;
      request.fields['folder'] = 'seelai_profiles/$role'; 
      request.fields['public_id'] = userId; 
      
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'] as String;
      } else {
        var responseData = await response.stream.bytesToString();
        throw Exception('Upload failed: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      throw Exception('Failed to upload to Cloudinary: $e');
    }
  }
  
  /// Upload a detection snapshot to Cloudinary
  Future<String?> uploadDetectionImage(File imageFile, String userId, String detectionType) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );
      
      // Use a preset that doesn't crop images into circles
      request.fields['upload_preset'] = uploadPresetDetections; 
      
      // ✅ This creates the dedicated folder structure: seelai_detections/object/user123
      request.fields['folder'] = 'seelai_detections/$detectionType/$userId'; 
      
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'] as String;
      } else {
        debugPrint('Upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to upload detection to Cloudinary: $e');
      return null;
    }
  }

  Future<bool> deleteProfileImage(String userId, String role) async {
    try {
      final publicId = 'seelai_profiles/$role/$userId';
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      final signature = _generateSignature(publicId, timestamp);
      
      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy'),
        body: {
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': apiKey,
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['result'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Failed to delete from Cloudinary: $e');
      return false;
    }
  }

  String _generateSignature(String publicId, String timestamp) {
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}

final CloudinaryService cloudinaryService = CloudinaryService();