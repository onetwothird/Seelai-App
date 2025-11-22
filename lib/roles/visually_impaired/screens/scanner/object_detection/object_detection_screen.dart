// File: lib/roles/visually_impaired/screens/scanner/object_detection/object_detection_screen.dart

// ignore_for_file: curly_braces_in_flow_control_structures, avoid_print, deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/visually_impaired/camera_service.dart';
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
  String _lastReadText = '';
  bool _hasReadObjects = false;
  Timer? _readingDebounceTimer;

  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
    _initializeTts();
    _announceMode();
    loadModel();
    startObjectDetection();
  }

  @override
  void dispose() {
    try {
      _readingDebounceTimer?.cancel();
      _flutterTts.stop();
      vision.closeYoloModel();
      
      // FIXED: Only stop image stream if it's actually running
      if (widget.cameraService.isInitialized && 
          widget.cameraService.controller != null &&
          widget.cameraService.controller!.value.isStreamingImages) {
        widget.cameraService.controller!.stopImageStream().catchError((e) {
          print('Error stopping image stream: $e');
        });
      }
    } catch (e) {
      print('Error during dispose: $e');
    }
    super.dispose();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isReading = false;
        });
      }
    });

    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isReading = true;
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isReading = false;
        });
      }
    });
  }

  void _announceMode() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
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
      setState(() {
        isModelLoaded = true;
      });
      print('Model loaded successfully with GPU acceleration');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  void startObjectDetection() async {
    if (!widget.cameraService.isInitialized || widget.cameraService.controller == null) return;

    widget.cameraService.controller!.startImageStream((image) {
      if (!isDetecting && isModelLoaded) {
        isDetecting = true;
        detectObjects(image);
      }
    });
  }

  Future<void> detectObjects(CameraImage image) async {
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

      if (mounted) {
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

        // Auto-announce detected objects
        if (recognitions.isNotEmpty && !_isReading && !_hasReadObjects) {
          _announceDetectedObjects();
        }
      }
    } catch (e) {
      print('Error detecting objects: $e');
    }

    isDetecting = false;
  }

  void _announceDetectedObjects() {
    _readingDebounceTimer?.cancel();
    _readingDebounceTimer = Timer(Duration(milliseconds: 500), () {
      if (recognitions.isNotEmpty && mounted) {
        final objects = recognitions
            .map((r) => '${r['tag']} ${((r['box'][4] ?? 0) * 100).toStringAsFixed(0)}%')
            .join(', ');

        if (objects != _lastReadText && !_isReading) {
          _lastReadText = objects;
          _hasReadObjects = true;
          _flutterTts.speak('Detected: $objects');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Detected: $objects'),
              backgroundColor: Colors.green,
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

    return Scaffold(
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
              previewH: widget.cameraService.controller!.value.previewSize!.width,
              previewW: widget.cameraService.controller!.value.previewSize!.height,
              screenH: screenHeight,
              screenW: screenWidth,
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
                onTap: () => Navigator.pop(context),
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
                      ? 'Detecting: ${recognitions.length} objects'
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
      child: Row(
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
                  ? 'Speaking...'
                  : recognitions.isNotEmpty
                      ? 'Objects detected'
                      : 'Scanning...',
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
    );
  }
}

class BoundingBoxes extends StatelessWidget {
  final List<Map<String, dynamic>> recognitions;
  final double previewH;
  final double previewW;
  final double screenH;
  final double screenW;

  const BoundingBoxes({
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
      painter: BoxPainter(
        recognitions: recognitions,
        previewH: previewH,
        previewW: previewW,
        screenH: screenH,
        screenW: screenW,
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

  BoxPainter({
    required this.recognitions,
    required this.previewH,
    required this.previewW,
    required this.screenH,
    required this.screenW,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

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