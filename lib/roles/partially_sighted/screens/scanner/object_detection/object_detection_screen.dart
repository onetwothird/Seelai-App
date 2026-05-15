import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/partially_sighted/camera_service.dart';
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
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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

   return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        await _controller.dispose();
        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
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
            
            // Animated Bounding Boxes - Smooth and Accurate
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
              color: white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: spacingLarge),
            Text(
              'Camera Initializing...',
              style: bodyBold.copyWith(
                color: white.withValues(alpha: 0.7),
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
              Colors.black.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.6),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
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
          const SizedBox(width: spacingMedium),
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
            padding: const EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(radiusMedium),
              border: Border.all(
                color: white.withValues(alpha: 0.2),
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
                : white.withValues(alpha: 0.7),
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
                const SnackBar(
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
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3),
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
      duration: const Duration(milliseconds: 500),
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
          color: Colors.orange.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(
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
      margin: const EdgeInsets.only(bottom: spacingLarge),
      padding: const EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.4),
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
              const SizedBox(width: spacingSmall),
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
          const SizedBox(height: spacingSmall),
          Text(
            _state.lastDetectedObjects.length > 80 
                ? '${_state.lastDetectedObjects.substring(0, 80)}...' 
                : _state.lastDetectedObjects,
            style: caption.copyWith(
              color: white.withValues(alpha: 0.7),
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
        const SizedBox(width: spacingSmall),
        Flexible(
          child: Text(
            _state.isReading
                ? 'Reading objects...'
                : _state.recognitions.isNotEmpty
                    ? (_state.readingCompleted ? 'Done - Ready for next scan' : 'Auto-scanning active')
                    : 'Looking for objects...',
            style: bodyBold.copyWith(
              color: white.withValues(alpha: 0.9),
              fontSize: screenWidth * 0.035,
            ),
          ),
        ),
        const SizedBox(width: spacingLarge),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03, 
            vertical: spacingSmall,
          ),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(radiusSmall),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
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
// SMOOTH Animated Object Bounding Boxes with Custom Corner UI
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
    if (recognitions.isEmpty || cameraController.value.previewSize == null) {
      return const SizedBox.shrink();
    }

    final Size previewSize = cameraController.value.previewSize!;
    double sourceWidth = previewSize.height; 
    double sourceHeight = previewSize.width; 

    final double scaleX = screenSize.width / sourceWidth;
    final double scaleY = screenSize.height / sourceHeight;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    final double displayedWidth = sourceWidth * scale;
    final double displayedHeight = sourceHeight * scale;

    final double offsetX = (displayedWidth - screenSize.width) / 2;
    final double offsetY = (displayedHeight - screenSize.height) / 2;

    return Stack(
      children: recognitions.asMap().entries.map((entry) {
        int idx = entry.key;
        var recognition = entry.value;
        final box = recognition['box'];
        
        if (box == null || box.length < 4) return const SizedBox.shrink();

        double x1 = box[0].toDouble();
        double y1 = box[1].toDouble();
        double x2 = box[2].toDouble();
        double y2 = box[3].toDouble();

        double w = x2 - x1;
        double h = y2 - y1;

        double scaledX = x1 * scale;
        double scaledY = y1 * scale;
        double scaledW = w * scale;
        double scaledH = h * scale;

        double finalX = scaledX - offsetX;
        double finalY = scaledY - offsetY;

        final label = recognition['tag'] ?? '';
        final confidence = box.length > 4 ? (box[4] ?? 0.0) : 0.0;
        final text = '$label ${(confidence * 100).toStringAsFixed(0)}%';
        const boxColor = Colors.green;

        return AnimatedPositioned(
          key: ValueKey('object_box_$idx'),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          left: finalX,
          top: finalY,
          width: scaledW,
          height: scaledH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Boundary and Corners
              Positioned.fill(
                child: CustomPaint(
                  painter: CornersPainter(boxColor),
                ),
              ),
              // Label
              Positioned(
                left: 0,
                top: -24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: boxColor.withValues(alpha: 0.9),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Custom Painter strictly for drawing the precise corner markers
class CornersPainter extends CustomPainter {
  final Color color;
  CornersPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    final rect = Offset.zero & size;
    canvas.drawRect(rect, boxPaint);

    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    
    const markerLength = 15.0;

    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(markerLength, 0), markerPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, markerLength), markerPaint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-markerLength, 0), markerPaint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, markerLength), markerPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(markerLength, 0), markerPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -markerLength), markerPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-markerLength, 0), markerPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -markerLength), markerPaint);
  }

  @override
  bool shouldRepaint(covariant CornersPainter oldDelegate) => oldDelegate.color != color;
}