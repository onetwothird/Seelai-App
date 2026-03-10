// File: lib/roles/visually_impaired/home/sections/recent_activities/all_detections_screen.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'detection_detail_screen.dart';

class AllDetectionsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> detections;
  final bool isDarkMode;
  final dynamic theme;
  final String selectedFilter;

  const AllDetectionsScreen({
    super.key,
    required this.detections,
    required this.isDarkMode,
    required this.theme,
    required this.selectedFilter,
  });

  @override
  State<AllDetectionsScreen> createState() => _AllDetectionsScreenState();
}

class _AllDetectionsScreenState extends State<AllDetectionsScreen> {
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _filteredDetections = [];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter;
    _updateFilteredDetections();
  }

  void _updateFilteredDetections() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredDetections = widget.detections;
      } else {
        _filteredDetections = widget.detections.where((detection) {
          switch (_selectedFilter) {
            case 'Faces':
              return detection['type'] == 'face';
            case 'Objects':
              return detection['type'] == 'object';
            case 'Text':
              return detection['type'] == 'text';
            default:
              return true;
          }
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
          'Detections Gallery',
          style: h2.copyWith(
            fontSize: 20,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.06,
              vertical: spacingMedium,
            ),
            child: _buildFilterChips(),
          ),

          // Detection count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: spacingSmall),
            child: Row(
              children: [
                Text(
                  '${_filteredDetections.length} ${_filteredDetections.length == 1 ? 'Record' : 'Records'} found',
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: widget.theme.subtextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Detections Feed
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _filteredDetections.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      key: ValueKey(_selectedFilter),
                      padding: EdgeInsets.only(
                        left: width * 0.06,
                        right: width * 0.06,
                        bottom: spacingLarge,
                        top: spacingMedium,
                      ),
                      itemCount: _filteredDetections.length,
                      itemBuilder: (context, index) {
                        final detection = _filteredDetections[index];
                        return _buildVisualFeedCard(detection);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'icon': Icons.grid_view_rounded},
      {'label': 'Faces', 'icon': Icons.face_rounded},
      {'label': 'Objects', 'icon': Icons.search_rounded},
      {'label': 'Text', 'icon': Icons.document_scanner_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['label'];
          return Padding(
            padding: EdgeInsets.only(right: spacingSmall),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = filter['label'] as String;
                  _updateFilteredDetections();
                });
              },
              borderRadius: BorderRadius.circular(radiusLarge),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: spacingMedium,
                  vertical: spacingSmall,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? primary : widget.theme.cardColor,
                  borderRadius: BorderRadius.circular(radiusLarge),
                  border: Border.all(
                    color: isSelected
                        ? primary
                        : widget.theme.subtextColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      color: isSelected ? white : widget.theme.textColor,
                      size: 18,
                    ),
                    SizedBox(width: spacingSmall),
                    Text(
                      filter['label'] as String,
                      style: bodyBold.copyWith(
                        fontSize: 14,
                        color: isSelected ? white : widget.theme.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 👇 The entirely new, highly visual feed card design
  Widget _buildVisualFeedCard(Map<String, dynamic> detection) {
    final type = detection['type'] as String;
    final color = detection['color'] as Color;
    final timestamp = DateTime.parse(detection['timestamp'] as String);
    final timeAgo = _getTimeAgo(timestamp);
    final imageUrl = detection['imageUrl'] as String?;

    String title = '';
    String description = '';
    String detectedLabel = ''; 

    switch (type) {
      case 'face':
        final faceCount = detection['faceCount'] as int;
        title = 'Face Detection';
        detectedLabel = 'Face';
        description = 'Detected $faceCount ${faceCount == 1 ? 'face' : 'faces'}';
        break;
      case 'object':
        final objects = detection['objects'] as List? ?? [];
        title = 'Object Detection';
        if (objects.isNotEmpty) {
          final firstObject = objects.first['label'] as String;
          detectedLabel = '${firstObject[0].toUpperCase()}${firstObject.substring(1).toLowerCase()}';
          final conf = objects.first['confidence'];
          description = conf != null ? 'Confidence: ${(conf * 100).toStringAsFixed(1)}%' : 'Detected successfully';
        } else {
          detectedLabel = 'Object';
          description = 'No objects found';
        }
        break;
      case 'text':
        final text = detection['text'] as String? ?? '';
        title = 'Text Scan';
        detectedLabel = 'Document';
        description = text.length > 50 ? '${text.substring(0, 50)}...' : text;
        break;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: spacingLarge),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetectionDetailScreen(
                detection: detection,
                isDarkMode: widget.isDarkMode,
                theme: widget.theme,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusLarge),
            boxShadow: widget.isDarkMode ? [] : softShadow,
            border: Border.all(
              color: widget.theme.subtextColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Full Width Image Header
              if (imageUrl != null && imageUrl.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: widget.theme.backgroundColor,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(Icons.broken_image_rounded, size: 40, color: widget.theme.subtextColor),
                        ),
                      ),
                      // Type Badge Overlay
                      Positioned(
                        top: spacingMedium,
                        right: spacingMedium,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(radiusLarge),
                            border: Border.all(color: color, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(detection['icon'] as IconData, color: color, size: 14),
                              SizedBox(width: 4),
                              Text(
                                title,
                                style: caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                )
              else
                // Fallback Header
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(detection['icon'] as IconData, size: 40, color: color.withValues(alpha: 0.5)),
                  ),
                ),

              // 2. Info Section
              Padding(
                padding: EdgeInsets.all(spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            detectedLabel,
                            style: h2.copyWith(
                              fontSize: 18,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: caption.copyWith(
                            fontSize: 12,
                            color: widget.theme.subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacingSmall),
                    Text(
                      description,
                      style: body.copyWith(
                        fontSize: 14,
                        color: widget.theme.subtextColor,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.06),
        padding: EdgeInsets.symmetric(vertical: spacingXLarge, horizontal: spacingLarge),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: widget.isDarkMode ? [] : softShadow,
          border: Border.all(color: widget.theme.subtextColor.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: widget.theme.subtextColor.withOpacity(0.5), size: 48),
            SizedBox(height: spacingMedium),
            Text(
              'No $_selectedFilter records',
              style: bodyBold.copyWith(fontSize: 16, color: widget.theme.textColor, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: spacingSmall),
            Text(
              'Try scanning with $_selectedFilter mode',
              style: caption.copyWith(fontSize: 13, color: widget.theme.subtextColor),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    Duration difference = DateTime.now().difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}