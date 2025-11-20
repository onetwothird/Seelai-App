// ignore_for_file: use_super_parameters, avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:math';
import 'dart:typed_data';
import 'package:seelai_app/firebase/visually_impaired/camera_service.dart';

class ObjectDetectionScreen extends StatefulWidget {
  final CameraService cameraService;
  final bool isDarkMode;

  const ObjectDetectionScreen({
    Key? key,
    required this.cameraService,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  bool _isDetecting = false;
  List<Detection> _detections = [];
  String _debugInfo = "Initializing...";
  
  final List<String> _classNames = ["book", "bottle", "chips", "glasses", "stapler"];
  final double _scoreThreshold = 0.3;
  final double _iouThreshold = 0.4;

  int _cameraImageWidth = 0;
  int _cameraImageHeight = 0;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    try {
      if (widget.cameraService.isInitialized && widget.cameraService.controller != null) {
        _cameraController = widget.cameraService.controller;
        print('✅ Using camera from service');
      } else {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          setState(() => _debugInfo = "❌ No cameras available");
          return;
        }

        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        print('✅ Camera initialized: ${_cameraController!.value.previewSize}');
      }
      
      if (mounted) {
        setState(() => _debugInfo = "Camera ready");
        _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      print('❌ Camera error: $e');
      setState(() => _debugInfo = "Camera error: $e");
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/object_model/objects.tflite');
      
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      
      print('✅ Model loaded successfully');
      print('   Input shape: $inputShape');
      print('   Output shape: $outputShape');
      print('   Expected format: [1, ${4 + _classNames.length}, num_predictions]');
      
      setState(() {
        _debugInfo = "Model ready\nInput: $inputShape\nOutput: $outputShape";
      });
    } catch (e) {
      print('❌ Failed to load model: $e');
      setState(() => _debugInfo = "Model error: $e");
    }
  }

  void _processCameraImage(CameraImage cameraImage) async {
    if (_isDetecting || _interpreter == null) return;
    _isDetecting = true;
    _frameCount++;

    try {
      _cameraImageWidth = cameraImage.width;
      _cameraImageHeight = cameraImage.height;

      bool shouldLog = _frameCount % 30 == 0;

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];

      // Convert and resize image
      final img.Image? image = _convertCameraImage(cameraImage);
      if (image == null) {
        _isDetecting = false;
        return;
      }

      final resizedImage = img.copyResize(image, width: inputWidth, height: inputHeight);
      final input = _imageToByteListFloat32(resizedImage, inputWidth, inputHeight);

      // Get output shape
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      
      if (shouldLog) {
        print('\n📸 Frame $_frameCount');
        print('   Output shape: $outputShape');
      }

      // Create output buffer using reshape - CRITICAL FIX
      // Calculate total size
      int totalSize = outputShape.reduce((a, b) => a * b);
      
      // Create the output buffer with reshape
      var output = List<double>.filled(totalSize, 0.0).reshape(outputShape);

      // Run inference
      final inferenceStart = DateTime.now();
      
      try {
        _interpreter!.run(input, output);
      } catch (e) {
        print('❌ Interpreter run error: $e');
        if (shouldLog) {
          print('   Total output size: $totalSize');
          print('   Output shape: $outputShape');
        }
        _isDetecting = false;
        return;
      }
      
      final inferenceTime = DateTime.now().difference(inferenceStart).inMilliseconds;

      if (shouldLog) {
        print('   ✅ Inference successful: ${inferenceTime}ms');
      }

      // Flatten output for processing
      Float32List flatOutput = _flattenOutput(output);

      if (shouldLog) {
        print('   Output flattened: ${flatOutput.length} values');
        if (flatOutput.length >= 10) {
          print('   First 10 values: ${flatOutput.sublist(0, 10)}');
        }
      }

      // Process detections
      final detections = _processYOLOv8Output(
        flatOutput,
        outputShape,
        cameraImage.width.toDouble(),
        cameraImage.height.toDouble(),
        inputWidth.toDouble(),
        inputHeight.toDouble(),
        shouldLog,
      );

      if (shouldLog) {
        print('   ✨ Final detections: ${detections.length}');
      }

      if (mounted) {
        setState(() {
          _detections = detections;
          _debugInfo = "Frame: $_frameCount\nDetections: ${detections.length}\nTime: ${inferenceTime}ms";
        });
      }
    } catch (e, stackTrace) {
      print('❌ Detection error: $e');
      if (_frameCount % 30 == 0) {
        print('Stack trace: $stackTrace');
      }
      setState(() => _debugInfo = "Error: $e");
    }

    _isDetecting = false;
  }

  Float32List _flattenOutput(dynamic output) {
    List<double> flat = [];
    
    void flatten(dynamic obj) {
      if (obj is List) {
        for (var item in obj) {
          flatten(item);
        }
      } else if (obj is double) {
        flat.add(obj);
      } else if (obj is int) {
        flat.add(obj.toDouble());
      }
    }
    
    flatten(output);
    return Float32List.fromList(flat);
  }

  List<Detection> _processYOLOv8Output(
    Float32List output,
    List<int> outputShape,
    double origWidth,
    double origHeight,
    double modelWidth,
    double modelHeight,
    bool shouldLog,
  ) {
    // YOLOv8 TFLite output format: [1, 4+num_classes, num_predictions]
    // For 5 classes: [1, 9, 8400]
    
    final numClasses = _classNames.length;
    final batchSize = outputShape[0];
    final numFeatures = outputShape[1]; // 4 + num_classes = 9
    final numPredictions = outputShape[2]; // 8400

    if (shouldLog) {
      print('   Parsing: batch=$batchSize, features=$numFeatures, predictions=$numPredictions');
    }

    List<List<double>> boxes = [];
    List<double> scores = [];
    List<int> classes = [];

    int foundAboveThreshold = 0;
    double maxScoreFound = 0.0;

    // Calculate scale for letterbox
    double scale = min(modelWidth / origWidth, modelHeight / origHeight);
    double padX = (modelWidth - origWidth * scale) / 2;
    double padY = (modelHeight - origHeight * scale) / 2;

    // Process each prediction
    // Output layout: [batch][feature][prediction]
    // Flattened: index = (batch * numFeatures * numPredictions) + (feature * numPredictions) + prediction
    // Since batch=1, we skip the batch dimension: index = (feature * numPredictions) + prediction
    
    for (int i = 0; i < numPredictions; i++) {
      // Get coordinates (features 0-3)
      double xCenter = output[0 * numPredictions + i];
      double yCenter = output[1 * numPredictions + i];
      double width = output[2 * numPredictions + i];
      double height = output[3 * numPredictions + i];

      // Get class probabilities (features 4 onwards)
      List<double> classProbs = [];
      for (int c = 0; c < numClasses; c++) {
        classProbs.add(output[(4 + c) * numPredictions + i]);
      }

      // Find max probability class
      int classId = 0;
      double maxProb = classProbs[0];
      for (int j = 1; j < classProbs.length; j++) {
        if (classProbs[j] > maxProb) {
          maxProb = classProbs[j];
          classId = j;
        }
      }

      if (maxProb > maxScoreFound) maxScoreFound = maxProb;

      if (maxProb < _scoreThreshold) continue;
      
      foundAboveThreshold++;

      // YOLOv8 outputs coordinates in pixel space relative to model input size
      // Convert to original image coordinates
      double x1 = (xCenter - width / 2);
      double y1 = (yCenter - height / 2);
      double x2 = (xCenter + width / 2);
      double y2 = (yCenter + height / 2);

      // Scale back to original image size (accounting for letterbox padding)
      x1 = (x1 - padX) / scale;
      y1 = (y1 - padY) / scale;
      x2 = (x2 - padX) / scale;
      y2 = (y2 - padY) / scale;

      // Clamp to image bounds
      x1 = max(0, min(x1, origWidth));
      y1 = max(0, min(y1, origHeight));
      x2 = max(0, min(x2, origWidth));
      y2 = max(0, min(y2, origHeight));

      // Check minimum box area
      double area = (x2 - x1) * (y2 - y1);
      if (area < 500) continue;

      boxes.add([x1, y1, x2, y2]);
      scores.add(maxProb);
      classes.add(classId);
    }

    if (shouldLog) {
      print('   Max score: ${maxScoreFound.toStringAsFixed(3)}');
      print('   Above threshold: $foundAboveThreshold');
      print('   After area filter: ${boxes.length}');
    }

    if (boxes.isEmpty) return [];

    // Apply NMS
    List<int> keep = _nms(boxes, scores, _iouThreshold);

    if (shouldLog) {
      print('   After NMS: ${keep.length}');
    }

    List<Detection> detections = [];
    for (int idx in keep) {
      detections.add(Detection(
        box: BoundingBox(boxes[idx][0], boxes[idx][1], boxes[idx][2], boxes[idx][3]),
        score: scores[idx],
        classId: classes[idx],
        className: _classNames[classes[idx]],
      ));
    }

    return detections;
  }

  List<int> _nms(
    List<List<double>> boxes,
    List<double> scores,
    double iouThreshold,
  ) {
    List<int> indices = List.generate(boxes.length, (i) => i);
    indices.sort((a, b) => scores[b].compareTo(scores[a]));

    List<int> keep = [];
    List<bool> suppressed = List.filled(boxes.length, false);

    for (int i in indices) {
      if (suppressed[i]) continue;
      keep.add(i);

      for (int j in indices) {
        if (suppressed[j] || i == j) continue;

        double xx1 = max(boxes[i][0], boxes[j][0]);
        double yy1 = max(boxes[i][1], boxes[j][1]);
        double xx2 = min(boxes[i][2], boxes[j][2]);
        double yy2 = min(boxes[i][3], boxes[j][3]);

        double w = max(0, xx2 - xx1);
        double h = max(0, yy2 - yy1);
        double inter = w * h;

        double areaI = (boxes[i][2] - boxes[i][0]) * (boxes[i][3] - boxes[i][1]);
        double areaJ = (boxes[j][2] - boxes[j][0]) * (boxes[j][3] - boxes[j][1]);
        double iou = inter / (areaI + areaJ - inter);

        if (iou > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return keep;
  }

  img.Image? _convertCameraImage(CameraImage cameraImage) {
    try {
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToImage(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToImage(cameraImage);
      }
      return null;
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }

  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = cameraImage.planes[0].bytes[index];
        final up = cameraImage.planes[1].bytes[uvIndex];
        final vp = cameraImage.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
  }

  img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    final image = img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: cameraImage.planes[0].bytes.buffer,
      format: img.Format.uint8,
      numChannels: 4,
    );
    return image;
  }

  Float32List _imageToByteListFloat32(img.Image image, int inputWidth, int inputHeight) {
    final convertedBytes = Float32List(1 * inputHeight * inputWidth * 3);
    final buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int y = 0; y < inputHeight; y++) {
      for (int x = 0; x < inputWidth; x++) {
        final pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return convertedBytes;
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _debugInfo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Object Detection (${_detections.length})'),
        backgroundColor: widget.isDarkMode ? Colors.black87 : Colors.blue,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          CustomPaint(
            painter: BoundingBoxPainter(
              detections: _detections,
              cameraImageWidth: _cameraImageWidth,
              cameraImageHeight: _cameraImageHeight,
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _debugInfo,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_detections.isNotEmpty)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _detections.map((det) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Text(
                        '${det.className} ${(det.score * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_cameraController != widget.cameraService.controller) {
      _cameraController?.dispose();
    }
    _interpreter?.close();
    super.dispose();
  }
}

class BoundingBox {
  final double x1, y1, x2, y2;
  BoundingBox(this.x1, this.y1, this.x2, this.y2);
}

class Detection {
  final BoundingBox box;
  final double score;
  final int classId;
  final String className;

  Detection({
    required this.box,
    required this.score,
    required this.classId,
    required this.className,
  });
}

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final int cameraImageWidth;
  final int cameraImageHeight;

  BoundingBoxPainter({
    required this.detections,
    required this.cameraImageWidth,
    required this.cameraImageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cameraImageWidth == 0 || cameraImageHeight == 0) return;

    final scaleX = size.width / cameraImageWidth;
    final scaleY = size.height / cameraImageHeight;

    final colors = [
      const Color(0xFF00FF00), // Green - book
      const Color(0xFF0000FF), // Blue - bottle
      const Color(0xFFFF00FF), // Magenta - chips
      const Color(0xFF00FFFF), // Cyan - glasses
      const Color(0xFFFFFF00), // Yellow - stapler
    ];

    for (final detection in detections) {
      final color = colors[detection.classId % colors.length];
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      final fillPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTRB(
        detection.box.x1 * scaleX,
        detection.box.y1 * scaleY,
        detection.box.x2 * scaleX,
        detection.box.y2 * scaleY,
      );

      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, paint);

      final text = '${detection.className} ${(detection.score * 100).toStringAsFixed(0)}%';
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textBackground = Paint()..color = Colors.black.withOpacity(0.7);
      final textRect = Rect.fromLTWH(
        rect.left,
        rect.top - 24,
        textPainter.width + 8,
        24,
      );
      
      canvas.drawRect(textRect, textBackground);
      textPainter.paint(canvas, Offset(rect.left + 4, rect.top - 22));
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) => true;
}