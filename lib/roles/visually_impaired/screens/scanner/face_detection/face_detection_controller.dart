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
      await _flutterTts.stop();
      
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
          'detectedNames': recognitions.map((r) => r['tag'] ?? 'unknown').toList(),
        },
      );
    } catch (e) {
      print('Firebase save error: $e');
    }
  }

  /// Get color for each caretaker
  Color getColorForPerson(String name) {
    switch (name.toLowerCase()) {
      case 'christian':
        return Colors.blue;
      case 'nash':
        return Colors.purple;
      case 'third':
        return Colors.green;
      default:
        return Colors.orange;
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
  final String lastDetectedFaces;

  FaceDetectionState({
    required this.recognitions,
    required this.isDetecting,
    required this.isModelLoaded,
    required this.isReading,
    required this.readingCompleted,
    required this.fps,
    required this.lastDetectedFaces,
  });
}