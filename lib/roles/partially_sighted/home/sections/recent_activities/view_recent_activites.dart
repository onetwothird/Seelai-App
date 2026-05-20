// File: lib/roles/partially_sighted/home/sections/recent_activities/view_recent_activites.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; 
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; 
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'detection_detail_screen.dart';
import 'all_detections_screen.dart';

class ViewRecentActivities extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final String userId;
  final VoidCallback onToggleDarkMode; // === ADDED: Accepts the theme toggle callback ===

  const ViewRecentActivities({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userId,
    required this.onToggleDarkMode, // === ADDED ===
  });

  @override
  State<ViewRecentActivities> createState() => _ViewRecentActivitiesState();
}

class _ViewRecentActivitiesState extends State<ViewRecentActivities> with TickerProviderStateMixin {
  final Color _primaryColor = const Color(0xFF7C3AED);

  final int maxDisplayedDetections = 5;
  String _selectedFilter = 'All';
  bool _isRefreshing = false;
  bool _isLoading = true;
  
  bool _isSimulatingLoad = true;

  List<Map<String, dynamic>> _faces = [];
  List<Map<String, dynamic>> _objects = [];
  List<Map<String, dynamic>> _texts = [];
  List<Map<String, dynamic>> _allDetections = [];

  StreamSubscription? _facesSub;
  StreamSubscription? _objectsSub;
  StreamSubscription? _textsSub;

  Timer? _messageTimer;
  int _currentMessageIndex = 0;

  // === ANIMATION CONTROLLERS (Header & Mascot Only) ===
  late AnimationController _entryController;
  late Animation<double> _headerOpacity;
  late Animation<Offset> _headerSlide;
  late Animation<double> _mascotScale;
  late Animation<double> _bubbleScale;
  late Animation<double> _gradientOpacity;

  @override
  void initState() {
    super.initState();
    _setupRealtimeStreams();
    _startMessageTimer();
    
    // === Initialize the staggered entry animation ===
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 1. Header Row (Title & Refresh) - Fades & slides RIGHT
    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );

    // 2. Gradient Background
    _gradientOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
    );

    // 3. Mascot
    _mascotScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack)),
    );

    // 4. Speech Bubble
    _bubbleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack)),
    );

    // Start header/mascot animations immediately
    _entryController.forward();
    
    // Trigger the skeleton animation for 600ms on load
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isSimulatingLoad = false;
        });
      }
    });
  }

  void _startMessageTimer() {
    _messageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % 2; 
        });
      }
    });
  }

  void _setupRealtimeStreams() {
    _facesSub = faceDetectionService.streamDetectedFaces(widget.userId).listen((faces) {
      _faces = faces.map((face) => {
        ...face,
        'type': 'face',
        'icon': Icons.face_rounded,
        'color': _primaryColor,
      }).toList();
      _combineAndSortDetections();
    });

    _objectsSub = objectDetectionService.streamDetectedObjects(widget.userId).listen((objects) {
      _objects = objects.map((obj) => {
        ...obj,
        'type': 'object',
        'icon': Icons.search_rounded,
        'color': Colors.green,
      }).toList();
      _combineAndSortDetections();
    });

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

  void _combineAndSortDetections() {
    final combined = [..._faces, ..._objects, ..._texts];
    
    combined.sort((a, b) {
      final aTime = DateTime.parse(a['timestamp'] as String);
      final bTime = DateTime.parse(b['timestamp'] as String);
      return bTime.compareTo(aTime); 
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
    _facesSub?.cancel();
    _objectsSub?.cancel();
    _textsSub?.cancel();
    _messageTimer?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  List<String> _getMascotMessages(int faceCount, int objectCount, int textCount) {
    return [
      'Hello! You have scanned $faceCount face${faceCount != 1 ? 's' : ''}, $objectCount object${objectCount != 1 ? 's' : ''}, and $textCount text block${textCount != 1 ? 's' : ''}.',
      'Tip: You can tap on any detection card below to view its full details.',
    ];
  }
  
  Widget _buildSkeletonList(double width) {
    final baseColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade100;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: spacingMedium),
          Row(
            children: List.generate(4, (index) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: 70, 
                  height: 36, 
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(24)
                  )
                ),
              ),
            )),
          ),
          const SizedBox(height: spacingLarge),
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: spacingMedium),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(radiusLarge),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool showSkeleton = _isLoading || _isSimulatingLoad;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Section (Header) - Always animates immediately
          FadeTransition(
            opacity: _headerOpacity,
            child: SlideTransition(
              position: _headerSlide,
              child: Padding(
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
                    // === UPDATED: Added Row to hold both Theme Toggle & Refresh ===
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PremiumThemeToggle(
                          isDarkMode: widget.isDarkMode,
                          onToggle: widget.onToggleDarkMode,
                          buttonBgColor: widget.isDarkMode ? Colors.white10 : const Color(0xFFF8FAFC),
                          iconColor: _primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: 'Refresh detections',
                          button: true,
                          hint: 'Double tap to refresh',
                          child: GestureDetector(
                            onTap: _refreshDetections,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: widget.isDarkMode ? Colors.white10 : const Color(0xFFF8FAFC),
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedRotation(
                                turns: _isRefreshing ? 1 : 0,
                                duration: const Duration(milliseconds: 600),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  color: _primaryColor,
                                  size: 20, // Match size of moon icon
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: spacingLarge),
          
          // Mascot Banner
          _buildMascotBanner(_allDetections), 
          
          // 2. Main Content Area - Instantly shows skeleton or data
          if (showSkeleton)
            _buildSkeletonList(width)
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: spacingMedium),
                  
                  _buildFilterTabs(),
                  
                  const SizedBox(height: spacingLarge),
                  
                  _buildDetectionsList(_allDetections),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMascotBanner(List<Map<String, dynamic>> detections) {
    int faceCount = detections.where((d) => d['type'] == 'face').length;
    int objectCount = detections.where((d) => d['type'] == 'object').length;
    int textCount = detections.where((d) => d['type'] == 'text').length;

    final messages = _getMascotMessages(faceCount, objectCount, textCount);
    final displayMessage = messages[_currentMessageIndex % messages.length];
    
    final longestMessage = messages.reduce((a, b) => a.length > b.length ? a : b);

    final double screenWidth = MediaQuery.of(context).size.width;
    
    final double mascotSize = (screenWidth * 0.32).clamp(100.0, 140.0);
    
    final double tailBottomMargin = mascotSize * 0.285; 
    final double bubbleBottomMargin = mascotSize * 0.242;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _gradientOpacity,
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
        ),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ScaleTransition(
                scale: _mascotScale,
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  'assets/seelai-icons/seelai3.png',
                  height: mascotSize, 
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: mascotSize * 0.65,
                    height: mascotSize * 0.65,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      color: _primaryColor,
                      size: mascotSize * 0.25, 
                    ),
                  ),
                ),
              ),
              
              Container(
                margin: EdgeInsets.only(bottom: tailBottomMargin), 
                child: ScaleTransition(
                  scale: _bubbleScale,
                  alignment: Alignment.bottomRight,
                  child: CustomPaint(
                    size: const Size(14, 16),
                    painter: _TailPainter(
                      color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: bubbleBottomMargin), 
                  child: ScaleTransition(
                    scale: _bubbleScale,
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
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
                          
                          Stack(
                            children: [
                              Text(
                                longestMessage,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.transparent, 
                                  height: 1.4,
                                ),
                              ),
                              Positioned.fill(
                                child: TypewriterText(
                                  text: displayMessage,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                  borderRadius: BorderRadius.circular(24), 
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

    return AnimationLimiter(
      key: ValueKey(_selectedFilter), 
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            ...displayedDetections.map((detection) {
              return Padding(
                padding: const EdgeInsets.only(bottom: spacingMedium),
                child: _buildDetectionCard(detection),
              );
            }),
            if (hasMoreDetections)
              Padding(
                padding: const EdgeInsets.only(top: spacingSmall),
                child: _buildViewAllButton(filteredDetections),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterDetections(List<Map<String, dynamic>> detections) {
    if (_selectedFilter == 'All') {
      return detections;
    }
    
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
      _isSimulatingLoad = true;
    });
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isSimulatingLoad = false;
        });
      }
    });
  }
}

class _TailPainter extends CustomPainter {
  final Color color;

  _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    
    path.moveTo(size.width, 0); 
    path.lineTo(0, size.height / 2); 
    path.lineTo(size.width, size.height); 
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    int msDuration = widget.text.length * 40; 
    
    _controller = AnimationController(
      vsync: this, 
      duration: Duration(milliseconds: msDuration),
    );
    _setupAnimation();
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      int msDuration = widget.text.length * 40; 
      _controller.duration = Duration(milliseconds: msDuration);
      _setupAnimation();
      _controller.reset();
      _controller.forward();
    }
  }

  void _setupAnimation() {
    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        int end = _characterCount.value;
        if (end > widget.text.length) {
          end = widget.text.length;
        }
        if (end < 0) {
          end = 0;
        }
        
        return Text(
          widget.text.substring(0, end),
          style: widget.style,
        );
      },
    );
  }
}

// ==========================================
// PREMIUM "SUPERNOVA" THEME TOGGLE
// ==========================================
class PremiumThemeToggle extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggle;
  final Color buttonBgColor;
  final Color iconColor;

  const PremiumThemeToggle({
    super.key,
    required this.isDarkMode,
    required this.onToggle,
    required this.buttonBgColor,
    required this.iconColor,
  });

  @override
  State<PremiumThemeToggle> createState() => _PremiumThemeToggleState();
}

class _PremiumThemeToggleState extends State<PremiumThemeToggle> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.7).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_controller);

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double glowOpacity = _controller.isAnimating 
              ? (1.0 - _controller.value).clamp(0.0, 0.4) 
              : 0.0;

          return Transform.scale(
            scale: _scaleAnimation.value,
            child: RotationTransition(
              turns: _rotationAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.buttonBgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.iconColor.withValues(alpha: glowOpacity),
                      blurRadius: 20 * _controller.value,
                      spreadRadius: 8 * _controller.value,
                    )
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Icon(
                    widget.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    key: ValueKey<bool>(widget.isDarkMode),
                    size: 20,
                    color: widget.iconColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}