// File: lib/roles/mswd/home/sections/requests/mswd_requests_content.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/roles/mswd/home/sections/requests/requests_details.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/themes/constants.dart';
import 'dart:async';

class RequestsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final ScrollController? scrollController;

  const RequestsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    this.scrollController,
  });

  @override
  State<RequestsContent> createState() => _RequestsContentState();
}

class _RequestsContentState extends State<RequestsContent> {
  // Brand Colors
  final Color _primaryColor = const Color(0xFF7C3AED);

  int _selectedFilterIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  List<RequestModel> _allRequests = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<RequestModel>>? _requestsSubscription;
  final Map<String, Map<String, dynamic>> _userDataCache = {};

  // Animation State
  Timer? _messageTimer;
  int _currentMessageIndex = 0;

  // --- PAGINATION & DELETION VARIABLES ---
  final int _itemsPerPage = 5;
  final Set<String> _hiddenRequestIds = {};
  
  // Added index 5 for the new 'Deleted' filter chip
  final Map<int, int> _filterPages = {0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1};

  // Added 'Deleted' to the filters
  final List<Map<String, dynamic>> _filters = [
    {'label': 'Pending', 'status': RequestStatus.pending, 'icon': Icons.pending_actions_rounded, 'color': const Color(0xFFF5A623)},
    {'label': 'Accepted', 'status': RequestStatus.accepted, 'icon': Icons.how_to_reg_rounded, 'color': const Color(0xFF3B82F6)},
    {'label': 'Active', 'status': RequestStatus.inProgress, 'icon': Icons.sync_rounded, 'color': const Color(0xFF8B5CF6)},
    {'label': 'Completed', 'status': RequestStatus.completed, 'icon': Icons.task_alt_rounded, 'color': const Color(0xFF10B981)},
    {'label': 'Declined', 'status': RequestStatus.declined, 'icon': Icons.block_rounded, 'color': const Color(0xFFEF4444)},
    {'label': 'Deleted', 'status': 'deleted', 'icon': Icons.delete_outline_rounded, 'color': const Color(0xFF9CA3AF)},
  ];

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _startMessageTimer();
  }

  void _startMessageTimer() {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex++;
        });
      }
    });
  }

  String _getFirstName() {
    final name = widget.userData['name'] as String? ?? 'Admin';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'Admin';
  }

  List<String> _getMascotMessages() {
    final pendingCount = _allRequests.where((r) => r.status == RequestStatus.pending && !_hiddenRequestIds.contains(r.id)).length;
    final emergencyCount = _allRequests.where((r) => r.priority.toString().contains('emergency') && r.status != RequestStatus.completed && !_hiddenRequestIds.contains(r.id)).length;

    List<String> msgs = [];
    if (pendingCount == 0 && emergencyCount == 0) {
      msgs.add('Hello, ${_getFirstName()}! The assistance log is clear. Great job keeping up!');
    } else {
      msgs.add('Hello, ${_getFirstName()}! You currently have $pendingCount pending request${pendingCount != 1 ? 's' : ''} and $emergencyCount active emergenc${emergencyCount != 1 ? 'ies' : 'y'}.');
    }
    msgs.add('Tip: Use the filter chips below to quickly sort requests by their status.');
    return msgs;
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _searchController.dispose();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  void _loadRequests() {
    _requestsSubscription = assistanceRequestService.streamAllRequests().listen(
      (requests) async {
        if (mounted) {
          requests.sort((a, b) {
            final aIsEmergency = a.priority.toString().contains('emergency');
            final bIsEmergency = b.priority.toString().contains('emergency');
            
            if (aIsEmergency && !bIsEmergency) return -1;
            if (bIsEmergency && !aIsEmergency) return 1;
            return b.timestamp.compareTo(a.timestamp);
          });

          setState(() {
            _allRequests = requests;
            _isLoading = false;
            _error = null;
          });
          await _preloadUserData(requests);
        }
      },
      onError: (error) {
        if (mounted) setState(() => _error = 'Stream Error: $error');
      },
    );
  }

  Future<void> _preloadUserData(List<RequestModel> requests) async {
    for (var request in requests) {
      if (!_userDataCache.containsKey(request.patientId)) await _getUserData(request.patientId);
      if (request.caretakerId != null && !_userDataCache.containsKey(request.caretakerId!)) {
        await _getUserData(request.caretakerId!);
      }
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    if (_userDataCache.containsKey(userId)) return _userDataCache[userId];
    try {
      final data = await databaseService.getUserData(userId);
      if (data != null && mounted) setState(() => _userDataCache[userId] = data);
      return data;
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();

    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
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
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildQuickStats(),
                const SizedBox(height: 24),
                _buildSearchAndFilter(),
                const SizedBox(height: 20),
                _buildFilterChips(),
                const SizedBox(height: 24),
                _buildRequestList(),
                
                const SizedBox(height: 120), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assistance Log',
          style: TextStyle(
            color: widget.theme.textColor,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage and track community requests',
          style: TextStyle(
            color: widget.theme.subtextColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMascotBanner() {
    final messages = _getMascotMessages();
    final safeIndex = _currentMessageIndex % messages.length;
    final displayMessage = messages[safeIndex];
    final longestMessage = messages.reduce((a, b) => a.length > b.length ? a : b);

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
                height: 120, 
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
                          TypewriterText(
                            key: ValueKey(displayMessage),
                            text: displayMessage,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
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

  Widget _buildQuickStats() {
    final pending = _allRequests.where((r) => r.status == RequestStatus.pending && !_hiddenRequestIds.contains(r.id)).length;
    final emergency = _allRequests.where((r) => r.priority.toString().contains('emergency') && r.status != RequestStatus.completed && !_hiddenRequestIds.contains(r.id)).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Action Needed',
            subtitle: 'Pending requests',
            count: pending.toString(),
            icon: Icons.assignment_rounded,
            color: const Color.fromARGB(255, 247, 179, 71),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Emergencies',
            subtitle: 'High priority',
            count: emergency.toString(),
            icon: Icons.warning_rounded,
            color: const Color.fromARGB(255, 211, 76, 76), 
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String subtitle,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 140, 
      clipBehavior: Clip.hardEdge, 
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(
          color: color.withValues(alpha: 0.15), 
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -10,
            child: Icon(
              icon,
              size: 110,
              color: color.withValues(alpha: 0.12),
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: color,
                      ),
                    ),
                    Text(
                      count,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(20), 
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: widget.isDarkMode 
              ? Colors.white10 
              : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: widget.theme.textColor, fontSize: 14),
        onChanged: (v) {
          setState(() {
            _searchQuery = v;
            _filterPages[_selectedFilterIndex] = 1; // Reset to page 1 on search
          });
        },
        decoration: InputDecoration(
          isDense: true, 
          hintText: 'Search patients or requests...',
          hintStyle: TextStyle(color: widget.theme.subtextColor.withValues(alpha: 0.7), fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.search_rounded, color: widget.theme.subtextColor, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16), 
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: widget.theme.subtextColor, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _filterPages[_selectedFilterIndex] = 1;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilterIndex == index;
          final color = filter['color'] as Color;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color : widget.theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? color : widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                  width: 1.5,
                ),
                boxShadow: widget.isDarkMode ? [] : (isSelected ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ] : []),
              ),
              child: Row(
                children: [
                  Icon(
                    filter['icon'],
                    size: 18,
                    color: isSelected ? Colors.white : widget.theme.subtextColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    filter['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : widget.theme.subtextColor,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestList() {
    final filterStatus = _filters[_selectedFilterIndex]['status'];
    
    final filtered = _allRequests.where((req) {
      final matchesSearch = _searchQuery.isEmpty || 
          req.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          req.requestType.toLowerCase().contains(_searchQuery.toLowerCase());
          
      if (!matchesSearch) return false;

      // Handle the custom 'deleted' filter
      if (filterStatus == 'deleted') {
        return _hiddenRequestIds.contains(req.id);
      } else {
        final matchesStatus = req.status == filterStatus;
        final isNotDeleted = !_hiddenRequestIds.contains(req.id);
        return matchesStatus && isNotDeleted;
      }
    }).toList();

    if (filtered.isEmpty) {
      IconData emptyIcon = Icons.inbox_rounded;
      String emptyTitle = 'No requests found';
      String emptySub = 'Try adjusting your filters or search criteria.';

      if (_selectedFilterIndex == 5) { // Deleted tab
        emptyIcon = Icons.delete_outline_rounded;
        emptyTitle = 'Trash is Empty';
        emptySub = 'Deleted requests will appear here.';
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(
            color: widget.isDarkMode 
                ? Colors.white10 
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(
                emptyIcon, 
                size: 48, 
                color: widget.theme.subtextColor.withValues(alpha: 0.5)
              ),
            ),
            const SizedBox(height: 20),
            Text(
              emptyTitle,
              style: TextStyle(
                color: widget.theme.textColor, 
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              emptySub,
              style: TextStyle(color: widget.theme.subtextColor, fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Pagination Calculations
    final int totalItems = filtered.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    
    int currentPage = _filterPages[_selectedFilterIndex] ?? 1;
    
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) setState(() { _filterPages[_selectedFilterIndex] = currentPage; });
      });
    }

    final int startIndex = (currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > totalItems) endIndex = totalItems;

    final paginatedRequests = filtered.sublist(startIndex, endIndex);

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero, 
          itemCount: paginatedRequests.length,
          itemBuilder: (context, index) {
            final request = paginatedRequests[index];
            final isLast = index == paginatedRequests.length - 1;
            
            Widget card;
            if (_selectedFilterIndex == 5) { // Deleted tab
              card = _buildDeletedCard(request);
            } else {
              card = _buildDismissibleCard(request);
            }

            // Margin is applied here so the Swipe-to-delete background matches perfectly
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: card,
            );
          },
        ),
        
        if (totalPages > 1) 
          Padding(
            padding: const EdgeInsets.only(top: 24.0), 
            child: _buildPaginationControls(currentPage, totalPages, _selectedFilterIndex),
          ),
      ],
    );
  }

  Widget _buildPaginationControls(int currentPage, int totalPages, int filterIndex) {
    return Padding(
      padding: EdgeInsets.zero, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: currentPage > 1 ? _primaryColor : widget.theme.subtextColor.withOpacity(0.3),
            onPressed: currentPage > 1 ? () {
              setState(() {
                _filterPages[filterIndex] = currentPage - 1;
              });
            } : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24), 
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
                _filterPages[filterIndex] = currentPage + 1;
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
            backgroundColor: _primaryColor,
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
      child: _buildRedesignedCard(request),
    );
  }

  // Used for active cards
  Widget _buildRedesignedCard(RequestModel request) {
    final userData = _userDataCache[request.patientId];
    final profileImg = userData?['profileImageUrl'];
    
    final statusColor = _getStatusColor(request.status);
    final isEmergency = request.priority.toString().contains('emergency');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RequestDetailsScreen(
            request: request,
            isDarkMode: widget.isDarkMode,
            theme: widget.theme,
            userDataCache: _userDataCache,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(
            color: isEmergency 
                ? Colors.red.withValues(alpha: 0.4) 
                : (widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
            width: isEmergency ? 1.5 : 1.0,
          ),
          boxShadow: widget.isDarkMode ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Hero(
                  tag: 'avatar_${request.id}',
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isDarkMode ? Colors.white10 : Colors.grey[100],
                      border: Border.all(color: widget.isDarkMode ? Colors.white24 : Colors.black12),
                      image: profileImg != null && profileImg.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(profileImg),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (profileImg == null || profileImg.isEmpty)
                        ? Center(
                            child: Text(
                              request.patientName.isNotEmpty ? request.patientName[0].toUpperCase() : '?',
                              style: TextStyle(color: widget.theme.subtextColor, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatShortTime(request.timestamp),
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.theme.subtextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? Colors.white10 : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_rounded, size: 16, color: widget.theme.subtextColor),
                      const SizedBox(width: 8),
                      Text(
                        request.requestType,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (isEmergency)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded, size: 16, color: Colors.red),
                        const SizedBox(width: 6),
                        Text(
                          'EMERGENCY',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (request.location != null)
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
                            color: Colors.green[600],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // AESTHETIC CARD FOR DELETED ITEMS (Includes Restore Button)
  Widget _buildDeletedCard(RequestModel request) {
    final userData = _userDataCache[request.patientId];
    final profileImg = userData?['profileImageUrl'];
    final statusColor = _getStatusColor(request.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
          width: 1.0,
        ),
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isDarkMode ? Colors.white10 : Colors.grey[100],
                  border: Border.all(color: widget.isDarkMode ? Colors.white24 : Colors.black12),
                  image: profileImg != null && profileImg.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(profileImg),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (profileImg == null || profileImg.isEmpty)
                    ? Center(
                        child: Text(
                          request.patientName.isNotEmpty ? request.patientName[0].toUpperCase() : '?',
                          style: TextStyle(color: widget.theme.subtextColor, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatShortTime(request.timestamp),
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.theme.subtextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request.status.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Colors.white10 : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_rounded, size: 16, color: widget.theme.subtextColor),
                    const SizedBox(width: 8),
                    Text(
                      request.requestType,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.theme.textColor,
                      ),
                    ),
                  ],
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
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Request restored.', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                      backgroundColor: _primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _buildLoading() => const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))); 
  Widget _buildError() => Center(child: Text(_error ?? 'Unknown Error', style: const TextStyle(color: Colors.red)));

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending: return const Color(0xFFF5A623);
      case RequestStatus.accepted: return const Color(0xFF3B82F6); 
      case RequestStatus.inProgress: return const Color(0xFF8B5CF6); 
      case RequestStatus.completed: return const Color(0xFF10B981); 
      case RequestStatus.declined: return const Color(0xFFEF4444); 
    }
  }

  String _formatShortTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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

// ==========================================
// TYPEWRITER ANIMATION WIDGET (DYNAMIC SPEED)
// ==========================================
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