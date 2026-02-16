// File: lib/roles/mswd/home/sections/requests/requests_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/mswd/home/sections/requests/requests_details.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
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
  // State
  int _selectedFilterIndex = 0; // 0: All, 1: Pending, etc.
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Data
  List<RequestModel> _allRequests = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<RequestModel>>? _requestsSubscription;
  final Map<String, Map<String, dynamic>> _userDataCache = {};

  // Filter Options
  final List<Map<String, dynamic>> _filters = [
    {'label': 'Pending', 'status': RequestStatus.pending, 'icon': Icons.pending_actions_rounded, 'color': Colors.orange},
    {'label': 'Accepted', 'status': RequestStatus.accepted, 'icon': Icons.how_to_reg_rounded, 'color': Colors.blue},
    {'label': 'Active', 'status': RequestStatus.inProgress, 'icon': Icons.sync_rounded, 'color': Colors.purple},
    {'label': 'Completed', 'status': RequestStatus.completed, 'icon': Icons.task_alt_rounded, 'color': Colors.green},
    {'label': 'Declined', 'status': RequestStatus.declined, 'icon': Icons.block_rounded, 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  void _loadRequests() {
    _requestsSubscription = assistanceRequestService.streamAllRequests().listen(
      (requests) async {
        if (mounted) {
          // accurate sorting: Emergency first, then newest
          requests.sort((a, b) {
            if (a.priority == RequestPriority.emergency && b.priority != RequestPriority.emergency) return -1;
            if (b.priority == RequestPriority.emergency && a.priority != RequestPriority.emergency) return 1;
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

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 24),
          _buildQuickStats(),
          SizedBox(height: 24),
          _buildSearchAndFilter(),
          SizedBox(height: 20),
          _buildFilterChips(),
          SizedBox(height: 20),
          _buildRequestList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assistance Log',
              style: h2.copyWith(
                color: widget.theme.textColor,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Manage and track community requests',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final pending = _allRequests.where((r) => r.status == RequestStatus.pending).length;
    final emergency = _allRequests.where((r) => r.priority == RequestPriority.emergency && r.status != RequestStatus.completed).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Action Needed',
            pending.toString(),
            Icons.notification_important_rounded,
            Colors.orange,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Emergencies',
            emergency.toString(),
            Icons.warning_rounded,
            Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: h2.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textColor,
                ),
              ),
              Text(
                title,
                style: caption.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: body.copyWith(color: widget.theme.textColor),
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by patient name or type...',
          hintStyle: body.copyWith(color: widget.theme.subtextColor),
          prefixIcon: Icon(Icons.search, color: widget.theme.subtextColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: widget.theme.subtextColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilterIndex == index;
          final color = filter['color'] as Color;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : widget.theme.cardColor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? color : widget.theme.subtextColor.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: Offset(0, 2))]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    filter['icon'],
                    size: 16,
                    color: isSelected ? Colors.white : widget.theme.subtextColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    filter['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : widget.theme.subtextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
    final targetStatus = _filters[_selectedFilterIndex]['status'] as RequestStatus;
    
    // Filter logic
    final filtered = _allRequests.where((req) {
      final matchesStatus = req.status == targetStatus;
      final matchesSearch = _searchQuery.isEmpty || 
          req.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          req.requestType.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.folder_open_rounded, size: 60, color: widget.theme.subtextColor.withOpacity(0.5)),
              SizedBox(height: 16),
              Text('No requests found', style: body.copyWith(color: widget.theme.subtextColor)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildRedesignedCard(filtered[index]);
      },
    );
  }

  Widget _buildRedesignedCard(RequestModel request) {
    final userData = _userDataCache[request.patientId];
    final profileImg = userData?['profileImageUrl'];
    
    // -------------------------------------------------------------
    // KEY CHANGE: The color is now based on STATUS, not PRIORITY.
    // -------------------------------------------------------------
    final statusColor = _getStatusColor(request.status);
    final isEmergency = request.priority == RequestPriority.emergency;

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: GestureDetector(
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
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.isDarkMode ? Colors.black26 : Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // STATUS STRIP (The container color follows the status)
                Container(
                  width: 6,
                  color: statusColor, 
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Type + Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.theme.backgroundColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                request.requestType.toUpperCase(),
                                style: caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: widget.theme.subtextColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              _formatShortTime(request.timestamp),
                              style: caption.copyWith(
                                fontSize: 12,
                                color: widget.theme.subtextColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        
                        // Body: Avatar + Name
                        Row(
                          children: [
                            Hero(
                              tag: 'avatar_${request.id}',
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    // BORDER matches STATUS color
                                    color: statusColor.withOpacity(0.5), 
                                    width: 2
                                  ),
                                  image: profileImg != null && profileImg.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(profileImg),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: (profileImg == null || profileImg.isEmpty)
                                    ? Center(child: Text(request.patientName[0], style: h2.copyWith(color: statusColor)))
                                    : null,
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.patientName,
                                    style: h2.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme.textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // We keep the Emergency warning here, but the container color is controlled by Status
                                  if (isEmergency)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                                          SizedBox(width: 4),
                                          Text(
                                            'Emergency Help',
                                            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Text(
                                      request.location != null ? 'Location attached' : 'No location',
                                      style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: widget.theme.subtextColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helpers
  Widget _buildLoading() => Center(child: CircularProgressIndicator(color: primary));
  Widget _buildError() => Center(child: Text(_error ?? 'Unknown Error', style: TextStyle(color: Colors.red)));

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending: return Colors.orange;
      case RequestStatus.accepted: return Colors.blue;
      case RequestStatus.inProgress: return Colors.purple;
      case RequestStatus.completed: return Colors.green;
      case RequestStatus.declined: return Colors.red;
    }
  }

  String _formatShortTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}