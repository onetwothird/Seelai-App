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
  
  // Brightness monitoring
  int _darkFrameCount = 0;
  int _brightFrameCount = 0;
  Timer? _brightnessMonitorTimer;

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
      _brightnessMonitorTimer?.cancel();
      
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
        _flutterTts.speak('Object detection mode activated. Point camera at objects.');
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
          detectObjects(image);
        }
      });
      isStreamRunning = true;
      _startBrightnessMonitoring();
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
      final result = await _vision.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5,
      );

      if (!isDisposing) {
        // Filter out low-confidence detections
        recognitions = result.where((detection) {
          if (detection['box'] != null && detection['box'].length > 4) {
            double confidence = detection['box'][4] ?? 0.0;
            return confidence >= 0.4;
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
        if (recognitions.isNotEmpty && !isReading) {
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
    if (isDisposing || isReading) return;
    
    try {
      final detectedObjectsText = recognitions
          .map((r) => '${r['tag']}')
          .join(', ');
      
      if (detectedObjectsText.isNotEmpty) {
        bool isDifferentObjects = (detectedObjectsText.length - lastDetectedObjects.length).abs() > 5 ||
                                 !detectedObjectsText.contains(lastDetectedObjects.substring(0, lastDetectedObjects.length.clamp(0, 10)));
        
        if ((isDifferentObjects || lastDetectedObjects.isEmpty) && !isReading) {
          lastDetectedObjects = detectedObjectsText;
          readingCompleted = false;
          
          // Save to Firebase BEFORE speaking
          await _saveDetectedObjectsToFirebase(recognitions.length);
          
          // Then speak
          await _flutterTts.speak('I see $detectedObjectsText');
          
          _notifyStateChanged();
        }
      } else {
        if (!isReading) {
          readingCompleted = true;
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

  /// Start monitoring brightness and auto-manage flash
  void _startBrightnessMonitoring() {
    _brightnessMonitorTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (isDisposing) {
        timer.cancel();
        return;
      }
      
      if (recognitions.isEmpty || _hasPoorQualityDetections()) {
        _darkFrameCount++;
        _brightFrameCount = 0;
        
        if (_darkFrameCount >= 3 && !isFlashOn) {
          await turnOnFlash();
        }
      } else {
        _brightFrameCount++;
        _darkFrameCount = 0;
        
        if (_brightFrameCount >= 3 && isFlashOn) {
          await turnOffFlash();
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
        
        _flutterTts.speak('Low light detected. Flashlight turned on.');
        
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