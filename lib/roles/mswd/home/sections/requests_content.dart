// File: lib/roles/mswd/home/sections/requests_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:intl/intl.dart';

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
  bool _showRequestDetails = false;
  Map<String, dynamic>? _selectedRequest;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (_showRequestDetails && _selectedRequest != null) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        physics: ClampingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            _buildRequestDetailsHeader(),
            SizedBox(height: spacingLarge),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: _buildRequestDetailsContent(),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: ClampingScrollPhysics(),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.pending_actions_rounded,
                label: 'Pending',
                count: 12,
                color: Colors.orange,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle_rounded,
                label: 'Accepted',
                count: 8,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildStatCard(
                icon: Icons.sync_rounded,
                label: 'In Progress',
                count: 15,
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
                count: 145,
                color: Colors.green,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildStatCard(
                icon: Icons.cancel_rounded,
                label: 'Declined',
                count: 3,
                color: Colors.red,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildStatCard(
                icon: Icons.emergency_rounded,
                label: 'Emergency',
                count: 2,
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
                  offset: Offset(0, 2),
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
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          vertical: spacingMedium,
          horizontal: spacingMedium,
        ),
        margin: EdgeInsets.only(right: 4),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? white : widget.theme.subtextColor,
            ),
            SizedBox(width: 6),
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

    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: List.generate(
        requests.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildRequestCard(requests[index]),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getRequestsForTab(int tab) {
    final allRequests = [
      {
        'id': 'REQ-001',
        'patient': 'Maria Santos',
        'caretaker': 'Rosa Martinez',
        'type': 'Navigation Help',
        'priority': 'High',
        'status': 'Pending',
        'created': DateTime.now().subtract(Duration(minutes: 10)),
        'location': 'Manila City Hall',
        'responseTime': null,
        'notes': 'Patient needs assistance navigating to the health center',
      },
      {
        'id': 'REQ-002',
        'patient': 'Juan Dela Cruz',
        'caretaker': 'Carlos Reyes',
        'type': 'Reading Assistance',
        'priority': 'Medium',
        'status': 'Accepted',
        'created': DateTime.now().subtract(Duration(minutes: 25)),
        'accepted': DateTime.now().subtract(Duration(minutes: 20)),
        'location': 'Quezon City Library',
        'responseTime': '5 mins',
        'notes': 'Help needed reading medical documents',
      },
      {
        'id': 'REQ-003',
        'patient': 'Pedro Garcia',
        'caretaker': 'Anna Lopez',
        'type': 'Emergency Call',
        'priority': 'Critical',
        'status': 'In Progress',
        'created': DateTime.now().subtract(Duration(hours: 1)),
        'accepted': DateTime.now().subtract(Duration(minutes: 58)),
        'location': 'Makati Medical Center',
        'responseTime': '2 mins',
        'notes': 'Emergency medical assistance required',
      },
      {
        'id': 'REQ-004',
        'patient': 'Ana Santos',
        'caretaker': 'Rosa Martinez',
        'type': 'Medication Reminder',
        'priority': 'Low',
        'status': 'Completed',
        'created': DateTime.now().subtract(Duration(hours: 3)),
        'accepted': DateTime.now().subtract(Duration(hours: 2, minutes: 55)),
        'completed': DateTime.now().subtract(Duration(hours: 2, minutes: 30)),
        'location': 'Patient Home',
        'responseTime': '5 mins',
        'notes': 'Medication reminder delivered successfully',
      },
      {
        'id': 'REQ-005',
        'patient': 'Luis Cruz',
        'caretaker': null,
        'type': 'Transportation Help',
        'priority': 'Medium',
        'status': 'Declined',
        'created': DateTime.now().subtract(Duration(hours: 5)),
        'declined': DateTime.now().subtract(Duration(hours: 4)),
        'location': 'Pasig City',
        'responseTime': '1 hr',
        'notes': 'No available caretaker at the moment',
      },
    ];

    switch (tab) {
      case 0:
        return allRequests.where((r) => r['status'] == 'Pending').toList();
      case 1:
        return allRequests.where((r) => r['status'] == 'Accepted').toList();
      case 2:
        return allRequests.where((r) => r['status'] == 'In Progress').toList();
      case 3:
        return allRequests.where((r) => r['status'] == 'Completed').toList();
      case 4:
        return allRequests.where((r) => r['status'] == 'Declined').toList();
      default:
        return allRequests;
    }
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final priorityColor = request['priority'] == 'Critical' || request['priority'] == 'High'
        ? error 
        : request['priority'] == 'Medium' 
            ? Colors.orange 
            : Colors.green;

    final statusColor = _getStatusColor(request['status']);

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: priorityColor.withOpacity(0.1),
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
        border: widget.isDarkMode
            ? Border.all(color: priorityColor.withOpacity(0.2), width: 1)
            : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedRequest = request;
              _showRequestDetails = true;
            });
          },
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: primaryGradient,
                        border: Border.all(
                          color: widget.isDarkMode 
                              ? primary.withOpacity(0.3) 
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          request['patient'].toString().substring(0, 1).toUpperCase(),
                          style: h2.copyWith(
                            color: white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: spacingMedium),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['patient'],
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
                                Icons.assignment_rounded,
                                size: 14,
                                color: widget.theme.subtextColor,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request['type'],
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
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        request['priority'].toString().toUpperCase(),
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
                        _formatTimeAgo(request['created']),
                      ),
                    ),
                    SizedBox(width: spacingSmall),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.location_on_rounded,
                        request['location'],
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
                            _getStatusIcon(request['status']),
                            size: 14,
                            color: statusColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            request['status'],
                            style: caption.copyWith(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
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

  // Request Details Screen
  Widget _buildRequestDetailsHeader() {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(radiusXLarge),
          bottomRight: Radius.circular(radiusXLarge),
        ),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
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
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showRequestDetails = false),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: widget.theme.textColor,
                  size: 24,
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Text(
                  'Request Details',
                  style: h2.copyWith(
                    fontSize: 20,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacingSmall,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(_selectedRequest!['status']).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radiusSmall),
                ),
                child: Text(
                  _selectedRequest!['status'],
                  style: caption.copyWith(
                    fontSize: 11,
                    color: _getStatusColor(_selectedRequest!['status']),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacingLarge),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _selectedRequest!['patient'].toString().substring(0, 1).toUpperCase(),
                style: h2.copyWith(
                  color: white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: spacingMedium),
          Text(
            _selectedRequest!['patient'],
            style: h2.copyWith(
              fontSize: 20,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Request ID: ${_selectedRequest!['id']}',
            style: caption.copyWith(
              fontSize: 12,
              color: widget.theme.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetailsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBasicInfoSection(),
        SizedBox(height: spacingLarge),
        _buildCaretakerSection(),
        SizedBox(height: spacingLarge),
        _buildTimestampsSection(),
        SizedBox(height: spacingLarge),
        _buildLocationSection(),
        SizedBox(height: spacingLarge),
        _buildNotesSection(),
        SizedBox(height: spacingLarge),
        _buildActionButtons(),
        SizedBox(height: spacingLarge),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    final priorityColor = _getPriorityColor(_selectedRequest!['priority']);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Information',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildDetailCard('Request Type', _selectedRequest!['type'], Icons.assignment_rounded),
        _buildDetailCard(
          'Priority Level',
          _selectedRequest!['priority'],
          Icons.priority_high_rounded,
          color: priorityColor,
        ),
        _buildDetailCard(
          'Status',
          _selectedRequest!['status'],
          _getStatusIcon(_selectedRequest!['status']),
          color: _getStatusColor(_selectedRequest!['status']),
        ),
      ],
    );
  }

  Widget _buildCaretakerSection() {
    final caretaker = _selectedRequest!['caretaker'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned Caretaker',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        if (caretaker != null)
          Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [accent, accent.withOpacity(0.7)],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.favorite_rounded,
                      color: white,
                      size: 24,
                    ),
                  ),
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caretaker,
                        style: bodyBold.copyWith(
                          fontSize: 15,
                          color: widget.theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Response Time: ${_selectedRequest!['responseTime'] ?? 'N/A'}',
                        style: caption.copyWith(
                          fontSize: 12,
                          color: widget.theme.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: widget.theme.subtextColor,
                ),
              ],
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_off_rounded,
                  color: widget.theme.subtextColor,
                  size: 24,
                ),
                SizedBox(width: spacingMedium),
                Text(
                  'No caretaker assigned',
                  style: body.copyWith(
                    fontSize: 14,
                    color: widget.theme.subtextColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimestampsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildTimelineItem(
          'Created',
          _selectedRequest!['created'],
          Icons.add_circle_rounded,
          Colors.blue,
          isFirst: true,
        ),
        if (_selectedRequest!['accepted'] != null)
          _buildTimelineItem(
            'Accepted',
            _selectedRequest!['accepted'],
            Icons.check_circle_rounded,
            Colors.green,
          ),
        if (_selectedRequest!['completed'] != null)
          _buildTimelineItem(
            'Completed',
            _selectedRequest!['completed'],
            Icons.done_all_rounded,
            Colors.green,
            isLast: true,
          ),
        if (_selectedRequest!['declined'] != null)
          _buildTimelineItem(
            'Declined',
            _selectedRequest!['declined'],
            Icons.cancel_rounded,
            Colors.red,
            isLast: true,
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String label,
    DateTime? timestamp,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    if (timestamp == null) return SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: widget.theme.subtextColor.withOpacity(0.3),
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 18),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: widget.theme.subtextColor.withOpacity(0.3),
              ),
          ],
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp),
                  style: caption.copyWith(
                    fontSize: 12,
                    color: widget.theme.subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        Container(
          padding: EdgeInsets.all(spacingMedium),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusLarge),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withOpacity(0.1),
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: primary,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Text(
                  _selectedRequest!['location'],
                  style: body.copyWith(
                    fontSize: 14,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(spacingMedium),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusLarge),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Text(
            _selectedRequest!['notes'] ?? 'No notes available',
            style: body.copyWith(
              fontSize: 14,
              color: widget.theme.textColor,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final status = _selectedRequest!['status'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == 'Pending') ...[
          _buildActionButton(
            'Assign Caretaker',
            Icons.person_add_rounded,
            primary,
            () {},
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            'View Patient Profile',
            Icons.account_circle_rounded,
            accent,
            () {},
          ),
        ] else if (status == 'In Progress') ...[
          _buildActionButton(
            'Track Location',
            Icons.my_location_rounded,
            primary,
            () {},
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            'Contact Caretaker',
            Icons.phone_rounded,
            accent,
            () {},
          ),
        ] else if (status == 'Completed') ...[
          _buildActionButton(
            'View Report',
            Icons.description_rounded,
            primary,
            () {},
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            'Rate Service',
            Icons.star_rounded,
            Colors.amber,
            () {},
          ),
        ],
        SizedBox(height: spacingMedium),
        _buildActionButton(
          'More Options',
          Icons.more_horiz_rounded,
          Colors.grey,
          () {},
          outlined: true,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: outlined
            ? Border.all(color: color.withOpacity(0.3))
            : Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusLarge),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacingMedium,
              vertical: spacingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
                SizedBox(width: 8),
                Text(
                  label,
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Container(
        padding: EdgeInsets.all(spacingMedium),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          border: Border.all(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (color ?? primary).withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: color ?? primary,
                ),
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: caption.copyWith(
                      fontSize: 11,
                      color: widget.theme.subtextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: body.copyWith(
                      fontSize: 14,
                      color: widget.theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.blue;
      case 'In Progress':
        return Colors.purple;
      case 'Completed':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending_actions_rounded;
      case 'Accepted':
        return Icons.check_circle_rounded;
      case 'In Progress':
        return Icons.sync_rounded;
      case 'Completed':
        return Icons.done_all_rounded;
      case 'Declined':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
      case 'High':
        return error;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
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