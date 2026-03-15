// File: lib/roles/mswd/home/sections/dashboard/all_announcements.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/mswd/home/model/announcement_model.dart';

class AllAnnouncementsPage extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final List<AnnouncementModel> announcements;
  final Function(String) onDelete;

  const AllAnnouncementsPage({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.announcements,
    required this.onDelete,
  });

  @override
  State<AllAnnouncementsPage> createState() => _AllAnnouncementsPageState();
}

class _AllAnnouncementsPageState extends State<AllAnnouncementsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.backgroundColor,
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
      body: ListView.builder(
        padding: EdgeInsets.all(spacingLarge),
        itemCount: widget.announcements.length,
        itemBuilder: (context, index) {
          final announcement = widget.announcements[index];
          return Padding(
            padding: EdgeInsets.only(bottom: spacingMedium),
            child: _buildAnnouncementCard(
              context: context,
              announcement: announcement,
            ),
          );
        },
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
        // Removed glowy colored shadow
        boxShadow: widget.isDarkMode
            ? []
            : softShadow,
        // Using the same clean, neutral border as the main dashboard
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
                  onTap: () => _showDeleteDialog(announcement.id),
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

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: bodyBold.copyWith(color: widget.theme.subtextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                widget.onDelete(id);
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to main page
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Announcement deleted'),
                    backgroundColor: Colors.green,
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
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}