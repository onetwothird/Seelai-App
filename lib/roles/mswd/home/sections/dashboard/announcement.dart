// File: lib/roles/mswd/home/sections/dashboard/announcement.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/mswd/announcement_service.dart';
import 'package:seelai_app/roles/mswd/home/model/announcement_model.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/add_announcement.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/all_announcements.dart';

class AnnouncementSection extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;

  const AnnouncementSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
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
    _announcementStream = _announcementService.getAnnouncementsStream();
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
                onTap: () => _navigateToCreateAnnouncement(context),
                borderRadius: BorderRadius.circular(radiusMedium),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(radiusMedium),
                    border: Border.all(color: primary.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, color: primary, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Create',
                        style: bodyBold.copyWith(
                          fontSize: 14,
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacingMedium),
      
        // Display announcements from Firebase
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
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(spacingLarge),
                  child: Column(
                    children: [
                      Icon(
                        Icons.campaign_rounded,
                        size: 48,
                        color: widget.theme.subtextColor.withOpacity(0.3),
                      ),
                      SizedBox(height: spacingSmall),
                      Text(
                        'No announcements yet',
                        style: body.copyWith(
                          color: widget.theme.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Show only first 5 announcements
            final displayedAnnouncements = allAnnouncements.take(maxDisplayedAnnouncements).toList();
            final hasMoreAnnouncements = allAnnouncements.length > maxDisplayedAnnouncements;
            
            return Column(
              children: [
                // Display announcement cards
                ...displayedAnnouncements.map((announcement) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacingMedium),
                    child: _buildAnnouncementCard(
                      context: context,
                      announcement: announcement,
                    ),
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

  void _navigateToCreateAnnouncement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAnnouncementPage(
          isDarkMode: widget.isDarkMode,
          theme: widget.theme,
        ),
      ),
    );
  }

  void _navigateToAllAnnouncements(BuildContext context, List<AnnouncementModel> announcements) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllAnnouncementsPage(
          isDarkMode: widget.isDarkMode,
          theme: widget.theme,
          announcements: announcements,
          onDelete: (id) => _deleteAnnouncement(id),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard({
    required BuildContext context,
    required AnnouncementModel announcement,
  }) {
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
        // Removed glowy colored shadow, using a neutral soft shadow
        boxShadow: widget.isDarkMode
            ? []
            : softShadow,
        // Replaced colored border with a neutral border to match the requested design
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
                    Row(
                      children: [
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
                            children: [
                              Icon(
                                _getAudienceIcon(announcement.targetAudience),
                                color: color,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                announcement.targetAudience == 'Specific Users'
                                    ? '${announcement.specificUsers.length} users'
                                    : announcement.targetAudience,
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
            announcement.message,
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
              Text(
                timeAgo,
                style: caption.copyWith(
                  fontSize: 11,
                  color: widget.theme.subtextColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _deleteAnnouncement(announcement.id),
                  borderRadius: BorderRadius.circular(radiusSmall),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: widget.theme.subtextColor.withOpacity(0.5),
                      size: 18,
                    ),
                  ),
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

  String _getTimeAgo(DateTime timestamp) {
    Duration difference = DateTime.now().difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  void _deleteAnnouncement(String id) {
    // 1. Capture the parent context for the SnackBar
    final parentContext = context;

    showDialog(
      context: parentContext,
      // 2. Rename to dialogContext to avoid shadowing
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: widget.theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          title: Text(
            'Delete Announcement',
            style: h3.copyWith(
              fontSize: 18,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this announcement?',
            style: body.copyWith(color: widget.theme.subtextColor),
          ),
          actions: [
            TextButton(
              // Use dialogContext to close the popup
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: bodyBold.copyWith(color: widget.theme.subtextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Execute the async operation
                final success = await _announcementService.deleteAnnouncement(id);
                
                // 3. GUARD: Check if the dialog is still open before popping
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                
                // 4. GUARD: Check if the main screen is still active before showing the SnackBar
                if (!parentContext.mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? 'Announcement deleted' 
                          : 'Failed to delete announcement'
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}