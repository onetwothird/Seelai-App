// File: lib/roles/partially_sighted/models/object_detection_controller.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:seelai_app/firebase/partially_sighted/camera_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/storage/cloudinary_service.dart';

class ObjectDetectionController {
  final CameraService cameraService;
  final Function(ObjectDetectionState) onStateChanged;
  
  late FlutterVision _vision;
  late FlutterTts _flutterTts;
  
  List<Map<String, dynamic>> recognitions = [];
  bool isDetecting = false;
  bool isModelLoaded = false;
  bool isReading = false;
  bool readingCompleted = false;
  bool isStreamRunning = false;
  bool isDisposing = false;
  
  int frameCount = 0;
  DateTime? lastFrameTime;
  double fps = 0.0;
  
  bool isLowLight = false;
  bool isFlashOn = false;
  bool showFlashIndicator = false;
  Timer? _flashIndicatorTimer;
  
  String lastDetectedObjects = '';
  DateTime _lastSpeechTime = DateTime.now();
  
  int _darkFrameCount = 0;
  int _brightFrameCount = 0;

  ObjectDetectionController({
    required this.cameraService,
    required this.onStateChanged,
  });

  Future<void> initialize() async {
    _vision = FlutterVision();
    _flutterTts = FlutterTts();
    
    await _initializeTts();
    loadModel();
    _announceMode();
  }

  Future<void> dispose() async {
    isDisposing = true;
    await _cleanupResources();
  }

  Future<void> _cleanupResources() async {
    try {
      _flashIndicatorTimer?.cancel();
      await _flutterTts.stop();
      await turnOffFlash();
      
      if (isStreamRunning && 
          cameraService.controller != null &&
          cameraService.controller!.value.isStreamingImages) {
        try {
          await cameraService.controller!.stopImageStream();
          isStreamRunning = false;
        } catch (_) { /* Ignored */ }
      }
      
      await Future.delayed(Duration(milliseconds: 100));
      
      try {
        await _vision.closeYoloModel();
      } catch (_) { /* Ignored */ }
    } catch (_) { /* Ignored */ }
  }

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage("fil-PH"); 
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        if (!isDisposing) {
          isReading = false;
          readingCompleted = true;
          _notifyStateChanged();
        }
      });

      _flutterTts.setStartHandler(() {
        if (!isDisposing) {
          isReading = true;
          readingCompleted = false;
          _notifyStateChanged();
        }
      });

      _flutterTts.setErrorHandler((msg) {
        if (!isDisposing) {
          isReading = false;
          readingCompleted = true;
          _notifyStateChanged();
        }
      });
    } catch (_) { /* Ignored */ }
  }

  void _announceMode() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (!isDisposing) {
        _flutterTts.speak('Object detection mode activated.');
      }
    });
  }

  Future<void> loadModel() async {
    try {
      await _vision.loadYoloModel(
        labels: 'assets/object_model/labels.txt',
        modelPath: 'assets/object_model/seelai_objects.tflite',
        modelVersion: "yolov8",
        quantization: true, 
        useGpu: true, 
        numThreads: 4,
      );
      
      if (!isDisposing) {
        isModelLoaded = true;
        _notifyStateChanged();
        await startObjectDetection();
      }
    } catch (_) { /* Ignored */ }
  }

  Future<void> startObjectDetection() async {
    if (isDisposing) return;
    if (!cameraService.isInitialized || cameraService.controller == null) return;
    if (!isModelLoaded) return;
    
    if (cameraService.controller!.value.isStreamingImages) return;

    try {
      await cameraService.controller!.startImageStream((image) {
        if (!isDetecting && isModelLoaded && !isDisposing) {
          isDetecting = true;
          _checkBrightnessAndManageFlash(image);
          detectObjects(image);
        }
      });
      isStreamRunning = true;
      _notifyStateChanged();
    } catch (_) { /* Ignored */ }
  }

  Future<void> detectObjects(CameraImage image) async {
    if (isDisposing) {
      isDetecting = false;
      return;
    }

    final now = DateTime.now();

    try {
      final result = await _vision.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.4,
        confThreshold: 0.6, 
        classThreshold: 0.6, 
      );

      if (!isDisposing) {
        recognitions = result.where((detection) {
          if (detection['box'] != null && detection['box'].length > 4) {
            double confidence = detection['box'][4] ?? 0.0;
            return confidence >= 0.6; 
          }
          return false;
        }).toList();

        frameCount++;

        if (lastFrameTime != null) {
          final elapsed = now.difference(lastFrameTime!).inMilliseconds;
          if (elapsed > 0) fps = 1000 / elapsed;
        }
        lastFrameTime = now;

        _notifyStateChanged();

        if (recognitions.isNotEmpty) {
          await _detectAndReadObjects();
        }
      }
    } catch (_) { /* Ignored */ }

    isDetecting = false;
  }

  Future<void> _detectAndReadObjects() async {
    if (isDisposing) return;
    
    try {
      final detectedObjectsText = recognitions.map((r) => '${r['tag']}').join(', ');
      
      if (detectedObjectsText.isNotEmpty) {
        final timeSinceLastSpeech = DateTime.now().difference(_lastSpeechTime).inMilliseconds;
        const speechInterval = 2500; 
        
        if (timeSinceLastSpeech > speechInterval && !isReading) {
          
          lastDetectedObjects = detectedObjectsText;
          readingCompleted = false;
          _lastSpeechTime = DateTime.now(); 
          
          // 1. SPEAK IMMEDIATELY: Don't let the user wait for the network
          _flutterTts.speak('I see $detectedObjectsText');
          _notifyStateChanged();

          // 2. FIRE AND FORGET: Handle capture and Cloudinary in the background
          _captureAndUploadInBackground(recognitions.length);
        }
      } 
    } catch (_) { /* Ignored */ }
  }

  // NEW METHOD: Handles the heavy lifting without blocking the stream
  Future<void> _captureAndUploadInBackground(int objectCount) async {
    final controller = cameraService.controller;
    final userId = authService.value.currentUser?.uid;

    if (controller == null || userId == null) return;

    try {
      // Pause stream JUST long enough to snap the physical photo
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
        isStreamRunning = false;
      }
      
      final xFile = await controller.takePicture();
      
      // RESTART STREAM IMMEDIATELY: Do not wait for the upload!
      startObjectDetection();
      
      // Now do the slow network upload in the background
      final uploadedImageUrl = await cloudinaryService.uploadDetectionImage(
        File(xFile.path), 
        userId, 
        'object'
      );
      
      await _saveDetectedObjectsToFirebase(objectCount, imageUrl: uploadedImageUrl);

    } catch (_) {
      // Failsafe: Ensure stream restarts even if taking the picture fails
      if (!isStreamRunning && !isDisposing) {
        startObjectDetection();
      }
    }
  }

  Future<void> _saveDetectedObjectsToFirebase(int objectCount, {String? imageUrl}) async {
    try {
      final userId = authService.value.currentUser?.uid;
      if (userId == null) return;

      await objectDetectionService.saveDetectedObjects(
        userId: userId,
        detectedObjects: recognitions,
        objectCount: objectCount,
        imageUrl: imageUrl,
        metadata: {
          'flashUsed': isFlashOn,
          'lowLight': isLowLight,
          'fps': fps.toStringAsFixed(1),
          'deviceInfo': 'mobile_camera',
        },
      );
    } catch (_) { /* Ignored */ }
  }

  void _checkBrightnessAndManageFlash(CameraImage image) {
    if (isDisposing) return;

    final plane = image.planes[0];
    final bytes = plane.bytes;
    int totalBrightness = 0;
    int sampleCount = 0;

    for (int i = 0; i < bytes.length; i += 500) {
      totalBrightness += bytes[i];
      sampleCount++;
    }

    double averageBrightness = totalBrightness / sampleCount;
    const int kDarkThreshold = 40; 
    const int kBrightThreshold = 150; 
    
    if (!isFlashOn) {
      if (averageBrightness < kDarkThreshold) {
        _darkFrameCount++;
        _brightFrameCount = 0;
      } else {
        _darkFrameCount = 0;
      }

      if (_darkFrameCount > 5) {
        turnOnFlash();
        _darkFrameCount = 0;
      }
    } else {
      if (averageBrightness > kBrightThreshold) {
        _brightFrameCount++;
        _darkFrameCount = 0;
      } else {
        _brightFrameCount = 0;
      }

      if (_brightFrameCount > 10) {
        turnOffFlash();
        _brightFrameCount = 0;
      }
    }
  }

  Future<void> turnOnFlash() async {
    try {
      final controller = cameraService.controller;
      if (controller != null && !isFlashOn) {
        await controller.setFlashMode(FlashMode.torch);
        isFlashOn = true;
        isLowLight = true;
        showFlashIndicator = true;
        
        _notifyStateChanged();
        _flutterTts.speak('Turning on light.');
        
        _flashIndicatorTimer?.cancel();
        _flashIndicatorTimer = Timer(Duration(seconds: 3), () {
          showFlashIndicator = false;
          _notifyStateChanged();
        });
      }
    } catch (_) { /* Ignored */ }
  }

  Future<void> turnOffFlash() async {
    try {
      final controller = cameraService.controller;
      if (controller != null && isFlashOn) {
        await controller.setFlashMode(FlashMode.off);
        isFlashOn = false;
        isLowLight = false;
        showFlashIndicator = false;
        _flashIndicatorTimer?.cancel();
        _notifyStateChanged();
      }
    } catch (_) { /* Ignored */ }
  }

  Future<void> toggleFlashManually() async {
    if (isFlashOn) {
      await turnOffFlash();
      _flutterTts.speak('Flashlight turned off.');
    } else {
      await turnOnFlash();
    }
  }

  void _notifyStateChanged() {
    if (!isDisposing) {
      onStateChanged(ObjectDetectionState(
        recognitions: recognitions,
        isDetecting: isDetecting,
        isModelLoaded: isModelLoaded,
        isReading: isReading,
        readingCompleted: readingCompleted,
        fps: fps,
        isFlashOn: isFlashOn,
        isLowLight: isLowLight,
        showFlashIndicator: showFlashIndicator,
        lastDetectedObjects: lastDetectedObjects,
      ));
    }
  }

  Size? get previewSize => cameraService.controller?.value.previewSize;
}

class ObjectDetectionState {
  final List<Map<String, dynamic>> recognitions;
  final bool isDetecting;
  final bool isModelLoaded;
  final bool isReading;
  final bool readingCompleted;
  final double fps;
  final bool isFlashOn;
  final bool isLowLight;
  final bool showFlashIndicator;
  final String lastDetectedObjects;

  ObjectDetectionState({
    required this.recognitions,
    required this.isDetecting,
    required this.isModelLoaded,
    required this.isReading,
    required this.readingCompleted,
    required this.fps,
    required this.isFlashOn,
    required this.isLowLight,
    required this.showFlashIndicator,
    required this.lastDetectedObjects,
  });
}