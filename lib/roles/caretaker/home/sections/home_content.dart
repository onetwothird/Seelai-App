// ignore_for_file: unnecessary_to_list_in_spreads, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/caretaker/request_service.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'dart:async';

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
  String? _caretakerId;
  
  // Stream subscriptions
  StreamSubscription? _patientsSubscription;
  StreamSubscription? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCaretakerId();
  }

  @override
  void dispose() {
    _statsController.dispose();
    _patientsSubscription?.cancel();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  /// Initialize caretaker ID - EXACT same as patients_content.dart
  Future<void> _initializeCaretakerId() async {
    String? caretakerId = widget.userData['uid'] as String?;
    
    if (caretakerId == null || caretakerId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      caretakerId = user?.uid;
    }
    
    if (caretakerId == null || caretakerId.isEmpty) {
      debugPrint('❌ HOME: Caretaker ID not found. Please log in again.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    debugPrint('✅ HOME: Caretaker ID initialized: $caretakerId');
    setState(() => _caretakerId = caretakerId);
    
    // Setup all listeners
    _setupPatientsStream();
    _setupRequestsStream();
    await _fetchAnnouncements();
  }

  /// Setup patients stream - EXACT same as patients_content.dart
  void _setupPatientsStream() {
    if (_caretakerId == null) {
      debugPrint('❌ HOME: Cannot setup patients stream - caretaker ID is null');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    debugPrint('🔄 HOME: Setting up patients stream for: $_caretakerId');
    
    _patientsSubscription = caretakerPatientService
        .streamCaretakerPatients(_caretakerId!)
        .listen(
      (patientsData) {
        debugPrint('📊 HOME: Received ${patientsData.length} patients');
        
        if (mounted) {
          setState(() {
            _totalPatients = patientsData.length;
          });
          
          if (patientsData.isNotEmpty) {
            debugPrint('✅ HOME: Patients list:');
            for (var patient in patientsData) {
              debugPrint('   - ${patient['name']} (ID: ${patient['userId']})');
            }
          } else {
            debugPrint('⚠️ HOME: No patients found in assignedPatients');
          }
        }
      },
      onError: (error) {
        debugPrint('❌ HOME: Error loading patients: $error');
        if (mounted) {
          setState(() {
            _totalPatients = 0;
            _isLoading = false;
          });
        }
      },
    );
  }

  /// Setup requests stream
  void _setupRequestsStream() {
    if (_caretakerId == null) {
      debugPrint('❌ HOME: Cannot setup requests stream - caretaker ID is null');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    debugPrint('🔄 HOME: Setting up requests stream');
    
    _requestsSubscription = assistanceRequestService
        .streamCaretakerRequests(_caretakerId!)
        .listen(
      (requests) {
        debugPrint('📊 HOME: Received ${requests.length} requests');
        
        if (mounted) {
          int pending = 0;
          int active = 0;
          int completed = 0;
          
          for (var request in requests) {
            final status = request.status.toString().split('.').last;
            
            if (status == 'pending') {
              pending++;
            } else if (status == 'accepted' || status == 'inProgress') {
              active++;
            } else if (status == 'completed') {
              completed++;
            }
          }
          
          setState(() {
            _pendingRequests = pending;
            _activeRequests = active;
            _completedRequests = completed;
            _isLoading = false;
          });
          
          debugPrint('✅ HOME: Requests - Pending: $pending, Active: $active, Completed: $completed');
        }
      },
      onError: (error) {
        debugPrint('❌ HOME: Error streaming requests: $error');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
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
        
        announcementsList.sort((a, b) => 
          (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0)
        );
        
        if (mounted) {
          setState(() => _announcements = announcementsList);
        }
      } else {
        if (mounted) {
          setState(() {
            _announcements = [
              {
                'title': 'Welcome to SeelAI',
                'message': 'Thank you for being part of our community.',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'targetAudience': 'Caretakers',
              },
            ];
          });
        }
      }
    } catch (e) {
      debugPrint('❌ HOME: Error fetching announcements: $e');
    }
  }

  /// Manual refresh
  Future<void> _refreshDashboardData() async {
    setState(() => _isLoading = true);
    await _fetchAnnouncements();
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
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
          _buildQuickStatsSection(),
          SizedBox(height: spacingXLarge),
          _buildAnnouncementsSection(),
          SizedBox(height: spacingXLarge),
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
        'subtitle': '✅ Total completed',
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
                  onTap: _refreshDashboardData,
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
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: spacingXLarge,
        horizontal: spacingLarge,
      ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
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
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacingSmall),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacingMedium),
            child: Text(
              'Check back later for updates from MSWD',
              style: caption.copyWith(
                fontSize: 13,
                color: widget.theme.subtextColor,
              ),
              textAlign: TextAlign.center,
            ),
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
            ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 16, offset: Offset(0, 6))]
            : softShadow,
        border: widget.isDarkMode ? Border.all(color: color.withOpacity(0.2), width: 1) : null,
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
                child: Icon(icon, color: color, size: 24),
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(radiusSmall),
                        border: Border.all(color: color.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        targetAudience,
                        style: caption.copyWith(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
    );
  }

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
    final totalRequests = _pendingRequests + _activeRequests + _completedRequests;
    
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
          percentage: totalRequests > 0 
              ? ((_pendingRequests / totalRequests) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
        SizedBox(height: spacingMedium),
        _buildBreakdownCard(
          icon: Icons.loop_rounded,
          label: 'Active Requests',
          value: _isLoading ? '...' : _activeRequests.toString(),
          color: Colors.blue,
          percentage: totalRequests > 0 
              ? ((_activeRequests / totalRequests) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
        SizedBox(height: spacingMedium),
        _buildBreakdownCard(
          icon: Icons.task_alt_rounded,
          label: 'Completed Requests',
          value: _isLoading ? '...' : _completedRequests.toString(),
          color: Colors.green,
          percentage: totalRequests > 0 
              ? ((_completedRequests / totalRequests) * 100).toStringAsFixed(1) 
              : '0.0',
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
            ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: Offset(0, 4))]
            : softShadow,
        border: widget.isDarkMode ? Border.all(color: color.withOpacity(0.2), width: 1) : null,
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
                  '$percentage% of total',
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
            ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 16, offset: Offset(0, 6))]
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
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            duration: Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: 4),
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