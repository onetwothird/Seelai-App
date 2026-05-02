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
  
  Offset _position = const Offset(300, 100);
  bool _isPositionInitialized = false;

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

  // Opens a Bottom Sheet to display the missed calls list
  void _openMissedCallsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Missed Calls',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              StreamBuilder<List<Map<String, dynamic>>>(
                // Listens to calls from the Patient path!
                stream: callTrackingService.streamMissedCalls(
                  path: 'partially_sighted_communication', 
                  userId: widget.caretakerId,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 48,
                            color: widget.isDarkMode ? Colors.white38 : Colors.black26,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "You're all caught up!",
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
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
                      final callIdsToDismiss = callsList.map((c) => c['callId'] as String).toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.isDarkMode 
                                ? const Color(0xFFEF4444).withValues(alpha: 0.3) 
                                : const Color(0xFFFEE2E2), 
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
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
                                        color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'From $callerName • $timeString',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: widget.isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: widget.isDarkMode ? Colors.white10 : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: widget.isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                  onPressed: () {
                                    callTrackingService.clearMissedCalls(
                                      path: 'partially_sighted_communication', 
                                      callIds: callIdsToDismiss,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.caretakerId.isEmpty) return const SizedBox.shrink();

    // Safely initialize the widget position to the right edge of the screen
    if (!_isPositionInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _position = Offset(MediaQuery.of(context).size.width - 80, 150);
          _isPositionInitialized = true;
        });
      });
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: callTrackingService.streamMissedCalls(
        path: 'partially_sighted_communication', 
        userId: widget.caretakerId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); 
        }

        final missedCalls = snapshot.data!;
        final callCount = missedCalls.length;

        return Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                
                double newX = _position.dx + details.delta.dx;
                double newY = _position.dy + details.delta.dy;

                _position = Offset(
                  newX.clamp(0.0, screenWidth - 70.0), 
                  newY.clamp(0.0, screenHeight - 200.0), 
                );
              });
            },
            onTap: () => _openMissedCallsSheet(),
            child: SizedBox(
              width: 70, 
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // MAIN WHITE BUBBLE
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isDarkMode ? Colors.white12 : const Color(0xFFFEE2E2),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.phone_missed_rounded,
                      color: Color(0xFFEF4444), 
                      size: 28,
                    ),
                  ),
                  
                  // NOTIFICATION BADGE
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444), 
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                          width: 2.5, 
                        ),
                      ),
                      child: Text(
                        '$callCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}