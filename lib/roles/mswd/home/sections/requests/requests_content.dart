// File: lib/roles/mswd/home/sections/requests/requests_content.dart

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
  int _selectedFilterIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  List<RequestModel> _allRequests = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<RequestModel>>? _requestsSubscription;
  final Map<String, Map<String, dynamic>> _userDataCache = {};

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

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildQuickStats(),
          const SizedBox(height: 32),
          _buildSearchAndFilter(),
          const SizedBox(height: 24),
          _buildFilterChips(),
          const SizedBox(height: 24),
          _buildRequestList(),
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
          style: h2.copyWith(
            color: widget.theme.textColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage and track community requests',
          style: body.copyWith(
            color: widget.theme.subtextColor,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final pending = _allRequests.where((r) => r.status == RequestStatus.pending).length;
    final emergency = _allRequests.where((r) => r.priority.toString().contains('emergency') && r.status != RequestStatus.completed).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Action Needed',
            count: pending.toString(),
            icon: Icons.notification_important_rounded,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Emergencies',
            count: emergency.toString(),
            icon: Icons.warning_rounded,
            color: const Color(0xFFEF4444), 
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: Border.all(
          color: widget.isDarkMode 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: h2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: widget.theme.textColor,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: caption.copyWith(
              color: widget.theme.subtextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
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
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: Border.all(
          color: widget.isDarkMode 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: body.copyWith(color: widget.theme.textColor),
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search patients or requests...',
          hintStyle: body.copyWith(color: widget.theme.subtextColor.withOpacity(0.7)),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(Icons.search_rounded, color: widget.theme.subtextColor),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: widget.theme.subtextColor),
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
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? color : widget.theme.subtextColor.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: const [],
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
    final targetStatus = _filters[_selectedFilterIndex]['status'] as RequestStatus;
    
    final filtered = _allRequests.where((req) {
      final matchesStatus = req.status == targetStatus;
      final matchesSearch = _searchQuery.isEmpty || 
          req.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          req.requestType.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    // Redesigned Empty State Card
    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.isDarkMode 
                ? Colors.white.withValues(alpha: 0.05) 
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // This fixes the awkward stretching!
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.theme.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded, 
                size: 40, 
                color: widget.theme.subtextColor.withValues(alpha: 0.5)
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No requests found',
              style: h3.copyWith(color: widget.theme.textColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search criteria.',
              style: body.copyWith(color: widget.theme.subtextColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildRedesignedCard(filtered[index]);
      },
    );
  }

  Widget _buildRedesignedCard(RequestModel request) {
    final userData = _userDataCache[request.patientId];
    final profileImg = userData?['profileImageUrl'];
    
    final statusColor = _getStatusColor(request.status);
    final isEmergency = request.priority.toString().contains('emergency');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isEmergency 
                  ? Colors.red.withValues(alpha: 0.5) 
                  : (widget.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              width: isEmergency ? 1.5 : 1.0,
            ),
            boxShadow: widget.isDarkMode ? [] : softShadow,
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
                        color: widget.theme.backgroundColor,
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
                                style: h2.copyWith(color: widget.theme.subtextColor, fontSize: 20),
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
                          style: h2.copyWith(
                            fontSize: 18,
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
                          style: caption.copyWith(
                            fontSize: 13,
                            color: widget.theme.subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.status.name.toUpperCase(),
                      style: caption.copyWith(
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.theme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.assignment_rounded, size: 16, color: widget.theme.subtextColor),
                        const SizedBox(width: 8),
                        Text(
                          request.requestType,
                          style: body.copyWith(
                            fontSize: 14,
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
                            style: caption.copyWith(
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
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: widget.theme.subtextColor.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          'Location shared',
                          style: caption.copyWith(
                            color: widget.theme.subtextColor.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers
  Widget _buildLoading() => const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))); 
  Widget _buildError() => Center(child: Text(_error ?? 'Unknown Error', style: const TextStyle(color: Colors.red)));

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending: return Colors.orange;
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