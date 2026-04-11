// File: lib/storage/cloudinary_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  static const String uploadPresetProfile = 'profile_images';
  static const String uploadPresetDetections = 'detection_images';

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

  /// Upload SOS Contact image to Cloudinary
  Future<String?> uploadContactImage(File imageFile, String patientId) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      request.fields['upload_preset'] = uploadPresetProfile;
      request.fields['folder'] = 'seelai_sos_contacts/$patientId';

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'] as String;
      } else {
        var responseData = await response.stream.bytesToString();
        debugPrint('❌ Contact upload failed: ${response.statusCode} - $responseData');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Failed to upload contact image: $e');
      return null;
    }
  }

  /// Upload a detection snapshot to Cloudinary
  /// Stores under: detected_images/face/{userId}
  ///               detected_images/object/{userId}
  ///               detected_images/text/{userId}
  Future<String?> uploadDetectionImage(
    File imageFile,
    String userId,
    String detectionType, // 'face' | 'object' | 'text'
  ) async {
    try {
      // ✅ Use SIGNED upload so folder override always works
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      final folder = 'detected_images/$detectionType/$userId';
      final signature = _generateDetectionSignature(folder: folder, timestamp: timestamp);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['folder'] = folder;
      request.fields['signature'] = signature;
      // ✅ NO upload_preset needed for signed uploads

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      debugPrint('📤 Uploading detection image to: $folder');
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseData);
        final url = jsonResponse['secure_url'] as String;
        debugPrint('✅ Detection image uploaded: $url');
        return url;
      } else {
        debugPrint('❌ Detection upload failed: ${response.statusCode} - $responseData');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Failed to upload detection image: $e');
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

  // ✅ Signature for detection uploads (signs: folder + timestamp)
  String _generateDetectionSignature({required String folder, required String timestamp}) {
    final stringToSign = 'folder=$folder&timestamp=$timestamp$apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  // Existing signature for delete
  String _generateSignature(String publicId, String timestamp) {
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}

final CloudinaryService cloudinaryService = CloudinaryService();