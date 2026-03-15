// File: lib/roles/mswd/home/sections/registration/roboflow_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart'; // <-- Added this import
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RoboflowService {
  static String get _apiKey => dotenv.env['ROBOFLOW_API_KEY'] ?? '';
  static const String _faceProjectId = 'seelai-face';
  static const String _objectProjectId = 'seelai-objects';

  static Future<bool> uploadImage(XFile imageFile, String subjectType) async {
    try {
      debugPrint('Starting upload to Roboflow...'); // <-- Changed to debugPrint

      // 1. Determine which project to send the image to
      final String targetProjectId = (subjectType == 'face') 
          ? _faceProjectId 
          : _objectProjectId;

      debugPrint('Routing upload to project: $targetProjectId'); // <-- Changed

      // 2. Convert image to Base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 3. Create a unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = '${subjectType}_$timestamp.jpg';

      // 4. Build the API URL
      final Uri url = Uri.parse(
          'https://api.roboflow.com/dataset/$targetProjectId/upload'
          '?api_key=$_apiKey'
          '&name=$filename'
          '&split=train' 
      );

      // 5. Send to Roboflow
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: base64Image,
      );

      // 6. Check the result
      if (response.statusCode == 200) {
        debugPrint('Success! Image uploaded to $targetProjectId.'); // <-- Changed
        return true;
      } else {
        debugPrint('Upload Failed. Status Code: ${response.statusCode}'); // <-- Changed
        debugPrint('Response: ${response.body}'); // <-- Changed
        return false;
      }
    } catch (e) {
      debugPrint('Upload Error: $e'); // <-- Changed
      return false;
    }
  }
}