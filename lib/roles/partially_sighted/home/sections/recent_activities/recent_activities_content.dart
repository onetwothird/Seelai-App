// File: lib/roles/partially_sighted/home/sections/recent_activities/recent_activities_content.dart

import 'package:flutter/material.dart';
import 'all_detections_screen.dart';
import 'detection_detail_screen.dart'; 
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class RecentActivitiesContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final String userId;

  const RecentActivitiesContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userId,
  });

  @override
  State<RecentActivitiesContent> createState() => _RecentActivitiesContentState();
}
class _RecentActivitiesContentState extends State<RecentActivitiesContent> {
  final int maxDisplayedDetections = 5;
  String _selectedFilter = 'All';
  
  // State management
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasError = false;
  List<Map<String, dynamic>> _allDetectionsCache = [];

  @override
  void initState() {
    super.initState();
    _fetchDetections(); // Fetch once when screen loads
  }

  // Optimized Fetching: Runs all 3 database calls at the exact same time
  Future<void> _fetchDetections() async {
    if (!mounted) return;
    
    try {
      // Start all futures concurrently instead of waiting for them one by one
      final futures = await Future.wait([
        faceDetectionService.getDetectedFaces(widget.userId, limit: 50),
        objectDetectionService.getDetectedObjects(widget.userId, limit: 50),
        textScanService.getScannedTexts(widget.userId, limit: 50),
      ]);

      final List<Map<String, dynamic>> combinedDetections = [];

      // 1. Process Faces
      final faces = futures[0] as List<dynamic>;
      combinedDetections.addAll(faces.map((face) => {
        ...face as Map<String, dynamic>,
        'type': 'face',
        'icon': Icons.face_rounded,
        'color': Colors.purple,
      }));

      // 2. Process Objects
      final objects = futures[1] as List<dynamic>;
      combinedDetections.addAll(objects.map((obj) => {
        ...obj as Map<String, dynamic>,
        'type': 'object',
        'icon': Icons.search_rounded,
        'color': Colors.green,
      }));

      // 3. Process Text
      final texts = futures[2] as List<dynamic>;
      combinedDetections.addAll(texts.map((text) => {
        ...text as Map<String, dynamic>,
        'type': 'text',
        'icon': Icons.document_scanner_rounded,
        'color': Colors.orange,
      }));

      // Sort newest first
      combinedDetections.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _allDetectionsCache = combinedDetections;
          _isLoading = false;
          _isRefreshing = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _hasError = true;
        });
      }
    }
  }

  void _refreshDetections() {
    setState(() {
      _isRefreshing = true;
      _isLoading = _allDetectionsCache.isEmpty; // Only show main loader if cache is empty
    });
    _fetchDetections();
  }

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
                    duration: const Duration(milliseconds: 600),
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
          
          // Detections List with animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildDetectionsList(), 
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
                    // Instant UI update! No network call needed.
                    setState(() {
                      _selectedFilter = filter['label'] as String;
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
                            : (widget.isDarkMode 
                                ? Colors.white.withValues(alpha: 0.05) 
                                : Colors.black.withValues(alpha: 0.05)),
                        width: 1,
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

  Widget _buildDetectionsList() {
    if (_isLoading) {
      return Center(
        key: const ValueKey('loader'),
        child: Padding(
          padding: EdgeInsets.all(spacingLarge),
          child: CircularProgressIndicator(color: primary),
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_allDetectionsCache.isEmpty) {
      return _buildEmptyState();
    }

    // Instant local filtering based on the cached data
    final filteredDetections = _filterDetections(_allDetectionsCache);

    if (filteredDetections.isEmpty) {
      return _buildNoResultsState();
    }

    // Show only first 5 detections
    final displayedDetections = filteredDetections.take(maxDisplayedDetections).toList();
    final hasMoreDetections = filteredDetections.length > maxDisplayedDetections;

    return Column(
      key: ValueKey(_selectedFilter), // Triggers the AnimatedSwitcher
      children: [
        // Display detection cards with staggered animation
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

        // "View All Detections" button if more than 5
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
              child: _buildViewAllButton(filteredDetections), // Pass filtered!
            ),
          ),
      ],
    );
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
        final objectCount = detection['objectCount'] as int;
        final objects = detection['objects'] as List? ?? [];
        title = 'Object Detection';
        if (objects.isNotEmpty) {
          final firstObject = objects.first['label'] as String;
          detectedLabel = '${firstObject[0].toUpperCase()}${firstObject.substring(1).toLowerCase()}';
          
          if (objectCount > 1) {
            final otherNames = objects.skip(1).take(2).map((o) => (o as Map)['label']).join(', ');
            description = objectCount > 3 
                ? '+$otherNames, +${objectCount - 3} more'
                : '+$otherNames';
          } else {
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
        detectedLabel = 'Document';
        description = text.length > 40 ? '${text.substring(0, 40)}...' : text;
        if (description.isEmpty) {
          description = 'Scanned $textBlockCount ${textBlockCount == 1 ? 'block' : 'blocks'}';
        }
        break;
    }

    return Semantics(
      label: '$detectedLabel. $title. $description. Scanned $timeAgo',
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
              boxShadow: widget.isDarkMode ? [] : softShadow,
              border: Border.all(
                color: widget.isDarkMode 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image Thumbnail 
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(radiusMedium),
                    border: Border.all(
                      color: widget.isDarkMode 
                          ? Colors.white.withValues(alpha: 0.05) 
                          : Colors.black.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                 child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    // ✅ Show shimmer/color while loading
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: color.withValues(alpha: 0.15),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Icon(
                      detection['icon'] as IconData? ?? Icons.image_rounded,
                      color: color,
                      size: 30,
                    ),
                  )
                : Icon(
                    detection['icon'] as IconData? ?? Icons.image_rounded,
                    color: color,
                    size: 30,
                  ),
                ),
                SizedBox(width: spacingMedium),
                
                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              detectedLabel,
                              style: h3.copyWith(
                                fontSize: 16,
                                color: widget.theme.textColor,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: caption.copyWith(
                              fontSize: 11,
                              color: widget.theme.subtextColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        title,
                        style: caption.copyWith(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: body.copyWith(
                          fontSize: 13,
                          color: widget.theme.subtextColor,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacingSmall),
                Icon(
                  Icons.chevron_right_rounded,
                  color: widget.theme.subtextColor.withOpacity(0.4),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllButton(List<Map<String, dynamic>> allDetections) {
    final totalCount = allDetections.length;
    return Semantics(
      label: 'View all $totalCount detections',
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
                  detections: allDetections,
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
                color: widget.isDarkMode 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.view_list_rounded,
                  color: primary,
                  size: 20,
                ),
                SizedBox(width: spacingSmall),
                Text(
                  'View All Detections ($totalCount)',
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: spacingSmall),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      key: const ValueKey('empty'),
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
          color: widget.isDarkMode 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.05),
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
      key: const ValueKey('no_results'),
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
          color: widget.isDarkMode 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.05),
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
      key: const ValueKey('error'),
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