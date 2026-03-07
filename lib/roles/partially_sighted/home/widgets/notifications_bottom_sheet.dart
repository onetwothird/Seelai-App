// File: lib/roles/visually_impaired/home/widgets/vi_notifications_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class ViNotificationsBottomSheet extends StatefulWidget {
  final String userId;
  final bool isDarkMode;
  final AssistanceRequestService requestService;

  const ViNotificationsBottomSheet({
    super.key,
    required this.userId,
    required this.isDarkMode,
    required this.requestService,
  });

  @override
  State<ViNotificationsBottomSheet> createState() => _ViNotificationsBottomSheetState();
}

class _ViNotificationsBottomSheetState extends State<ViNotificationsBottomSheet> {
  // Cache to hold Caretaker Name and Profile Image
  final Map<String, Map<String, dynamic>?> _caretakerCache = {};

  Future<void> _loadCaretakerData(String? caretakerId) async {
    if (caretakerId == null || _caretakerCache.containsKey(caretakerId)) return;
    try {
      final userData = await databaseService.getUserData(caretakerId);
      if (mounted) {
        setState(() {
          _caretakerCache[caretakerId] = userData;
        });
      }
    } catch (e) {
      debugPrint("Error loading caretaker: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = widget.isDarkMode ? Colors.white54 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle & Title
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Semantics(
                  label: 'Close notifications',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.done_all, color: primary),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Mark all as read',
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Notifications Stream
          Expanded(
            child: StreamBuilder<List<RequestModel>>(
              stream: widget.requestService.streamPatientRequests(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading notifications.', style: TextStyle(color: subTextColor)));
                }

                final requests = snapshot.data ?? [];
                
                // Filter out 'pending' requests (since those are sent BY the patient, not notifications TO them)
                final notifications = requests.where((r) => r.status != RequestStatus.pending).toList();

                if (notifications.isEmpty) {
                  return Center(
                    child: Semantics(
                      label: 'You have no notifications yet',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 60, color: subTextColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text("No notifications yet", style: TextStyle(color: subTextColor, fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }

                // Categorize into "New" (Active Responses) and "Earlier" (Finished Responses)
                final newNotifications = notifications.where((r) => r.status == RequestStatus.accepted || r.status == RequestStatus.inProgress).toList();
                final earlierNotifications = notifications.where((r) => r.status == RequestStatus.completed || r.status == RequestStatus.declined).toList();

                // Sort both by response timestamp (newest first)
                newNotifications.sort((a, b) => (b.responseTime ?? b.timestamp).compareTo(a.responseTime ?? a.timestamp));
                earlierNotifications.sort((a, b) => (b.responseTime ?? b.timestamp).compareTo(a.responseTime ?? a.timestamp));

                // Preload caretaker images and names
                for (var req in notifications) {
                  _loadCaretakerData(req.caretakerId);
                }

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (newNotifications.isNotEmpty) ...[
                      _buildSectionHeader('New', textColor),
                      ...newNotifications.map((req) => _buildNotificationTile(req, isNew: true, textColor: textColor, subTextColor: subTextColor)),
                    ],
                    if (earlierNotifications.isNotEmpty) ...[
                      if (newNotifications.isNotEmpty) const Divider(height: 1),
                      _buildSectionHeader('Earlier', textColor),
                      ...earlierNotifications.take(20).map((req) => _buildNotificationTile(req, isNew: false, textColor: textColor, subTextColor: subTextColor)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(RequestModel request, {required bool isNew, required Color textColor, required Color subTextColor}) {
    // 1. Extract Caretaker Data securely
    String caretakerName = 'A caretaker';
    String? profileUrl;
    
    if (request.caretakerId != null && _caretakerCache.containsKey(request.caretakerId)) {
      caretakerName = _caretakerCache[request.caretakerId]?['name'] ?? 'A caretaker';
      profileUrl = _caretakerCache[request.caretakerId]?['profileImageUrl'];
    }

    // 2. Format Action Text Based on Status
    String actionText = '';
    switch(request.status) {
      case RequestStatus.accepted:
        actionText = 'accepted your request for';
        break;
      case RequestStatus.inProgress:
        actionText = 'is on the way for your';
        break;
      case RequestStatus.completed:
        actionText = 'completed your request for';
        break;
      case RequestStatus.declined:
        actionText = 'declined your request for';
        break;
      default:
        actionText = 'updated your request for';
    }

    final timeAgo = _getTimeAgo(request.responseTime ?? request.timestamp);
    final unreadBgColor = widget.isDarkMode ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.05);

    return Semantics(
      label: 'Notification: $caretakerName $actionText ${request.requestType}. $timeAgo.',
      button: true,
      child: InkWell(
        onTap: () {
          // You can navigate to a request details page if you have one for the patient side
        },
        child: Container(
          color: isNew ? unreadBgColor : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Priority Status Overlay
              ExcludeSemantics(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profileUrl != null && profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                      child: (profileUrl == null || profileUrl.isEmpty) ? Icon(Icons.person, color: Colors.grey[600], size: 30) : null,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: request.getPriorityColor(),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isNew 
                              ? (widget.isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF0F8FF))
                              : (widget.isDarkMode ? const Color(0xFF121212) : Colors.white), 
                            width: 2
                          ),
                        ),
                        child: Icon(request.getIcon(), size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Notification Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
                          children: [
                            TextSpan(
                              text: '$caretakerName ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '$actionText '),
                            TextSpan(
                              text: '${request.requestType}.',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ExcludeSemantics(
                      child: Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 13,
                          color: isNew ? Colors.blue : subTextColor,
                          fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Unread Indicator Dot
              if (isNew)
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, left: 8),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 18),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${difference.inDays ~/ 7}w'; 
  }
}