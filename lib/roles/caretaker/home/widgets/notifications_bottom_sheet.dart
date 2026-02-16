// File: lib/roles/caretaker/home/widgets/notifications_bottom_sheet.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/firebase/caretaker/request_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_details_screen.dart';

class NotificationsBottomSheet extends StatefulWidget {
  final String caretakerId;
  final bool isDarkMode;
  final RequestService requestService;

  const NotificationsBottomSheet({
    super.key,
    required this.caretakerId,
    required this.isDarkMode,
    required this.requestService,
  });

  @override
  State<NotificationsBottomSheet> createState() => _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<NotificationsBottomSheet> {
  final Map<String, String?> _profileImageCache = {};

  Future<void> _loadProfileImage(String patientId) async {
    if (_profileImageCache.containsKey(patientId)) return;
    try {
      final userData = await databaseService.getUserData(patientId);
      if (mounted) {
        setState(() {
          _profileImageCache[patientId] = userData?['profileImageUrl'] as String?;
        });
      }
    } catch (e) {
      debugPrint("Error loading image: $e");
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
                color: Colors.grey.withOpacity(0.3),
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
                IconButton(
                  icon: const Icon(Icons.done_all, color: primary),
                  onPressed: () {
                    // Placeholder for Mark All as Read
                  },
                  tooltip: 'Mark all as read',
                )
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Notifications Stream
          Expanded(
            child: StreamBuilder<List<RequestModel>>(
              // FIX: Now correctly using streamRequests
              stream: widget.requestService.streamRequests(widget.caretakerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading notifications.', style: TextStyle(color: subTextColor)));
                }

                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 60, color: subTextColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text("No notifications yet", style: TextStyle(color: subTextColor, fontSize: 16)),
                      ],
                    ),
                  );
                }

                // Categorize into "New" (Pending) and "Earlier" (Handled)
                final newRequests = requests.where((r) => r.status == RequestStatus.pending).toList();
                final earlierRequests = requests.where((r) => r.status != RequestStatus.pending).toList();

                // Sort both by timestamp (newest first)
                newRequests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                earlierRequests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                // Preload images
                for (var req in requests) {
                  _loadProfileImage(req.patientId);
                }

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (newRequests.isNotEmpty) ...[
                      _buildSectionHeader('New', textColor),
                      ...newRequests.map((req) => _buildNotificationTile(req, isNew: true, textColor: textColor, subTextColor: subTextColor)),
                    ],
                    if (earlierRequests.isNotEmpty) ...[
                      if (newRequests.isNotEmpty) const Divider(height: 1),
                      _buildSectionHeader('Earlier', textColor),
                      ...earlierRequests.take(20).map((req) => _buildNotificationTile(req, isNew: false, textColor: textColor, subTextColor: subTextColor)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(RequestModel request, {required bool isNew, required Color textColor, required Color subTextColor}) {
    final profileUrl = _profileImageCache[request.patientId];
    final timeAgo = _getTimeAgo(request.timestamp);
    
    // Facebook uses a subtle blue background for unread notifications
    final unreadBgColor = widget.isDarkMode ? Colors.blueAccent.withOpacity(0.1) : Colors.blue.withOpacity(0.05);

    return InkWell(
      onTap: () {
        // Navigate to details and pass the cached image
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailsScreen(
              request: request,
              isDarkMode: widget.isDarkMode,
              requestService: widget.requestService,
              preloadedProfileImage: profileUrl,
            ),
          ),
        );
      },
      child: Container(
        color: isNew ? unreadBgColor : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Facebook-style Avatar with status icon overlay
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
                  child: profileUrl == null ? Icon(Icons.person, color: Colors.grey[600], size: 30) : null,
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
                          ? (widget.isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF0F8FF)) // match background
                          : (widget.isDarkMode ? const Color(0xFF121212) : Colors.white), 
                        width: 2
                      ),
                    ),
                    child: Icon(request.getIcon(), size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            
            // 2. Notification Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
                      children: [
                        TextSpan(
                          text: '${request.patientName} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: isNew ? 'needs your assistance for a ' : 'sent a request for ',
                        ),
                        TextSpan(
                          text: '${request.requestType} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: request.status == RequestStatus.pending 
                              ? 'request.' 
                              : '(Status: ${request.status.name}).',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 13,
                      color: isNew ? Colors.blue : subTextColor,
                      fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            
            // 3. Unread Indicator Dot
            if (isNew)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 8),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            else
              const SizedBox(width: 18), // Spacer to maintain alignment
          ],
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
    return '${difference.inDays ~/ 7}w'; // e.g., 2w for 2 weeks
  }
}