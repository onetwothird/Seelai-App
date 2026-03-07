// File: lib/roles/visually_impaired/screens/scanner/mode_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/partially_sighted/camera_service.dart';
import 'package:seelai_app/roles/partially_sighted/screens/scanner/object_detection/object_detection_screen.dart';
import 'package:seelai_app/roles/partially_sighted/screens/scanner/face_detection/face_detection_screen.dart';
import 'package:seelai_app/roles/partially_sighted/screens/scanner/text_document/text_reader_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  final CameraService cameraService;
  final bool isDarkMode;

  const ModeSelectionScreen({
    super.key,
    required this.cameraService,
    required this.isDarkMode,
  });

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToMode(String mode) {
    Widget screen;
    
    switch (mode) {
      case 'object':
        screen = ObjectDetectionScreen(
          cameraService: widget.cameraService,
          isDarkMode: widget.isDarkMode,
        );
        break;
      case 'face':
        screen = FaceDetectionScreen(
          cameraService: widget.cameraService,
          isDarkMode: widget.isDarkMode,
        );
        break;
      case 'text':
        screen = TextReaderScreen(
          cameraService: widget.cameraService,
          isDarkMode: widget.isDarkMode,
        );
        break;
      default:
        return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview Background
          if (widget.cameraService.isInitialized && 
              widget.cameraService.controller != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: CameraPreview(widget.cameraService.controller!),
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
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.9),
                  ],
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
          
          // Mode selector
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildModeSelector(),
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
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: Text(
              'Choose Scan Mode',
              style: h2.copyWith(
                color: white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radiusXLarge),
        ),
        border: Border(
          top: BorderSide(
            color: white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          SizedBox(height: spacingLarge),
          
          Text(
            'Select Detection Mode',
            style: h2.copyWith(
              color: white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          
          SizedBox(height: spacingSmall),
          
          Text(
            'Choose what you want to scan',
            style: body.copyWith(
              color: white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          
          SizedBox(height: spacingXLarge),
          
          // Mode options
          _buildModeOption(
            icon: Icons.search_rounded,
            title: 'Object Detection',
            description: 'Identify objects around you',
            color: accent,
            onTap: () => _navigateToMode('object'),
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildModeOption(
            icon: Icons.face_rounded,
            title: 'Face Detection',
            description: 'Detect and recognize caretakers',
            color: Colors.purple,
            onTap: () => _navigateToMode('face'),
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildModeOption(
            icon: Icons.document_scanner_rounded,
            title: 'Read Document',
            description: 'Extract text from documents',
            color: Colors.orange,
            onTap: () => _navigateToMode('text'),
          ),
          
          SizedBox(height: spacingLarge),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: '$title button',
      hint: description,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusLarge),
          child: Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: white,
                    size: 28,
                  ),
                ),
                
                SizedBox(width: spacingLarge),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: bodyBold.copyWith(
                          color: white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: caption.copyWith(
                          color: white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}