// File: lib/roles/caretaker/home/sections/home_screen/all_announcements_caretaker.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/mswd/home/model/announcement_model.dart';
import 'package:intl/intl.dart'; // Ensure you have intl package or use basic formatting

class AllAnnouncementsCaretakerPage extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final List<AnnouncementModel> announcements;
  final String caretakerId;

  const AllAnnouncementsCaretakerPage({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.announcements,
    required this.caretakerId,
  });

  @override
  Widget build(BuildContext context) {
    // Background color: slightly off-white for light mode to let cards pop
    final backgroundColor = isDarkMode ? const Color(0xFF0A0E27) : const Color(0xFFF8F9FE);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent, // Prevents color shift on scroll
        scrolledUnderElevation: 0,            // Prevents shadow/elevation on scroll
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.subtextColor.withOpacity(0.1)),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: theme.textColor),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifications',
          style: h3.copyWith(
            fontSize: 16,
            color: theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: announcements.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _buildModernCard(announcement),
                );
              },
            ),
    );
  }

  Widget _buildModernCard(AnnouncementModel announcement) {
    IconData icon;
    try {
      icon = IconData(
        int.parse(announcement.iconCodePoint.replaceAll('0x', ''), radix: 16),
        fontFamily: 'MaterialIcons',
      );
    } catch (e) {
      icon = Icons.notifications;
    }
    Color color = Color(announcement.colorValue);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF909090).withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: theme.subtextColor.withOpacity(isDarkMode ? 0.1 : 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 16),
              // Title and Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: bodyBold.copyWith(
                        fontSize: 16,
                        color: theme.textColor,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: theme.subtextColor),
                        SizedBox(width: 4),
                        Text(
                          _getTimeAgo(announcement.timestamp),
                          style: caption.copyWith(
                            fontSize: 12,
                            color: theme.subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Divider for separation
          Divider(color: theme.subtextColor.withOpacity(0.1), height: 1),
          SizedBox(height: 16),
          // Message Body
          Text(
            announcement.message,
            style: body.copyWith(
              fontSize: 14,
              color: theme.textColor.withOpacity(0.8),
              height: 1.6,
            ),
          ),
          SizedBox(height: 12),
          // Audience Tag (Minimalist pill)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.subtextColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getAudienceLabel(announcement),
                style: caption.copyWith(
                  fontSize: 11,
                  color: theme.subtextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: Offset(0,10)
                 )
              ]
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: theme.subtextColor.withOpacity(0.5),
              size: 48,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'All caught up!',
            style: h3.copyWith(
              fontSize: 20,
              color: theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No new announcements at the moment.',
            style: body.copyWith(
              color: theme.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getAudienceLabel(AnnouncementModel announcement) {
    if (announcement.targetAudience == 'Caretakers') {
      return 'Public Announcement';
    } else if (announcement.targetAudience == 'Specific Users' &&
        announcement.specificUsers.contains(caretakerId)) {
      return 'For You';
    }
    return announcement.targetAudience;
  }

  String _getTimeAgo(DateTime timestamp) {
    Duration difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}