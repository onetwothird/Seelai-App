// File: lib/roles/caretaker/home/sections/home_screen/announcement.dart // (Assuming path based on imports)

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/mswd/announcement_service.dart';
import 'package:seelai_app/roles/mswd/home/model/announcement_model.dart';
import 'package:seelai_app/roles/caretaker/home/sections/home_screen/all_announcements_caretaker.dart';

class AnnouncementSection extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final String caretakerId; // Pass the caretaker's user ID

  const AnnouncementSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.caretakerId,
  });

  @override
  State<AnnouncementSection> createState() => _AnnouncementSectionState();
}

class _AnnouncementSectionState extends State<AnnouncementSection> {
  final AnnouncementService _announcementService = AnnouncementService();
  late Stream<List<AnnouncementModel>> _announcementStream;
  final int maxDisplayedAnnouncements = 5;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    _announcementStream = _announcementService.getAnnouncementsForUser(
      widget.caretakerId,
      'Caretakers',
    );
  }

  void _refreshStream() {
    setState(() {
      _initializeStream();
    });
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
                onTap: _refreshStream,
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
        StreamBuilder<List<AnnouncementModel>>(
          stream: _announcementStream,
          builder: (context, snapshot) {
            // Show loading only on initial load
            if (snapshot.connectionState == ConnectionState.waiting && 
                !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(spacingLarge),
                  child: CircularProgressIndicator(color: primary),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(spacingMedium),
                  child: Column(
                    children: [
                      Text(
                        'Error loading announcements',
                        style: body.copyWith(color: Colors.red),
                      ),
                      SizedBox(height: spacingSmall),
                      TextButton(
                        onPressed: _refreshStream,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final allAnnouncements = snapshot.data ?? [];

            if (allAnnouncements.isEmpty) {
              return _buildEmptyAnnouncementsCard();
            }

            final displayedAnnouncements = allAnnouncements.take(maxDisplayedAnnouncements).toList();
            final hasMoreAnnouncements = allAnnouncements.length > maxDisplayedAnnouncements;

            return Column(
              children: [
                ...displayedAnnouncements.map((announcement) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacingMedium),
                    child: _buildAnnouncementCard(announcement),
                  );
                }),

                // "View All Announcements" button if more than 5
                if (hasMoreAnnouncements)
                  Padding(
                    padding: EdgeInsets.only(top: spacingSmall),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _navigateToAllAnnouncements(context, allAnnouncements),
                        borderRadius: BorderRadius.circular(radiusMedium),
                        child: Container(
                          padding: EdgeInsets.all(spacingMedium),
                          decoration: BoxDecoration(
                            color: widget.theme.cardColor,
                            borderRadius: BorderRadius.circular(radiusMedium),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.view_list_rounded,
                                color: primary,
                                size: 20,
                              ),
                              SizedBox(width: spacingSmall),
                              Text(
                                'View All Announcements (${allAnnouncements.length})',
                                style: bodyBold.copyWith(
                                  fontSize: 14,
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: spacingSmall),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: primary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _navigateToAllAnnouncements(BuildContext context, List<AnnouncementModel> announcements) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllAnnouncementsCaretakerPage(
          isDarkMode: widget.isDarkMode,
          theme: widget.theme,
          announcements: announcements,
          caretakerId: widget.caretakerId,
        ),
      ),
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
        // Removed dark mode shadow
        boxShadow: widget.isDarkMode ? [] : softShadow,
        // Using neutral subtle border
        border: Border.all(
          color: widget.isDarkMode 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.05),
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

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    String timeAgo = _getTimeAgo(announcement.timestamp);
    IconData icon = IconData(
      int.parse(announcement.iconCodePoint.replaceAll('0x', ''), radix: 16),
      fontFamily: 'MaterialIcons',
    );
    Color color = Color(announcement.colorValue);

    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        // Removed colored glowy shadow
        boxShadow: widget.isDarkMode
            ? []
            : softShadow,
        // Replaced colored border with neutral subtle border
        border: Border.all(
          color: widget.isDarkMode 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
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
    if (announcement.targetAudience == 'Caretakers') {
      return 'For All Caretakers';
    } else if (announcement.targetAudience == 'Specific Users' &&
        announcement.specificUsers.contains(widget.caretakerId)) {
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