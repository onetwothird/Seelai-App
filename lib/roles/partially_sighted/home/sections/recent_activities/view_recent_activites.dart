// File: lib/roles/partially_sighted/home/sections/recent_activities/view_recent_activites.dart

import 'dart:async';
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
  // Brand Colors - Vibrant Purple
  final Color _primaryColor = const Color(0xFF7C3AED);

  final int maxDisplayedDetections = 5;
  String _selectedFilter = 'All';
  bool _isRefreshing = false;
  bool _isLoading = true;

  // State lists for our real-time data
  List<Map<String, dynamic>> _faces = [];
  List<Map<String, dynamic>> _objects = [];
  List<Map<String, dynamic>> _texts = [];
  List<Map<String, dynamic>> _allDetections = [];

  // Subscriptions to clean up when we leave the screen
  StreamSubscription? _facesSub;
  StreamSubscription? _objectsSub;
  StreamSubscription? _textsSub;

  @override
  void initState() {
    super.initState();
    _setupRealtimeStreams();
  }

  // ✅ THE FIX: We listen to the streams exactly once when the widget loads
  void _setupRealtimeStreams() {
    // 1. Listen to Faces
    _facesSub = faceDetectionService.streamDetectedFaces(widget.userId).listen((faces) {
      _faces = faces.map((face) => {
        ...face,
        'type': 'face',
        'icon': Icons.face_rounded,
        'color': _primaryColor,
      }).toList();
      _combineAndSortDetections();
    });

    // 2. Listen to Objects
    _objectsSub = objectDetectionService.streamDetectedObjects(widget.userId).listen((objects) {
      _objects = objects.map((obj) => {
        ...obj,
        'type': 'object',
        'icon': Icons.search_rounded,
        'color': Colors.green,
      }).toList();
      _combineAndSortDetections();
    });

    // 3. Listen to Texts
    _textsSub = textScanService.streamScannedTexts(widget.userId).listen((texts) {
      _texts = texts.map((text) => {
        ...text,
        'type': 'text',
        'icon': Icons.document_scanner_rounded,
        'color': Colors.orange,
      }).toList();
      _combineAndSortDetections();
    });
  }

  // Merges the three lists together and sorts them by date
  void _combineAndSortDetections() {
    final combined = [..._faces, ..._objects, ..._texts];
    
    combined.sort((a, b) {
      final aTime = DateTime.parse(a['timestamp'] as String);
      final bTime = DateTime.parse(b['timestamp'] as String);
      return bTime.compareTo(aTime); // Newest first
    });

    if (mounted) {
      setState(() {
        _allDetections = combined;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Prevent memory leaks by canceling streams when leaving the screen
    _facesSub?.cancel();
    _objectsSub?.cancel();
    _textsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.only(
              left: width * 0.06,
              right: width * 0.06,
              top: spacingLarge,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Detections',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: widget.theme.textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your scanning history',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.theme.subtextColor,
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
                        color: _primaryColor,
                        size: 26,
                      ),
                    ),
                    tooltip: 'Refresh detections',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: spacingLarge),
          
          // Show loader if waiting for Firebase, otherwise show content
          _isLoading 
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(spacingLarge),
                  child: CircularProgressIndicator(color: _primaryColor),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Edge-to-edge Mascot Banner with Bubble
                  _buildMascotBanner(_allDetections),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: spacingMedium),
                        
                        // Filter Pills
                        _buildFilterTabs(),
                        
                        const SizedBox(height: spacingLarge),
                        
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
                          // We pass our state list directly now! No StreamBuilder needed!
                          child: _buildDetectionsList(_allDetections),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildMascotBanner(List<Map<String, dynamic>> detections) {
    // Calculate counts for the speech bubble
    int faceCount = detections.where((d) => d['type'] == 'face').length;
    int objectCount = detections.where((d) => d['type'] == 'object').length;
    int textCount = detections.where((d) => d['type'] == 'text').length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Edge-to-edge gradient background strictly tied to the top
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withValues(alpha: widget.isDarkMode ? 0.25 : 0.15),
                  _primaryColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        
        // Mascot and Speech Bubble
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Mascot Figure
               Image.asset(
                        'assets/seelai-icons/seelai3.png',
                        width: 90,
                        height: 105,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.smart_toy_outlined,
                            color: primary,
                            size: 36,
                          ),
                        ),
                      ),
              
              // Speech Bubble Tail (Pointing left, aligned to mouth)
              Container(
                margin: const EdgeInsets.only(bottom: 40), 
                child: CustomPaint(
                  size: const Size(12, 16),
                  painter: _TailPainter(
                    color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                  ),
                ),
              ),

              // Speech Bubble Content - Conversational Format
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: widget.isDarkMode ? [] : [
                      BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      Text(
                        'Seelai',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hello! You have scanned $faceCount face${faceCount != 1 ? 's' : ''}, $objectCount object${objectCount != 1 ? 's' : ''}, and $textCount text block${textCount != 1 ? 's' : ''}.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: widget.isDarkMode
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Faces', 'Objects', 'Text'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((label) {
          bool isSelected = _selectedFilter == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = label;
                  _isRefreshing = true;
                });
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (mounted) {
                    setState(() {
                      _isRefreshing = false;
                    });
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : widget.theme.cardColor,
                  borderRadius: BorderRadius.circular(24), // Pill shape
                  border: Border.all(
                    color: isSelected 
                        ? _primaryColor 
                        : (widget.isDarkMode ? Colors.white10 : Colors.black12),
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ] : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : widget.theme.subtextColor,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetectionsList(List<Map<String, dynamic>> allDetections) {
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
      key: ValueKey(_selectedFilter), // Forces animation when switching tabs
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
              padding: const EdgeInsets.only(bottom: spacingMedium),
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
              padding: const EdgeInsets.only(top: spacingSmall),
              child: _buildViewAllButton(filteredDetections),
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
            padding: const EdgeInsets.all(spacingMedium),
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
                const SizedBox(width: spacingMedium),
                
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
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: caption.copyWith(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                const SizedBox(width: spacingSmall),
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

  Widget _buildViewAllButton(List<Map<String, dynamic>> filteredDetections) {
    final totalCount = filteredDetections.length;
    final categoryLabel = _selectedFilter == 'All' ? 'Detections' : _selectedFilter;
    
    return Semantics(
      label: 'View all $totalCount $categoryLabel',
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
            padding: const EdgeInsets.all(spacingMedium),
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
                const Icon(Icons.view_list_rounded, color: primary, size: 20),
                const SizedBox(width: spacingSmall),
                Text(
                  'View All $categoryLabel ($totalCount)',
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: spacingSmall),
                const Icon(Icons.arrow_forward_rounded, color: primary, size: 18),
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
      padding: const EdgeInsets.symmetric(
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
          const SizedBox(height: spacingMedium),
          Text(
            'No detections yet',
            style: bodyBold.copyWith(
              fontSize: 16,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: spacingSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: spacingMedium),
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
      padding: const EdgeInsets.symmetric(
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
          const SizedBox(height: spacingMedium),
          Text(
            'No $_selectedFilter detections',
            style: bodyBold.copyWith(
              fontSize: 16,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: spacingSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: spacingMedium),
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
    
    // With pure streams, we don't need to manually re-fetch here
    // But we keep the UI animation to acknowledge the user's tap
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    });
  }
}

// Custom Painter to draw the speech bubble tail pointing to the mascot
class _TailPainter extends CustomPainter {
  final Color color;

  _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    
    // Draw a triangle pointing to the left
    path.moveTo(size.width, 0); // Top right corner
    path.lineTo(0, size.height / 2); // Pointing left (middle)
    path.lineTo(size.width, size.height); // Bottom right corner
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}