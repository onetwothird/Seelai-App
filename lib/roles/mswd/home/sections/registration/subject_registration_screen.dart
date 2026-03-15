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
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
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
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      await _setupCameraController();
    } catch (e) {
      debugPrint('Error fetching cameras: $e');
    }
  }

  Future<void> _setupCameraController() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    // Dispose of the previous controller if switching cameras
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    final camera = _cameras![_selectedCameraIndex];

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera controller: $e');
    }
  }

  void _toggleCamera() {
    // Only toggle if we have more than 1 camera and aren't currently uploading
    if (_cameras == null || _cameras!.length < 2 || _isUploading) return;

    setState(() {
      _isCameraInitialized = false; // Show loading while switching
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    });

    _setupCameraController();
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
        actions: [
          // --- CAMERA TOGGLE BUTTON ---
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: Icon(Icons.flip_camera_ios, color: textColor),
              onPressed: _isUploading ? null : _toggleCamera,
            ),
        ],
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
                  // Removed the border from here!
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