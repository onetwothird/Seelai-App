// File: lib/roles/partially_sighted/home/sections/home_screen/all_announcements_vi.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // --- ADDED TTS ---
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
  // --- NEW TTS VARIABLES ---
  final FlutterTts _flutterTts = FlutterTts();
  String? _currentlySpeakingId;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  // --- NEW TTS SETUP ---
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _currentlySpeakingId = null);
    });
  }

  // --- NEW TTS PLAYBACK FUNCTION ---
  Future<void> _speakAnnouncement(String text, String id) async {
    if (_currentlySpeakingId == id) {
      await _flutterTts.stop();
      if (mounted) setState(() => _currentlySpeakingId = null);
    } else {
      await _flutterTts.stop();
      if (mounted) setState(() => _currentlySpeakingId = id);
      await _flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: widget.theme.textColor),
          onPressed: () {
            _flutterTts.stop(); // Stop speaking if they leave the page
            Navigator.of(context).pop();
          },
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
    IconData icon = _getSafeIcon(announcement.iconCodePoint);
    Color color = Color(announcement.colorValue);
    bool isSpeaking =
        _currentlySpeakingId == announcement.id; // Check TTS state

    return Semantics(
      label:
          'Announcement: ${announcement.title}. ${announcement.message}. Posted $timeAgo',
      readOnly: true,
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(spacingSmall),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  child: Icon(icon, color: color, size: 24),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                // --- NEW TTS BUTTON ---
                IconButton(
                  icon: Icon(
                    isSpeaking
                        ? Icons.stop_circle_rounded
                        : Icons.volume_up_rounded,
                    color: isSpeaking ? Colors.red : primary,
                    size: 28,
                  ),
                  onPressed: () => _speakAnnouncement(
                    "${announcement.title}. ${announcement.message}",
                    announcement.id,
                  ),
                  tooltip: isSpeaking
                      ? 'Stop playback'
                      : 'Listen to announcement',
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
      case 'Partially Sighted':
        return Icons.visibility_off_rounded;
      case 'Specific Users':
        return Icons.person_rounded;
      default:
        return Icons.people_rounded;
    }
  }

  String _getAudienceLabel(AnnouncementModel announcement) {
    if (announcement.targetAudience == 'Partially Sighted') {
      return 'For All Partially Sighted';
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
