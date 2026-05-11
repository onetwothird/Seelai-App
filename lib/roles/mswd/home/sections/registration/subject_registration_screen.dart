// File: lib/roles/mswd/home/sections/registration/subject_registration_screen.dart

import 'dart:async';
import 'dart:ui';
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
  
  // Video-like Recording State
  bool _isRecording = false;
  Timer? _recordingTimer;
  Timer? _instructionTimer;
  int _currentInstructionIndex = 0;
  int _uploadedFrames = 0;
  int _recordingSeconds = 0;

  late final List<String> _instructions;

  @override
  void initState() {
    super.initState();
    _instructions = widget.subjectType == SubjectType.face 
        ? [
            'Look straight ahead',
            'Turn head slightly left',
            'Turn head slightly right',
            'Tilt head slightly up',
            'Tilt head slightly down'
          ]
        : [
            'Show the front view',
            'Rotate object slightly left',
            'Rotate object slightly right',
            'Show from a higher angle',
            'Show from a lower angle'
          ];
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;
      await _setupCameraController();
    } catch (e) {
      debugPrint('Error fetching cameras: $e');
    }
  }

  Future<void> _setupCameraController() async {
    if (_cameras == null || _cameras!.isEmpty) return;

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
    if (_cameras == null || _cameras!.length < 2 || _isRecording) return;
    setState(() {
      _isCameraInitialized = false; 
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    });
    _setupCameraController();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _instructionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  void _startRecording() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isRecording = true;
      _uploadedFrames = 0;
      _recordingSeconds = 0;
      _currentInstructionIndex = 0;
    });

    final String typeString = widget.subjectType == SubjectType.face ? 'face' : 'object';

    // 1. Timer for duration & rotating instructions every 3 seconds
    _instructionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordingSeconds++;
        if (_recordingSeconds % 3 == 0) {
          _currentInstructionIndex = (_currentInstructionIndex + 1) % _instructions.length;
        }
      });
    });

    // 2. Timer to capture and upload a frame every 1.5 seconds smoothly
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      try {
        final XFile photo = await _cameraController!.takePicture();
        
        // Fire-and-forget upload so the UI never freezes
        RoboflowService.uploadImage(photo, typeString).then((success) {
          if (success && mounted) {
            setState(() {
              _uploadedFrames++;
            });
          }
        });
      } catch (e) {
        debugPrint('Capture error during recording: $e');
      }
    });
  }

  void _stopRecording() {
    _instructionTimer?.cancel();
    _recordingTimer?.cancel();

    setState(() {
      _isRecording = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Processing complete! Saved $_uploadedFrames frames.',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFace = widget.subjectType == SubjectType.face;
    final title = isFace ? 'Register Caretaker' : 'Register Object';
    
    // Core Theme Colors
    const Color primaryColor = Color(0xFF8B5CF6); 
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
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: Icon(Icons.flip_camera_ios, color: textColor),
              onPressed: _isRecording ? null : _toggleCamera,
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
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: _isCameraInitialized
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_cameraController!),
                          
                          // --- BEAUTIFUL GLASSMORPHIC HUD OVERLAY ---
                          if (_isRecording)
                            Positioned(
                              top: 24,
                              left: 16,
                              right: 16,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E2C).withValues(alpha: 0.6), // Darker glass
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: primaryColor.withValues(alpha: 0.5),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        )
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Left Icon Indicator
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isFace ? Icons.face_retouching_natural : Icons.view_in_ar,
                                            color: primaryColor,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // Instruction Text & Timer
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.redAccent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'REC • 00:${_recordingSeconds.toString().padLeft(2, '0')}',
                                                    style: const TextStyle(
                                                      color: Colors.redAccent,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _instructions[_currentInstructionIndex],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator(color: primaryColor)),
              ),
            ),

            const SizedBox(height: 40),

            // --- CAPTURE BUTTON ---
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
              child: GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 68, 
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.redAccent : primaryColor,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.redAccent : primaryColor).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isRecording ? 'Stop Recording' : 'Start Video Capture',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
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