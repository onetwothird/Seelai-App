import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/caretaker/request_service.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final Function(String) onNotificationUpdate;
  final RequestService requestService;
  final LocationService locationService;

  const HomeContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.onNotificationUpdate,
    required this.requestService,
    required this.locationService,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  int _currentStatIndex = 0;
  final PageController _statsController = PageController();
  
  // Statistics
  int _totalPatients = 0;
  int _pendingRequests = 0;
  int _completedRequests = 0;
  int _activeRequests = 0;
  
  // Announcements
  List<Map<String, dynamic>> _announcements = [];
  
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

  /// Fetch all dashboard data
  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _fetchStatistics(),
        _fetchAnnouncements(),
      ]);
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Fetch statistics for the caretaker
  Future<void> _fetchStatistics() async {
    try {
      // TODO: Replace with actual data fetching logic
      // For now using placeholder values
      if (mounted) {
        setState(() {
          _totalPatients = 5;
          _pendingRequests = 3;
          _completedRequests = 12;
          _activeRequests = 2;
        });
      }
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
    }
  }

  /// Fetch announcements from MSWD
  Future<void> _fetchAnnouncements() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('announcements/mswd')
          .orderByChild('timestamp')
          .limitToLast(5)
          .once();
      
      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final announcementsList = <Map<String, dynamic>>[];
        
        data.forEach((key, value) {
          final announcement = Map<String, dynamic>.from(value as Map);
          announcement['id'] = key;
          announcementsList.add(announcement);
        });
        
        // Sort by timestamp (newest first)
        announcementsList.sort((a, b) => 
          (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0)
        );
        
        if (mounted) {
          setState(() {
            _announcements = announcementsList;
          });
        }
      } else {
        // Set default announcements if none exist
        if (mounted) {
          setState(() {
            _announcements = [
              {
                'title': 'Welcome to SeelAI',
                'message': 'Thank you for being part of our community. Your dedication to helping visually impaired individuals is greatly appreciated.',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'priority': 'normal',
              },
            ];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
      // Set fallback announcement
      if (mounted) {
        setState(() {
          _announcements = [
            {
              'title': 'Welcome',
              'message': 'Stay tuned for important updates and announcements.',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'priority': 'normal',
            },
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Section - Swipeable
          _buildQuickStatsSection(),
          
          SizedBox(height: spacingXLarge),
                   
          //  Announcements Section
          _buildAnnouncementsSection(),
          
          SizedBox(height: spacingXLarge),

            // Patient Breakdown Section
          _buildPatientBreakdownSection(),
          
          SizedBox(height: spacingXLarge),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    final stats = [
      {
        'icon': Icons.people_rounded,
        'label': 'Total Patients',
        'value': _isLoading ? '...' : _totalPatients.toString(),
        'color': primary,
        'subtitle': '👥 Under your care',
      },
      {
        'icon': Icons.pending_actions_rounded,
        'label': 'Pending Requests',
        'value': _isLoading ? '...' : _pendingRequests.toString(),
        'color': Colors.orange,
        'subtitle': '⏱ Awaiting response',
      },
      {
        'icon': Icons.touch_app_rounded,
        'label': 'Active Requests',
        'value': _isLoading ? '...' : _activeRequests.toString(),
        'color': Colors.blue,
        'subtitle': '🔄 In progress',
      },
      {
        'icon': Icons.check_circle_rounded,
        'label': 'Completed',
        'value': _isLoading ? '...' : _completedRequests.toString(),
        'color': Colors.green,
        'subtitle': '✅ This month',
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

Widget _buildAnnouncementsSection() {
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
          // Refresh button matching Overview style
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
                onTap: _fetchAnnouncements,
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
      
      // Display announcements
      if (_announcements.isEmpty)
        _buildEmptyAnnouncementsCard()
      else
        ..._announcements.map((announcement) => Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildAnnouncementCard(
            title: announcement['title'] ?? 'No Title',
            message: announcement['message'] ?? 'No message',
            targetAudience: announcement['targetAudience'] ?? 'All Users',
            timestamp: _formatTimestamp(announcement['timestamp'] ?? 0),
            icon: _getIconForAudience(announcement['targetAudience'] ?? 'All Users'),
            color: _getColorForAudience(announcement['targetAudience'] ?? 'All Users'),
          ),
        )).toList(),
    ],
  );
}

Widget _buildEmptyAnnouncementsCard() {
  return Container(
    padding: EdgeInsets.all(spacingLarge),
    decoration: BoxDecoration(
      color: widget.theme.cardColor,
      borderRadius: BorderRadius.circular(radiusLarge),
      boxShadow: widget.isDarkMode ? [] : softShadow,
      border: Border.all(
        color: widget.theme.subtextColor.withOpacity(0.2),
        width: 1,
      ),
    ),
    child: Column(
      children: [
        Icon(
          Icons.notifications_none_rounded,
          color: widget.theme.subtextColor.withOpacity(0.5),
          size: 48,
        ),
        SizedBox(height: spacingMedium),
        Text(
          'No announcements yet',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingSmall),
        Text(
          'Check back later for updates from MSWD',
          style: caption.copyWith(
            fontSize: 13,
            color: widget.theme.subtextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
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
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: widget.theme.subtextColor.withOpacity(0.7),
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  timestamp,
                  style: caption.copyWith(
                    fontSize: 11,
                    color: widget.theme.subtextColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

// Helper methods
IconData _getIconForAudience(String audience) {
  switch (audience) {
    case 'Caretakers':
      return Icons.volunteer_activism_rounded;
    case 'Visually Impaired':
      return Icons.visibility_off_rounded;
    case 'All Users':
      return Icons.campaign_rounded;
    default:
      return Icons.info_rounded;
  }
}

Color _getColorForAudience(String audience) {
  switch (audience) {
    case 'Caretakers':
      return Colors.green;
    case 'Visually Impaired':
      return Colors.purple;
    case 'All Users':
      return primary;
    default:
      return Colors.blue;
  }
}

String _formatTimestamp(int timestamp) {
  if (timestamp == 0) return 'Just now';
  
  final now = DateTime.now();
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final difference = now.difference(date);
  
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
  } else {
    final months = (difference.inDays / 30).floor();
    return '$months ${months == 1 ? 'month' : 'months'} ago';
  }
}

  Widget _buildPatientBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Breakdown',
          style: h3.copyWith(
            fontSize: 20,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildBreakdownCard(
          icon: Icons.hourglass_empty_rounded,
          label: 'Pending Requests',
          value: _isLoading ? '...' : _pendingRequests.toString(),
          color: Colors.orange,
          percentage: (_totalPatients + _pendingRequests + _activeRequests) > 0 
              ? ((_pendingRequests / (_totalPatients + _pendingRequests + _activeRequests)) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
        SizedBox(height: spacingMedium),
        _buildBreakdownCard(
          icon: Icons.loop_rounded,
          label: 'Active Requests',
          value: _isLoading ? '...' : _activeRequests.toString(),
          color: Colors.blue,
          percentage: (_totalPatients + _pendingRequests + _activeRequests) > 0 
              ? ((_activeRequests / (_totalPatients + _pendingRequests + _activeRequests)) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
        SizedBox(height: spacingMedium),
        _buildBreakdownCard(
          icon: Icons.task_alt_rounded,
          label: 'Completed Requests',
          value: _isLoading ? '...' : _completedRequests.toString(),
          color: Colors.green,
          percentage: '100',
        ),
      ],
    );
  }

  Widget _buildBreakdownCard({
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
                  'Status tracking',
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

}