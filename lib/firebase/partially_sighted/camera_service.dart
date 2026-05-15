import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }
      
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high, 
        enableAudio: false,
      );
      
      await _controller!.initialize();
      _isInitialized = true;
      
      return true;
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  Future<String?> takePicture() async {
    if (!_isInitialized || _controller == null) {
      debugPrint('Camera not initialized');
      return null;
    }

    try {
      final image = await _controller!.takePicture();
      return image.path;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
  }

  Future<void> startImageStream(Function(CameraImage) onImage) async {
    if (!_isInitialized || _controller == null) {
      debugPrint('Camera not initialized');
      return;
    }

    try {
      await _controller!.startImageStream(onImage);
    } catch (e) {
      debugPrint('Error starting image stream: $e');
    }
  }

  Future<void> stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
      } catch (e) {
        debugPrint('Error stopping image stream: $e');
      }
    }
  }
}