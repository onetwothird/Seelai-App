// File: lib/roles/visually_impaired/screens/camera_scanner_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/services/camera_service.dart';
import 'package:camera/camera.dart';

class CameraScannerScreen extends StatefulWidget {
  final CameraService cameraService;
  final bool isDarkMode;

  const CameraScannerScreen({
    super.key,
    required this.cameraService,
    required this.isDarkMode,
  });

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String? _selectedMode;
  bool _showModeSelector = true;

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

  void _selectMode(String mode) {
    setState(() {
      _selectedMode = mode;
      _showModeSelector = false;
    });
    
    // Announce selection
    String announcement = '';
    switch (mode) {
      case 'object':
        announcement = 'Object detection mode activated';
        break;
      case 'face':
        announcement = 'Face detection mode activated';
        break;
      case 'text':
        announcement = 'Text reading mode activated';
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(announcement),
        backgroundColor: primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _backToModeSelector() {
    setState(() {
      _selectedMode = null;
      _showModeSelector = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (widget.cameraService.isInitialized && widget.cameraService.controller != null)
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
          
          // Dark overlay for better visibility
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
          
          // Header with back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildHeader(),
            ),
          ),
          
          // Mode selector or scanning interface
          if (_showModeSelector)
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
            )
          else
            Positioned.fill(
              child: _buildScanningInterface(),
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
            child: Text(
              _selectedMode == null 
                ? 'Choose Scan Mode' 
                : _getModeTitle(_selectedMode!),
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

  String _getModeTitle(String mode) {
    switch (mode) {
      case 'object':
        return 'Object Detection';
      case 'face':
        return 'Face Detection';
      case 'text':
        return 'Read Document';
      default:
        return 'Scanner';
    }
  }

  Widget _buildModeSelector() {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radiusXLarge),
        ),
        border: Border(
          top: BorderSide(
            color: white.withOpacity(0.1),
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
              color: white.withOpacity(0.3),
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
              color: white.withOpacity(0.7),
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
            onTap: () => _selectMode('object'),
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildModeOption(
            icon: Icons.face_rounded,
            title: 'Face Detection',
            description: 'Detect and recognize faces',
            color: Colors.purple,
            onTap: () => _selectMode('face'),
          ),
          
          SizedBox(height: spacingMedium),
          
          _buildModeOption(
            icon: Icons.document_scanner_rounded,
            title: 'Read Document',
            description: 'Extract text from documents',
            color: Colors.orange,
            onTap: () => _selectMode('text'),
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
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
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
                          color: white.withOpacity(0.7),
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

  Widget _buildScanningInterface() {
    return Stack(
      children: [
        // Scanning frame overlay
        Center(
          child: _buildScanFrame(),
        ),
        
        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: _buildScanningControls(),
          ),
        ),
        
        // Instructions at top
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: _buildInstructions(),
        ),
      ],
    );
  }

  Widget _buildScanFrame() {
    Color frameColor = accent;
    if (_selectedMode == 'face') frameColor = Colors.purple;
    if (_selectedMode == 'text') frameColor = Colors.orange;
    
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        border: Border.all(
          color: frameColor,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      child: Stack(
        children: [
          // Corner accents
          Positioned(
            top: -2,
            left: -2,
            child: _buildCornerAccent(frameColor, isTopLeft: true),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: _buildCornerAccent(frameColor, isTopRight: true),
          ),
          Positioned(
            bottom: -2,
            left: -2,
            child: _buildCornerAccent(frameColor, isBottomLeft: true),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: _buildCornerAccent(frameColor, isBottomRight: true),
          ),
          
          // Scanning animation line
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(seconds: 2),
            builder: (context, double value, child) {
              return Positioned(
                top: value * 280,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        frameColor.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted) {
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCornerAccent(Color color, {
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: isTopLeft ? Radius.circular(radiusMedium) : Radius.zero,
          topRight: isTopRight ? Radius.circular(radiusMedium) : Radius.zero,
          bottomLeft: isBottomLeft ? Radius.circular(radiusMedium) : Radius.zero,
          bottomRight: isBottomRight ? Radius.circular(radiusMedium) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    String instruction = '';
    IconData instructionIcon = Icons.info_outline_rounded;
    
    switch (_selectedMode) {
      case 'object':
        instruction = 'Point camera at object to identify';
        instructionIcon = Icons.search_rounded;
        break;
      case 'face':
        instruction = 'Position face within the frame';
        instructionIcon = Icons.face_rounded;
        break;
      case 'text':
        instruction = 'Align document within the frame';
        instructionIcon = Icons.document_scanner_rounded;
        break;
    }
    
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
              instructionIcon,
              color: white,
              size: 20,
            ),
            SizedBox(width: spacingSmall),
            Flexible(
              child: Text(
                instruction,
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

  Widget _buildScanningControls() {
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
          // Capture/Scan button
          Semantics(
            label: 'Capture button',
            hint: 'Double tap to capture and analyze',
            button: true,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Scanning feature coming soon!'),
                    backgroundColor: primary,
                  ),
                );
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: white,
                  boxShadow: [
                    BoxShadow(
                      color: white.withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_rounded,
                  color: Colors.black,
                  size: 32,
                ),
              ),
            ),
          ),
          
          SizedBox(height: spacingLarge),
          
          // Change mode button
          Semantics(
            label: 'Change mode button',
            hint: 'Double tap to select different detection mode',
            button: true,
            child: TextButton.icon(
              onPressed: _backToModeSelector,
              icon: Icon(Icons.swap_horiz_rounded, color: white),
              label: Text(
                'Change Mode',
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