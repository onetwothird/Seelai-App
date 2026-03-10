// File: lib/roles/visually_impaired/screens/scanner/text_document/text_reader_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/partially_sighted/camera_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart'; 
import 'package:seelai_app/services/cloudinary_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextReaderScreen extends StatefulWidget {
  final CameraService cameraService;
  final bool isDarkMode;

  const TextReaderScreen({
    super.key,
    required this.cameraService,
    required this.isDarkMode,
  });

  @override
  State<TextReaderScreen> createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends State<TextReaderScreen> {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isProcessing = false;
  String? _extractedText;
  bool _documentDetected = false;
  int _textBlockCount = 0;
  Rect? _textBoundingBox;
  bool _hasReadText = false;
  String _lastReadText = '';
  bool _isReading = false;
  bool _readingCompleted = false;
  bool _isLowLight = false;
  bool _isFlashOn = false;
  int _brightnessCheckCounter = 0;
  bool _showFlashIndicator = false;
  Timer? _flashIndicatorTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeTts();
    _announceMode();
    _startContinuousDetection();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _flutterTts.stop();
    _turnOffFlash();
    _flashIndicatorTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isReading = false;
          _readingCompleted = true;
        });
      }
    });
    
    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isReading = true;
          _readingCompleted = false;
        });
      }
    });
    
    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isReading = false;
          _readingCompleted = true;
        });
      }
    });
  }

  void _announceMode() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _flutterTts.speak('Text reading mode activated. Point camera at text.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Text reading mode activated - Point camera at text'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _startContinuousDetection() async {
    while (mounted) {
      if (!_isProcessing && 
          widget.cameraService.isInitialized && 
          (!_isReading || !_hasReadText)) {
        await _detectAndReadText();
      }
      await Future.delayed(Duration(milliseconds: 300));
    }
  }

  Future<void> _checkBrightnessAndToggleFlash() async {
    _brightnessCheckCounter++;
    if (_brightnessCheckCounter < 5) return;
    _brightnessCheckCounter = 0;

    if (!widget.cameraService.isInitialized || 
        widget.cameraService.controller == null) {
      return;
    }

    try {
      if (!_documentDetected && !_isFlashOn) {
        await _turnOnFlash();
      }
    } catch (e) {
      debugPrint('Error checking brightness: $e');
    }
  }

  Future<void> _turnOnFlash() async {
    try {
      final controller = widget.cameraService.controller;
      if (controller != null && mounted) {
        await controller.setFlashMode(FlashMode.torch);
        setState(() {
          _isFlashOn = true;
          _isLowLight = true;
          _showFlashIndicator = true;
        });
        
        _flutterTts.speak('Low light detected. Flashlight turned on.');
        
        _flashIndicatorTimer?.cancel();
        _flashIndicatorTimer = Timer(Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showFlashIndicator = false;
            });
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.flashlight_on, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Low light - Flashlight mode ON'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error turning on flash: $e');
    }
  }

  Future<void> _turnOffFlash() async {
    try {
      final controller = widget.cameraService.controller;
      if (controller != null && mounted) {
        await controller.setFlashMode(FlashMode.off);
        setState(() {
          _isFlashOn = false;
          _isLowLight = false;
          _showFlashIndicator = false;
        });
        _flashIndicatorTimer?.cancel();
      }
    } catch (e) {
      debugPrint('Error turning off flash: $e');
    }
  }

  void _toggleFlashManually() async {
    if (_isFlashOn) {
      await _turnOffFlash();
      _flutterTts.speak('Flashlight turned off.');
    } else {
      await _turnOnFlash();
    }
  }

  Rect _calculateBoundingBox(List<TextBlock> blocks) {
    if (blocks.isEmpty) return Rect.zero;
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (var block in blocks) {
      final rect = block.boundingBox;
      if (rect.left < minX) minX = rect.left;
      if (rect.top < minY) minY = rect.top;
      if (rect.right > maxX) maxX = rect.right;
      if (rect.bottom > maxY) maxY = rect.bottom;
    }
    
    final width = maxX - minX;
    final height = maxY - minY;
    final area = width * height;
    
    double paddingHorizontal = 100.0;
    double paddingVertical = 100.0;
    
    if (area > 500000) {
      paddingHorizontal = 150.0;
      paddingVertical = 150.0;
    } else if (area > 300000) {
      paddingHorizontal = 120.0;
      paddingVertical = 120.0;
    } else if (area > 100000) {
      paddingHorizontal = 100.0;
      paddingVertical = 100.0;
    } else {
      paddingHorizontal = 80.0;
      paddingVertical = 80.0;
    }
    
    if (blocks.length > 1 || (blocks.isNotEmpty && blocks.first.lines.length > 2)) {
      paddingHorizontal *= 1.15;
      paddingVertical *= 1.15;
    }
    
    return Rect.fromLTRB(
      minX - paddingHorizontal,
      minY - paddingVertical,
      maxX + paddingHorizontal,
      maxY + paddingVertical,
    );
  }

  Future<void> _saveScannedTextToFirebase(String text, int blockCount, {String? imageUrl}) async {
    try {
      final userId = authService.value.currentUser?.uid;
      if (userId == null) {
        debugPrint('No user logged in, cannot save to Firebase');
        return;
      }

      final success = await textScanService.saveScannedText(
        userId: userId,
        scannedText: text,
        textBlockCount: blockCount,
        sourceType: 'document',
        imageUrl: imageUrl,
        metadata: {
          'flashUsed': _isFlashOn,
          'lowLight': _isLowLight,
          'deviceInfo': 'mobile_camera',
        },
      );

      if (success) {
        debugPrint('Scanned text saved to Firebase successfully');
      } else {
        debugPrint('Failed to save scanned text to Firebase');
      }
    } catch (e) {
      debugPrint('Error saving to Firebase: $e');
    }
  }

  Future<void> _detectAndReadText() async {
    if (_isProcessing || widget.cameraService.controller == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final image = await widget.cameraService.controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (mounted) {
        final hasText = recognizedText.blocks.isNotEmpty;
        final extractedText = recognizedText.text.trim();
        
        setState(() {
          _textBlockCount = recognizedText.blocks.length;
          _documentDetected = hasText;
          _extractedText = extractedText.isNotEmpty ? extractedText : null;
          
          if (hasText) {
            _textBoundingBox = _calculateBoundingBox(recognizedText.blocks);
          } else {
            _textBoundingBox = null;
          }
        });
        
        await _checkBrightnessAndToggleFlash();
        
        if (extractedText.isNotEmpty) {
          bool isDifferentText = (extractedText.length - _lastReadText.length).abs() > 10 ||
                                 !extractedText.contains(_lastReadText.substring(0, _lastReadText.length.clamp(0, 20)));
          
          if ((isDifferentText || _lastReadText.isEmpty) && !_isReading) {
            _lastReadText = extractedText;
            _hasReadText = true;
            _readingCompleted = false;
            
            String? uploadedImageUrl;
            final userId = authService.value.currentUser?.uid;
            if (userId != null) {
              uploadedImageUrl = await cloudinaryService.uploadDetectionImage(
                File(image.path), 
                userId, 
                'text'
              );
            }
            
            await _saveScannedTextToFirebase(extractedText, recognizedText.blocks.length, imageUrl: uploadedImageUrl);
            
            await _flutterTts.speak(extractedText);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reading all detected text: ${recognizedText.blocks.length} blocks'),
                  backgroundColor: Colors.green,
                  duration: Duration(milliseconds: 800),
                ),
              );
            }
          }
        } else {
          if (!_isReading) {
            _readingCompleted = true;
          }
        }
      }
    } catch (e) {
      debugPrint('Error detecting text: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showTextModal() {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        height: screenHeight * 0.8,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Colors.grey[900] : white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXLarge),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: spacingMedium),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDarkMode 
                    ? white.withValues(alpha: 0.3) 
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(spacingLarge),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Extracted Text',
                    style: h2.copyWith(
                      color: widget.isDarkMode ? white : Colors.black,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(modalContext),
                    icon: Icon(
                      Icons.close_rounded,
                      color: widget.isDarkMode ? white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(spacingLarge),
                child: SelectableText(
                  _extractedText ?? '',
                  style: body.copyWith(
                    color: widget.isDarkMode ? white : Colors.black,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                color: widget.isDarkMode 
                    ? Colors.grey[850] 
                    : Colors.grey[100],
                border: Border(
                  top: BorderSide(
                    color: widget.isDarkMode 
                        ? Colors.grey[700]! 
                        : Colors.grey[300]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _extractedText ?? ''));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Text copied to clipboard'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.copy_rounded),
                      label: Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: white,
                        padding: EdgeInsets.symmetric(vertical: spacingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radiusMedium),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: spacingMedium),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_extractedText != null) {
                          await _flutterTts.speak(_extractedText!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reading text aloud...'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.volume_up_rounded),
                      label: Text('Read Aloud'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isDarkMode 
                            ? Colors.grey[800] 
                            : Colors.grey[300],
                        foregroundColor: widget.isDarkMode ? white : Colors.black,
                        padding: EdgeInsets.symmetric(vertical: spacingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
                        size: screenWidth * 0.2,
                        color: white.withValues(alpha: 0.3),
                      ),
                      SizedBox(height: spacingLarge),
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
              ),
            ),
          
          Positioned.fill(
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
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildHeader(screenWidth),
            ),
          ),
          
          if (_documentDetected && _textBoundingBox != null)
            _buildDynamicDocumentFrame(screenWidth, screenHeight),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLowLight && _isFlashOn)
                    _buildFlashIndicator(screenWidth),
                  _buildControls(screenWidth, screenHeight),
                ],
              ),
            ),
          ),
          
          if (_isProcessing)
            Positioned(
              top: screenHeight * 0.5 - 40,
              left: screenWidth * 0.5 - 20,
              child: Container(
                padding: EdgeInsets.all(spacingSmall),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDynamicDocumentFrame(double screenWidth, double screenHeight) {
    if (_textBoundingBox == null) return SizedBox.shrink();
    
    final controller = widget.cameraService.controller;
    if (controller == null) return SizedBox.shrink();
    
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return SizedBox.shrink();
    
    final isPortrait = previewSize.height > previewSize.width;
    final cameraWidth = isPortrait ? previewSize.width : previewSize.height;
    final cameraHeight = isPortrait ? previewSize.height : previewSize.width;
    
    final scaleX = screenWidth / cameraWidth;
    final scaleY = screenHeight / cameraHeight;
    final scale = scaleX > scaleY ? scaleX : scaleY;
    
    final previewWidth = cameraWidth * scale;
    final previewHeight = cameraHeight * scale;
    
    final offsetX = (previewWidth - screenWidth) / 2;
    final offsetY = (previewHeight - screenHeight) / 2;
    
    final scaledLeft = (_textBoundingBox!.left * scale) - offsetX;
    final scaledTop = (_textBoundingBox!.top * scale) - offsetY;
    final scaledWidth = _textBoundingBox!.width * scale;
    final scaledHeight = _textBoundingBox!.height * scale;
    
    final minMargin = screenWidth * 0.02;
    final topMargin = screenHeight * 0.12;
    final bottomMargin = screenHeight * 0.25;
    
    final constrainedLeft = scaledLeft.clamp(minMargin, screenWidth - minMargin - 50);
    final constrainedTop = scaledTop.clamp(topMargin, screenHeight - bottomMargin - 50);
    final maxWidth = screenWidth - (minMargin * 2);
    final maxHeight = screenHeight - topMargin - bottomMargin;
    final constrainedWidth = scaledWidth.clamp(screenWidth * 0.2, maxWidth);
    final constrainedHeight = scaledHeight.clamp(screenHeight * 0.08, maxHeight);
    
    return Positioned(
      left: constrainedLeft,
      top: constrainedTop,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: constrainedWidth,
        height: constrainedHeight,
        decoration: BoxDecoration(
          border: Border.all(
            color: Color(0xFFFF006E),
            width: screenWidth * 0.015,
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF006E).withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.04),
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
                    size: screenWidth * 0.06,
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
                  'Read Document',
                  style: h2.copyWith(
                    color: white,
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _documentDetected 
                      ? 'Reading: $_textBlockCount blocks' 
                      : 'Searching for text...',
                  style: caption.copyWith(
                    color: _documentDetected 
                        ? (_isReading ? Colors.orange : Colors.green)
                        : white.withValues(alpha: 0.7),
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: _isFlashOn ? 'Flashlight is on. Double tap to turn off' : 'Flashlight is off. Double tap to turn on',
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleFlashManually,
                borderRadius: BorderRadius.circular(radiusSmall),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: screenWidth * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: _isFlashOn 
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(radiusSmall),
                    border: Border.all(
                      color: _isFlashOn ? Colors.orange : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isFlashOn ? Icons.flashlight_on : Icons.flashlight_off,
                        color: _isFlashOn ? Colors.orange : Colors.grey[400],
                        size: screenWidth * 0.045,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        _isFlashOn ? 'ON' : 'OFF',
                        style: caption.copyWith(
                          color: _isFlashOn ? Colors.orange : Colors.grey[400],
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashIndicator(double screenWidth) {
    return AnimatedOpacity(
      opacity: _showFlashIndicator ? 1.0 : 0.0,
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
          color: Colors.orange.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
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

  Widget _buildControls(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_extractedText != null)
            Container(
              margin: EdgeInsets.only(bottom: spacingLarge),
              padding: EdgeInsets.all(spacingMedium),
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
                      SizedBox(width: spacingSmall),
                      Expanded(
                        child: Text(
                          'Text Auto-Read & Saved',
                          style: bodyBold.copyWith(
                            color: white,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _showTextModal,
                        child: Text(
                          'View Full',
                          style: bodyBold.copyWith(
                            color: Colors.green,
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacingSmall),
                  Text(
                    _extractedText!.length > 100 
                        ? '${_extractedText!.substring(0, 100)}...' 
                        : _extractedText!,
                    style: caption.copyWith(
                      color: white.withValues(alpha: 0.7),
                      fontSize: screenWidth * 0.03,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isReading 
                    ? Icons.volume_up
                    : _documentDetected 
                        ? Icons.check_circle 
                        : Icons.search,
                color: _isReading
                    ? Colors.orange
                    : _documentDetected 
                        ? Colors.green 
                        : Colors.orange,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: spacingSmall),
              Flexible(
                child: Text(
                  _isReading
                      ? 'Reading text...'
                      : _documentDetected 
                          ? (_readingCompleted ? 'Done - Ready for next scan' : 'Auto-scanning active')
                          : 'Looking for text...',
                  style: bodyBold.copyWith(
                    color: white.withValues(alpha: 0.9),
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}