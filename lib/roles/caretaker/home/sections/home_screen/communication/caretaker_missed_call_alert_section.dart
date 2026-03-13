// File: lib/roles/caretaker/home/sections/home_screen/communication/caretaker_missed_call_alert_section.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class CaretakerMissedCallAlertSection extends StatefulWidget {
  final String caretakerId; 
  final bool isDarkMode;
  final dynamic theme;

  const CaretakerMissedCallAlertSection({
    super.key,
    required this.caretakerId,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<CaretakerMissedCallAlertSection> createState() => _CaretakerMissedCallAlertSectionState();
}

class _CaretakerMissedCallAlertSectionState extends State<CaretakerMissedCallAlertSection> {
  final Map<String, String> _callerNamesCache = {};

  Future<void> _fetchCallerName(String callerId) async {
    if (_callerNamesCache.containsKey(callerId)) return;

    final userData = await databaseService.getUserData(callerId);
    if (mounted && userData != null) {
      setState(() {
        _callerNamesCache[callerId] = userData['name'] ?? 'Patient';
      });
    }
  }

  String _formatTimestamp(int timestamp) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final Duration diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // FIX: Now displays your beautiful empty state instead of being invisible!
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: widget.isDarkMode ? Colors.white54 : const Color(0xFF64748B),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Missed Calls',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You\'re all caught up!',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.caretakerId.isEmpty) return _buildEmptyState();

    return StreamBuilder<List<Map<String, dynamic>>>(
      // Listens to calls from the Patient path!
      stream: callTrackingService.streamMissedCalls(
        path: 'visually_impaired_communication', 
        userId: widget.caretakerId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(); 
        }

        final missedCalls = snapshot.data!;
        Map<String, List<Map<String, dynamic>>> groupedMissedCalls = {};

        for (var callData in missedCalls) {
          String callerId = callData['callerId'] ?? 'Unknown';
          if (!groupedMissedCalls.containsKey(callerId)) {
            groupedMissedCalls[callerId] = [];
          }
          groupedMissedCalls[callerId]!.add(callData);
        }

        return Column(
          children: groupedMissedCalls.entries.map((entry) {
            final callerId = entry.key;
            final callsList = entry.value;
            
            if (!_callerNamesCache.containsKey(callerId)) {
              _fetchCallerName(callerId);
            }
            
            final latestCall = callsList.first;
            final count = callsList.length;
            final timeString = _formatTimestamp(latestCall['timestamp'] as int);
            final callerName = _callerNamesCache[callerId] ?? 'Loading...';
            final isVideo = latestCall['type'] == 'video';

            final List<String> callIdsToDismiss = callsList.map((c) => c['callId'] as String).toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF3F1616) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: widget.isDarkMode ? 0.3 : 0.2),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isVideo ? Icons.missed_video_call_rounded : Icons.phone_missed_rounded,
                          color: const Color(0xFFEF4444),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              count > 1 
                                  ? '$count Missed Calls' 
                                  : 'Missed ${isVideo ? 'Video' : 'Voice'} Call',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.isDarkMode ? Colors.white : const Color(0xFF7F1D1D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'From $callerName • $timeString',
                              style: TextStyle(
                                fontSize: 13,
                                color: widget.isDarkMode ? Colors.white70 : const Color(0xFF991B1B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: widget.isDarkMode ? Colors.white70 : const Color(0xFF991B1B),
                        ),
                        onPressed: () => callTrackingService.clearMissedCalls(
                          path: 'visually_impaired_communication', 
                          callIds: callIdsToDismiss,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}