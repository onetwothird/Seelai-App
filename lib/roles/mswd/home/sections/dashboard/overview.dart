// File: lib/roles/mswd/home/sections/dashboard/overview.dart

// ignore_for_file: unrelated_type_equality_checks, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';

class OverviewSection extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;

  const OverviewSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  int _currentStatIndex = 0;
  final PageController _statsController = PageController();
  
  // Statistics
  int _totalUsers = 0;
  int _pendingVerifications = 0;
  int _activeRequests = 0;
  int _emergencyAlerts = 0;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOverviewData();
  }

  @override
  void dispose() {
    _statsController.dispose();
    super.dispose();
  }

  /// Fetch overview statistics
  Future<void> _fetchOverviewData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _fetchTotalUsers(),
        _fetchPendingVerifications(),
        _fetchActiveRequests(),
        _fetchEmergencyAlerts(),
      ]);
    } catch (e) {
      debugPrint('Error fetching overview data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Fetch total users count
  Future<void> _fetchTotalUsers() async {
    try {
      final viCount = await _countUsersInPath('user_info/visually_impaired');
      final ctCount = await _countUsersInPath('user_info/caretaker');
      final mswdCount = await _countUsersInPath('user_info/mswd');
      
      if (mounted) {
        setState(() {
          _totalUsers = viCount + ctCount + mswdCount;
        });
      }
    } catch (e) {
      debugPrint('Error fetching total users: $e');
    }
  }

  /// Helper method to count users in a specific path
  Future<int> _countUsersInPath(String path) async {
    try {
      final snapshot = await adminService.getUsersByRole(
        path.split('/').last,
      );
      return snapshot.length;
    } catch (e) {
      debugPrint('Error counting users in $path: $e');
      return 0;
    }
  }

  /// Fetch pending verifications
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
    } catch (e) {
      debugPrint('Error fetching pending verifications: $e');
    }
  }

  /// Fetch active requests
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
    } catch (e) {
      debugPrint('Error fetching active requests: $e');
    }
  }

  /// Fetch emergency alerts
  Future<void> _fetchEmergencyAlerts() async {
    try {
      final allRequests = await _getAllAssistanceRequests();
      
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
    } catch (e) {
      debugPrint('Error fetching emergency alerts: $e');
    }
  }

  /// Get all assistance requests
  Future<List<RequestModel>> _getAllAssistanceRequests() async {
    try {
      final caretakers = await adminService.getUsersByRole('caretaker');
      final List<RequestModel> allRequests = [];
      
      for (var caretaker in caretakers) {
        final caretakerId = caretaker['userId'] as String;
        try {
          final requests = await assistanceRequestService.getCaretakerRequests(caretakerId);
          allRequests.addAll(requests);
        } catch (e) {
          debugPrint('Error fetching requests for caretaker $caretakerId: $e');
        }
      }
      
      final uniqueRequests = <String, RequestModel>{};
      for (var request in allRequests) {
        uniqueRequests[request.id] = request;
      }
      
      return uniqueRequests.values.toList();
    } catch (e) {
      debugPrint('Error getting all assistance requests: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'icon': Icons.people_rounded,
        'label': 'Total Users',
        'value': _isLoading ? '...' : _totalUsers.toString(),
        'color': primary,
        'subtitle': '👥 - Registered Users',
      },
      {
        'icon': Icons.pending_actions_rounded,
        'label': 'Pending Verifications',
        'value': _isLoading ? '...' : _pendingVerifications.toString(),
        'color': Colors.orange,
        'subtitle': '⏱ - Awaiting approval',
      },
      {
        'icon': Icons.touch_app_rounded,
        'label': 'Active Requests',
        'value': _isLoading ? '...' : _activeRequests.toString(),
        'color': Colors.blue,
        'subtitle': '🔄 - In progress',
      },
      {
        'icon': Icons.warning_rounded,
        'label': 'Emergency Alerts',
        'value': _isLoading ? '...' : _emergencyAlerts.toString(),
        'color': error,
        'subtitle': '🚨- Urgent',
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
                  onTap: _fetchOverviewData,
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
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 21),
                  child: Text(
                    value,
                    style: h1.copyWith(
                      fontSize: 32,
                      color: widget.theme.textColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
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
}