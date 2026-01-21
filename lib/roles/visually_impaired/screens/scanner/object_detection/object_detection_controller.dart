// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:seelai_app/firebase/visually_impaired/camera_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

/// Controller that handles all object detection logic
class ObjectDetectionController {
  final CameraService cameraService;
  final Function(ObjectDetectionState) onStateChanged;
  
  late FlutterVision _vision;
  late FlutterTts _flutterTts;
  
  // Detection state
  List<Map<String, dynamic>> recognitions = [];
  bool isDetecting = false;
  bool isModelLoaded = false;
  bool isReading = false;
  bool readingCompleted = false;
  bool isStreamRunning = false;
  bool isDisposing = false;
  
  // Performance tracking
  int frameCount = 0;
  DateTime? lastFrameTime;
  double fps = 0.0;
  
  // Flash/brightness related
  bool isLowLight = false;
  bool isFlashOn = false;
  bool showFlashIndicator = false;
  Timer? _flashIndicatorTimer;
  
  // Detection tracking
  String lastDetectedObjects = '';
  DateTime _lastSpeechTime = DateTime.now(); // Controls the "Again and Again" timing
  
  // Brightness monitoring
  int _darkFrameCount = 0;
  int _brightFrameCount = 0;

  ObjectDetectionController({
    required this.cameraService,
    required this.onStateChanged,
  });

  /// Initialize the controller
  Future<void> initialize() async {
    _vision = FlutterVision();
    _flutterTts = FlutterTts();
    
    await _initializeTts();
    
    // Start loading model and detection immediately
    loadModel();
    
    // Announce mode without blocking
    _announceMode();
  }

  /// Cleanup all resources
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
        } catch (e) {
          // Silent fail
        }
      }
      
      await Future.delayed(Duration(milliseconds: 100));
      
      try {
        await _vision.closeYoloModel();
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
    } catch (e) {
      // Silent fail
    }
  }

  void _announceMode() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (!isDisposing) {
        _flutterTts.speak('Object detection mode activated.');
      }
    });
  }

  /// Load the YOLO model
  Future<void> loadModel() async {
    try {
      await _vision.loadYoloModel(
        labels: 'assets/object_model/labels.txt',
        modelPath: 'assets/object_model/object.tflite',
        modelVersion: "yolov8",
        numThreads: 4,
        useGpu: true,
      );
      
      if (!isDisposing) {
        isModelLoaded = true;
        _notifyStateChanged();
        await startObjectDetection();
      }
    } catch (e) {
      print('Model loading error: $e');
    }
  }

  /// Start the object detection stream
  Future<void> startObjectDetection() async {
    if (isDisposing) return;
    if (!cameraService.isInitialized || cameraService.controller == null) return;
    if (!isModelLoaded) return;
    
    if (cameraService.controller!.value.isStreamingImages) {
      return;
    }

    try {
      await cameraService.controller!.startImageStream((image) {
        if (!isDetecting && isModelLoaded && !isDisposing) {
          isDetecting = true;
          
          // 1. Check brightness FIRST on every frame
          _checkBrightnessAndManageFlash(image);

          // 2. Run Detection
          detectObjects(image);
        }
      });
      isStreamRunning = true;
      _notifyStateChanged();
    } catch (e) {
      print('Stream start error: $e');
    }
  }

  /// Detect objects in the camera frame
  Future<void> detectObjects(CameraImage image) async {
    if (isDisposing) {
      isDetecting = false;
      return;
    }

    final now = DateTime.now();

    try {
      // UPGRADE 2: High Accuracy Settings
      // Increased thresholds to 0.60 (60%) or 0.70 (70%) to ensure it matches ONLY your trained model
      // and ignores random background noise.
      final result = await _vision.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.4,
        confThreshold: 0.6, // Strict confidence (was 0.4)
        classThreshold: 0.6, // Strict class matching (was 0.5)
      );

      if (!isDisposing) {
        // Double check filter for high confidence
        recognitions = result.where((detection) {
          if (detection['box'] != null && detection['box'].length > 4) {
            double confidence = detection['box'][4] ?? 0.0;
            return confidence >= 0.6; // Only accept > 60%
          }
          return false;
        }).toList();

        frameCount++;

        if (lastFrameTime != null) {
          final elapsed = now.difference(lastFrameTime!).inMilliseconds;
          if (elapsed > 0) {
            fps = 1000 / elapsed;
          }
        }
        lastFrameTime = now;

        _notifyStateChanged();

        // Auto-detect and read objects
        if (recognitions.isNotEmpty) {
          await _detectAndReadObjects();
        }
      }
    } catch (e) {
      print('Detection error: $e');
    }

    isDetecting = false;
  }

  /// Detect and read objects automatically
  Future<void> _detectAndReadObjects() async {
    if (isDisposing) return;
    
    try {
      final detectedObjectsText = recognitions
          .map((r) => '${r['tag']}')
          .join(', ');
      
      if (detectedObjectsText.isNotEmpty) {
        // UPGRADE 3: "Again and Again" Logic
        // We check if enough time (e.g., 2.5 seconds) has passed since the last speech.
        // If yes, we speak, even if the object is the same as before.
        
        final timeSinceLastSpeech = DateTime.now().difference(_lastSpeechTime).inMilliseconds;
        const speechInterval = 2500; // 2.5 seconds delay between repeats
        
        if (timeSinceLastSpeech > speechInterval && !isReading) {
          
          lastDetectedObjects = detectedObjectsText;
          readingCompleted = false;
          _lastSpeechTime = DateTime.now(); // Reset timer
          
          // Save to Firebase (Optional: You might want to limit this if it saves too often)
          await _saveDetectedObjectsToFirebase(recognitions.length);
          
          // Speak
          await _flutterTts.speak('I see $detectedObjectsText');
          
          _notifyStateChanged();
        }
      } 
    } catch (e) {
      print('Read objects error: $e');
    }
  }

  /// Save detected objects to Firebase
  Future<void> _saveDetectedObjectsToFirebase(int objectCount) async {
    try {
      final userId = authService.value.currentUser?.uid;
      if (userId == null) return;

      await objectDetectionService.saveDetectedObjects(
        userId: userId,
        detectedObjects: recognitions,
        objectCount: objectCount,
        metadata: {
          'flashUsed': isFlashOn,
          'lowLight': isLowLight,
          'fps': fps.toStringAsFixed(1),
          'deviceInfo': 'mobile_camera',
        },
      );
    } catch (e) {
      print('Firebase save error: $e');
    }
  }

  /// UPGRADE 1: Calculate pixel brightness directly from camera stream
  /// UPGRADE 1: Calculate pixel brightness directly from camera stream
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
    
    // Thresholds
    const int kDarkThreshold = 40;   // Turn ON point
    const int kBrightThreshold = 150; // Turn OFF point (Higher to ignore flash glare)
    
    // Logic to toggle flash with Hysteresis
    if (!isFlashOn) {
      // Check if it's getting dark
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
      // Flash is ON: Check if environment is actually bright (Daylight/Indoor Lights)
      if (averageBrightness > kBrightThreshold) {
        _brightFrameCount++;
        _darkFrameCount = 0;
      } else {
        _brightFrameCount = 0; // Keep flash ON
      }

      // Require more frames (10) to be sure before turning off
      if (_brightFrameCount > 10) {
        turnOffFlash();
        _brightFrameCount = 0;
      }
    }
  }

  /// Turn on flash/torch
  Future<void> turnOnFlash() async {
    try {
      final controller = cameraService.controller;
      if (controller != null && !isFlashOn) {
        await controller.setFlashMode(FlashMode.torch);
        isFlashOn = true;
        isLowLight = true;
        showFlashIndicator = true;
        
        _notifyStateChanged();
        
        // Announce light change
        _flutterTts.speak('Turning on light.');
        
        _flashIndicatorTimer?.cancel();
        _flashIndicatorTimer = Timer(Duration(seconds: 3), () {
          showFlashIndicator = false;
          _notifyStateChanged();
        });
      }
    } catch (e) {
      print('Flash on error: $e');
    }
  }

  /// Turn off flash/torch
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
    } catch (e) {
      print('Flash off error: $e');
    }
  }

  /// Toggle flash manually
  Future<void> toggleFlashManually() async {
    if (isFlashOn) {
      await turnOffFlash();
      _flutterTts.speak('Flashlight turned off.');
    } else {
      await turnOnFlash();
    }
  }

  /// Notify state changed
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

  /// Get current camera preview size
  Size? get previewSize => cameraService.controller?.value.previewSize;
}

/// State object for object detection
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