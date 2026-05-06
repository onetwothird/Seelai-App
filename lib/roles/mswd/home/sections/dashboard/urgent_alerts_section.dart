// File: lib/roles/mswd/home/sections/dashboard/urgent_alerts_section.dart

import 'package:flutter/material.dart';
import 'dart:async'; // ADDED: For StreamSubscription
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/roles/mswd/home/sections/requests/requests_details.dart';

class UrgentAlertsSection extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Function(int) onNavigateToTab;

  const UrgentAlertsSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.onNavigateToTab,
  });

  @override
  State<UrgentAlertsSection> createState() => _UrgentAlertsSectionState();
}

class _UrgentAlertsSectionState extends State<UrgentAlertsSection> {
  StreamSubscription<List<RequestModel>>? _requestsSubscription;
  List<RequestModel> _topEmergencies = [];
  bool _isLoading = true;
  bool _hasError = false;
  
  // ADDED: Cache to store patient and caretaker data to pass to RequestDetailsScreen
  final Map<String, Map<String, dynamic>> _userDataCache = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  // ADDED: Replaced StreamBuilder approach with StreamSubscription to allow data preloading
  void _loadRequests() {
    _requestsSubscription = assistanceRequestService.streamAllRequests().listen(
      (requests) async {
        if (mounted) {
          final emergencies = requests.where((req) => 
            req.priority.toString().contains('emergency') && 
            req.status != RequestStatus.completed
          ).toList();

          emergencies.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          final topEmergencies = emergencies.take(3).toList();

          // Fetch caretaker/patient details before updating UI
          await _preloadUserData(topEmergencies);

          if (mounted) {
            setState(() {
              _topEmergencies = topEmergencies;
              _isLoading = false;
              _hasError = false;
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      },
    );
  }

  // ADDED: Preload function identical to the one in mswd_requests_content.dart
  Future<void> _preloadUserData(List<RequestModel> requests) async {
    for (var request in requests) {
      if (!_userDataCache.containsKey(request.patientId)) {
        try {
          final data = await databaseService.getUserData(request.patientId);
          if (data != null && mounted) {
            setState(() => _userDataCache[request.patientId] = data);
          }
        } catch (_) {}
      }
      if (request.caretakerId != null && !_userDataCache.containsKey(request.caretakerId!)) {
        try {
          final data = await databaseService.getUserData(request.caretakerId!);
          if (data != null && mounted) {
            setState(() => _userDataCache[request.caretakerId!] = data);
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }

  String _formatShortTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Urgent Alerts',
              style: h3.copyWith(
                fontSize: 20,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateToTab(2), 
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All',
                style: bodyBold.copyWith(
                  color: const Color(0xFF3B82F6),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16), 
        _buildContent(),
      ],
    );
  }

  // ADDED: Sub-builder method to handle the state manually
  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFEF4444))),
      );
    }

    if (_hasError) {
      return _buildEmptyState('Error loading alerts');
    }

    if (_topEmergencies.isEmpty) {
      return _buildEmptyState('No active emergencies right now.');
    }

    return Column(
      children: _topEmergencies.map((request) => _buildAlertCard(request)).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded, 
            size: 32, 
            color: const Color(0xFF10B981).withValues(alpha: 0.5), 
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: body.copyWith(
              color: widget.theme.subtextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(RequestModel request) {
    const color = Color(0xFFEF4444); 

    return Padding(
      padding: const EdgeInsets.only(bottom: 16), 
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestDetailsScreen(
                  request: request,
                  isDarkMode: widget.isDarkMode,
                  theme: widget.theme,
                  userDataCache: _userDataCache, // FIXED: Now passes the populated cache instead of const {}
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isDarkMode 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
              boxShadow: widget.isDarkMode ? [] : softShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              request.requestType,
                              style: bodyBold.copyWith(
                                fontSize: 15,
                                color: widget.theme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatShortTime(request.timestamp),
                            style: caption.copyWith(
                              fontSize: 11,
                              color: color, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient: ${request.patientName}',
                        style: caption.copyWith(
                          fontSize: 13,
                          color: widget.theme.subtextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: widget.theme.subtextColor.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}