// File: lib/roles/mswd/home/sections/dashboard_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/caretaker/models/request_model.dart';
import 'package:firebase_database/firebase_database.dart';

class DashboardContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final ScrollController? scrollController;

  const DashboardContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    this.scrollController,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  int _currentStatIndex = 0;
  final PageController _statsController = PageController();
  
  // Dashboard statistics
  int _totalUsers = 0;
  int _visuallyImpairedUsers = 0;
  int _caretakerUsers = 0;
  int _mswdUsers = 0;
  int _pendingVerifications = 0;
  int _activeRequests = 0;
  int _emergencyAlerts = 0;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _statsController.dispose();
    super.dispose();
  }

  /// Fetch all dashboard statistics from Firebase
  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch data in parallel for better performance
      await Future.wait([
        _fetchAllUsers(),
        _fetchPendingVerifications(),
        _fetchActiveRequests(),
        _fetchEmergencyAlerts(),
      ]);
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Fetch all users categorized by role - FIXED VERSION
  Future<void> _fetchAllUsers() async {
    try {
      debugPrint('🔍 Fetching all users from Firebase...');
      
      // Fetch all user counts in parallel
      final viCountFuture = _countUsersInPath('user_info/visually_impaired');
      final ctCountFuture = _countUsersInPath('user_info/caretaker');
      final mswdCountFuture = _countUsersInPath('user_info/mswd');
      
      final viCount = await viCountFuture;
      final ctCount = await ctCountFuture;
      final mswdCount = await mswdCountFuture;
      final totalCount = viCount + ctCount + mswdCount;
      
      if (mounted) {
        setState(() {
          _visuallyImpairedUsers = viCount;
          _caretakerUsers = ctCount;
          _mswdUsers = mswdCount;
          _totalUsers = totalCount;
        });
      }
      
      debugPrint('✅ Total System Users: $totalCount');
      debugPrint('   └─ Visually Impaired: $viCount');
      debugPrint('   └─ Caretakers: $ctCount');
      debugPrint('   └─ MSWD Staff: $mswdCount');
      
    } catch (e) {
      debugPrint('❌ Error fetching users: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        setState(() {
          _totalUsers = 0;
          _visuallyImpairedUsers = 0;
          _caretakerUsers = 0;
          _mswdUsers = 0;
        });
      }
    }
  }

  /// Helper method to count users in a specific path - FIXED
  Future<int> _countUsersInPath(String path) async {
    try {
      // Add error handling and logging
      debugPrint('   📍 Querying path: $path');
      
      final snapshot = await FirebaseDatabase.instance
          .ref(path)
          .once();
      
      if (!snapshot.snapshot.exists) {
        debugPrint('   🔭 $path: 0 users (path empty)');
        return 0;
      }
      
      final data = snapshot.snapshot.value;
      
      // Handle different data types
      if (data is Map) {
        final count = data.length;
        debugPrint('   ✔️ $path: $count users found');
        return count;
      } else if (data is List) {
        // In case data is returned as a list
        final count = data.length;
        debugPrint('   ✔️ $path: $count users found (list format)');
        return count;
      } else {
        debugPrint('   ⚠️ $path: Unexpected data type: ${data.runtimeType}');
        return 0;
      }
      
    } catch (e) {
      debugPrint('   ❌ Error counting users in $path: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      return 0;
    }
  }

  /// Fetch pending verifications (requests with 'pending' status)
  Future<void> _fetchPendingVerifications() async {
    try {
      final allRequests = await _getAllAssistanceRequests();
      final pendingCount = allRequests
          .where((req) => req.status == RequestStatus.pending)
          .length;
      
      if (mounted) {
        setState(() {
          _pendingVerifications = pendingCount;
        });
      }
      debugPrint('📋 Pending Verifications: $pendingCount');
    } catch (e) {
      debugPrint('❌ Error fetching pending verifications: $e');
    }
  }

  /// Fetch active requests (requests marked as 'inProgress')
  Future<void> _fetchActiveRequests() async {
    try {
      final allRequests = await _getAllAssistanceRequests();
      final activeCount = allRequests
          .where((req) => req.status == RequestStatus.inProgress)
          .length;
      
      if (mounted) {
        setState(() {
          _activeRequests = activeCount;
        });
      }
      debugPrint('📄 Active Requests: $activeCount');
    } catch (e) {
      debugPrint('❌ Error fetching active requests: $e');
    }
  }

  /// Fetch emergency alerts (requests with emergency/SOS type)
  Future<void> _fetchEmergencyAlerts() async {
    try {
      final allRequests = await _getAllAssistanceRequests();
      
      // Count requests that are emergency-related
      final emergencyCount = allRequests.where((req) {
        final type = req.requestType.toLowerCase();
        return type.contains('emergency') || 
               type.contains('sos') || 
               type.contains('urgent') ||
               req.priority == 'high' ||
               req.priority == 'urgent';
      }).length;
      
      if (mounted) {
        setState(() {
          _emergencyAlerts = emergencyCount;
        });
      }
      debugPrint('🚨 Emergency Alerts: $emergencyCount');
    } catch (e) {
      debugPrint('❌ Error fetching emergency alerts: $e');
    }
  }

  /// Helper method to get all assistance requests from all caretakers
  Future<List<RequestModel>> _getAllAssistanceRequests() async {
    try {
      final caretakers = await adminService.getUsersByRole('caretaker');
      final List<RequestModel> allRequests = [];
      
      // Fetch requests for each caretaker
      for (var caretaker in caretakers) {
        final caretakerId = caretaker['userId'] as String;
        try {
          final requests = await assistanceRequestService.getCaretakerRequests(caretakerId);
          allRequests.addAll(requests);
        } catch (e) {
          debugPrint('⚠️ Error fetching requests for caretaker $caretakerId: $e');
        }
      }
      
      // Remove duplicates based on request ID
      final uniqueRequests = <String, RequestModel>{};
      for (var request in allRequests) {
        uniqueRequests[request.id] = request;
      }
      
      return uniqueRequests.values.toList();
    } catch (e) {
      debugPrint('❌ Error getting all assistance requests: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
          // Quick Stats Grid - Swipeable
          _buildQuickStatsSection(),

          SizedBox(height: spacingXLarge),

          // Announcement Section
          _buildAnnouncementSection(),

          SizedBox(height: spacingXLarge),

          // User Breakdown Section
          _buildUserBreakdownSection(),

          SizedBox(height: spacingXLarge),

         
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    final stats = [
      {
        'icon': Icons.people_rounded,
        'label': 'Total Users',
        'value': _isLoading ? '...' : _totalUsers.toString(),
        'color': primary,
        'subtitle': '👥 Registered Users',
      },
      {
        'icon': Icons.pending_actions_rounded,
        'label': 'Pending Verifications',
        'value': _isLoading ? '...' : _pendingVerifications.toString(),
        'color': Colors.orange,
        'subtitle': '⏱ Awaiting approval',
      },
      {
        'icon': Icons.touch_app_rounded,
        'label': 'Active Requests',
        'value': _isLoading ? '...' : _activeRequests.toString(),
        'color': Colors.blue,
        'subtitle': '📄 In progress',
      },
      {
        'icon': Icons.warning_rounded,
        'label': 'Emergency Alerts',
        'value': _isLoading ? '...' : _emergencyAlerts.toString(),
        'color': error,
        'subtitle': '🚨 Urgent',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overview',
              style: h3.copyWith(
                fontSize: 20,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              )
            else
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _fetchDashboardData,
                  borderRadius: BorderRadius.circular(radiusMedium),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: spacingMedium),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _statsController,
            onPageChanged: (index) {
              setState(() => _currentStatIndex = index % stats.length);
            },
            itemBuilder: (context, index) {
              final stat = stats[index % stats.length];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildStatCard(
                  icon: stat['icon'] as IconData,
                  label: stat['label'] as String,
                  value: stat['value'] as String,
                  subtitle: stat['subtitle'] as String,
                  color: stat['color'] as Color,
                ),
              );
            },
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildPageIndicator(stats.length),
      ],
    );
  }

  Widget _buildUserBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Breakdown',
          style: h3.copyWith(
            fontSize: 20,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildUserTypeCard(
          icon: Icons.visibility_off_rounded,
          label: 'Visually Impaired',
          value: _isLoading ? '...' : _visuallyImpairedUsers.toString(),
          color: Colors.purple,
          percentage: _totalUsers > 0 
              ? ((_visuallyImpairedUsers / _totalUsers) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
        SizedBox(height: spacingMedium),
        _buildUserTypeCard(
          icon: Icons.volunteer_activism_rounded,
          label: 'Caretakers',
          value: _isLoading ? '...' : _caretakerUsers.toString(),
          color: Colors.green,
          percentage: _totalUsers > 0 
              ? ((_caretakerUsers / _totalUsers) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
        SizedBox(height: spacingMedium),
        _buildUserTypeCard(
          icon: Icons.admin_panel_settings_rounded,
          label: 'MSWD Staff',
          value: _isLoading ? '...' : _mswdUsers.toString(),
          color: Colors.teal,
          percentage: _totalUsers > 0 
              ? ((_mswdUsers / _totalUsers) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
      ],
    );
  }

  Widget _buildUserTypeCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String percentage,
  }) {
    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: color.withOpacity(0.2), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacingSmall),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: bodyBold.copyWith(
                    fontSize: 15,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$percentage% of total users',
                  style: caption.copyWith(
                    fontSize: 12,
                    color: widget.theme.subtextColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: h2.copyWith(
              fontSize: 28,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: color.withOpacity(0.3), width: 1.5)
            : Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(spacingMedium),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(radiusSmall),
                ),
                child: Text(
                  subtitle,
                  style: caption.copyWith(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: h1.copyWith(
                  fontSize: 32,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: caption.copyWith(
                  fontSize: 13,
                  color: widget.theme.subtextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int itemCount) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          itemCount,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentStatIndex == index ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentStatIndex == index
                  ? primary
                  : widget.theme.subtextColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
  // Replace the _buildRecentActivity() method with this new announcement section

Widget _buildAnnouncementSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Announcements',
            style: h3.copyWith(
              fontSize: 20,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showCreateAnnouncementDialog(),
              borderRadius: BorderRadius.circular(radiusMedium),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(radiusMedium),
                  border: Border.all(color: primary.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, color: primary, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Create',
                      style: bodyBold.copyWith(
                        fontSize: 14,
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: spacingMedium),
      
      // Sample announcements - Replace with Firebase data
      _buildAnnouncementCard(
        title: 'Community Event This Weekend',
        message: 'Join us for a community gathering at the town hall this Saturday at 10 AM.',
        targetAudience: 'Caretakers',
        timestamp: '2 hours ago',
        icon: Icons.event_rounded,
        color: Colors.blue,
      ),
      SizedBox(height: spacingMedium),
      _buildAnnouncementCard(
        title: 'New Navigation Features Available',
        message: 'We\'ve added improved voice guidance and obstacle detection to help you navigate better.',
        targetAudience: 'Visually Impaired',
        timestamp: '1 day ago',
        icon: Icons.navigation_rounded,
        color: Colors.purple,
      ),
      SizedBox(height: spacingMedium),
      _buildAnnouncementCard(
        title: 'Important: App Maintenance',
        message: 'The app will undergo maintenance on Sunday from 2 AM to 4 AM. Services may be temporarily unavailable.',
        targetAudience: 'All Users',
        timestamp: '2 days ago',
        icon: Icons.build_rounded,
        color: Colors.orange,
      ),
    ],
  );
}

  Widget _buildAnnouncementCard({
    required String title,
    required String message,
    required String targetAudience,
    required String timestamp,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacingSmall),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: bodyBold.copyWith(
                        fontSize: 15,
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(radiusSmall),
                            border: Border.all(color: color.withOpacity(0.3), width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                targetAudience == 'Caretakers' 
                                    ? Icons.volunteer_activism_rounded 
                                    : targetAudience == 'Visually Impaired'
                                        ? Icons.visibility_off_rounded
                                        : Icons.people_rounded,
                                color: color,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                targetAudience,
                                style: caption.copyWith(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600,
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
            ],
          ),
          SizedBox(height: spacingMedium),
          Text(
            message,
            style: caption.copyWith(
              fontSize: 13,
              color: widget.theme.subtextColor,
              height: 1.5,
            ),
          ),
          SizedBox(height: spacingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timestamp,
                style: caption.copyWith(
                  fontSize: 11,
                  color: widget.theme.subtextColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // TODO: Implement delete announcement
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delete announcement functionality coming soon'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(radiusSmall),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: widget.theme.subtextColor.withOpacity(0.5),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateAnnouncementDialog() {
    String selectedAudience = 'Visually Impaired';
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: widget.theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusLarge),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacingSmall),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    child: Icon(Icons.campaign_rounded, color: primary, size: 24),
                  ),
                  SizedBox(width: spacingSmall),
                  Text(
                    'Create Announcement',
                    style: h3.copyWith(
                      fontSize: 18,
                      color: widget.theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Audience Selection
                    Text(
                      'Target Audience',
                      style: bodyBold.copyWith(
                        fontSize: 14,
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: spacingSmall),
                    Container(
                      decoration: BoxDecoration(
                        color: widget.theme.backgroundColor,
                        borderRadius: BorderRadius.circular(radiusMedium),
                        border: Border.all(
                          color: widget.theme.subtextColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAudience,
                          isExpanded: true,
                          padding: EdgeInsets.symmetric(horizontal: spacingMedium),
                          borderRadius: BorderRadius.circular(radiusMedium),
                          dropdownColor: widget.theme.cardColor,
                          style: body.copyWith(color: widget.theme.textColor),
                          icon: Icon(Icons.arrow_drop_down, color: widget.theme.textColor),
                          items: [
                            DropdownMenuItem(
                              value: 'Visually Impaired',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_off_rounded, 
                                      color: Colors.purple, size: 20),
                                  SizedBox(width: spacingSmall),
                                  Text('Visually Impaired'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Caretakers',
                              child: Row(
                                children: [
                                  Icon(Icons.volunteer_activism_rounded, 
                                      color: Colors.green, size: 20),
                                  SizedBox(width: spacingSmall),
                                  Text('Caretakers'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'All Users',
                              child: Row(
                                children: [
                                  Icon(Icons.people_rounded, 
                                      color: primary, size: 20),
                                  SizedBox(width: spacingSmall),
                                  Text('All Users'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedAudience = value!;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: spacingMedium),
                    
                    // Title Input
                    Text(
                      'Title',
                      style: bodyBold.copyWith(
                        fontSize: 14,
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: spacingSmall),
                    TextField(
                      controller: titleController,
                      style: body.copyWith(color: widget.theme.textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter announcement title',
                        hintStyle: body.copyWith(
                          color: widget.theme.subtextColor.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: widget.theme.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radiusMedium),
                          borderSide: BorderSide(
                            color: widget.theme.subtextColor.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radiusMedium),
                          borderSide: BorderSide(
                            color: widget.theme.subtextColor.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radiusMedium),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: spacingMedium),
                    
                    // Message Input
                    Text(
                      'Message',
                      style: bodyBold.copyWith(
                        fontSize: 14,
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: spacingSmall),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      style: body.copyWith(color: widget.theme.textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter announcement message',
                        hintStyle: body.copyWith(
                          color: widget.theme.subtextColor.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: widget.theme.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radiusMedium),
                          borderSide: BorderSide(
                            color: widget.theme.subtextColor.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radiusMedium),
                          borderSide: BorderSide(
                            color: widget.theme.subtextColor.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radiusMedium),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: bodyBold.copyWith(
                      color: widget.theme.subtextColor,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement Firebase save logic
                    if (titleController.text.isNotEmpty && 
                        messageController.text.isNotEmpty) {
                      // Save announcement to Firebase
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Announcement sent to $selectedAudience'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: spacingLarge,
                      vertical: spacingSmall,
                    ),
                  ),
                  child: Text(
                    'Send',
                    style: bodyBold.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  } 
}