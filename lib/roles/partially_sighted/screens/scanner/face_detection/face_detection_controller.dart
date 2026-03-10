import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:seelai_app/firebase/partially_sighted/camera_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/services/cloudinary_service.dart';

class FaceDetectionController {
  final CameraService cameraService;
  final Function(FaceDetectionState) onStateChanged;
  
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
  int _darkFrameCount = 0;
  int _brightFrameCount = 0;
  
  String lastDetectedFaces = '';
  DateTime? lastSpeakTime;

  FaceDetectionController({
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
    } catch (_) { /* Ignored */ }
  }

  void _announceMode() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (!isDisposing) {
        _flutterTts.speak('Face detection mode activated. Looking for caretakers.');
      }
    });
  }

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
    } catch (_) { /* Ignored */ }
  }

  Future<void> startFaceDetection() async {
    if (isDisposing) return;
    if (!cameraService.isInitialized || cameraService.controller == null) return;
    if (!isModelLoaded) return;
    
    if (cameraService.controller!.value.isStreamingImages) return;

    try {
      await cameraService.controller!.startImageStream((image) {
        if (!isDetecting && isModelLoaded && !isDisposing) {
          isDetecting = true;
          _checkBrightnessAndManageFlash(image);
          detectFaces(image);
        }
      });
      isStreamRunning = true;
      _notifyStateChanged();
    } catch (_) { /* Ignored */ }
  }

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
          if (elapsed > 0) fps = 1000 / elapsed;
        }
        lastFrameTime = now;

        _notifyStateChanged();

        if (recognitions.isNotEmpty) {
          await _detectAndReadFaces();
        } else {
          lastDetectedFaces = '';
        }
      }
    } catch (_) { /* Ignored */ }

    isDetecting = false;
  }

  Future<void> _detectAndReadFaces() async {
    if (isDisposing || isReading) return;
    
    final now = DateTime.now();
    if (lastSpeakTime != null && now.difference(lastSpeakTime!).inSeconds < 3) return;
    
    try {
      final faceCount = recognitions.length;
      
      if (faceCount > 0) {
        final faceNames = recognitions.map((r) => (r['tag'] ?? 'unknown person').toString()).toSet().toList();
        
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
        bool isDifferentFaces = lastDetectedFaces != detectedFacesText;
        
        if (isDifferentFaces && !isReading) {
          lastDetectedFaces = detectedFacesText;
          lastSpeakTime = now;
          readingCompleted = false;
          
          String? uploadedImageUrl;
          final controller = cameraService.controller;
          final userId = authService.value.currentUser?.uid;

          if (controller != null && userId != null) {
            try {
              if (controller.value.isStreamingImages) {
                await controller.stopImageStream();
                isStreamRunning = false;
              }
              
              final xFile = await controller.takePicture();
              
              startFaceDetection();
              
              uploadedImageUrl = await cloudinaryService.uploadDetectionImage(
                File(xFile.path), 
                userId, 
                'face'
              );
            } catch (_) {
              if (!isStreamRunning) {
                startFaceDetection();
              }
            }
          }
          
          await _saveDetectedFacesToFirebase(faceCount, imageUrl: uploadedImageUrl);
          await _flutterTts.speak(speechText);
          
          _notifyStateChanged();
        }
      }
    } catch (_) { /* Ignored */ }
  }

  Future<void> _saveDetectedFacesToFirebase(int faceCount, {String? imageUrl}) async {
    try {
      final userId = authService.value.currentUser?.uid;
      if (userId == null) return;

      await faceDetectionService.saveDetectedFaces(
        userId: userId,
        detectedFaces: recognitions,
        faceCount: faceCount,
        imageUrl: imageUrl,
        metadata: {
          'fps': fps.toStringAsFixed(1),
          'deviceInfo': 'mobile_camera',
          'flashUsed': isFlashOn,
          'lowLight': isLowLight,
          'detectedNames': recognitions.map((r) => r['tag'] ?? 'unknown').toList(),
        },
      );
    } catch (_) { /* Ignored */ }
  }

  Color getColorForPerson(String name) {
    return Colors.purple; 
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

  Size? get previewSize => cameraService.controller?.value.previewSize;
}

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