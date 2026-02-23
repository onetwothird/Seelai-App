// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/partially_sighted/camera_service.dart';
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
    isFlashOn: false,
    isLowLight: false,
    showFlashIndicator: false,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_state.isLowLight && _state.isFlashOn)
                      _buildFlashIndicator(screenWidth),
                    _buildControls(screenWidth),
                  ],
                ),
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
          _buildFlashToggle(screenWidth),
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

  // ADDED: Flash Toggle Button in Header
  Widget _buildFlashToggle(double screenWidth) {
    return Semantics(
      label: _state.isFlashOn 
          ? 'Flashlight is on. Double tap to turn off' 
          : 'Flashlight is off. Double tap to turn on',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _controller.toggleFlashManually();
            if (_state.isFlashOn) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Flashlight turned off'),
                  backgroundColor: Colors.grey,
                  duration: Duration(milliseconds: 800),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(radiusSmall),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.025,
              vertical: screenWidth * 0.015,
            ),
            decoration: BoxDecoration(
              color: _state.isFlashOn 
                  ? Colors.purple.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(radiusSmall),
              border: Border.all(
                color: _state.isFlashOn ? Colors.purple : Colors.grey,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _state.isFlashOn ? Icons.flashlight_on : Icons.flashlight_off,
                  color: _state.isFlashOn ? Colors.purple : Colors.grey[400],
                  size: screenWidth * 0.045,
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  _state.isFlashOn ? 'ON' : 'OFF',
                  style: caption.copyWith(
                    color: _state.isFlashOn ? Colors.purple : Colors.grey[400],
                    fontSize: screenWidth * 0.028,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ADDED: Auto-Flash Indicator
  Widget _buildFlashIndicator(double screenWidth) {
    return AnimatedOpacity(
      opacity: _state.showFlashIndicator ? 1.0 : 0.0,
      duration: Duration(milliseconds: 500),
      child: Container(
        margin: EdgeInsets.only(
          bottom: spacingMedium,
          left: screenWidth * 0.04,
          right: screenWidth * 0.04,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: spacingMedium,
        ),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.9),
          borderRadius: BorderRadius.circular(radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flashlight_on,
              color: Colors.white,
              size: screenWidth * 0.05,
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'Low light - Flashlight mode ON',
              style: bodyBold.copyWith(
                color: Colors.white,
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
// FIXED Face Box Painter - Corrects XYXY parsing and Aspect Ratio Scaling
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
    // 1. Get the actual source image dimensions
    if (cameraController.value.previewSize == null) return;
    final Size previewSize = cameraController.value.previewSize!;
    
    // 2. Determine the source dimensions relative to the screen orientation.
    double sourceWidth = previewSize.height; 
    double sourceHeight = previewSize.width; 

    // 3. Calculate Scale to maintain aspect ratio (BoxFit.cover)
    final double scaleX = size.width / sourceWidth;
    final double scaleY = size.height / sourceHeight;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    // 4. Calculate the size of the camera feed on the screen
    final double displayedWidth = sourceWidth * scale;
    final double displayedHeight = sourceHeight * scale;

    // 5. Calculate offsets to center the camera feed (cropping)
    final double offsetX = (displayedWidth - size.width) / 2;
    final double offsetY = (displayedHeight - size.height) / 2;

    for (var recognition in recognitions) {
      final box = recognition['box'];
      
      if (box == null || box.length < 4) continue;

      // Coordinate Conversion (YOLO XYXY)
      double x1 = box[0].toDouble();
      double y1 = box[1].toDouble();
      double x2 = box[2].toDouble();
      double y2 = box[3].toDouble();
      
      // Calculate ACTUAL width and height
      double w = x2 - x1;
      double h = y2 - y1;

      // Apply Scale
      double scaledX = x1 * scale;
      double scaledY = y1 * scale;
      double scaledW = w * scale;
      double scaledH = h * scale;

      // Apply Crop Offset
      double finalX = scaledX - offsetX;
      double finalY = scaledY - offsetY;

      // Get person name 
      final personName = (recognition['tag'] ?? 'unknown').toString();
      // Force PURPLE color for everyone as requested
      final boxColor = Colors.purple; 

      // Draw
      final rect = Rect.fromLTWH(finalX, finalY, scaledW, scaledH);
      
      // Safety check: only draw if partially visible
      if (rect.overlaps(Offset.zero & size)) {
        
        // Draw bounding box
        final paint = Paint()
          ..color = boxColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        
        canvas.drawRect(rect, paint);

        // Draw label
        _drawLabel(canvas, rect, recognition, box, boxColor, personName);
        
        // Draw corner markers
        _drawCornerMarkers(canvas, rect, boxColor);
      }
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, Map<String, dynamic> recognition, 
                  List<dynamic> box, Color color, String personName) {
    // Confidence is at index 4
    final confidence = box.length > 4 ? (box[4] ?? 0.0) : 0.0;
    final text = '$personName ${(confidence * 100).toStringAsFixed(0)}%';

    // UPDATED: Matched Object Detection Font Style (No heavy shadow)
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
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
    
    // Position label above box
    double labelTop = rect.top - labelHeight - 2;
    if (labelTop < 0) {
      labelTop = rect.top + 2;
    }

    // Ensure label doesn't go off-screen right
    double labelLeft = rect.left;
    if (labelLeft + labelWidth > screenSize.width) {
      labelLeft = screenSize.width - labelWidth;
    }

    final labelRect = Rect.fromLTWH(
      labelLeft,
      labelTop,
      labelWidth,
      labelHeight,
    );
    
    // Draw simple background rect (same as Object Detection)
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