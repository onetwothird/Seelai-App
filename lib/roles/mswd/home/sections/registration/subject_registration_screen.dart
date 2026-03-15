// File: lib/roles/mswd/home/sections/registration/subject_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:seelai_app/themes/constants.dart';
import 'roboflow_service.dart';

enum SubjectType { face, object }

class SubjectRegistrationScreen extends StatefulWidget {
  final bool isDarkMode;
  final SubjectType subjectType;

  const SubjectRegistrationScreen({
    super.key,
    required this.isDarkMode,
    required this.subjectType,
  });

  @override
  State<SubjectRegistrationScreen> createState() => _SubjectRegistrationScreenState();
}

class _SubjectRegistrationScreenState extends State<SubjectRegistrationScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Get list of available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Use the first available camera (usually the back camera)
      final camera = cameras.first; 

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureAndUpload() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Take the picture
      final XFile photo = await _cameraController!.takePicture();

      // 2. Upload to Roboflow
      final String typeString = widget.subjectType == SubjectType.face ? 'face' : 'object';
      final bool success = await RoboflowService.uploadImage(photo, typeString);

      // 3. Show Result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Successfully sent to Roboflow!' 
                : 'Failed to upload image. Check console.'),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFace = widget.subjectType == SubjectType.face;
    final title = isFace ? 'Register Caretaker Face' : 'Register New Object';
    
    // Set to your requested primary color
    final Color primaryColor = const Color(0xFF8B5CF6); 
    
    final bgColor = widget.isDarkMode ? const Color(0xFF0A0E27) : backgroundPrimary;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // --- LIVE CAMERA PREVIEW ---
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.black,
                  border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 2),
                ),
                child: _isCameraInitialized
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_cameraController!),
                          // Loading overlay during upload
                          if (_isUploading)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),

            const SizedBox(height: 40),

            // --- CAPTURE BUTTON ---
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
              child: GestureDetector(
                onTap: _isUploading ? null : _captureAndUpload,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 64,
                  decoration: BoxDecoration(
                    color: _isUploading ? Colors.grey : primaryColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      if (!_isUploading)
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isUploading ? 'Uploading...' : 'Take Photo & Upload',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}