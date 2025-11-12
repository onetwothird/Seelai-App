// File: lib/roles/mswd/home/widgets/mswd_header_section.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seelai_app/themes/constants.dart';

class MSWDHeaderSection extends StatelessWidget {
  final String userName;
  final bool isDarkMode;
  final String notificationMessage;
  final VoidCallback onToggleDarkMode;
  final VoidCallback onNotificationTap;
  final Color textColor;
  final Color subtextColor;
  final int unreadNotificationCount;

  const MSWDHeaderSection({
    super.key,
    required this.userName,
    required this.isDarkMode,
    required this.notificationMessage,
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
    final greeting = _getGreeting();
    
    return Container(
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
                    Text(
                      '$greeting, $userName!',
                      style: h1.copyWith(
                        fontSize: width * 0.07,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: spacingXSmall),
                    Text(
                      formattedDate,
                      style: body.copyWith(
                        fontSize: width * 0.038,
                        color: subtextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Dark Mode Toggle
              _buildIconButton(
                icon: isDarkMode 
                  ? Icons.dark_mode_rounded 
                  : Icons.light_mode_rounded,
                onPressed: onToggleDarkMode,
              ),
              
              SizedBox(width: spacingSmall),
              
              // Notification Bell with Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildIconButton(
                    icon: Icons.notifications_rounded,
                    onPressed: onNotificationTap,
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
                            color: isDarkMode ? Color(0xFF0A0E27) : Color(0xFFFAF5FF),
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
            ],
          ),
          
          SizedBox(height: spacingMedium),
          
          // Notification Area
          _buildNotificationArea(),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ]
          : softShadow,
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      child: Material(
        color: isDarkMode 
          ? primary.withOpacity(0.2)
          : primaryLight.withOpacity(0.12),
        borderRadius: BorderRadius.circular(radiusMedium),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radiusMedium),
          splashColor: primary.withOpacity(0.3),
          child: Container(
            padding: EdgeInsets.all(spacingMedium),
            child: Icon(
              icon,
              size: 28,
              color: isDarkMode ? primaryLight : primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationArea() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: isDarkMode 
          ? LinearGradient(
              colors: [
                primary.withOpacity(0.25), 
                accent.withOpacity(0.2)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : LinearGradient(
              colors: [
                primaryLight.withOpacity(0.15), 
                accent.withOpacity(0.1)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: isDarkMode 
            ? primary.withOpacity(0.4) 
            : primary.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.2),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ]
          : softShadow,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: isDarkMode ? primaryLight : primary,
            size: 22,
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: Text(
              notificationMessage,
              style: bodyBold.copyWith(
                fontSize: 15,
                color: isDarkMode ? white : primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}