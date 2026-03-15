// File: lib/roles/partially_sighted/home/sections/registration/roboflow_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RoboflowService {
  static String get _apiKey => dotenv.env['ROBOFLOW_API_KEY'] ?? '';  
  static const String _faceProjectId = 'seelai-face';
  static const String _objectProjectId = 'seelai-objects';

  static Future<bool> uploadImage(XFile imageFile, String subjectType) async {
    try {
      debugPrint('Starting upload to Roboflow...');

      final String targetProjectId = (subjectType == 'face') 
          ? _faceProjectId 
          : _objectProjectId;

      debugPrint('Routing upload to project: $targetProjectId');

      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = '${subjectType}_$timestamp.jpg';

      final Uri url = Uri.parse(
          'https://api.roboflow.com/dataset/$targetProjectId/upload'
          '?api_key=$_apiKey'
          '&name=$filename'
          '&split=train' 
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: base64Image,
      );

      if (response.statusCode == 200) {
        debugPrint('Success! Image uploaded to $targetProjectId.');
        return true;
      } else {
        debugPrint('Upload Failed. Status Code: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Upload Error: $e');
      return false;
    }
  }
}