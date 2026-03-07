// File: lib/roles/visually_impaired/home/sections/recent_activities/view_recent_activites.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'detection_detail_screen.dart';
import 'all_detections_screen.dart';

class ViewRecentActivities extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final String userId;

  const ViewRecentActivities({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userId,
  });

  @override
  State<ViewRecentActivities> createState() => _ViewRecentActivitiesState();
}

class _ViewRecentActivitiesState extends State<ViewRecentActivities> {
  final int maxDisplayedDetections = 5;
  String _selectedFilter = 'All';
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Detections',
                      style: h2.copyWith(
                        fontSize: 26,
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: spacingSmall),
                    Text(
                      'Your scanning history',
                      style: body.copyWith(
                        color: widget.theme.subtextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Refresh detections',
                button: true,
                hint: 'Double tap to refresh',
                child: IconButton(
                  onPressed: _refreshDetections,
                  icon: AnimatedRotation(
                    turns: _isRefreshing ? 1 : 0,
                    duration: Duration(milliseconds: 600),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: primary,
                      size: 24,
                    ),
                  ),
                  tooltip: 'Refresh detections',
                ),
              ),
            ],
          ),
          
          SizedBox(height: spacingLarge),
          
          // Filter chips
          _buildFilterChips(),
          
          SizedBox(height: spacingLarge),
          
          // Detections stream with animation
          AnimatedSwitcher(
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
            child: _buildDetectionsStream(),
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
                      _isRefreshing = true;
                    });
                    Future.delayed(Duration(milliseconds: 600), () {
                      if (mounted) {
                        setState(() {
                          _isRefreshing = false;
                        });
                      }
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
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetectionsStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(_selectedFilter),
      stream: _getCombinedDetectionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(spacingLarge),
              child: CircularProgressIndicator(color: primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final allDetections = snapshot.data ?? [];

        if (allDetections.isEmpty) {
          return _buildEmptyState();
        }

        final filteredDetections = _filterDetections(allDetections);

        if (filteredDetections.isEmpty) {
          return _buildNoResultsState();
        }

        final displayedDetections = filteredDetections.take(maxDisplayedDetections).toList();
        final hasMoreDetections = filteredDetections.length > maxDisplayedDetections;

        return Column(
          children: [
            ...displayedDetections.asMap().entries.map((entry) {
              final index = entry.key;
              final detection = entry.value;
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 50)),
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
            }),

            if (hasMoreDetections)
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (displayedDetections.length * 50)),
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
                  padding: EdgeInsets.only(top: spacingSmall),
                  child: _buildViewAllButton(filteredDetections),
                ),
              ),
          ],
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getCombinedDetectionsStream() async* {
    await for (final _ in Stream.periodic(Duration(milliseconds: 500))) {
      try {
        final List<Map<String, dynamic>> allDetections = [];

        if (_selectedFilter == 'All' || _selectedFilter == 'Faces') {
          final faces = await faceDetectionService.getDetectedFaces(widget.userId, limit: 50);
          allDetections.addAll(faces.map((face) {
            return {
              ...face,
              'type': 'face',
              'icon': Icons.face_rounded,
              'color': Colors.purple,
            };
          }));
        }

        if (_selectedFilter == 'All' || _selectedFilter == 'Objects') {
          final objects = await objectDetectionService.getDetectedObjects(widget.userId, limit: 50);
          allDetections.addAll(objects.map((obj) {
            return {
              ...obj,
              'type': 'object',
              'icon': Icons.search_rounded,
              'color': Colors.green,
            };
          }));
        }

        if (_selectedFilter == 'All' || _selectedFilter == 'Text') {
          final texts = await textScanService.getScannedTexts(widget.userId, limit: 50);
          allDetections.addAll(texts.map((text) {
            return {
              ...text,
              'type': 'text',
              'icon': Icons.document_scanner_rounded,
              'color': Colors.orange,
            };
          }));
        }

        allDetections.sort((a, b) {
          final aTime = DateTime.parse(a['timestamp'] as String);
          final bTime = DateTime.parse(b['timestamp'] as String);
          return bTime.compareTo(aTime);
        });

        yield allDetections;
      } catch (e) {
        yield [];
      }
    }
  }

  List<Map<String, dynamic>> _filterDetections(List<Map<String, dynamic>> detections) {
    if (_selectedFilter == 'All') return detections;
    
    return detections.where((detection) {
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

  Widget _buildDetectionCard(Map<String, dynamic> detection) {
    final type = detection['type'] as String;
    final icon = detection['icon'] as IconData;
    final color = detection['color'] as Color;
    final timestamp = DateTime.parse(detection['timestamp'] as String);
    final timeAgo = _getTimeAgo(timestamp);

    String title = '';
    String description = '';

    switch (type) {
      case 'face':
        final faceCount = detection['faceCount'] as int;
        title = 'Face Detection';
        description = 'Detected $faceCount ${faceCount == 1 ? 'face' : 'faces'}';
        break;
      case 'object':
        final objectCount = detection['objectCount'] as int;
        final objects = detection['objects'] as List? ?? [];
        title = 'Object Detection';
        if (objects.isNotEmpty) {
          final objectNames = objects.take(3).map((o) => (o as Map)['label']).join(', ');
          description = objectCount > 3 
              ? '$objectNames, +${objectCount - 3} more'
              : objectNames;
        } else {
          description = 'Detected $objectCount ${objectCount == 1 ? 'object' : 'objects'}';
        }
        break;
      case 'text':
        final textBlockCount = detection['textBlockCount'] as int? ?? 0;
        final text = detection['text'] as String? ?? '';
        title = 'Text Scan';
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
                    Container(
                      padding: EdgeInsets.all(spacingSmall),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(radiusMedium),
                      ),
                      child: Icon(icon, color: color, size: 24),
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

  Widget _buildViewAllButton(List<Map<String, dynamic>> filteredDetections) {
    final totalCount = filteredDetections.length;
    final categoryLabel = _selectedFilter == 'All' ? 'All' : _selectedFilter;
    
    return Semantics(
      label: 'View all $totalCount $categoryLabel detections',
      button: true,
      hint: 'Double tap to open full detection list',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllDetectionsScreen(
                  detections: filteredDetections,
                  isDarkMode: widget.isDarkMode,
                  theme: widget.theme,
                  selectedFilter: _selectedFilter,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(radiusMedium),
          child: Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusMedium),
              border: Border.all(
                color: primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.view_list_rounded, color: primary, size: 20),
                SizedBox(width: spacingSmall),
                Text(
                  'View All $categoryLabel ($totalCount)',
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: spacingSmall),
                Icon(Icons.arrow_forward_rounded, color: primary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
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
            Icons.qr_code_scanner_rounded,
            color: widget.theme.subtextColor.withOpacity(0.5),
            size: 48,
          ),
          SizedBox(height: spacingMedium),
          Text(
            'No detections yet',
            style: bodyBold.copyWith(
              fontSize: 16,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacingSmall),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacingMedium),
            child: Text(
              'Start scanning to see your detection history',
              style: caption.copyWith(
                fontSize: 13,
                color: widget.theme.subtextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      width: double.infinity,
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacingMedium),
            child: Text(
              'Try scanning with $_selectedFilter detection mode',
              style: caption.copyWith(
                fontSize: 13,
                color: widget.theme.subtextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final errorColor = widget.isDarkMode ? Colors.red.shade400 : Colors.red.shade700;
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(color: errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: errorColor),
          SizedBox(width: spacingMedium),
          Expanded(
            child: Text(
              'Unable to load detections',
              style: body.copyWith(color: widget.theme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'face':
        return 'Face Scan';
      case 'object':
        return 'Object Scan';
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

  void _refreshDetections() {
    setState(() {
      _isRefreshing = true;
    });
    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    });
  }
}