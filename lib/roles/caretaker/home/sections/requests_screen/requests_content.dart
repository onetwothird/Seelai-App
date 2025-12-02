// ignore_for_file: deprecated_member_use, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/firebase/caretaker/request_service.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'dart:async';

class RequestsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final RequestService requestService;
  final Function(int) onRequestCountChange;

  const RequestsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.requestService,
    required this.onRequestCountChange,
  });

  @override
  State<RequestsContent> createState() => _RequestsContentState();
}

class _RequestsContentState extends State<RequestsContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RequestModel> _pendingRequests = [];
  List<RequestModel> _activeRequests = [];
  List<RequestModel> _completedRequests = [];
  bool _isLoading = true;
  String? _error;
  String? _caretakerId;
  StreamSubscription<List<RequestModel>>? _requestsSubscription;
  
  // Cache for profile images
  final Map<String, String?> _profileImageCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _initializeCaretakerId();
  }

  Future<void> _initializeCaretakerId() async {
    String? caretakerId;
    
    caretakerId = widget.userData['uid'] as String?;
    
    if (caretakerId == null || caretakerId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      caretakerId = user?.uid;
    }
    
    if (caretakerId == null || caretakerId.isEmpty) {
      setState(() {
        _error = 'Caretaker ID not found. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _caretakerId = caretakerId;
    });

    _setupRequestsStream();
  }
 
  void _setupRequestsStream() {
    if (_caretakerId == null) {
      setState(() {
        _error = 'Caretaker ID not found';
        _isLoading = false;
      });
      return;
    }

    _requestsSubscription = widget.requestService
        .streamRequests(_caretakerId!)
        .listen(
      (requests) {
        if (mounted) {
          setState(() {
            _pendingRequests = requests
                .where((req) => req.status == RequestStatus.pending)
                .toList();
            
            _activeRequests = requests
                .where((req) => 
                    req.status == RequestStatus.accepted ||
                    req.status == RequestStatus.inProgress)
                .toList();
            
            _completedRequests = requests
                .where((req) => 
                    req.status == RequestStatus.completed ||
                    req.status == RequestStatus.declined)
                .toList();
            
            _isLoading = false;
            _error = null;
            
            widget.onRequestCountChange(_pendingRequests.length);
          });
          
          _preloadProfileImages(requests);
        }
      },
      onError: (error) {
        debugPrint('Error loading requests: $error');
        if (mounted) {
          setState(() {
            _error = 'Failed to load requests: $error';
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _preloadProfileImages(List<RequestModel> requests) async {
    for (var request in requests) {
      if (!_profileImageCache.containsKey(request.patientId)) {
        _getProfileImage(request.patientId);
      }
    }
  }

  Future<String?> _getProfileImage(String patientId) async {
    if (_profileImageCache.containsKey(patientId)) {
      return _profileImageCache[patientId];
    }

    try {
      final userData = await databaseService.getUserData(patientId);
      final profileImageUrl = userData?['profileImageUrl'] as String?;
      
      if (mounted) {
        setState(() {
          _profileImageCache[patientId] = profileImageUrl;
        });
      }
      
      return profileImageUrl;
    } catch (e) {
      debugPrint('Error fetching profile image: $e');
      if (mounted) {
        setState(() {
          _profileImageCache[patientId] = null;
        });
      }
      return null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshRequests() async {
    if (_caretakerId == null) {
      await _initializeCaretakerId();
      return;
    }
    
    setState(() => _isLoading = true);
    
    await Future.delayed(Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (_error != null && !_isLoading) {
      return Container(
        height: height - 200,
        padding: EdgeInsets.symmetric(horizontal: width * 0.05),
        child: _buildErrorState(),
      );
    }

    if (_isLoading && _pendingRequests.isEmpty && _activeRequests.isEmpty && _completedRequests.isEmpty) {
      return Container(
        height: height - 200,
        padding: EdgeInsets.symmetric(horizontal: width * 0.05),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primary),
                strokeWidth: 3,
              ),
              SizedBox(height: spacingLarge),
              Text(
                'Loading requests...',
                style: body.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshRequests,
      color: primary,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            left: width * 0.05,
            right: width * 0.05,
            top: spacingMedium,
            bottom: 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsOverview(),
              
              SizedBox(height: spacingXLarge),
              
              _buildTabBar(),
              
              SizedBox(height: spacingLarge),
              
              _buildCurrentTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.pending_actions_rounded,
            label: 'Pending',
            count: _pendingRequests.length,
            color: Colors.orange,
            gradientColors: [
              Colors.orange.withOpacity(0.15),
              Colors.orange.withOpacity(0.05),
            ],
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: _buildStatCard(
            icon: Icons.access_time_rounded,
            label: 'Active',
            count: _activeRequests.length,
            color: Colors.blue,
            gradientColors: [
              Colors.blue.withOpacity(0.15),
              Colors.blue.withOpacity(0.05),
            ],
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_rounded,
            label: 'Done',
            count: _completedRequests.length,
            color: Colors.green,
            gradientColors: [
              Colors.green.withOpacity(0.15),
              Colors.green.withOpacity(0.05),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: spacingLarge,
        horizontal: spacingSmall,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: color.withOpacity(widget.isDarkMode ? 0.3 : 0.25),
          width: 1,
        ),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: spacingSmall),
          Text(
            count.toString(),
            style: h2.copyWith(
              fontSize: 24,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: caption.copyWith(
              fontSize: 12,
              color: widget.theme.subtextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
        border: widget.isDarkMode
            ? Border.all(color: primary.withOpacity(0.2), width: 1)
            : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.pending_actions_rounded, 'Pending', Colors.orange),
          _buildTab(1, Icons.trending_up_rounded, 'Active', Colors.blue),
          _buildTab(2, Icons.history_rounded, 'History', Colors.green),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label, Color accentColor) {
    final isSelected = _tabController.index == index;
    
    return Expanded(
      child: Semantics(
        label: '$label tab',
        selected: isSelected,
        button: true,
        child: GestureDetector(
          onTap: () {
            _tabController.animateTo(index);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.symmetric(vertical: spacingMedium),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(radiusMedium),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? white : widget.theme.subtextColor,
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? white : widget.theme.subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

 
Widget _buildCurrentTabContent() {
  List<RequestModel> currentRequests;
  
  switch (_tabController.index) {
    case 0:
      currentRequests = _pendingRequests;
      break;
    case 1:
      currentRequests = _activeRequests;
      break;
    case 2:
      currentRequests = _completedRequests;
      break;
    default:
      currentRequests = _pendingRequests;
  }

  if (currentRequests.isEmpty) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      child: _buildEmptyState(),
    );
  }

  return Column(
    children: currentRequests.map((request) {
      return Padding(
        padding: EdgeInsets.only(bottom: spacingLarge),
        child: _buildRequestCard(request),
      );
    }).toList(),
  );
}
  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_tabController.index) {
      case 0:
        message = 'No pending requests\nYou\'re all caught up!';
        icon = Icons.inbox_rounded;
        break;
      case 1:
        message = 'No active requests\nStart accepting requests to see them here';
        icon = Icons.task_alt_rounded;
        break;
      case 2:
        message = 'No completed requests yet\nYour history will appear here';
        icon = Icons.history_rounded;
        break;
      default:
        message = 'No requests yet';
        icon = Icons.inbox_rounded;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(spacingXLarge),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? primary.withOpacity(0.1)
                  : primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: primary.withOpacity(0.5),
            ),
          ),
          SizedBox(height: spacingLarge),
          Text(
            message,
            style: body.copyWith(
              color: widget.theme.subtextColor,
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(spacingXLarge),
              decoration: BoxDecoration(
                color: error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: error,
              ),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'Failed to load requests',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              _error ?? 'An error occurred',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacingLarge),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializeCaretakerId();
              },
              icon: Icon(Icons.refresh_rounded),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(
                  horizontal: spacingXLarge,
                  vertical: spacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    final priorityColor = request.getPriorityColor();
    final cachedImage = _profileImageCache[request.patientId];

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double responsiveWidth(double value) => value * (screenWidth / 375);
    double responsiveHeight(double value) => value * (screenHeight / 812);
    double responsiveFont(double value) => value * (screenWidth / 375);

    return Semantics(
      label: 'Request from ${request.patientName}',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: widget.isDarkMode
              ? [
                  BoxShadow(
                    color: priorityColor.withOpacity(0.15),
                    blurRadius: responsiveWidth(20),
                    offset: Offset(0, responsiveHeight(8)),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: responsiveWidth(16),
                    offset: Offset(0, responsiveHeight(4)),
                  ),
                ],
          borderRadius: BorderRadius.circular(responsiveWidth(radiusXLarge)),
        ),
        child: Material(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(responsiveWidth(radiusXLarge)),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestDetailsScreen(
                    request: request,
                    isDarkMode: widget.isDarkMode,
                    requestService: widget.requestService,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(responsiveWidth(radiusXLarge)),
            splashColor: priorityColor.withOpacity(0.1),
            child: Container(
              padding: EdgeInsets.all(responsiveWidth(spacingLarge * 1.2)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(responsiveWidth(radiusXLarge)),
                border: Border.all(
                  color: widget.isDarkMode
                      ? primary.withOpacity(0.2)
                      : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Profile Image Container with Network Image
                      Container(
                        width: responsiveWidth(56),
                        height: responsiveWidth(56),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isDarkMode
                                ? primary.withOpacity(0.3)
                                : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.15),
                              blurRadius: responsiveWidth(8),
                              offset: Offset(0, responsiveHeight(2)),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: cachedImage != null && cachedImage.isNotEmpty
                              ? Image.network(
                                  cachedImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: responsiveWidth(20),
                                        height: responsiveWidth(20),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : FutureBuilder<String?>(
                                  future: _getProfileImage(request.patientId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                        child: SizedBox(
                                          width: responsiveWidth(20),
                                          height: responsiveWidth(20),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(primary),
                                          ),
                                        ),
                                      );
                                    }
                                    if (snapshot.hasData &&
                                        snapshot.data != null &&
                                        snapshot.data!.isNotEmpty) {
                                      return Image.network(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildDefaultAvatar();
                                        },
                                      );
                                    }
                                    return _buildDefaultAvatar();
                                  },
                                ),
                        ),
                      ),
                      SizedBox(width: responsiveWidth(spacingMedium)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.patientName,
                              style: bodyBold.copyWith(
                                fontSize: responsiveFont(17),
                                color: widget.theme.textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: responsiveHeight(4)),
                            Row(
                              children: [
                                Icon(
                                  request.getIcon(),
                                  size: responsiveWidth(14),
                                  color: widget.theme.subtextColor,
                                ),
                                SizedBox(width: responsiveWidth(4)),
                                Expanded(
                                  child: Text(
                                    request.requestType,
                                    style: caption.copyWith(
                                      fontSize: responsiveFont(13),
                                      color: widget.theme.subtextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsiveWidth(spacingSmall),
                          vertical: responsiveHeight(6),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [priorityColor, priorityColor.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(responsiveWidth(radiusSmall)),
                          boxShadow: [
                            BoxShadow(
                              color: priorityColor.withOpacity(0.3),
                              blurRadius: responsiveWidth(6),
                              offset: Offset(0, responsiveHeight(2)),
                            ),
                          ],
                        ),
                        child: Text(
                          request.priority.toString().split('.').last.toUpperCase(),
                          style: caption.copyWith(
                            color: white,
                            fontWeight: FontWeight.w800,
                            fontSize: responsiveFont(10),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsiveHeight(spacingMedium)),
                  Container(
                    padding: EdgeInsets.all(responsiveWidth(spacingMedium)),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(responsiveWidth(radiusMedium)),
                    ),
                    child: Text(
                      request.message,
                      style: body.copyWith(
                        fontSize: responsiveFont(14),
                        color: widget.theme.textColor,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: responsiveHeight(spacingMedium)),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsiveWidth(spacingSmall),
                          vertical: responsiveHeight(5),
                        ),
                        decoration: BoxDecoration(
                          color: widget.theme.subtextColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(responsiveWidth(radiusSmall)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: responsiveWidth(14),
                              color: widget.theme.subtextColor,
                            ),
                            SizedBox(width: responsiveWidth(4)),
                            Text(
                              _getTimeAgo(request.timestamp),
                              style: caption.copyWith(
                                fontSize: responsiveFont(12),
                                color: widget.theme.subtextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (request.location != null) ...[
                        SizedBox(width: responsiveWidth(spacingSmall)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsiveWidth(spacingSmall),
                            vertical: responsiveHeight(5),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(responsiveWidth(radiusSmall)),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: responsiveWidth(14),
                                color: Colors.green,
                              ),
                              SizedBox(width: responsiveWidth(4)),
                              Text(
                                'Location',
                                style: caption.copyWith(
                                  fontSize: responsiveFont(12),
                                  color: Colors.green,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: responsiveWidth(16),
                        color: primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: primaryGradient,
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: white,
          size: 28,
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}