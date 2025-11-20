// File: lib/roles/visually_impaired/screens/scanner/face_detection/face_detection_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/visually_impaired/camera_service.dart';

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
  bool _isScanning = false;
  String? _recognizedPerson;
  String? _relationship;

  @override
  void initState() {
    super.initState();
    _announceMode();
  }

  void _announceMode() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face detection mode activated - Caretaker recognition'),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _detectFace() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    // This is a placeholder for demonstration
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isScanning = false;
        _recognizedPerson = 'Maria Santos';
        _relationship = 'Primary Caretaker';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recognized: $_recognizedPerson ($_relationship)'),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (widget.cameraService.isInitialized && 
              widget.cameraService.controller != null)
            Positioned.fill(
              child: CameraPreview(widget.cameraService.controller!),
            )
          else
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 80,
                        color: white.withOpacity(0.3),
                      ),
                      SizedBox(height: spacingLarge),
                      Text(
                        'Camera Initializing...',
                        style: bodyBold.copyWith(
                          color: white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Dark overlay
          Positioned.fill(
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
          ),
          
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildHeader(),
            ),
          ),
          
          // Face detection frame
          Center(
            child: _buildFaceFrame(),
          ),
          
          // Instructions
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: _buildInstructions(),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildControls(),
            ),
          ),
          
          // Scanning indicator
          if (_isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                      ),
                      SizedBox(height: spacingLarge),
                      Text(
                        'Detecting face...',
                        style: bodyBold.copyWith(
                          color: white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(spacingLarge),
      child: Row(
        children: [
          Semantics(
            label: 'Back button',
            hint: 'Double tap to go back',
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
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
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Face Detection',
                  style: h2.copyWith(
                    color: white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Caretaker Recognition',
                  style: caption.copyWith(
                    color: white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceFrame() {
    return Container(
      width: 280,
      height: 340,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.purple,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(radiusXLarge),
      ),
      child: Stack(
        children: [
          // Corner accents
          _buildCornerAccent(Colors.purple, top: -2, left: -2, topLeft: true),
          _buildCornerAccent(Colors.purple, top: -2, right: -2, topRight: true),
          _buildCornerAccent(Colors.purple, bottom: -2, left: -2, bottomLeft: true),
          _buildCornerAccent(Colors.purple, bottom: -2, right: -2, bottomRight: true),
          
          // Face guide overlay
          Center(
            child: Icon(
              Icons.face_outlined,
              size: 120,
              color: Colors.purple.withOpacity(0.3),
            ),
          ),
          
          // Scanning animation line
          if (!_isScanning)
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(seconds: 2),
              builder: (context, double value, child) {
                return Positioned(
                  top: value * 340,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.purple.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
              onEnd: () {
                if (mounted && !_isScanning) {
                  setState(() {});
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCornerAccent(
    Color color, {
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: topLeft ? Radius.circular(radiusMedium) : Radius.zero,
            topRight: topRight ? Radius.circular(radiusMedium) : Radius.zero,
            bottomLeft: bottomLeft ? Radius.circular(radiusMedium) : Radius.zero,
            bottomRight: bottomRight ? Radius.circular(radiusMedium) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: spacingLarge),
        padding: EdgeInsets.symmetric(
          horizontal: spacingLarge,
          vertical: spacingMedium,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(radiusLarge),
          border: Border.all(
            color: white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.face_rounded,
              color: Colors.purple,
              size: 20,
            ),
            SizedBox(width: spacingSmall),
            Flexible(
              child: Text(
                'Position face within the frame',
                style: bodyBold.copyWith(
                  color: white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recognition result
          if (_recognizedPerson != null)
            Container(
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
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacingSmall),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _recognizedPerson!,
                          style: bodyBold.copyWith(
                            color: white,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _relationship ?? 'Unknown',
                          style: caption.copyWith(
                            color: white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.purple,
                    size: 24,
                  ),
                ],
              ),
            ),
          
          // Detect button
          Semantics(
            label: 'Detect face button',
            hint: 'Double tap to detect and recognize face',
            button: true,
            child: GestureDetector(
              onTap: _detectFace,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.purple.withOpacity(0.8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.face_rounded,
                  color: white,
                  size: 32,
                ),
              ),
            ),
          ),
          
          SizedBox(height: spacingMedium),
          
          // Manage caretakers button
          Semantics(
            label: 'Manage caretakers button',
            hint: 'Double tap to add or remove caretakers',
            button: true,
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Caretaker management coming soon!'),
                    backgroundColor: Colors.purple,
                  ),
                );
              },
              icon: Icon(Icons.people_rounded, color: white),
              label: Text(
                'Manage Caretakers',
                style: bodyBold.copyWith(
                  color: white,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: spacingLarge,
                  vertical: spacingMedium,
                ),
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusLarge),
                  side: BorderSide(
                    color: white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}