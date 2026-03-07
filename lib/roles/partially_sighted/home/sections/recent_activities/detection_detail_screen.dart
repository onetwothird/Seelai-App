// File: lib/roles/visually_impaired/home/sections/recent_activities/detection_detail_screen.dart

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
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });

    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.detection['type'] as String;
    final icon = widget.detection['icon'] as IconData;
    final color = widget.detection['color'] as Color;
    final timestamp = DateTime.parse(widget.detection['timestamp'] as String);

    return Scaffold(
      backgroundColor: widget.theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.theme.backgroundColor,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              margin: EdgeInsets.all(spacingLarge),
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(radiusLarge),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacingMedium),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    child: Icon(icon, color: color, size: 40),
                  ),
                  SizedBox(width: spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTypeLabel(type),
                          style: h2.copyWith(
                            fontSize: 22,
                            color: widget.theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatDateTime(timestamp),
                          style: caption.copyWith(
                            fontSize: 13,
                            color: widget.theme.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Details Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacingLarge),
              child: _buildDetailsContent(type),
            ),

            SizedBox(height: spacingXLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsContent(String type) {
    switch (type) {
      case 'face':
        return _buildFaceDetails();
      case 'object':
        return _buildObjectDetails();
      case 'text':
        return _buildTextDetails();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildFaceDetails() {
    final faceCount = widget.detection['faceCount'] as int;
    final faces = widget.detection['faces'] as List? ?? [];
    final metadata = widget.detection['metadata'] as Map? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Detection Summary'),
        SizedBox(height: spacingMedium),
        _buildInfoCard([
          _buildInfoRow('Total Faces', '$faceCount'),
          if (metadata['fps'] != null)
            _buildInfoRow('FPS', metadata['fps'].toString()),
          _buildInfoRow('Device', metadata['deviceInfo']?.toString() ?? 'Camera'),
        ]),

        if (faces.isNotEmpty) ...[
          SizedBox(height: spacingLarge),
          _buildSectionTitle('Detected Faces'),
          SizedBox(height: spacingMedium),
          ...faces.asMap().entries.map((entry) {
            final index = entry.key;
            final face = entry.value as Map;
            final confidence = (face['confidence'] ?? 0.0) * 100;
            
            return Padding(
              padding: EdgeInsets.only(bottom: spacingMedium),
              child: Container(
                padding: EdgeInsets.all(spacingMedium),
                decoration: BoxDecoration(
                  color: widget.theme.cardColor,
                  borderRadius: BorderRadius.circular(radiusMedium),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(spacingSmall),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(radiusSmall),
                      ),
                      child: Icon(
                        Icons.face_rounded,
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
                            'Face ${index + 1}',
                            style: bodyBold.copyWith(
                              fontSize: 14,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Confidence: ${confidence.toStringAsFixed(1)}%',
                            style: caption.copyWith(
                              fontSize: 12,
                              color: widget.theme.subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(confidence).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(radiusSmall),
                      ),
                      child: Text(
                        _getConfidenceLabel(confidence),
                        style: caption.copyWith(
                          fontSize: 11,
                          color: _getConfidenceColor(confidence),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildObjectDetails() {
    final objectCount = widget.detection['objectCount'] as int;
    final objects = widget.detection['objects'] as List? ?? [];
    final metadata = widget.detection['metadata'] as Map? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Detection Summary'),
        SizedBox(height: spacingMedium),
        _buildInfoCard([
          _buildInfoRow('Total Objects', '$objectCount'),
          if (metadata['fps'] != null)
            _buildInfoRow('FPS', metadata['fps'].toString()),
          if (metadata['flashUsed'] != null)
            _buildInfoRow('Flash', metadata['flashUsed'] == true ? 'Used' : 'Not used'),
          _buildInfoRow('Device', metadata['deviceInfo']?.toString() ?? 'Camera'),
        ]),

        if (objects.isNotEmpty) ...[
          SizedBox(height: spacingLarge),
          _buildSectionTitle('Detected Objects'),
          SizedBox(height: spacingMedium),
          ...objects.asMap().entries.map((entry) {
            final obj = entry.value as Map;
            final label = obj['label'] ?? 'Unknown';
            final confidence = (obj['confidence'] ?? 0.0) * 100;

            return Padding(
              padding: EdgeInsets.only(bottom: spacingMedium),
              child: Container(
                padding: EdgeInsets.all(spacingMedium),
                decoration: BoxDecoration(
                  color: widget.theme.cardColor,
                  borderRadius: BorderRadius.circular(radiusMedium),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(spacingSmall),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(radiusSmall),
                      ),
                      child: Icon(
                        Icons.label_rounded,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: bodyBold.copyWith(
                              fontSize: 14,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Confidence: ${confidence.toStringAsFixed(1)}%',
                            style: caption.copyWith(
                              fontSize: 12,
                              color: widget.theme.subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(confidence).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(radiusSmall),
                      ),
                      child: Text(
                        _getConfidenceLabel(confidence),
                        style: caption.copyWith(
                          fontSize: 11,
                          color: _getConfidenceColor(confidence),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildTextDetails() {
    final text = widget.detection['text'] as String? ?? '';
    final textBlockCount = widget.detection['textBlockCount'] as int? ?? 0;
    final wordCount = widget.detection['wordCount'] as int? ?? 0;
    final characterCount = widget.detection['characterCount'] as int? ?? 0;
    final metadata = widget.detection['metadata'] as Map? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Detection Summary'),
        SizedBox(height: spacingMedium),
        _buildInfoCard([
          _buildInfoRow('Text Blocks', '$textBlockCount'),
          _buildInfoRow('Words', '$wordCount'),
          _buildInfoRow('Characters', '$characterCount'),
          if (metadata['flashUsed'] != null)
            _buildInfoRow('Flash', metadata['flashUsed'] == true ? 'Used' : 'Not used'),
          _buildInfoRow('Device', metadata['deviceInfo']?.toString() ?? 'Camera'),
        ]),

        if (text.isNotEmpty) ...[
          SizedBox(height: spacingLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Scanned Text'),
              Row(
                children: [
                  Semantics(
                    label: _isSpeaking ? 'Stop reading' : 'Read aloud',
                    button: true,
                    hint: 'Double tap to ${_isSpeaking ? 'stop' : 'read text aloud'}',
                    child: IconButton(
                      onPressed: () async {
                        if (_isSpeaking) {
                          await _flutterTts.stop();
                        } else {
                          await _flutterTts.speak(text);
                        }
                      },
                      icon: Icon(
                        _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                        color: Colors.orange,
                      ),
                      tooltip: _isSpeaking ? 'Stop reading' : 'Read aloud',
                    ),
                  ),
                  Semantics(
                    label: 'Copy text',
                    button: true,
                    hint: 'Double tap to copy text to clipboard',
                    child: IconButton(
                      onPressed: () async {
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
                      icon: Icon(
                        Icons.copy_rounded,
                        color: primary,
                      ),
                      tooltip: 'Copy text',
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacingMedium),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusMedium),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: SelectableText(
              text,
              style: body.copyWith(
                fontSize: 14,
                color: widget.theme.textColor,
                height: 1.6,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: bodyBold.copyWith(
        fontSize: 16,
        color: widget.theme.textColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusMedium),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: Border.all(
          color: widget.theme.subtextColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: body.copyWith(
              fontSize: 14,
              color: widget.theme.subtextColor,
            ),
          ),
          Text(
            value,
            style: bodyBold.copyWith(
              fontSize: 14,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

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
      case 'face':
        return 'Face Detection';
      case 'object':
        return 'Object Detection';
      case 'text':
        return 'Text Scan';
      default:
        return 'Detection';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $year at $hour:$minute $period';
  }
}