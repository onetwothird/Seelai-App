// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:seelai_app/firebase/visually_impaired/camera_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

/// Controller that handles all face detection logic
class FaceDetectionController {
  final CameraService cameraService;
  final Function(FaceDetectionState) onStateChanged;
  
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
  
  // Flash/brightness related (ADDED)
  bool isLowLight = false;
  bool isFlashOn = false;
  bool showFlashIndicator = false;
  Timer? _flashIndicatorTimer;
  int _darkFrameCount = 0;
  int _brightFrameCount = 0;
  
  // Detection tracking
  String lastDetectedFaces = '';
  DateTime? lastSpeakTime;

  FaceDetectionController({
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
        _flutterTts.speak('Face detection mode activated. Looking for caretakers.');
      }
    });
  }

  /// Load the YOLO model for face detection
  Future<void> loadModel() async {
    try {
      await _vision.loadYoloModel(
        labels: 'assets/face_model/labels.txt',
        modelPath: 'assets/face_model/final_face.tflite',
        modelVersion: "yolov8",
        numThreads: 4,
        useGpu: true,
      );
      
      if (!isDisposing) {
        isModelLoaded = true;
        _notifyStateChanged();
        await startFaceDetection();
      }
    } catch (e) {
      print('Model loading error: $e');
    }
  }

  /// Start the face detection stream
  Future<void> startFaceDetection() async {
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
          
          // 1. Check brightness FIRST on every frame (ADDED)
          _checkBrightnessAndManageFlash(image);
          
          // 2. Run Detection
          detectFaces(image);
        }
      });
      isStreamRunning = true;
      _notifyStateChanged();
    } catch (e) {
      print('Stream start error: $e');
    }
  }

  /// Detect faces in the camera frame
  Future<void> detectFaces(CameraImage image) async {
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
        iouThreshold: 0.45,
        confThreshold: 0.5,
        classThreshold: 0.5,
      );

      if (!isDisposing) {
        // Filter out low-confidence detections
        recognitions = result.where((detection) {
          if (detection['box'] != null && detection['box'].length > 4) {
            double confidence = detection['box'][4] ?? 0.0;
            return confidence >= 0.5;
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

        // Auto-detect and read faces
        if (recognitions.isNotEmpty) {
          await _detectAndReadFaces();
        } else {
          lastDetectedFaces = '';
        }
      }
    } catch (e) {
      print('Detection error: $e');
    }

    isDetecting = false;
  }

  /// Detect and read faces automatically with debouncing
  Future<void> _detectAndReadFaces() async {
    if (isDisposing || isReading) return;
    
    // Debounce: only speak every 3 seconds
    final now = DateTime.now();
    if (lastSpeakTime != null && 
        now.difference(lastSpeakTime!).inSeconds < 3) {
      return;
    }
    
    try {
      final faceCount = recognitions.length;
      
      if (faceCount > 0) {
        // Get unique face names
        final faceNames = recognitions
            .map((r) => (r['tag'] ?? 'unknown person').toString())
            .toSet()
            .toList();
        
        // Create natural speech text
        String speechText;
        if (faceNames.length == 1) {
          speechText = 'I see ${faceNames[0]}';
        } else if (faceNames.length == 2) {
          speechText = 'I see ${faceNames[0]} and ${faceNames[1]}';
        } else {
          final lastPerson = faceNames.removeLast();
          speechText = 'I see ${faceNames.join(", ")}, and $lastPerson';
        }
        
        final detectedFacesText = faceNames.join(', ');
        
        // Check if detection changed significantly
        bool isDifferentFaces = lastDetectedFaces != detectedFacesText;
        
        if (isDifferentFaces && !isReading) {
          lastDetectedFaces = detectedFacesText;
          lastSpeakTime = now;
          readingCompleted = false;
          
          // Save to Firebase BEFORE speaking
          await _saveDetectedFacesToFirebase(faceCount);
          
          // Then speak
          await _flutterTts.speak(speechText);
          
          _notifyStateChanged();
        }
      }
    } catch (e) {
      print('Read faces error: $e');
    }
  }

  /// Save detected faces to Firebase
  Future<void> _saveDetectedFacesToFirebase(int faceCount) async {
    try {
      final userId = authService.value.currentUser?.uid;
      if (userId == null) return;

      await faceDetectionService.saveDetectedFaces(
        userId: userId,
        detectedFaces: recognitions,
        faceCount: faceCount,
        metadata: {
          'fps': fps.toStringAsFixed(1),
          'deviceInfo': 'mobile_camera',
          'flashUsed': isFlashOn,
          'lowLight': isLowLight,
          'detectedNames': recognitions.map((r) => r['tag'] ?? 'unknown').toList(),
        },
      );
    } catch (e) {
      print('Firebase save error: $e');
    }
  }

  /// Get color for each caretaker - UPDATED TO PURPLE ONLY
  Color getColorForPerson(String name) {
    // Returning purple for everyone as requested
    return Colors.purple; 
  }
  
  /// Calculate pixel brightness and manage flash with Hysteresis
  void _checkBrightnessAndManageFlash(CameraImage image) {
    if (isDisposing) return;

    // 1. Calculate average luminance
    final plane = image.planes[0];
    final bytes = plane.bytes;
    int totalBrightness = 0;
    int sampleCount = 0;

    for (int i = 0; i < bytes.length; i += 500) { 
      totalBrightness += bytes[i];
      sampleCount++;
    }

    double averageBrightness = totalBrightness / sampleCount;

    // 2. Define Thresholds
    // Dark threshold to turn ON (keep this low, e.g., 40)
    const int kDarkThreshold = 40; 
    
    // Bright threshold to turn OFF (Must be HIGH to prevent flicker when flash is on)
    // If flash is on, we expect the image to be bright (~100+). 
    // We only want to turn it off if it's VERY bright (e.g., daylight > 150).
    const int kBrightThreshold = 150; 

    // 3. Logic with Hysteresis
    if (!isFlashOn) {
      // CASE A: Flash is OFF. We look for DARKNESS.
      if (averageBrightness < kDarkThreshold) {
        _darkFrameCount++;
        _brightFrameCount = 0; // Reset bright count
      } else {
        _darkFrameCount = 0; // Not dark enough
      }

      // Trigger ON after 5 consistent dark frames
      if (_darkFrameCount > 5) {
        turnOnFlash();
        _darkFrameCount = 0;
      }

    } else {
      // CASE B: Flash is ON. We look for BRIGHT ENVIRONMENTS.
      // We check against the HIGHER threshold (kBrightThreshold) to ignore the flash's own light.
      if (averageBrightness > kBrightThreshold) {
        _brightFrameCount++;
        _darkFrameCount = 0; 
      } else {
        _brightFrameCount = 0; // It's still effectively dark (relying on flash), keep it on.
      }

      // Trigger OFF after 10 consistent bright frames (slower to turn off for stability)
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
      onStateChanged(FaceDetectionState(
        recognitions: recognitions,
        isDetecting: isDetecting,
        isModelLoaded: isModelLoaded,
        isReading: isReading,
        readingCompleted: readingCompleted,
        fps: fps,
        isFlashOn: isFlashOn,
        isLowLight: isLowLight,
        showFlashIndicator: showFlashIndicator,
        lastDetectedFaces: lastDetectedFaces,
      ));
    }
  }

  /// Get current camera preview size
  Size? get previewSize => cameraService.controller?.value.previewSize;
}

/// State object for face detection
class FaceDetectionState {
  final List<Map<String, dynamic>> recognitions;
  final bool isDetecting;
  final bool isModelLoaded;
  final bool isReading;
  final bool readingCompleted;
  final double fps;
  final bool isFlashOn;
  final bool isLowLight;
  final bool showFlashIndicator;
  final String lastDetectedFaces;

  FaceDetectionState({
    required this.recognitions,
    required this.isDetecting,
    required this.isModelLoaded,
    required this.isReading,
    required this.readingCompleted,
    required this.fps,
    required this.isFlashOn,
    required this.isLowLight,
    required this.showFlashIndicator,
    required this.lastDetectedFaces,
  });
}