// ignore_for_file: deprecated_member_use, sized_box_for_whitespace

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/firebase/caretaker/request_service.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_details_screen.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class RequestsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final RequestService requestService;
  final Function(int) onRequestCountChange;
  final ScrollController? scrollController;

  const RequestsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.requestService,
    required this.onRequestCountChange,
    this.scrollController,
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
    String? caretakerId = widget.userData['uid'] as String?;
    
    if (caretakerId == null || caretakerId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      caretakerId = user?.uid;
    }
    
    if (caretakerId == null || caretakerId.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Caretaker ID not found.';
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _caretakerId = caretakerId;
      });
    }

    _setupRequestsStream();
  }

  void _setupRequestsStream() {
    if (_caretakerId == null) return;

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
            _error = 'Failed to load requests';
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
    // The stream updates automatically, but we simulate a refresh feel
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && !_isLoading) {
      return _buildErrorState();
    }

    if (_isLoading && _pendingRequests.isEmpty) {
      return Center(child: CircularProgressIndicator(color: primary));
    }

    // Using CustomScrollView to handle the passed scrollController effectively
    return RefreshIndicator(
      onRefresh: _refreshRequests,
      color: primary,
      child: CustomScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Stats Section
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, spacingMedium, 20, spacingMedium),
            sliver: SliverToBoxAdapter(
              child: _buildMinimalStats(),
            ),
          ),

          // 2. Custom Tabs
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _buildMinimalTabs(),
            ),
          ),

          // 3. Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 4. Request List or Empty State
          _buildRequestListSliver(),

          // 5. Bottom Padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ==================== UI COMPONENTS ====================

  Widget _buildMinimalStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            count: _pendingRequests.length,
            label: 'Pending',
            color: Colors.orange,
            icon: Icons.notifications_active_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            count: _activeRequests.length,
            label: 'Active',
            color: Colors.blue,
            icon: Icons.run_circle_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            count: _completedRequests.length,
            label: 'Done',
            color: Colors.green,
            icon: Icons.task_alt_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode 
            ? color.withOpacity(0.15) 
            : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode ? Colors.transparent : color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.theme.textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: widget.theme.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalTabs() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: primary,
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: widget.theme.subtextColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Active'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  Widget _buildRequestListSliver() {
    List<RequestModel> currentRequests;
    switch (_tabController.index) {
      case 0: currentRequests = _pendingRequests; break;
      case 1: currentRequests = _activeRequests; break;
      case 2: currentRequests = _completedRequests; break;
      default: currentRequests = _pendingRequests;
    }

    if (currentRequests.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 300,
          child: _buildEmptyState(),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final request = currentRequests[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: _buildMinimalRequestCard(request),
          );
        },
        childCount: currentRequests.length,
      ),
    );
  }

  Widget _buildMinimalRequestCard(RequestModel request) {
    final priorityColor = request.getPriorityColor();
    final cachedImage = _profileImageCache[request.patientId];

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: widget.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestDetailsScreen(
                  request: request,
                  isDarkMode: widget.isDarkMode,
                  requestService: widget.requestService,
                  // PASS CACHED IMAGE HERE FOR HERO ANIMATION
                  preloadedProfileImage: cachedImage, 
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // === UPDATED: WRAP WITH HERO FOR ANIMATION ===
                    Hero(
                      tag: 'avatar_${request.id}', // Must match Details Screen tag
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isDarkMode ? Colors.white10 : Colors.grey[200],
                          border: Border.all(color: Colors.black, width: 1), 
                          image: cachedImage != null
                              ? DecorationImage(
                                  image: NetworkImage(cachedImage),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: cachedImage == null
                            ? Icon(Icons.person, color: Colors.grey[400])
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Name and Type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.patientName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(request.getIcon(), size: 12, color: widget.theme.subtextColor),
                              const SizedBox(width: 4),
                              Text(
                                request.requestType,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: widget.theme.subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        request.priority.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Message Preview
                Text(
                  request.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.theme.textColor.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Footer (Time & Location)
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: widget.theme.subtextColor),
                    const SizedBox(width: 4),
                    Text(
                      _getTimeAgo(request.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.theme.subtextColor,
                      ),
                    ),
                    if (request.location != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, size: 14, color: Colors.green[400]),
                      const SizedBox(width: 4),
                      Text(
                        'Location Attached',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
    IconData icon;
    String title;
    String sub;

    switch (_tabController.index) {
      case 0:
        icon = Icons.inbox_rounded;
        title = "All Caught Up!";
        sub = "No pending requests at the moment.";
        break;
      case 1:
        icon = Icons.assignment_turned_in_rounded;
        title = "No Active Tasks";
        sub = "Accept a request to see it here.";
        break;
      case 2:
        icon = Icons.history_edu_rounded;
        title = "No History";
        sub = "Completed requests will appear here.";
        break;
      default:
        icon = Icons.inbox;
        title = "No Data";
        sub = "";
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: widget.theme.subtextColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              fontSize: 14,
              color: widget.theme.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: TextStyle(color: widget.theme.subtextColor),
          ),
          TextButton(
            onPressed: () {
              setState(() { _isLoading = true; _error = null; });
              _initializeCaretakerId();
            },
            child: const Text('Try Again', style: TextStyle(color: primary)),
          )
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}