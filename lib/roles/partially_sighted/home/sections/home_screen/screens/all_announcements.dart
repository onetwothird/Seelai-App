// File: lib/roles/visually_impaired/home/sections/home_screen/all_announcements_vi.dart


import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/mswd/home/model/announcement_model.dart';

class AllAnnouncementsVIPage extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final List<AnnouncementModel> announcements;
  final String userId;

  const AllAnnouncementsVIPage({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.announcements,
    required this.userId,
  });

  @override
  State<AllAnnouncementsVIPage> createState() => _AllAnnouncementsVIPageState();
}

class _AllAnnouncementsVIPageState extends State<AllAnnouncementsVIPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: widget.theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: widget.theme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'All Announcements',
          style: h3.copyWith(
            fontSize: 18,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: widget.announcements.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(spacingLarge),
              itemCount: widget.announcements.length,
              itemBuilder: (context, index) {
                final announcement = widget.announcements[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: spacingMedium),
                  child: _buildAnnouncementCard(announcement),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: widget.theme.subtextColor.withOpacity(0.5),
              size: 64,
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
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    String timeAgo = _getTimeAgo(announcement.timestamp);
    IconData icon = IconData(
      int.parse(announcement.iconCodePoint.replaceAll('0x', ''), radix: 16),
      fontFamily: 'MaterialIcons',
    );
    Color color = Color(announcement.colorValue);

    return Semantics(
      label: 'Announcement: ${announcement.title}. ${announcement.message}. Posted $timeAgo',
      readOnly: true,
      child: Container(
        padding: EdgeInsets.all(spacingMedium),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: widget.isDarkMode
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : softShadow,
          border: widget.isDarkMode
              ? Border.all(
                  color: color.withValues(alpha: 0.2),
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
                    color: color.withValues(alpha: 0.15),
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
                        announcement.title,
                        style: bodyBold.copyWith(
                          fontSize: 15,
                          color: widget.theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(radiusSmall),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getAudienceIcon(announcement.targetAudience),
                              color: color,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _getAudienceLabel(announcement),
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
                ),
              ],
            ),
            SizedBox(height: spacingMedium),
            Text(
              announcement.message,
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
                  timeAgo,
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
      ),
    );
  }

  IconData _getAudienceIcon(String audience) {
    switch (audience) {
      case 'Caretakers':
        return Icons.volunteer_activism_rounded;
      case 'Visually Impaired':
        return Icons.visibility_off_rounded;
      case 'Specific Users':
        return Icons.person_rounded;
      default:
        return Icons.people_rounded;
    }
  }

  String _getAudienceLabel(AnnouncementModel announcement) {
    if (announcement.targetAudience == 'Visually Impaired') {
      return 'For All Visually Impaired';
    } else if (announcement.targetAudience == 'Specific Users' &&
        announcement.specificUsers.contains(widget.userId)) {
      return 'For You';
    }
    return announcement.targetAudience;
  }

  String _getTimeAgo(DateTime timestamp) {
    Duration difference = DateTime.now().difference(timestamp);

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
}