// File: lib/roles/partially_sighted/home/sections/recent_activities/detection_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DetectionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> detection;
  final bool isDarkMode;
  final dynamic theme;

  const DetectionDetailScreen({
    super.key,
    required this.detection,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<DetectionDetailScreen> createState() => _DetectionDetailScreenState();
}

class _DetectionDetailScreenState extends State<DetectionDetailScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.detection['type'] as String;
    final color = widget.detection['color'] as Color;
    final timestamp = DateTime.parse(widget.detection['timestamp'] as String);
    final imageUrl = widget.detection['imageUrl'] as String?;

    return Scaffold(
      backgroundColor: widget.theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.theme.backgroundColor,
        surfaceTintColor: Colors.transparent, 
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: Semantics(
          label: 'Back button',
          button: true,
          hint: 'Double tap to go back',
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: widget.theme.textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          _getTypeLabel(type),
          style: h2.copyWith(
            fontSize: 20,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Image Section
            if (imageUrl != null && imageUrl.isNotEmpty)
              _buildHeroImage(imageUrl, color)
            else
              _buildFallbackHeader(color, type),

            // 2. Title & Action Row
            Padding(
              // Reduced bottom padding here so the Summary sits tighter against the header
              padding: EdgeInsets.fromLTRB(spacingLarge, spacingMedium, spacingLarge, spacingMedium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTypeLabel(type),
                          style: h2.copyWith(
                            fontSize: 24,
                            color: widget.theme.textColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: widget.theme.subtextColor),
                            SizedBox(width: 6),
                            Text(
                              _formatDateTime(timestamp),
                              style: bodyBold.copyWith(
                                fontSize: 13,
                                color: widget.theme.subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildActionButtons(type, color),
                ],
              ),
            ),

            // 3. Dynamic Details Content (Summary & List)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacingLarge),
              child: _buildDetailsContent(type, color),
            ),

            SizedBox(height: spacingXLarge * 2), // Bottom padding
          ],
        ),
      ),
    );
  }

  // ==================== WIDGET BUILDERS ====================

  Widget _buildHeroImage(String imageUrl, Color themeColor) {
    return Container(
      width: double.infinity,
      height: 280,
      margin: EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radiusLarge),
        color: widget.theme.cardColor,
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
        border: widget.isDarkMode ? Border.all(color: themeColor.withValues(alpha: 0.2)) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: themeColor,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: widget.theme.cardColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_rounded, color: widget.theme.subtextColor, size: 48),
                SizedBox(height: spacingSmall),
                Text('Image unavailable', style: caption.copyWith(color: widget.theme.subtextColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackHeader(Color color, String type) {
    IconData getFallbackIcon() {
      switch (type) {
        case 'face': return Icons.face_rounded;
        case 'object': return Icons.search_rounded;
        case 'text': return Icons.document_scanner_rounded;
        default: return Icons.image_rounded;
      }
    }

    return Container(
      width: double.infinity,
      height: 140,
      margin: EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingSmall),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Center(
        child: Icon(getFallbackIcon(), size: 64, color: color.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildActionButtons(String type, Color themeColor) {
    if (type != 'text' && type != 'face' && type != 'object') return SizedBox.shrink();

    return Row(
      children: [
        if (type == 'text') ...[
          Semantics(
            label: 'Copy text',
            button: true,
            child: IconButton(
              onPressed: () async {
                final text = widget.detection['text'] as String? ?? '';
                await Clipboard.setData(ClipboardData(text: text));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Text copied to clipboard'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: Icon(Icons.copy_rounded, color: widget.theme.textColor),
              tooltip: 'Copy text',
            ),
          ),
        ],
        Semantics(
          label: _isSpeaking ? 'Stop reading' : 'Read aloud',
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: _isSpeaking ? Colors.red.withValues(alpha: 0.1) : themeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () async {
                if (_isSpeaking) {
                  await _flutterTts.stop();
                } else {
                  String textToSpeak = _generateSpeechText(type);
                  await _flutterTts.speak(textToSpeak);
                }
              },
              icon: Icon(
                _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                color: _isSpeaking ? Colors.red : themeColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _generateSpeechText(String type) {
    switch (type) {
      case 'text':
        return widget.detection['text'] as String? ?? 'No text found.';
      case 'object':
        final objects = widget.detection['objects'] as List? ?? [];
        if (objects.isEmpty) return 'No objects detected.';
        final labels = objects.map((e) => e['label']).join(', ');
        return 'Detected objects are: $labels';
      case 'face':
        final faces = widget.detection['faces'] as List? ?? [];
        if (faces.isEmpty) return 'No faces detected.';
        final labels = faces.map((e) => e['label']).join(', ');
        return 'Detected faces: $labels';
      default:
        return 'Detection complete.';
    }
  }

  Widget _buildDetailsContent(String type, Color themeColor) {
    switch (type) {
      case 'face': return _buildFaceDetails(themeColor);
      case 'object': return _buildObjectDetails(themeColor);
      case 'text': return _buildTextDetails(themeColor);
      default: return SizedBox.shrink();
    }
  }

  // ==================== TYPE SPECIFIC DETAILS ====================

  Widget _buildFaceDetails(Color themeColor) {
    final faceCount = widget.detection['faceCount'] as int;
    final faces = widget.detection['faces'] as List? ?? [];
    final metadata = widget.detection['metadata'] as Map? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Detection Summary FIRST
        _buildSectionTitle('Detection Summary'),
        _buildInfoGrid([
          _buildGridItem('Total Faces', '$faceCount', Icons.people_alt_rounded, themeColor),
          if (metadata['fps'] != null)
            _buildGridItem('FPS', '${metadata['fps']}', Icons.speed_rounded, Colors.blue),
          if (metadata['lowLight'] != null)
            _buildGridItem('Light', metadata['lowLight'] == true ? 'Low' : 'Good', Icons.brightness_6_rounded, Colors.orange),
        ]),
        
        // 2. Detected Faces SECOND
        if (faces.isNotEmpty) ...[
          SizedBox(height: spacingXLarge), // Spacing added between sections
          _buildSectionTitle('Identified Faces'),
          ...faces.map((face) => _buildItemCard(
            label: face['label'] ?? 'Face',
            confidence: (face['confidence'] ?? 0.0) * 100,
            icon: Icons.face_rounded,
            themeColor: themeColor,
          )),
        ],
      ],
    );
  }

  Widget _buildObjectDetails(Color themeColor) {
    final objectCount = widget.detection['objectCount'] as int;
    final objects = widget.detection['objects'] as List? ?? [];
    final metadata = widget.detection['metadata'] as Map? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Detection Summary FIRST
        _buildSectionTitle('Detection Summary'),
        _buildInfoGrid([
          _buildGridItem('Total Objects', '$objectCount', Icons.category_rounded, themeColor),
          if (metadata['fps'] != null)
            _buildGridItem('FPS', '${metadata['fps']}', Icons.speed_rounded, Colors.blue),
          if (metadata['flashUsed'] != null)
            _buildGridItem('Flash', metadata['flashUsed'] == true ? 'Used' : 'Off', Icons.flashlight_on_rounded, Colors.orange),
        ]),

        // 2. Detected Objects SECOND
        if (objects.isNotEmpty) ...[
          SizedBox(height: spacingXLarge), // Spacing added between sections
          _buildSectionTitle('Detected Objects'),
          ...objects.map((obj) {
            String rawLabel = obj['label'] ?? 'Unknown';
            String cleanLabel = '${rawLabel[0].toUpperCase()}${rawLabel.substring(1).toLowerCase()}';
            return _buildItemCard(
              label: cleanLabel,
              confidence: (obj['confidence'] ?? 0.0) * 100,
              icon: Icons.label_rounded,
              themeColor: themeColor,
            );
          }),
        ],
      ],
    );
  }

  Widget _buildTextDetails(Color themeColor) {
    final text = widget.detection['text'] as String? ?? '';
    final textBlockCount = widget.detection['textBlockCount'] as int? ?? 0;
    final wordCount = widget.detection['wordCount'] as int? ?? 0;
    final metadata = widget.detection['metadata'] as Map? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Scan Summary FIRST
        _buildSectionTitle('Scan Summary'),
        _buildInfoGrid([
          _buildGridItem('Text Blocks', '$textBlockCount', Icons.view_agenda_rounded, themeColor),
          _buildGridItem('Word Count', '$wordCount', Icons.text_snippet_rounded, Colors.blue),
          if (metadata['flashUsed'] != null)
            _buildGridItem('Flash', metadata['flashUsed'] == true ? 'Used' : 'Off', Icons.flashlight_on_rounded, Colors.orange),
        ]),

        // 2. Extracted Document SECOND
        if (text.isNotEmpty) ...[
          SizedBox(height: spacingXLarge), // Spacing added between sections
          _buildSectionTitle('Extracted Document'),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(color: widget.theme.subtextColor.withValues(alpha: 0.1)),
              boxShadow: widget.isDarkMode ? [] : softShadow,
            ),
            child: SelectableText(
              text,
              style: body.copyWith(
                fontSize: 15,
                color: widget.theme.textColor,
                height: 1.6,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ==================== UI COMPONENTS ====================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Text(
        title,
        style: h3.copyWith(
          fontSize: 16,
          color: widget.theme.textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoGrid(List<Widget> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: item == items.last ? 0 : spacingSmall, 
            ),
            child: item,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: spacingMedium, horizontal: 4),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(color: widget.theme.subtextColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: caption.copyWith(fontSize: 11, color: widget.theme.subtextColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: bodyBold.copyWith(fontSize: 14, color: widget.theme.textColor, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard({required String label, required double confidence, required IconData icon, required Color themeColor}) {
    final confColor = _getConfidenceColor(confidence);
    
    return Container(
      margin: EdgeInsets.only(bottom: spacingMedium),
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(color: widget.theme.subtextColor.withValues(alpha: 0.1)),
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Icon(icon, color: themeColor, size: 20),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: bodyBold.copyWith(
                    fontSize: 15,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Confidence:',
                      style: caption.copyWith(fontSize: 12, color: widget.theme.subtextColor),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${confidence.toStringAsFixed(1)}%',
                      style: bodyBold.copyWith(fontSize: 12, color: widget.theme.textColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: confColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
            child: Text(
              _getConfidenceLabel(confidence),
              style: caption.copyWith(
                fontSize: 11,
                color: confColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getConfidenceLabel(double confidence) {
    if (confidence >= 80) return 'High';
    if (confidence >= 60) return 'Medium';
    return 'Low';
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'face': return 'Face Detection';
      case 'object': return 'Object Detection';
      case 'text': return 'Text Scan';
      default: return 'Detection';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour == 0 ? 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $year at $hour:$minute $period';
  }
}