// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/visually_impaired/camera_service.dart';
import 'object_detection_controller.dart';

class ObjectDetectionScreen extends StatefulWidget {
  final CameraService cameraService;
  final bool isDarkMode;

  const ObjectDetectionScreen({
    super.key,
    required this.cameraService,
    required this.isDarkMode,
  });

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  late ObjectDetectionController _controller;
  ObjectDetectionState _state = ObjectDetectionState(
    recognitions: [],
    isDetecting: false,
    isModelLoaded: false,
    isReading: false,
    readingCompleted: false,
    fps: 0.0,
    isFlashOn: false,
    isLowLight: false,
    showFlashIndicator: false,
    lastDetectedObjects: '',
  );

  @override
  void initState() {
    super.initState();
    _controller = ObjectDetectionController(
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
            content: Text('Object detection mode activated - Point camera at objects'),
            backgroundColor: Colors.orange,
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
            
            // Bounding Boxes - ACCURATE VERSION
            if (_state.isModelLoaded)
              BoundingBoxes(
                recognitions: _state.recognitions,
                cameraController: widget.cameraService.controller!,
                screenSize: screenSize,
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
          'Detect Objects',
          style: h2.copyWith(
            color: white,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          _state.recognitions.isNotEmpty
              ? 'Reading: ${_state.recognitions.length} objects'
              : 'Looking for objects...',
          style: caption.copyWith(
            color: _state.recognitions.isNotEmpty
                ? (_state.isReading ? Colors.orange : Colors.green)
                : white.withOpacity(0.7),
            fontSize: screenWidth * 0.03,
          ),
        ),
      ],
    );
  }

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
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(radiusSmall),
              border: Border.all(
                color: _state.isFlashOn ? Colors.orange : Colors.grey,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _state.isFlashOn ? Icons.flashlight_on : Icons.flashlight_off,
                  color: _state.isFlashOn ? Colors.orange : Colors.grey[400],
                  size: screenWidth * 0.045,
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  _state.isFlashOn ? 'ON' : 'OFF',
                  style: caption.copyWith(
                    color: _state.isFlashOn ? Colors.orange : Colors.grey[400],
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
          color: Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
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
          if (_state.lastDetectedObjects.isNotEmpty)
            _buildDetectedObjectsInfo(screenWidth),
          _buildStatusRow(screenWidth),
        ],
      ),
    );
  }

  Widget _buildDetectedObjectsInfo(double screenWidth) {
    return Container(
      margin: EdgeInsets.only(bottom: spacingLarge),
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(
          color: Colors.green.withOpacity(0.4),
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
                color: Colors.green,
                size: screenWidth * 0.05,
              ),
              SizedBox(width: spacingSmall),
              Expanded(
                child: Text(
                  'Objects Auto-Read & Saved',
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
            _state.lastDetectedObjects.length > 80 
                ? '${_state.lastDetectedObjects.substring(0, 80)}...' 
                : _state.lastDetectedObjects,
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
                  ? Icons.check_circle
                  : Icons.search,
          color: _state.isReading
              ? Colors.orange
              : _state.recognitions.isNotEmpty
                  ? Colors.green
                  : Colors.orange,
          size: screenWidth * 0.06,
        ),
        SizedBox(width: spacingSmall),
        Flexible(
          child: Text(
            _state.isReading
                ? 'Reading objects...'
                : _state.recognitions.isNotEmpty
                    ? (_state.readingCompleted ? 'Done - Ready for next scan' : 'Auto-scanning active')
                    : 'Looking for objects...',
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
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(radiusSmall),
            border: Border.all(color: Colors.orange.withOpacity(0.4)),
          ),
          child: Text(
            'FPS: ${_state.fps.toStringAsFixed(1)}',
            style: caption.copyWith(
              color: Colors.orange,
              fontSize: screenWidth * 0.03,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ACCURATE Bounding Boxes - Tight fit on ALL devices
// =============================================================================

class BoundingBoxes extends StatelessWidget {
  final List<Map<String, dynamic>> recognitions;
  final CameraController cameraController;
  final Size screenSize;

  const BoundingBoxes({
    super.key,
    required this.recognitions,
    required this.cameraController,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    if (recognitions.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: BoxPainter(
        recognitions: recognitions,
        cameraController: cameraController,
        screenSize: screenSize,
      ),
    );
  }
}

// =============================================================================
// FIXED Box Painter - Accurate coordinates for ALL mobile devices
// =============================================================================

class BoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> recognitions;
  final CameraController cameraController;
  final Size screenSize;

  BoxPainter({
    required this.recognitions,
    required this.cameraController,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

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
        
        // Draw bounding box
        canvas.drawRect(rect, paint);

        // Draw label
        _drawLabel(canvas, rect, recognition, box);
        
        // Draw corner markers
        _drawCornerMarkers(canvas, rect);
      }
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, Map<String, dynamic> recognition, List<dynamic> box) {
    final label = recognition['tag'] ?? '';
    final confidence = box.length > 4 ? (box[4] ?? 0.0) : 0.0;
    final text = '$label ${(confidence * 100).toStringAsFixed(0)}%';

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
    
    // Draw label background with shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);
    
    canvas.drawRect(
      labelRect.shift(Offset(0, 1)), 
      shadowPaint
    );
    
    canvas.drawRect(
      labelRect, 
      Paint()..color = Colors.green.withOpacity(0.9)
    );

    // Draw text
    textPainter.paint(
      canvas, 
      Offset(labelRect.left + (labelPadding / 2), labelTop + 3)
    );
  }

  void _drawCornerMarkers(Canvas canvas, Rect rect) {
    final markerPaint = Paint()
      ..color = Colors.green
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