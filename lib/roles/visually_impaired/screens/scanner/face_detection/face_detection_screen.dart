// File: lib/roles/visually_impaired/screens/scanner/face_detection/face_detection_screen.dart

// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/visually_impaired/camera_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FaceDetectionScreen extends StatefulWidget {
  final CameraService cameraService;
  final bool isDarkMode;

  const FaceDetectionScreen({
    super.key,
    required this.cameraService,
    required this.isDarkMode,
  });

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  late FlutterVision vision;
  late List<Map<String, dynamic>> recognitions = [];
  bool isDetecting = false;
  bool isModelLoaded = false;
  int frameCount = 0;
  DateTime? lastFrameTime;
  double fps = 0.0;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isReading = false;
  bool _isStreamRunning = false;
  bool _isDisposing = false;
  
  // Detection state - matching object_detection_screen.dart
  String _lastDetectedFaces = '';
  bool _readingCompleted = false;

  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
    _initializeTts();
    _announceMode();
    loadModel();
    startFaceDetection();
  }

  @override
  void dispose() {
    _isDisposing = true;
    _cleanupResources();
    super.dispose();
  }

  Future<void> _cleanupResources() async {
    try {
      await _flutterTts.stop();
      
      if (_isStreamRunning && 
          widget.cameraService.controller != null &&
          widget.cameraService.controller!.value.isStreamingImages) {
        try {
          await widget.cameraService.controller!.stopImageStream();
          _isStreamRunning = false;
        } catch (_) {}
      }
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      try {
        await vision.closeYoloModel();
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      if (mounted && !_isDisposing) {
        setState(() {
          _isReading = false;
          _readingCompleted = true;
        });
      }
    });

    _flutterTts.setStartHandler(() {
      if (mounted && !_isDisposing) {
        setState(() {
          _isReading = true;
          _readingCompleted = false;
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted && !_isDisposing) {
        setState(() {
          _isReading = false;
          _readingCompleted = true;
        });
      }
    });
  }

  void _announceMode() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isDisposing) {
        _flutterTts.speak('Face detection mode activated. Looking for faces.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face detection mode activated - Looking for faces'),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> loadModel() async {
    try {
      await vision.loadYoloModel(
        labels: 'assets/face_model/labels.txt',
        modelPath: 'assets/face_model/face_detection.tflite',
        modelVersion: "yolov8",
        numThreads: 4,
        useGpu: true,
      );
      if (mounted && !_isDisposing) {
        setState(() => isModelLoaded = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading face model. Check model files.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void startFaceDetection() async {
    if (_isDisposing) return;
    if (!widget.cameraService.isInitialized || 
        widget.cameraService.controller == null) return;
    
    if (widget.cameraService.controller!.value.isStreamingImages) return;

    try {
      await widget.cameraService.controller!.startImageStream((image) {
        if (!isDetecting && isModelLoaded && !_isDisposing) {
          isDetecting = true;
          detectFaces(image);
        }
      });
      _isStreamRunning = true;
    } catch (_) {}
  }

  Future<void> detectFaces(CameraImage image) async {
    if (_isDisposing) {
      isDetecting = false;
      return;
    }

    final now = DateTime.now();

    try {
      final result = await vision.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.4,
        confThreshold: 0.3,
        classThreshold: 0.4,
      );

      if (mounted && !_isDisposing) {
        setState(() {
          recognitions = result;
          frameCount++;

          if (lastFrameTime != null) {
            final elapsed = now.difference(lastFrameTime!).inMilliseconds;
            if (elapsed > 0) {
              fps = 1000 / elapsed;
            }
          }
          lastFrameTime = now;
        });

        // Auto-detect and read faces (matching object_detection_screen.dart)
        if (recognitions.isNotEmpty && !_isReading) {
          await _detectAndReadFaces();
        } else if (recognitions.isEmpty) {
          _readingCompleted = false;
        }
      }
    } catch (_) {}

    isDetecting = false;
  }

  /// Detect and read faces - matching object_detection_screen.dart pattern
  Future<void> _detectAndReadFaces() async {
    if (_isDisposing || _isReading) return;
    
    try {
      final faceCount = recognitions.length;
      
      if (faceCount > 0) {
        // Get the class names from detections (same as object detection)
        final detectedFacesText = recognitions
            .map((r) => r['tag'] ?? 'face')
            .join(', ');
        
        // Check if it's different from last read
        bool isDifferentFaces = (detectedFacesText.length - _lastDetectedFaces.length).abs() > 2 ||
                               !detectedFacesText.contains(_lastDetectedFaces.substring(0, _lastDetectedFaces.length.clamp(0, 4)));
        
        if ((isDifferentFaces || _lastDetectedFaces.isEmpty) && !_isReading) {
          _lastDetectedFaces = detectedFacesText;
          _readingCompleted = false;
          
          // Save to Firebase BEFORE speaking (exactly like object_detection_screen.dart)
          await _saveDetectedFacesToFirebase(faceCount);
          
          // Then speak - EXACT format: "I see face detection" or "I see face detection, face detection"
          await _flutterTts.speak('I see $detectedFacesText');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reading detected faces: $faceCount face(s)'),
                backgroundColor: Colors.purple,
                duration: Duration(milliseconds: 800),
              ),
            );
          }
        }
      } else {
        if (!_isReading) {
          _readingCompleted = true;
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Save detected faces to Firebase - matching object_detection_service.dart pattern
  Future<void> _saveDetectedFacesToFirebase(int faceCount) async {
    try {
      final userId = authService.value.currentUser?.uid;
      if (userId == null) {
        return;
      }

      final success = await faceDetectionService.saveDetectedFaces(
        userId: userId,
        detectedFaces: recognitions,
        faceCount: faceCount,
        metadata: {
          'fps': fps.toStringAsFixed(1),
          'deviceInfo': 'mobile_camera',
        },
      );

      if (success) {
        // Successfully saved
      }
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    if (!widget.cameraService.isInitialized || 
        widget.cameraService.controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: screenWidth * 0.2,
                color: white.withOpacity(0.3),
              ),
              SizedBox(height: spacingLarge),
              Text(
                'Camera Initializing...',
                style: bodyBold.copyWith(
                  color: white.withOpacity(0.7),
                  fontSize: screenWidth * 0.04,
                ),
              ),
            ],
          ),
        ),
      );
    }

    var scale = screenSize.aspectRatio * 
        widget.cameraService.controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return WillPopScope(
      onWillPop: () async {
        await _cleanupResources();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(widget.cameraService.controller!),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.6),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            if (isModelLoaded)
              FaceBoundingBoxes(
                recognitions: recognitions,
                previewH: widget.cameraService.controller!.value.previewSize!.height,
                previewW: widget.cameraService.controller!.value.previewSize!.width,
                screenH: screenHeight,
                screenW: screenWidth,
                scale: scale,
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _buildHeader(screenWidth),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _buildControls(screenWidth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Row(
        children: [
          Semantics(
            label: 'Back button',
            hint: 'Double tap to go back',
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await _cleanupResources();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                borderRadius: BorderRadius.circular(radiusMedium),
                child: Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(radiusMedium),
                    border: Border.all(
                      color: white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: white,
                    size: screenWidth * 0.06,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Face Detection',
                  style: h2.copyWith(
                    color: white,
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  recognitions.isNotEmpty
                      ? 'Reading: ${recognitions.length} face(s)'
                      : 'Looking for faces...',
                  style: caption.copyWith(
                    color: recognitions.isNotEmpty
                        ? (_isReading ? Colors.purple.shade300 : Colors.purple)
                        : white.withOpacity(0.7),
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show detected faces info (matching object_detection_screen.dart)
          if (_lastDetectedFaces.isNotEmpty)
            Container(
              margin: EdgeInsets.only(bottom: spacingLarge),
              padding: EdgeInsets.all(spacingMedium),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(radiusMedium),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.purple,
                        size: screenWidth * 0.05,
                      ),
                      SizedBox(width: spacingSmall),
                      Expanded(
                        child: Text(
                          'Faces Auto-Read & Saved',
                          style: bodyBold.copyWith(
                            color: white,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacingSmall),
                  Text(
                    'Detected: $_lastDetectedFaces',
                    style: caption.copyWith(
                      color: white.withOpacity(0.7),
                      fontSize: screenWidth * 0.03,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isReading
                    ? Icons.volume_up
                    : recognitions.isNotEmpty
                        ? Icons.face
                        : Icons.face_outlined,
                color: _isReading
                    ? Colors.purple.shade300
                    : recognitions.isNotEmpty
                        ? Colors.purple
                        : Colors.purple.shade200,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: spacingSmall),
              Flexible(
                child: Text(
                  _isReading
                      ? 'Reading faces...'
                      : recognitions.isNotEmpty
                          ? (_readingCompleted ? 'Done - Ready for next scan' : 'Auto-scanning active')
                          : 'Looking for faces...',
                  style: bodyBold.copyWith(
                    color: white.withOpacity(0.9),
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
              SizedBox(width: spacingLarge),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: spacingSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(radiusSmall),
                  border: Border.all(color: Colors.purple.withOpacity(0.4)),
                ),
                child: Text(
                  'FPS: ${fps.toStringAsFixed(1)}',
                  style: caption.copyWith(
                    color: Colors.purple,
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FaceBoundingBoxes extends StatelessWidget {
  final List<Map<String, dynamic>> recognitions;
  final double previewH;
  final double previewW;
  final double screenH;
  final double screenW;
  final double scale;

  const FaceBoundingBoxes({
    super.key,
    required this.recognitions,
    required this.previewH,
    required this.previewW,
    required this.screenH,
    required this.screenW,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    if (recognitions.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: FaceBoxPainter(
        recognitions: recognitions,
        previewH: previewH,
        previewW: previewW,
        screenH: screenH,
        screenW: screenW,
        scale: scale,
      ),
    );
  }
}

class FaceBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> recognitions;
  final double previewH;
  final double previewW;
  final double screenH;
  final double screenW;
  final double scale;

  FaceBoxPainter({
    required this.recognitions,
    required this.previewH,
    required this.previewW,
    required this.screenH,
    required this.screenW,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final cameraAspectRatio = previewH / previewW;
    final screenAspectRatio = size.width / size.height;

    double scaleX, scaleY;
    double offsetX = 0, offsetY = 0;

    if (screenAspectRatio > cameraAspectRatio) {
      scaleY = size.height / previewW;
      scaleX = scaleY;
      offsetX = (size.width - (previewH * scaleX)) / 2;
    } else {
      scaleX = size.width / previewH;
      scaleY = scaleX;
      offsetY = (size.height - (previewW * scaleY)) / 2;
    }

    for (var recognition in recognitions) {
      final box = recognition['box'];

      double x = box[0].toDouble();
      double y = box[1].toDouble();
      double w = box[2].toDouble();
      double h = box[3].toDouble();

      final left = (x * scaleX) + offsetX;
      final top = (y * scaleY) + offsetY;
      final width = w * scaleX;
      final height = h * scaleY;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, width, height),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, paint);

      final cornerLength = (width * 0.15).clamp(15.0, 30.0);
      final cornerPaint = Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;

      // Draw corner brackets
      canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), cornerPaint);
      canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
      canvas.drawLine(Offset(left + width - cornerLength, top), Offset(left + width, top), cornerPaint);
      canvas.drawLine(Offset(left + width, top), Offset(left + width, top + cornerLength), cornerPaint);
      canvas.drawLine(Offset(left, top + height - cornerLength), Offset(left, top + height), cornerPaint);
      canvas.drawLine(Offset(left, top + height), Offset(left + cornerLength, top + height), cornerPaint);
      canvas.drawLine(Offset(left + width - cornerLength, top + height), Offset(left + width, top + height), cornerPaint);
      canvas.drawLine(Offset(left + width, top + height - cornerLength), Offset(left + width, top + height), cornerPaint);

      final label = recognition['tag'] ?? 'Person';
      final confidence = box[4] ?? 0.0;
      final text = '$label ${(confidence * 100).toStringAsFixed(0)}%';

      final fontSize = (width * 0.08).clamp(12.0, 18.0);

      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.purple,
      );

      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final labelPadding = (width * 0.03).clamp(6.0, 10.0);
      final labelHeight = (fontSize * 1.8).clamp(20.0, 28.0);

      final labelRect = Rect.fromLTWH(
        left,
        top - labelHeight - 2,
        textPainter.width + (labelPadding * 2),
        labelHeight,
      );
      
      final labelRRect = RRect.fromRectAndRadius(
        labelRect,
        const Radius.circular(4),
      );
      
      canvas.drawRRect(labelRRect, Paint()..color = Colors.purple);
      textPainter.paint(
        canvas, 
        Offset(left + labelPadding, top - labelHeight + (labelHeight - fontSize) / 2 - 2)
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}