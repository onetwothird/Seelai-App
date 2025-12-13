// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/visually_impaired/camera_service.dart';
import 'face_detection_controller.dart';

class FaceDetectionScreen extends StatefulWidget {
  final CameraService cameraService;
  final bool isDarkMode;

  const FaceDetectionScreen({
    super.key,
    required this.cameraService,
    required this.isDarkMode,
  });

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  late FaceDetectionController _controller;
  FaceDetectionState _state = FaceDetectionState(
    recognitions: [],
    isDetecting: false,
    isModelLoaded: false,
    isReading: false,
    readingCompleted: false,
    fps: 0.0,
    lastDetectedFaces: '',
  );

  @override
  void initState() {
    super.initState();
    _controller = FaceDetectionController(
      cameraService: widget.cameraService,
      onStateChanged: (newState) {
        if (mounted) {
          setState(() {
            _state = newState;
          });
        }
      },
    );
    _controller.initialize();
    _showInitialSnackBar();
  }

  void _showInitialSnackBar() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face detection mode activated - Looking for caretakers'),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    if (!widget.cameraService.isInitialized || widget.cameraService.controller == null) {
      return _buildLoadingScreen(screenWidth);
    }

    return WillPopScope(
      onWillPop: () async {
        await _controller.dispose();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Preview - Full Screen
            _buildCameraPreview(),
            
            // Gradient Overlay
            _buildGradientOverlay(),
            
            // Bounding Boxes for Faces
            if (_state.isModelLoaded)
              FaceBoundingBoxes(
                recognitions: _state.recognitions,
                cameraController: widget.cameraService.controller!,
                screenSize: screenSize,
                controller: _controller,
              ),
            
            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _buildHeader(screenWidth),
              ),
            ),
            
            // Bottom Controls
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
      ),
    );
  }

  Widget _buildLoadingScreen(double screenWidth) {
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

  Widget _buildCameraPreview() {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: widget.cameraService.controller!.value.previewSize!.height,
          height: widget.cameraService.controller!.value.previewSize!.width,
          child: CameraPreview(widget.cameraService.controller!),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
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
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Row(
        children: [
          _buildBackButton(screenWidth),
          SizedBox(width: spacingMedium),
          Expanded(child: _buildHeaderInfo(screenWidth)),
        ],
      ),
    );
  }

  Widget _buildBackButton(double screenWidth) {
    return Semantics(
      label: 'Back button',
      hint: 'Double tap to go back',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await _controller.dispose();
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
    );
  }

  Widget _buildHeaderInfo(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Face Detection',
          style: h2.copyWith(
            color: white,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          _state.recognitions.isNotEmpty
              ? 'Detected: ${_state.recognitions.length} person${_state.recognitions.length > 1 ? "s" : ""}'
              : 'Looking for faces...',
          style: caption.copyWith(
            color: _state.recognitions.isNotEmpty
                ? (_state.isReading ? Colors.purple.shade300 : Colors.purple)
                : white.withOpacity(0.7),
            fontSize: screenWidth * 0.03,
          ),
        ),
      ],
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
          if (_state.lastDetectedFaces.isNotEmpty)
            _buildDetectedFacesInfo(screenWidth),
          _buildStatusRow(screenWidth),
        ],
      ),
    );
  }

  Widget _buildDetectedFacesInfo(double screenWidth) {
    return Container(
      margin: EdgeInsets.only(bottom: spacingLarge),
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(
          color: Colors.purple.withOpacity(0.4),
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
                color: Colors.purple,
                size: screenWidth * 0.05,
              ),
              SizedBox(width: spacingSmall),
              Expanded(
                child: Text(
                  'Caretakers Detected & Saved',
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
            'Found: ${_state.lastDetectedFaces}',
            style: caption.copyWith(
              color: white.withOpacity(0.7),
              fontSize: screenWidth * 0.03,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _state.isReading
              ? Icons.volume_up
              : _state.recognitions.isNotEmpty
                  ? Icons.face
                  : Icons.face_outlined,
          color: _state.isReading
              ? Colors.purple.shade300
              : _state.recognitions.isNotEmpty
                  ? Colors.purple
                  : Colors.purple.shade200,
          size: screenWidth * 0.06,
        ),
        SizedBox(width: spacingSmall),
        Flexible(
          child: Text(
            _state.isReading
                ? 'Announcing caretaker...'
                : _state.recognitions.isNotEmpty
                    ? 'Scanning caretakers...'
                    : 'Looking for faces...',
            style: bodyBold.copyWith(
              color: white.withOpacity(0.9),
              fontSize: screenWidth * 0.035,
            ),
          ),
        ),
        SizedBox(width: spacingLarge),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03, 
            vertical: spacingSmall,
          ),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(radiusSmall),
            border: Border.all(color: Colors.purple.withOpacity(0.4)),
          ),
          child: Text(
            'FPS: ${_state.fps.toStringAsFixed(1)}',
            style: caption.copyWith(
              color: Colors.purple,
              fontSize: screenWidth * 0.03,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ACCURATE Face Bounding Boxes with Color Coding
// =============================================================================

class FaceBoundingBoxes extends StatelessWidget {
  final List<Map<String, dynamic>> recognitions;
  final CameraController cameraController;
  final Size screenSize;
  final FaceDetectionController controller;

  const FaceBoundingBoxes({
    super.key,
    required this.recognitions,
    required this.cameraController,
    required this.screenSize,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (recognitions.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: FaceBoxPainter(
        recognitions: recognitions,
        cameraController: cameraController,
        screenSize: screenSize,
        controller: controller,
      ),
    );
  }
}

// =============================================================================
// Face Box Painter with Color Coding for Each Caretaker
// =============================================================================

class FaceBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> recognitions;
  final CameraController cameraController;
  final Size screenSize;
  final FaceDetectionController controller;

  FaceBoxPainter({
    required this.recognitions,
    required this.cameraController,
    required this.screenSize,
    required this.controller,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Get the actual camera preview size (reported in landscape orientation)
    final previewSize = cameraController.value.previewSize!;
    
    // Camera stream dimensions in portrait (swap width/height)
    final double cameraWidth = previewSize.height;
    final double cameraHeight = previewSize.width;

    // Calculate how camera preview fits on screen
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    
    // Calculate the scale to fit camera preview to screen (cover mode)
    final double scaleX = screenWidth / cameraWidth;
    final double scaleY = screenHeight / cameraHeight;
    final double scale = scaleX > scaleY ? scaleX : scaleY;
    
    // Calculate the actual displayed camera dimensions
    final double displayWidth = cameraWidth * scale;
    final double displayHeight = cameraHeight * scale;
    
    // Calculate crop offsets (for BoxFit.cover)
    final double offsetX = (displayWidth - screenWidth) / 2;
    final double offsetY = (displayHeight - screenHeight) / 2;

    for (var recognition in recognitions) {
      final box = recognition['box'];
      
      if (box == null || box.length < 4) continue;

      // Get person name and corresponding color
      final personName = (recognition['tag'] ?? 'unknown').toString();
      final boxColor = controller.getColorForPerson(personName);

      // YOLO coordinates are in camera space
      double x = box[0].toDouble();
      double y = box[1].toDouble();
      double w = box[2].toDouble();
      double h = box[3].toDouble();

      // Scale to display size
      double scaledX = x * scale;
      double scaledY = y * scale;
      double scaledW = w * scale;
      double scaledH = h * scale;

      // Apply crop offset
      double finalX = scaledX - offsetX;
      double finalY = scaledY - offsetY;

      // Only draw if box is visible on screen
      if (finalX + scaledW > 0 && finalX < screenWidth &&
          finalY + scaledH > 0 && finalY < screenHeight) {
        
        final rect = Rect.fromLTWH(finalX, finalY, scaledW, scaledH);
        
        // Draw bounding box with person's color
        final paint = Paint()
          ..color = boxColor.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        
        canvas.drawRect(rect, paint);

        // Draw label with person's name
        _drawLabel(canvas, rect, recognition, box, boxColor, personName);
        
        // Draw corner markers with person's color
        _drawCornerMarkers(canvas, rect, boxColor);
      }
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, Map<String, dynamic> recognition, 
                  List<dynamic> box, Color color, String personName) {
    final confidence = box.length > 4 ? (box[4] ?? 0.0) : 0.0;
    final text = '$personName ${(confidence * 100).toStringAsFixed(0)}%';

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.8),
          offset: Offset(1, 1),
          blurRadius: 2,
        ),
      ],
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final labelHeight = 22.0;
    final labelPadding = 8.0;
    final labelWidth = textPainter.width + labelPadding;
    
    // Position label above box, or inside if would go off-screen
    double labelTop = rect.top - labelHeight - 2;
    if (labelTop < 0) {
      labelTop = rect.top + 2;
    }

    final labelRect = Rect.fromLTWH(
      rect.left.clamp(0, screenSize.width - labelWidth),
      labelTop,
      labelWidth,
      labelHeight,
    );
    
    // Draw label background with shadow (using person's color)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);
    
    canvas.drawRect(
      labelRect.shift(Offset(0, 1)), 
      shadowPaint
    );
    
    canvas.drawRect(
      labelRect, 
      Paint()..color = color.withOpacity(0.9)
    );

    // Draw text
    textPainter.paint(
      canvas, 
      Offset(labelRect.left + (labelPadding / 2), labelTop + 3)
    );
  }

  void _drawCornerMarkers(Canvas canvas, Rect rect, Color color) {
    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    
    const markerLength = 15.0;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(markerLength, 0), markerPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, markerLength), markerPaint);

    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-markerLength, 0), markerPaint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, markerLength), markerPaint);

    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(markerLength, 0), markerPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -markerLength), markerPaint);

    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-markerLength, 0), markerPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -markerLength), markerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}