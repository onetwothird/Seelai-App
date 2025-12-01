// File: lib/roles/visually_impaired/screens/scanner/object_detection/object_detection_screen.dart

// ignore_for_file: curly_braces_in_flow_control_structures, avoid_print, deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/visually_impaired/camera_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ObjectDetectionScreen extends StatefulWidget {
  final CameraService cameraService;
  final bool isDarkMode;

  const ObjectDetectionScreen({
    super.key,
    required this.cameraService,
    required this.isDarkMode,
  });

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
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
  
  // Flash/brightness related
  bool _isLowLight = false;
  bool _isFlashOn = false;
  bool _showFlashIndicator = false;
  Timer? _flashIndicatorTimer;
  
  // Detection state - matching text_reader_screen.dart
  String _lastDetectedObjects = '';
  bool _readingCompleted = false;
  
  // Brightness monitoring
  int _darkFrameCount = 0;
  int _brightFrameCount = 0;
  Timer? _brightnessMonitorTimer;

  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
    _initializeTts();
    _announceMode();
    loadModel();
    _startBrightnessMonitoring();
  }

  @override
  void dispose() {
    _isDisposing = true;
    _cleanupResources();
    super.dispose();
  }

  Future<void> _cleanupResources() async {
    try {
      _flashIndicatorTimer?.cancel();
      _brightnessMonitorTimer?.cancel();
      
      await _flutterTts.stop();
      await _turnOffFlash();
      
      if (_isStreamRunning && 
          widget.cameraService.controller != null &&
          widget.cameraService.controller!.value.isStreamingImages) {
        try {
          await widget.cameraService.controller!.stopImageStream();
          _isStreamRunning = false;
        } catch (e) {
          // Silent fail
        }
      }
      
      await Future.delayed(Duration(milliseconds: 100));
      
      try {
        await vision.closeYoloModel();
      } catch (e) {
        // Silent fail
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _initializeTts() async {
    try {
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
    } catch (e) {
      // Silent fail
    }
  }

  void _announceMode() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted && !_isDisposing) {
        _flutterTts.speak('Object detection mode activated. Point camera at objects.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Object detection mode activated - Point camera at objects'),
            backgroundColor: Colors.orange,
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
        labels: 'assets/object_model/labels.txt',
        modelPath: 'assets/object_model/objects.tflite',
        modelVersion: "yolov8",
        numThreads: 4,
        useGpu: true,
      );
      if (mounted && !_isDisposing) {
        setState(() {
          isModelLoaded = true;
        });
        startObjectDetection();
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _startBrightnessMonitoring() {
    _brightnessMonitorTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (_isDisposing || !mounted) {
        timer.cancel();
        return;
      }
      
      // Check if environment is dark based on detection results
      if (recognitions.isEmpty || _hasPoorQualityDetections()) {
        _darkFrameCount++;
        _brightFrameCount = 0;
        
        // Turn on flash if dark for 3 consecutive checks (6 seconds)
        if (_darkFrameCount >= 3 && !_isFlashOn) {
          await _turnOnFlash();
        }
      } else {
        _brightFrameCount++;
        _darkFrameCount = 0;
        
        // Turn off flash if bright for 3 consecutive checks (6 seconds)
        if (_brightFrameCount >= 3 && _isFlashOn) {
          await _turnOffFlash();
        }
      }
    });
  }

  bool _hasPoorQualityDetections() {
    if (recognitions.isEmpty) return true;
    
    int lowConfidenceCount = 0;
    for (var detection in recognitions) {
      double confidence = detection['box'][4] ?? 0.0;
      if (confidence < 0.4) {
        lowConfidenceCount++;
      }
    }
    
    return lowConfidenceCount > (recognitions.length / 2);
  }

  void startObjectDetection() async {
    if (_isDisposing) return;
    if (!widget.cameraService.isInitialized || widget.cameraService.controller == null) return;
    if (!isModelLoaded) return;
    
    if (widget.cameraService.controller!.value.isStreamingImages) {
      return;
    }

    try {
      await widget.cameraService.controller!.startImageStream((image) {
        if (!isDetecting && isModelLoaded && !_isDisposing) {
          isDetecting = true;
          detectObjects(image);
        }
      });
      _isStreamRunning = true;
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _turnOnFlash() async {
    try {
      final controller = widget.cameraService.controller;
      if (controller != null && mounted && !_isFlashOn) {
        await controller.setFlashMode(FlashMode.torch);
        setState(() {
          _isFlashOn = true;
          _isLowLight = true;
          _showFlashIndicator = true;
        });
        
        _flutterTts.speak('Low light detected. Flashlight turned on.');
        
        _flashIndicatorTimer?.cancel();
        _flashIndicatorTimer = Timer(Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showFlashIndicator = false;
            });
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.flashlight_on, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Low light - Flashlight mode ON'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _turnOffFlash() async {
    try {
      final controller = widget.cameraService.controller;
      if (controller != null && mounted && _isFlashOn) {
        await controller.setFlashMode(FlashMode.off);
        setState(() {
          _isFlashOn = false;
          _isLowLight = false;
          _showFlashIndicator = false;
        });
        _flashIndicatorTimer?.cancel();
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _toggleFlashManually() async {
    if (_isFlashOn) {
      await _turnOffFlash();
      _flutterTts.speak('Flashlight turned off.');
    } else {
      await _turnOnFlash();
    }
  }

  Future<void> detectObjects(CameraImage image) async {
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
        confThreshold: 0.25,
        classThreshold: 0.5,
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

        // Auto-detect and read objects (like text_reader_screen.dart)
        if (recognitions.isNotEmpty && !_isReading) {
          await _detectAndReadObjects();
        }
      }
    } catch (e) {
      // Silent fail
    }

    isDetecting = false;
  }

  /// Detect and read objects - matching text_reader_screen.dart pattern
  Future<void> _detectAndReadObjects() async {
    if (_isDisposing || _isReading) return;
    
    try {
      // Simple object names only - no confidence percentages
      final detectedObjectsText = recognitions
          .map((r) => '${r['tag']}')
          .join(', ');
      
      if (detectedObjectsText.isNotEmpty) {
        // Check if it's different from last read (similar to text reader)
        bool isDifferentObjects = (detectedObjectsText.length - _lastDetectedObjects.length).abs() > 5 ||
                                 !detectedObjectsText.contains(_lastDetectedObjects.substring(0, _lastDetectedObjects.length.clamp(0, 10)));
        
        if ((isDifferentObjects || _lastDetectedObjects.isEmpty) && !_isReading) {
          _lastDetectedObjects = detectedObjectsText;
          _readingCompleted = false;
          
          // Save to Firebase BEFORE speaking (exactly like text_reader_screen.dart)
          await _saveDetectedObjectsToFirebase(recognitions.length);
          
          // Then speak - simple format: "I see book, bottle, chips"
          await _flutterTts.speak('I see $detectedObjectsText');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reading all detected objects: ${recognitions.length} items'),
                backgroundColor: Colors.green,
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

  /// Save detected objects to Firebase - matching text_scan_service.dart pattern
  Future<void> _saveDetectedObjectsToFirebase(int objectCount) async {
    try {
      final userId = authService.value.currentUser?.uid;
      if (userId == null) {
        return;
      }

      final success = await objectDetectionService.saveDetectedObjects(
        userId: userId,
        detectedObjects: recognitions,
        objectCount: objectCount,
        metadata: {
          'flashUsed': _isFlashOn,
          'lowLight': _isLowLight,
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
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            if (isModelLoaded)
              BoundingBoxes(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLowLight && _isFlashOn)
                      _buildFlashIndicator(screenWidth),
                    _buildControls(screenWidth),
                  ],
                ),
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
                  'Detect Objects',
                  style: h2.copyWith(
                    color: white,
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  recognitions.isNotEmpty
                      ? 'Reading: ${recognitions.length} objects'
                      : 'Looking for objects...',
                  style: caption.copyWith(
                    color: recognitions.isNotEmpty
                        ? (_isReading ? Colors.orange : Colors.green)
                        : white.withOpacity(0.7),
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: _isFlashOn ? 'Flashlight is on. Double tap to turn off' : 'Flashlight is off. Double tap to turn on',
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleFlashManually,
                borderRadius: BorderRadius.circular(radiusSmall),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: screenWidth * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: _isFlashOn 
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(radiusSmall),
                    border: Border.all(
                      color: _isFlashOn ? Colors.orange : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isFlashOn ? Icons.flashlight_on : Icons.flashlight_off,
                        color: _isFlashOn ? Colors.orange : Colors.grey[400],
                        size: screenWidth * 0.045,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        _isFlashOn ? 'ON' : 'OFF',
                        style: caption.copyWith(
                          color: _isFlashOn ? Colors.orange : Colors.grey[400],
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashIndicator(double screenWidth) {
    return AnimatedOpacity(
      opacity: _showFlashIndicator ? 1.0 : 0.0,
      duration: Duration(milliseconds: 500),
      child: Container(
        margin: EdgeInsets.only(
          bottom: spacingMedium,
          left: screenWidth * 0.04,
          right: screenWidth * 0.04,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: spacingMedium,
        ),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flashlight_on,
              color: Colors.white,
              size: screenWidth * 0.05,
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'Low light - Flashlight mode ON',
              style: bodyBold.copyWith(
                color: Colors.white,
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
          // Show detected objects info (matching text_reader_screen.dart)
          if (_lastDetectedObjects.isNotEmpty)
            Container(
              margin: EdgeInsets.only(bottom: spacingLarge),
              padding: EdgeInsets.all(spacingMedium),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(radiusMedium),
                border: Border.all(
                  color: Colors.green.withOpacity(0.4),
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
                        color: Colors.green,
                        size: screenWidth * 0.05,
                      ),
                      SizedBox(width: spacingSmall),
                      Expanded(
                        child: Text(
                          'Objects Auto-Read & Saved',
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
                    _lastDetectedObjects.length > 80 
                        ? '${_lastDetectedObjects.substring(0, 80)}...' 
                        : _lastDetectedObjects,
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
                        ? Icons.check_circle
                        : Icons.search,
                color: _isReading
                    ? Colors.orange
                    : recognitions.isNotEmpty
                        ? Colors.green
                        : Colors.orange,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: spacingSmall),
              Flexible(
                child: Text(
                  _isReading
                      ? 'Reading objects...'
                      : recognitions.isNotEmpty
                          ? (_readingCompleted ? 'Done - Ready for next scan' : 'Auto-scanning active')
                          : 'Looking for objects...',
                  style: bodyBold.copyWith(
                    color: white.withOpacity(0.9),
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
              SizedBox(width: spacingLarge),
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: spacingSmall),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(radiusSmall),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: Text(
                  'FPS: ${fps.toStringAsFixed(1)}',
                  style: caption.copyWith(
                    color: Colors.orange,
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

class BoundingBoxes extends StatelessWidget {
  final List<Map<String, dynamic>> recognitions;
  final double previewH;
  final double previewW;
  final double screenH;
  final double screenW;
  final double scale;

  const BoundingBoxes({
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
      painter: BoxPainter(
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

class BoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> recognitions;
  final double previewH;
  final double previewW;
  final double screenH;
  final double screenW;
  final double scale;

  BoxPainter({
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
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final cameraAspectRatio = previewW / previewH;
    final screenAspectRatio = size.width / size.height;

    double displayWidth, displayHeight;
    double offsetX = 0, offsetY = 0;

    if (screenAspectRatio > cameraAspectRatio) {
      displayHeight = size.height;
      displayWidth = displayHeight * cameraAspectRatio;
      offsetX = (size.width - displayWidth) / 2;
    } else {
      displayWidth = size.width;
      displayHeight = displayWidth / cameraAspectRatio;
      offsetY = (size.height - displayHeight) / 2;
    }

    displayWidth *= scale;
    displayHeight *= scale;
    offsetX = (size.width - displayWidth) / 2;
    offsetY = (size.height - displayHeight) / 2;

    for (var recognition in recognitions) {
      final box = recognition['box'];

      double x = box[0].toDouble();
      double y = box[1].toDouble();
      double w = box[2].toDouble();
      double h = box[3].toDouble();

      final scaleW = displayWidth / previewH;
      final scaleH = displayHeight / previewW;

      final left = (x * scaleW) + offsetX;
      final top = (y * scaleH) + offsetY;
      final width = w * scaleW;
      final height = h * scaleH;

      canvas.drawRect(
        Rect.fromLTWH(left, top, width, height),
        paint,
      );

      final label = recognition['tag'] ?? '';
      final confidence = box[4] ?? 0.0;
      final text = '$label ${(confidence * 100).toStringAsFixed(0)}%';

      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.green,
      );

      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final labelRect = Rect.fromLTWH(
        left,
        top - 20,
        textPainter.width + 8,
        20,
      );
      canvas.drawRect(labelRect, Paint()..color = Colors.green);

      textPainter.paint(canvas, Offset(left + 4, top - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}