// File: lib/roles/visually_impaired/home/sections/recent_activities/all_detections_screen.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'detection_detail_screen.dart'; // ✅ ADD THIS IMPORT

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
          'All Detections',
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
            padding: EdgeInsets.symmetric(horizontal: width * 0.06),
            child: Row(
              children: [
                Text(
                  '${_filteredDetections.length} ${_filteredDetections.length == 1 ? 'detection' : 'detections'}',
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: widget.theme.subtextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: spacingMedium),

          // Detections list
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _filteredDetections.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      key: ValueKey(_selectedFilter),
                      padding: EdgeInsets.only(
                        left: width * 0.06,
                        right: width * 0.06,
                        bottom: spacingLarge,
                      ),
                      itemCount: _filteredDetections.length,
                      itemBuilder: (context, index) {
                        final detection = _filteredDetections[index];
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 300 + (index * 30)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.only(bottom: spacingMedium),
                            child: _buildDetectionCard(detection),
                          ),
                        );
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
            child: Semantics(
              label: '${filter['label']} filter',
              button: true,
              selected: isSelected,
              hint: 'Double tap to filter by ${filter['label']}',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter['label'] as String;
                      _updateFilteredDetections();
                    });
                  },
                  borderRadius: BorderRadius.circular(radiusLarge),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: spacingMedium,
                      vertical: spacingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary
                          : widget.theme.cardColor,
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
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetectionCard(Map<String, dynamic> detection) {
    final type = detection['type'] as String;
    final color = detection['color'] as Color;
    final timestamp = DateTime.parse(detection['timestamp'] as String);
    final timeAgo = _getTimeAgo(timestamp);

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
        final objectCount = detection['objectCount'] as int;
        final objects = detection['objects'] as List? ?? [];
        title = 'Object Detection';
        if (objects.isNotEmpty) {
          final firstObject = objects.first['label'] as String;
          // Capitalize the first letter of the detected object
          detectedLabel = '${firstObject[0].toUpperCase()}${firstObject.substring(1).toLowerCase()}';
          
          if (objectCount > 1) {
            final otherNames = objects.skip(1).take(2).map((o) => (o as Map)['label']).join(', ');
            description = objectCount > 3 
                ? '+$otherNames, +${objectCount - 3} more'
                : '+$otherNames';
          } else {
             // Show confidence if there are no other objects to list
             final conf = objects.first['confidence'];
             if (conf != null) {
                description = 'Confidence: ${(conf * 100).toStringAsFixed(1)}%';
             } else {
                description = 'Detected 1 object';
             }
          }
        } else {
          detectedLabel = 'Object';
          description = 'Detected 0 objects';
        }
        break;
      case 'text':
        final textBlockCount = detection['textBlockCount'] as int? ?? 0;
        final text = detection['text'] as String? ?? '';
        title = 'Text Scan';
        detectedLabel = 'Text';
        description = text.length > 50 ? '${text.substring(0, 50)}...' : text;
        if (description.isEmpty) {
          description = 'Scanned $textBlockCount ${textBlockCount == 1 ? 'block' : 'blocks'}';
        }
        break;
    }

    return Semantics(
      label: '$title. $description. Scanned $timeAgo',
      button: true,
      hint: 'Double tap to view details',
      child: Material(
        color: Colors.transparent,
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
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusLarge),
              boxShadow: widget.isDarkMode
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : softShadow,
              border: widget.isDarkMode
                  ? Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 👇 THIS CONTAINER REPLACES THE ICON WIDGET
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        maxWidth: 80, // Prevents extremely long words from breaking layout
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(radiusMedium),
                      ),
                      child: Text(
                        detectedLabel,
                        style: bodyBold.copyWith(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: bodyBold.copyWith(
                              fontSize: 15,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(radiusSmall),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getTypeLabel(type),
                              style: caption.copyWith(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: widget.theme.subtextColor.withOpacity(0.5),
                      size: 24,
                    ),
                  ],
                ),
                SizedBox(height: spacingMedium),
                Text(
                  description,
                  style: caption.copyWith(
                    fontSize: 13,
                    color: widget.theme.subtextColor,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: spacingSmall),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: widget.theme.subtextColor.withOpacity(0.7),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: caption.copyWith(
                        fontSize: 11,
                        color: widget.theme.subtextColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.06),
        padding: EdgeInsets.symmetric(
          vertical: spacingXLarge,
          horizontal: spacingLarge,
        ),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: widget.isDarkMode ? [] : softShadow,
          border: Border.all(
            color: widget.theme.subtextColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: widget.theme.subtextColor.withOpacity(0.5),
              size: 48,
            ),
            SizedBox(height: spacingMedium),
            Text(
              'No $_selectedFilter detections',
              style: bodyBold.copyWith(
                fontSize: 16,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacingSmall),
            Text(
              'Try scanning with $_selectedFilter detection mode',
              style: caption.copyWith(
                fontSize: 13,
                color: widget.theme.subtextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

  String _getTimeAgo(DateTime timestamp) {
    Duration difference = DateTime.now().difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}