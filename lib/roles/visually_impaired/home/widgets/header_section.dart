// File: lib/roles/visually_impaired/home/widgets/header_section.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/home/widgets/icon_button.dart';

class HeaderSection extends StatelessWidget {
  final String userName;
  final bool isDarkMode;
  final VoidCallback onVoiceAssistant;
  final VoidCallback onToggleDarkMode;
  final VoidCallback onNotificationTap;
  final Color textColor;
  final Color subtextColor;
  final int unreadNotificationCount;

  const HeaderSection({
    super.key,
    required this.userName,
    required this.isDarkMode,
    required this.onVoiceAssistant,
    required this.onToggleDarkMode,
    required this.onNotificationTap,
    required this.textColor,
    required this.subtextColor,
    this.unreadNotificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
    
    return Semantics(
      label: 'Header section. Hi $userName. Today is $formattedDate',
      child: Container(
        padding: EdgeInsets.all(width * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting and controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: 'Greeting',
                        child: Text(
                          'Hi, $userName!',
                          style: h1.copyWith(
                            fontSize: width * 0.075,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      SizedBox(height: spacingXSmall),
                      Semantics(
                        label: 'Today\'s date',
                        child: Text(
                          formattedDate,
                          style: body.copyWith(
                            fontSize: width * 0.04,
                            color: subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Dark Mode Toggle
                Semantics(
                  label: isDarkMode ? 'Dark mode is on' : 'Light mode is on',
                  hint: 'Double tap to toggle theme mode',
                  button: true,
                  child: CustomIconButton(
                    icon: isDarkMode 
                      ? Icons.dark_mode_rounded 
                      : Icons.light_mode_rounded,
                    onPressed: onToggleDarkMode,
                    size: 28,
                    isDarkMode: isDarkMode,
                    isSpecial: isDarkMode,
                  ),
                ),
                
                SizedBox(width: spacingSmall),
                
                // Notification Bell with Badge
                Semantics(
                  label: unreadNotificationCount > 0 
                    ? 'Notifications. You have $unreadNotificationCount unread notification${unreadNotificationCount > 1 ? 's' : ''}' 
                    : 'Notifications',
                  hint: 'Double tap to view notifications',
                  button: true,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomIconButton(
                        icon: Icons.notifications_rounded,
                        onPressed: onNotificationTap,
                        size: 28,
                        isDarkMode: isDarkMode,
                        isSpecial: false,
                      ),
                      if (unreadNotificationCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDarkMode ? Color(0xFF0A0E27) : backgroundPrimary,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: error.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                unreadNotificationCount > 9 ? '9+' : unreadNotificationCount.toString(),
                                style: TextStyle(
                                  color: white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: spacingMedium),
            
            // Notification Area
          ],
        ),
      ),
    );
  }
}