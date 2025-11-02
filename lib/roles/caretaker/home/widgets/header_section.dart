// File: lib/roles/caretaker/home/widgets/header_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seelai_app/themes/constants.dart';

class HeaderSection extends StatelessWidget {
  final String userName;
  final bool isDarkMode;
  final String notificationMessage;
  final int pendingNotifications;
  final VoidCallback onToggleDarkMode;
  final VoidCallback onNotificationTap;
  final Color textColor;
  final Color subtextColor;

  const HeaderSection({
    super.key,
    required this.userName,
    required this.isDarkMode,
    required this.notificationMessage,
    required this.pendingNotifications,
    required this.onToggleDarkMode,
    required this.onNotificationTap,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
    
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
                      'Hello, $userName!',
                      style: h1.copyWith(
                        fontSize: width * 0.075,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: spacingXSmall),
                    Text(
                      formattedDate,
                      style: body.copyWith(
                        fontSize: width * 0.04,
                        color: subtextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              Row(
                children: [
                  // Notification Bell
                  _buildIconButton(
                    icon: Icons.notifications_rounded,
                    onPressed: onNotificationTap,
                    badge: pendingNotifications > 0 ? pendingNotifications : null,
                  ),
                  
                  SizedBox(width: spacingSmall),
                  
                  // Dark Mode Toggle
                  _buildIconButton(
                    icon: isDarkMode 
                      ? Icons.dark_mode_rounded 
                      : Icons.light_mode_rounded,
                    onPressed: onToggleDarkMode,
                    isSpecial: isDarkMode,
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

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    int? badge,
    bool isSpecial = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            boxShadow: isDarkMode 
              ? [
                  BoxShadow(
                    color: (isSpecial ? accent : primary).withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : softShadow,
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          child: Material(
            color: isDarkMode 
              ? (isSpecial ? accent.withOpacity(0.25) : primary.withOpacity(0.2))
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
                  color: isDarkMode 
                    ? (isSpecial ? accent : primaryLight)
                    : primary,
                ),
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode ? Color(0xFF1A1F3A) : white,
                  width: 2,
                ),
              ),
              constraints: BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                badge > 9 ? '9+' : badge.toString(),
                style: caption.copyWith(
                  color: white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
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
            Icons.info_rounded,
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