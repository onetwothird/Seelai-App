// File: lib/roles/mswd/home/sections/requests/requests_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/mswd/home/sections/requests/requests_details.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/caretaker/models/request_model.dart';
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

class _RequestsContentState extends State<RequestsContent> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  int _selectedTab = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Real data from Firebase
  List<RequestModel> _allRequests = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<RequestModel>>? _requestsSubscription;
  
  // Cache for user data (patient and caretaker info)
  final Map<String, Map<String, dynamic>> _userDataCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  void _loadRequests() {
    _requestsSubscription = assistanceRequestService
        .streamAllRequests()
        .listen(
      (requests) async {
        if (mounted) {
          setState(() {
            _allRequests = requests;
            _isLoading = false;
            _error = null;
          });
          
          // Preload user data for all requests
          await _preloadUserData(requests);
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

  Future<void> _preloadUserData(List<RequestModel> requests) async {
    for (var request in requests) {
      // Load patient data
      if (!_userDataCache.containsKey(request.patientId)) {
        await _getUserData(request.patientId);
      }
      
      // Load caretaker data if assigned
      if (request.caretakerId != null && 
          !_userDataCache.containsKey(request.caretakerId!)) {
        await _getUserData(request.caretakerId!);
      }
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    if (_userDataCache.containsKey(userId)) {
      return _userDataCache[userId];
    }

    try {
      final userData = await databaseService.getUserData(userId);
      if (userData != null && mounted) {
        setState(() {
          _userDataCache[userId] = userData;
        });
      }
      return userData;
    } catch (e) {
      debugPrint('Error fetching user data for $userId: $e');
      return null;
    }
  }

  Map<String, int> _getStatistics() {
    return {
      'pending': _allRequests.where((r) => r.status == RequestStatus.pending).length,
      'accepted': _allRequests.where((r) => r.status == RequestStatus.accepted).length,
      'inProgress': _allRequests.where((r) => r.status == RequestStatus.inProgress).length,
      'completed': _allRequests.where((r) => r.status == RequestStatus.completed).length,
      'declined': _allRequests.where((r) => r.status == RequestStatus.declined).length,
      'emergency': _allRequests.where((r) => r.priority == RequestPriority.emergency).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)),
            SizedBox(height: spacingLarge),
            Text(
              'Loading requests...',
              style: body.copyWith(color: widget.theme.subtextColor),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: error),
            SizedBox(height: spacingLarge),
            Text(
              'Failed to load requests',
              style: bodyBold.copyWith(color: widget.theme.textColor),
            ),
            SizedBox(height: spacingSmall),
            Text(
              _error!,
              style: body.copyWith(color: widget.theme.subtextColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacingLarge),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadRequests();
              },
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: spacingLarge),
          _buildStatsOverview(),
          SizedBox(height: spacingLarge),
          _buildSearchBar(),
          SizedBox(height: spacingLarge),
          _buildTabBar(),
          SizedBox(height: spacingLarge),
          _buildCurrentTabContent(),
          SizedBox(height: spacingLarge),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requests & Assistance',
          style: h2.copyWith(
            fontSize: 24,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Monitor all assistance requests',
          style: body.copyWith(
            color: widget.theme.subtextColor,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    final stats = _getStatistics();
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.pending_actions_rounded,
                label: 'Pending',
                count: stats['pending']!,
                color: Colors.orange,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle_rounded,
                label: 'Accepted',
                count: stats['accepted']!,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildStatCard(
                icon: Icons.sync_rounded,
                label: 'In Progress',
                count: stats['inProgress']!,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(height: spacingMedium),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.done_all_rounded,
                label: 'Completed',
                count: stats['completed']!,
                color: Colors.green,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildStatCard(
                icon: Icons.cancel_rounded,
                label: 'Declined',
                count: stats['declined']!,
                color: Colors.red,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildStatCard(
                icon: Icons.emergency_rounded,
                label: 'Emergency',
                count: stats['emergency']!,
                color: error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: spacingMedium,
        horizontal: spacingSmall,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
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
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: spacingSmall),
          Text(
            count.toString(),
            style: h2.copyWith(
              fontSize: 20,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: caption.copyWith(
              fontSize: 10,
              color: widget.theme.subtextColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: widget.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: _searchController,
        style: body.copyWith(color: widget.theme.textColor),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search requests...',
          hintStyle: body.copyWith(color: widget.theme.subtextColor),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: widget.theme.subtextColor,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: widget.theme.subtextColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: widget.isDarkMode
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
          border: widget.isDarkMode
              ? Border.all(color: primary.withOpacity(0.2), width: 1)
              : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
        ),
        child: Row(
          children: [
            _buildTab(0, Icons.pending_actions_rounded, 'Pending', Colors.orange),
            _buildTab(1, Icons.check_circle_rounded, 'Accepted', Colors.blue),
            _buildTab(2, Icons.sync_rounded, 'In Progress', Colors.purple),
            _buildTab(3, Icons.done_all_rounded, 'Completed', Colors.green),
            _buildTab(4, Icons.cancel_rounded, 'Declined', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label, Color accentColor) {
    final isSelected = _tabController.index == index;
    
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          vertical: spacingMedium,
          horizontal: spacingMedium,
        ),
        margin: const EdgeInsets.only(right: 4),
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
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? white : widget.theme.subtextColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? white : widget.theme.subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    final requests = _getRequestsForTab(_selectedTab);
    final filteredRequests = requests
        .where((r) => _searchQuery.isEmpty ||
            r.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.requestType.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (filteredRequests.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: List.generate(
        filteredRequests.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildRequestCard(filteredRequests[index]),
        ),
      ),
    );
  }

  List<RequestModel> _getRequestsForTab(int tab) {
    switch (tab) {
      case 0:
        return _allRequests.where((r) => r.status == RequestStatus.pending).toList();
      case 1:
        return _allRequests.where((r) => r.status == RequestStatus.accepted).toList();
      case 2:
        return _allRequests.where((r) => r.status == RequestStatus.inProgress).toList();
      case 3:
        return _allRequests.where((r) => r.status == RequestStatus.completed).toList();
      case 4:
        return _allRequests.where((r) => r.status == RequestStatus.declined).toList();
      default:
        return _allRequests;
    }
  }

  Widget _buildRequestCard(RequestModel request) {
    final priorityColor = request.getPriorityColor();
    final statusColor = _getStatusColor(request.status);
    final patientData = _userDataCache[request.patientId];
    final profileImageUrl = patientData?['profileImageUrl'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: priorityColor.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
        border: widget.isDarkMode
            ? Border.all(color: priorityColor.withOpacity(0.2), width: 1)
            : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestDetailsScreen(
                  request: request,
                  isDarkMode: widget.isDarkMode,
                  theme: widget.theme,
                  userDataCache: _userDataCache,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Patient Profile Image
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isDarkMode 
                              ? primary.withOpacity(0.3) 
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? Image.network(
                                profileImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(request.patientName),
                              )
                            : _buildDefaultAvatar(request.patientName),
                      ),
                    ),
                    
                    SizedBox(width: spacingMedium),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.patientName,
                            style: bodyBold.copyWith(
                              fontSize: 16,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                request.getIcon(),
                                size: 14,
                                color: widget.theme.subtextColor,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request.requestType,
                                  style: caption.copyWith(
                                    fontSize: 13,
                                    color: widget.theme.subtextColor,
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
                        horizontal: spacingSmall,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [priorityColor, priorityColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(radiusSmall),
                        boxShadow: [
                          BoxShadow(
                            color: priorityColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        request.priority.toString().split('.').last.toUpperCase(),
                        style: caption.copyWith(
                          color: white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: spacingMedium),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.access_time_rounded,
                        _formatTimeAgo(request.timestamp),
                      ),
                    ),
                    SizedBox(width: spacingSmall),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.location_on_rounded,
                        request.location != null ? 'Location' : 'No location',
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: spacingSmall),
                
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacingSmall,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(request.status),
                            size: 14,
                            color: statusColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            request.status.toString().split('.').last,
                            style: caption.copyWith(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: primary,
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

  Widget _buildDefaultAvatar(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: primaryGradient,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: h2.copyWith(
            color: white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacingSmall,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: widget.theme.subtextColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: widget.theme.subtextColor,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: caption.copyWith(
                fontSize: 11,
                color: widget.theme.subtextColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      message = 'No requests matching "$_searchQuery"';
      icon = Icons.search_off_rounded;
    } else {
      switch (_selectedTab) {
        case 0:
          message = 'No pending requests';
          icon = Icons.inbox_rounded;
          break;
        case 1:
          message = 'No accepted requests';
          icon = Icons.check_circle_outline_rounded;
          break;
        case 2:
          message = 'No requests in progress';
          icon = Icons.sync_rounded;
          break;
        case 3:
          message = 'No completed requests';
          icon = Icons.done_all_rounded;
          break;
        case 4:
          message = 'No declined requests';
          icon = Icons.cancel_outlined;
          break;
        default:
          message = 'No requests';
          icon = Icons.inbox_rounded;
      }
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacingXLarge * 2),
        child: Column(
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
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.accepted:
        return Colors.blue;
      case RequestStatus.inProgress:
        return Colors.purple;
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.declined:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.pending_actions_rounded;
      case RequestStatus.accepted:
        return Icons.check_circle_rounded;
      case RequestStatus.inProgress:
        return Icons.sync_rounded;
      case RequestStatus.completed:
        return Icons.done_all_rounded;
      case RequestStatus.declined:
        return Icons.cancel_rounded;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hrs ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}