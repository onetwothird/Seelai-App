// ignore_for_file: avoid_print

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  // Your Cloudinary credentials
  static const String cloudName = 'dpkko2k4u';
  static const String apiKey = '473668786762914';
  static const String apiSecret = 'Kt4OIMrujtPtb2kGmn6nolTe4kc';
  static const String uploadPreset = 'profile_images'; // The preset we created
  
  /// Upload image to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String?> uploadProfileImage(File imageFile, String userId, String role) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );
      
      // Add fields
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'seelai_profiles/$role'; // Organize by role
      request.fields['public_id'] = userId; // Use userId as filename
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      
      // Send request
      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        
        // Return the secure URL
        return jsonResponse['secure_url'] as String;
      } else {
        var responseData = await response.stream.bytesToString();
        throw Exception('Upload failed: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      throw Exception('Failed to upload to Cloudinary: $e');
    }
  }
  
  /// Delete image from Cloudinary
  Future<bool> deleteProfileImage(String userId, String role) async {
    try {
      final publicId = 'seelai_profiles/$role/$userId';
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      
      // Generate signature for authenticated request
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
      print('Failed to delete from Cloudinary: $e');
      return false;
    }
  }
  
  /// Generate SHA-1 signature for authenticated requests
  String _generateSignature(String publicId, String timestamp) {
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}

// Create a singleton instance
final CloudinaryService cloudinaryService = CloudinaryService();