// File: lib/roles/caretaker/home/sections/requests_screen/requests_content.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/firebase/caretaker/request_service.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_details_screen.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';

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
  // Brand Colors - Updated to requested violet
  final Color _primaryColor = const Color(0xFF8B5CF6);

  late TabController _tabController;
  List<RequestModel> _pendingRequests = [];
  List<RequestModel> _activeRequests = [];
  List<RequestModel> _completedRequests = [];
  
  bool _isLoading = true;
  String? _error;
  String? _caretakerId;
  StreamSubscription<List<RequestModel>>? _requestsSubscription;
  final Map<String, String?> _profileImageCache = {};

  // Animation State for Mascot Messages
  Timer? _messageTimer;
  int _currentMessageIndex = 0;

  // --- STATE VARIABLES FOR DELETION & PAGINATION ---
  final Set<String> _hiddenRequestIds = {};
  final Map<int, int> _tabPages = {0: 1, 1: 1, 2: 1, 3: 1}; // Added index 3 for Deleted tab
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    
    // Changed length to 4 to include the 'Deleted' tab
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _initializeCaretakerId().then((_) {
      if (_caretakerId != null) {
        databaseService.saveUserFCMToken(_caretakerId!, 'caretaker');
      }
    });

    _startMessageTimer();
    
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      switch (event!.event) {
        case Event.actionCallAccept:
          break;
        case Event.actionCallDecline:
          debugPrint("Alarm dismissed by user.");
          break;
        default:
          break;
      }
    });
  }

  void _startMessageTimer() {
    _messageTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex++;
        });
      }
    });
  }

  String _getFirstName() {
    final name = widget.userData['name'] as String? ?? 'Caretaker';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'Caretaker';
  }

  List<String> _getMascotMessages() {
    int pendingCount = _pendingRequests.length;
    int activeCount = _activeRequests.length;
    
    List<String> messages = [];
    
    if (pendingCount > 0 || activeCount > 0) {
      messages.add('Hello, ${_getFirstName()}! You have $pendingCount pending request${pendingCount != 1 ? 's' : ''} and $activeCount active task${activeCount != 1 ? 's' : ''} right now.');
    } else {
      messages.add('Hello, ${_getFirstName()}! You\'re all caught up. No pending or active requests at the moment.');
    }
    
    messages.add('Remember to check the priority labels on requests. Red signifies an urgent need!');
    messages.add('You can quickly switch between the Pending, Active, and History tabs to manage your workflow.');
    
    return messages;
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
    _messageTimer?.cancel();
    _tabController.dispose();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshRequests() async {
    if (_caretakerId == null) {
      await _initializeCaretakerId();
      return;
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _showBrandSnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF8B5CF6), // Enforced Brand Color
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && !_isLoading) {
      return _buildErrorState();
    }

    if (_isLoading && _pendingRequests.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    final width = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: _refreshRequests,
      color: _primaryColor,
      child: CustomScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: width * 0.05,
                    right: width * 0.05,
                    top: spacingLarge,
                  ),
                  child: _buildHeader(),
                ),
                const SizedBox(height: spacingMedium),
                _buildMascotBanner(),
                const SizedBox(height: spacingMedium),
              ],
            ),
          ),
          
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            sliver: SliverToBoxAdapter(
              child: _buildMinimalStats(),
            ),
          ),
          
          SliverPadding(
            padding: EdgeInsets.only(
              left: width * 0.05, 
              right: width * 0.05, 
              top: spacingLarge,
              bottom: spacingMedium
            ),
            sliver: SliverToBoxAdapter(
              child: _buildMinimalTabs(),
            ),
          ),
          
          SliverToBoxAdapter(
            child: _buildRequestListContainer(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ==================== UI COMPONENTS ====================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assistance Requests',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: widget.theme.textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage incoming help requests',
          style: TextStyle(
            fontSize: 14,
            color: widget.theme.subtextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMascotBanner() {
    final messages = _getMascotMessages();
    final safeIndex = _currentMessageIndex % messages.length;
    final displayMessage = messages[safeIndex];

    return Stack(
      clipBehavior: Clip.none,
      children: [
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
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Image.asset(
                'assets/seelai-icons/seelai4.png',
                height: 125, 
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100, width: 100,
                  alignment: Alignment.bottomCenter,
                  child: Icon(Icons.image_not_supported, color: widget.theme.subtextColor),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 40), 
                child: CustomPaint(
                  size: const Size(12, 16),
                  painter: _TailPainter(
                    color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                  ),
                ),
              ),
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
                      Container(
                        height: 65, 
                        alignment: Alignment.topLeft,
                        child: TypewriterText(
                          text: displayMessage,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: widget.isDarkMode
                                ? Colors.white.withValues(alpha: 0.85)
                                : Colors.black87,
                            height: 1.4,
                          ),
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

  Widget _buildMinimalStats() {
    final int totalRequests = _pendingRequests.length + _activeRequests.length + _completedRequests.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                count: totalRequests,
                title: 'Total',
                subtitle: 'All requests',
                bottomLabel: 'TOTAL',
                baseColor: _primaryColor,
                backgroundIcon: Icons.all_inbox_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                count: _pendingRequests.length,
                title: 'Pending',
                subtitle: 'Awaiting review',
                bottomLabel: 'REQUESTS',
                baseColor: const Color(0xFFF5A623),
                backgroundIcon: Icons.assignment_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                count: _activeRequests.length,
                title: 'In Progress',
                subtitle: 'Active sessions',
                bottomLabel: 'ONGOING',
                baseColor: const Color(0xFF60A5FA),
                backgroundIcon: Icons.touch_app_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                count: _completedRequests.length,
                title: 'Completed',
                subtitle: 'Finished tasks',
                bottomLabel: 'TOTAL',
                baseColor: const Color(0xFF34D399),
                backgroundIcon: Icons.task_alt_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required int count,
    required String title,
    required String subtitle,
    required String bottomLabel,
    required Color baseColor,
    required IconData backgroundIcon,
  }) {
    return Container(
      height: 140, 
      clipBehavior: Clip.hardEdge, 
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.15), 
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -10,
            child: Icon(
              backgroundIcon,
              size: 110,
              color: baseColor.withValues(alpha: 0.12),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.theme.subtextColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_horiz_rounded,
                      color: widget.theme.subtextColor,
                      size: 20,
                    ),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      bottomLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.theme.subtextColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2, 
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 26,
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
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
          color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: _primaryColor,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: widget.theme.subtextColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.2),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4), // Added to prevent overflow
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Active'),
          Tab(text: 'History'),
          Tab(text: 'Deleted'), // 4th Tab Included
        ],
      ),
    );
  }

  Widget _buildRequestListContainer() {
    List<RequestModel> visibleRequests;
    final currentTabIndex = _tabController.index;

    // Filter requests directly into `visibleRequests` based on the active tab
    switch (currentTabIndex) {
      case 0: 
        visibleRequests = _pendingRequests; 
        break;
      case 1: 
        visibleRequests = _activeRequests; 
        break;
      case 2: 
        visibleRequests = _completedRequests.where((req) => !_hiddenRequestIds.contains(req.id)).toList(); 
        break;
      case 3: 
        visibleRequests = _completedRequests.where((req) => _hiddenRequestIds.contains(req.id)).toList(); 
        break;
      default: 
        visibleRequests = _pendingRequests;
    }

    if (visibleRequests.isEmpty) {
      return SizedBox(
        height: 300,
        child: _buildEmptyState(),
      );
    }

    final int totalItems = visibleRequests.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    
    int currentPage = _tabPages[currentTabIndex] ?? 1;
    
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
      WidgetsBinding.instance.addPostFrameCallback((_) {
         setState(() { _tabPages[currentTabIndex] = currentPage; });
      });
    }

    final int startIndex = (currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > totalItems) endIndex = totalItems;

    final paginatedRequests = visibleRequests.sublist(startIndex, endIndex);
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // Removed the "Restore All" button from here

        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paginatedRequests.length,
          itemBuilder: (context, index) {
            final request = paginatedRequests[index];
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05, 
                vertical: 6
              ),
              child: _buildCardForCurrentTab(request, currentTabIndex),
            );
          },
        ),
        
        if (totalPages > 1) 
          _buildPaginationControls(currentPage, totalPages, currentTabIndex),
      ],
    );
  }

  // Decides which card widget to render based on the current active tab
  Widget _buildCardForCurrentTab(RequestModel request, int currentTabIndex) {
    if (currentTabIndex == 2) {
      return _buildDismissibleCard(request);
    } else if (currentTabIndex == 3) {
      return _buildDeletedCard(request);
    } else {
      return _buildMinimalRequestCard(request);
    }
  }

  // --- NEW: AESTHETIC CARD FOR DELETED ITEMS ---
  Widget _buildDeletedCard(RequestModel request) {
    final priorityColor = request.getPriorityColor();
    final cachedImage = _profileImageCache[request.patientId];

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Name, Type, Priority
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (cachedImage != null && cachedImage.isNotEmpty)
                        ? (widget.isDarkMode ? Colors.white10 : Colors.white)
                        : _primaryColor.withValues(alpha: 0.1), 
                    border: Border.all(
                      color: _primaryColor.withValues(alpha: 0.2), 
                      width: 1.5,
                    ), 
                    image: cachedImage != null
                        ? DecorationImage(
                            image: NetworkImage(cachedImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: cachedImage == null
                      ? Icon(Icons.person_rounded, color: _primaryColor, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                
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
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(request.getIcon(), size: 14, color: widget.theme.subtextColor),
                          const SizedBox(width: 4),
                          Text(
                            request.requestType,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: widget.theme.subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                        request.priority.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: priorityColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Message
            Text(
              request.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: widget.theme.textColor.withOpacity(0.85),
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bottom Row: Time and RESTORE Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.access_time_rounded, size: 14, color: widget.theme.subtextColor),
                ),
                const SizedBox(width: 6),
                Text(
                  _getTimeAgo(request.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.subtextColor,
                  ),
                ),
                
                const Spacer(),
                
                // RESTORE BUTTON
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    foregroundColor: Colors.green,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('Restore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    setState(() { _hiddenRequestIds.remove(request.id); });
                    _showBrandSnackbar('Request restored.');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int currentPage, int totalPages, int tabIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: currentPage > 1 ? _primaryColor : widget.theme.subtextColor.withOpacity(0.3),
            onPressed: currentPage > 1 ? () {
              setState(() {
                _tabPages[tabIndex] = currentPage - 1;
              });
            } : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Page $currentPage of $totalPages',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _primaryColor,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: currentPage < totalPages ? _primaryColor : widget.theme.subtextColor.withOpacity(0.3),
            onPressed: currentPage < totalPages ? () {
              setState(() {
                _tabPages[tabIndex] = currentPage + 1;
              });
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleCard(RequestModel request) {
    return Dismissible(
      key: Key(request.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        setState(() {
          _hiddenRequestIds.add(request.id);
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Moved to Deleted', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
            backgroundColor: const Color(0xFF8B5CF6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _hiddenRequestIds.remove(request.id);
                  });
                }
              },
            ),
          ),
        );
      },
      child: _buildMinimalRequestCard(request),
    );
  }

  Widget _buildMinimalRequestCard(RequestModel request) {
    final priorityColor = request.getPriorityColor();
    final cachedImage = _profileImageCache[request.patientId];

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'avatar_${request.id}', 
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (cachedImage != null && cachedImage.isNotEmpty)
                              ? (widget.isDarkMode ? Colors.white10 : Colors.white)
                              : _primaryColor.withValues(alpha: 0.1), 
                          border: Border.all(
                            color: _primaryColor.withValues(alpha: 0.2), 
                            width: 1.5,
                          ), 
                          image: cachedImage != null
                              ? DecorationImage(
                                  image: NetworkImage(cachedImage),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: cachedImage == null
                            ? Icon(Icons.person_rounded, color: _primaryColor, size: 24)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
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
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(request.getIcon(), size: 14, color: widget.theme.subtextColor),
                              const SizedBox(width: 4),
                              Text(
                                request.requestType,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: widget.theme.subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        request.priority.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  request.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.theme.textColor.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.access_time_rounded, size: 14, color: widget.theme.subtextColor),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getTimeAgo(request.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.theme.subtextColor,
                      ),
                    ),
                    if (request.location != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 12, color: Colors.green[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
      case 3: // Newly added state
        icon = Icons.delete_outline_rounded;
        title = "Trash is Empty";
        sub = "Deleted requests will appear here.";
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: widget.theme.subtextColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: widget.theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: TextStyle(color: widget.theme.subtextColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() { _isLoading = true; _error = null; });
              _initializeCaretakerId();
            },
            style: TextButton.styleFrom(
              backgroundColor: _primaryColor.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Try Again', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
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
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: msDuration));
    _setupAnimation();
    _controller.forward();
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
        if (end > widget.text.length) end = widget.text.length;
        if (end < 0) end = 0;
        
        return Text(
          widget.text.substring(0, end),
          style: widget.style,
        );
      },
    );
  }
}