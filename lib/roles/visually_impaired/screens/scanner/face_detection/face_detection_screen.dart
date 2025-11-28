// File: lib/roles/visually_impaired/screens/scanner/face_detection/face_detection_screen.dart

// ignore_for_file: curly_braces_in_flow_control_structures, avoid_print, deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/visually_impaired/camera_service.dart';
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
  String _lastReadText = '';
  bool _hasReadFaces = false;
  Timer? _readingDebounceTimer;
  bool _isStreamRunning = false;
  bool _isDisposing = false;
  int _detectedFaceCount = 0;
  List<String> _detectedCaretakers = [];

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
      // Cancel timers first
      _readingDebounceTimer?.cancel();
      
      // Stop TTS
      await _flutterTts.stop();
      
      // Stop image stream if running
      if (_isStreamRunning && 
          widget.cameraService.controller != null &&
          widget.cameraService.controller!.value.isStreamingImages) {
        try {
          await widget.cameraService.controller!.stopImageStream();
          _isStreamRunning = false;
          print('✅ Image stream stopped successfully');
        } catch (e) {
          print('⚠️ Error stopping image stream: $e');
        }
      }
      
      // Small delay to ensure stream is fully stopped
      await Future.delayed(Duration(milliseconds: 100));
      
      // Close vision model
      try {
        await vision.closeYoloModel();
        print('✅ YOLO model closed successfully');
      } catch (e) {
        print('⚠️ Error closing YOLO model: $e');
      }
    } catch (e) {
      print('❌ Error during cleanup: $e');
    }
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      if (mounted && !_isDisposing) {
        setState(() {
          _isReading = false;
        });
      }
    });

    _flutterTts.setStartHandler(() {
      if (mounted && !_isDisposing) {
        setState(() {
          _isReading = true;
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted && !_isDisposing) {
        setState(() {
          _isReading = false;
        });
      }
    });
  }

  void _announceMode() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted && !_isDisposing) {
        _flutterTts.speak('Face detection mode activated. Point camera at faces.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face detection mode activated - Point camera at faces'),
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
        modelPath: 'assets/face_model/face-detection.tflite',
        modelVersion: "yolov8",
        numThreads: 4,
        useGpu: true,
      );
      if (mounted && !_isDisposing) {
        setState(() {
          isModelLoaded = true;
        });
      }
      print('✅ Face detection model loaded successfully with GPU acceleration');
    } catch (e) {
      print('❌ Error loading face detection model: $e');
    }
  }

  void startFaceDetection() async {
    if (_isDisposing) return;
    if (!widget.cameraService.isInitialized || widget.cameraService.controller == null) return;
    
    // Check if stream is already running
    if (widget.cameraService.controller!.value.isStreamingImages) {
      print('⚠️ Image stream already running');
      return;
    }

    try {
      await widget.cameraService.controller!.startImageStream((image) {
        if (!isDetecting && isModelLoaded && !_isDisposing) {
          isDetecting = true;
          detectFaces(image);
        }
      });
      _isStreamRunning = true;
      print('✅ Image stream started successfully');
    } catch (e) {
      print('❌ Error starting image stream: $e');
    }
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
        confThreshold: 0.5,  // Higher confidence for faces
        classThreshold: 0.6,
      );

      if (mounted && !_isDisposing) {
        setState(() {
          recognitions = result;
          _detectedFaceCount = result.length;
          
          // Extract caretaker names from detected faces
          _detectedCaretakers = result
              .map((r) => r['tag']?.toString() ?? 'Unknown')
              .toSet()
              .toList();
          
          frameCount++;

          if (lastFrameTime != null) {
            final elapsed = now.difference(lastFrameTime!).inMilliseconds;
            if (elapsed > 0) {
              fps = 1000 / elapsed;
            }
          }
          lastFrameTime = now;
        });

        // Auto-announce detected faces
        if (recognitions.isNotEmpty && !_isReading && !_hasReadFaces) {
          _announceDetectedFaces();
        } else if (recognitions.isEmpty) {
          // Reset flag when no faces detected
          _hasReadFaces = false;
        }
      }
    } catch (e) {
      print('❌ Error detecting faces: $e');
    }

    isDetecting = false;
  }

  void _announceDetectedFaces() {
    if (_isDisposing) return;
    
    _readingDebounceTimer?.cancel();
    _readingDebounceTimer = Timer(Duration(milliseconds: 800), () {
      if (recognitions.isNotEmpty && mounted && !_isDisposing) {
        // Create announcement text
        String announcement;
        if (_detectedFaceCount == 1) {
          final name = recognitions[0]['tag'] ?? 'Unknown person';
          final confidence = ((recognitions[0]['box'][4] ?? 0) * 100).toStringAsFixed(0);
          announcement = 'Detected: $name with $confidence percent confidence';
        } else {
          final names = _detectedCaretakers.join(', ');
          announcement = 'Detected $_detectedFaceCount faces: $names';
        }

        if (announcement != _lastReadText && !_isReading) {
          _lastReadText = announcement;
          _hasReadFaces = true;
          _flutterTts.speak(announcement);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(announcement),
              backgroundColor: Colors.purple,
              duration: Duration(milliseconds: 800),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    if (!widget.cameraService.isInitialized || widget.cameraService.controller == null) {
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

    var scale = screenSize.aspectRatio * widget.cameraService.controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return WillPopScope(
      onWillPop: () async {
        // Ensure cleanup happens before popping
        await _cleanupResources();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Preview
            Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(widget.cameraService.controller!),
              ),
            ),
            
            // Gradient Overlay
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
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            
            // Bounding Boxes
            if (isModelLoaded)
              FaceBoundingBoxes(
                recognitions: recognitions,
                previewH: widget.cameraService.controller!.value.previewSize!.width,
                previewW: widget.cameraService.controller!.value.previewSize!.height,
                screenH: screenHeight,
                screenW: screenWidth,
              ),
            
            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _buildHeader(screenWidth),
              ),
            ),
            
            // Controls
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
                  // Ensure cleanup before navigation
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
                  'Detect Faces',
                  style: h2.copyWith(
                    color: white,
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  recognitions.isNotEmpty
                      ? 'Detecting: $_detectedFaceCount ${_detectedFaceCount == 1 ? "face" : "faces"}'
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Row
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
                      ? 'Speaking...'
                      : recognitions.isNotEmpty
                          ? '$_detectedFaceCount ${_detectedFaceCount == 1 ? "face" : "faces"} detected'
                          : 'Scanning for faces...',
                  style: bodyBold.copyWith(
                    color: white.withOpacity(0.9),
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
            ],
          ),
          
          // Detected Caretakers List
          if (_detectedCaretakers.isNotEmpty) ...[
            SizedBox(height: spacingMedium),
            Container(
              padding: EdgeInsets.all(spacingMedium),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(radiusMedium),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.purple,
                    size: screenWidth * 0.05,
                  ),
                  SizedBox(width: spacingSmall),
                  Expanded(
                    child: Text(
                      _detectedCaretakers.join(', '),
                      style: bodyBold.copyWith(
                        color: white,
                        fontSize: screenWidth * 0.035,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: spacingMedium),
          
          // FPS Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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

// Custom Widget for Face Bounding Boxes
class FaceBoundingBoxes extends StatelessWidget {
  final List<Map<String, dynamic>> recognitions;
  final double previewH;
  final double previewW;
  final double screenH;
  final double screenW;

  const FaceBoundingBoxes({
    super.key,
    required this.recognitions,
    required this.previewH,
    required this.previewW,
    required this.screenH,
    required this.screenW,
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
      ),
    );
  }
}

// Custom Painter for Face Bounding Boxes
class FaceBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> recognitions;
  final double previewH;
  final double previewW;
  final double screenH;
  final double screenW;

  FaceBoxPainter({
    required this.recognitions,
    required this.previewH,
    required this.previewW,
    required this.screenH,
    required this.screenW,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    for (var recognition in recognitions) {
      final box = recognition['box'];

      double x = box[0].toDouble();
      double y = box[1].toDouble();
      double w = box[2].toDouble();
      double h = box[3].toDouble();

      final scaleW = size.width / previewW;
      final scaleH = size.height / previewH;

      final left = x * scaleW;
      final top = y * scaleH;
      final width = w * scaleW;
      final height = h * scaleH;

      // Draw rounded rectangle for face
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, width, height),
        Radius.circular(12),
      );
      canvas.drawRRect(rect, paint);

      // Draw corners for enhanced effect
      final cornerLength = 20.0;
      final cornerPaint = Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0;

      // Top-left corner
      canvas.drawLine(
        Offset(left, top + cornerLength),
        Offset(left, top),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(left, top),
        Offset(left + cornerLength, top),
        cornerPaint,
      );

      // Top-right corner
      canvas.drawLine(
        Offset(left + width - cornerLength, top),
        Offset(left + width, top),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(left + width, top),
        Offset(left + width, top + cornerLength),
        cornerPaint,
      );

      // Bottom-left corner
      canvas.drawLine(
        Offset(left, top + height - cornerLength),
        Offset(left, top + height),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(left, top + height),
        Offset(left + cornerLength, top + height),
        cornerPaint,
      );

      // Bottom-right corner
      canvas.drawLine(
        Offset(left + width - cornerLength, top + height),
        Offset(left + width, top + height),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(left + width, top + height - cornerLength),
        Offset(left + width, top + height),
        cornerPaint,
      );

      // Draw label
      final label = recognition['tag'] ?? 'Unknown';
      final confidence = box[4] ?? 0.0;
      final text = '$label ${(confidence * 100).toStringAsFixed(0)}%';

      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.purple,
      );

      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Position label above the box
      final labelRect = Rect.fromLTWH(
        left,
        top - 24,
        textPainter.width + 12,
        24,
      );
      
      final labelRRect = RRect.fromRectAndRadius(
        labelRect,
        Radius.circular(6),
      );
      
      canvas.drawRRect(labelRRect, Paint()..color = Colors.purple);
      textPainter.paint(canvas, Offset(left + 6, top - 22));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}