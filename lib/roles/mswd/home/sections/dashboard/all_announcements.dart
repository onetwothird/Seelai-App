// File: lib/roles/mswd/home/sections/dashboard/all_announcements.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Added TTS import
import 'package:shimmer/shimmer.dart';
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
  bool _isSimulatingLoad = true;
  final FlutterTts _flutterTts = FlutterTts(); // Added TTS instance

  @override
  void initState() {
    super.initState();
    _initTts(); // Initialize TTS
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _isSimulatingLoad = false);
      }
    });
  }

  // Added TTS initialization method
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US"); 
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Stop TTS on dispose
    super.dispose();
  }

  // Added TTS helper method
  void _speakMessage(String message) {
    _flutterTts.speak(message);
  }
  
  IconData _getSafeIcon(String hexCode) {
    final Map<String, IconData> safeIcons = {
      '0xef4c': Icons.notifications,
      '0xe000': Icons.warning,
      '0xe3fc': Icons.event,
      '0xe88a': Icons.home,
      '0xe3e3': Icons.info,
      '0xe047': Icons.campaign,
    };
    
    String formattedCode = hexCode.toLowerCase().trim();
    return safeIcons[formattedCode] ?? Icons.notifications; 
  }

  Widget _buildSkeletonList() {
    final baseColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: EdgeInsets.all(spacingLarge),
        itemCount: widget.announcements.isEmpty ? 5 : widget.announcements.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: spacingMedium),
            child: Container(
              padding: EdgeInsets.all(spacingMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radiusMedium))),
                      SizedBox(width: spacingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 150, height: 16, color: Colors.white),
                            SizedBox(height: 8),
                            Container(width: 80, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radiusSmall))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacingMedium),
                  Container(width: double.infinity, height: 14, color: Colors.white),
                  SizedBox(height: 4),
                  Container(width: double.infinity, height: 14, color: Colors.white),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 60, height: 12, color: Colors.white),
                      Container(width: 20, height: 20, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

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
      body: _isSimulatingLoad 
        ? _buildSkeletonList() 
        : ListView.builder(
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
    IconData icon = _getSafeIcon(announcement.iconCodePoint);
    Color color = Color(announcement.colorValue);
    
    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
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
      case 'Caretakers': return Icons.volunteer_activism_rounded;
      case 'Partially Sighted': return Icons.visibility_off_rounded;
      case 'Specific Users': return Icons.person_rounded;
      default: return Icons.people_rounded;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    Duration difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 30) return '${difference.inDays} days ago';
    return '${(difference.inDays / 30).floor()} months ago';
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
              child: Text('Cancel', style: bodyBold.copyWith(color: widget.theme.subtextColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                widget.onDelete(id);
                Navigator.of(context).pop(); 
                Navigator.of(context).pop(); 
                
                _speakMessage('Announcement deleted');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}