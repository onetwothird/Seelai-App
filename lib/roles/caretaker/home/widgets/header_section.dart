// File: lib/roles/caretaker/home/widgets/header_section.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seelai_app/themes/constants.dart';

class HeaderSection extends StatelessWidget {
  final String caretakerName;
  final String? profileImageUrl;
  final bool isDarkMode;
  final int pendingRequestsCount;
  final VoidCallback onToggleDarkMode;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final Color textColor;
  final Color subtextColor;

  const HeaderSection({
    super.key,
    required this.caretakerName,
    this.profileImageUrl,
    required this.isDarkMode,
    required this.pendingRequestsCount,
    required this.onToggleDarkMode,
    this.onProfileTap,
    this.onNotificationTap,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(now);
    
    // Better responsive sizing
    final profileSize = 56.0;
    final iconSize = 24.0;
    
    return Semantics(
      label: 'Header section. Hi $caretakerName. Today is $formattedDate',
      child: Container(
        padding: EdgeInsets.fromLTRB(
          width * 0.05,
          height * 0.015,
          width * 0.05,
          height * 0.015,
        ),
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0E27).withOpacity(0.5),
                    Color(0xFF0A0E27).withOpacity(0.3),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundPrimary,
                    backgroundPrimary.withOpacity(0.9),
                  ],
                ),
        ),
        child: Row(
          children: [
            // Profile Picture - Clickable
            Semantics(
              label: 'Profile picture',
              hint: 'Double tap to view profile',
              button: true,
              child: GestureDetector(
                onTap: onProfileTap ?? () {},
                child: Hero(
                  tag: 'caretaker_profile_picture',
                  child: Container(
                    width: profileSize,
                    height: profileSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary,
                          primary.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: isDarkMode 
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.8),
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                          ? Image.network(
                              profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar(profileSize);
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                );
                              },
                            )
                          : _buildDefaultAvatar(profileSize),
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 14),
            
            // Greeting and Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    label: 'Greeting',
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hello there, ',
                            style: body.copyWith(
                              fontSize: 18,
                              color: subtextColor,
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                            ),
                          ),
                          TextSpan(
                            text: caretakerName.split(' ')[0], // First name only
                            style: h2.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              letterSpacing: -0.3,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 2),
                  Semantics(
                    label: 'Today\'s date',
                    child: Text(
                      formattedDate,
                      style: caption.copyWith(
                        fontSize: 12,
                        color: subtextColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Buttons Row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dark Mode Toggle
                Semantics(
                  label: isDarkMode ? 'Dark mode is on' : 'Light mode is on',
                  hint: 'Double tap to toggle theme mode',
                  button: true,
                  child: _buildActionButton(
                    icon: isDarkMode 
                      ? Icons.dark_mode_rounded 
                      : Icons.light_mode_rounded,
                    onPressed: onToggleDarkMode,
                    size: iconSize,
                  ),
                ),
                
                SizedBox(width: 8),
                
                // Pending Requests Badge
                if (onNotificationTap != null)
                  Semantics(
                    label: pendingRequestsCount > 0 
                      ? 'Pending requests. You have $pendingRequestsCount pending request${pendingRequestsCount > 1 ? 's' : ''}' 
                      : 'Pending requests',
                    hint: 'Double tap to view requests',
                    button: true,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildActionButton(
                          icon: Icons.assignment_rounded,
                          onPressed: onNotificationTap!,
                          size: iconSize,
                        ),
                        if (pendingRequestsCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDarkMode 
                                      ? Color(0xFF0A0E27) 
                                      : backgroundPrimary,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: error.withOpacity(0.4),
                                    blurRadius: 6,
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
                                  pendingRequestsCount > 9 
                                      ? '9+' 
                                      : pendingRequestsCount.toString(),
                                  style: TextStyle(
                                    color: white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
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
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode 
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.04),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(100),
          splashColor: primary.withOpacity(0.2),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              icon,
              size: size,
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.9)
                  : Colors.black.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(double size) {
    // Get initials from caretakerName
    String initials = '';
    if (caretakerName.isNotEmpty) {
      List<String> nameParts = caretakerName.trim().split(' ');
      if (nameParts.length >= 2) {
        initials = nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
      } else {
        initials = nameParts[0].substring(0, nameParts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            primary.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              )
            : Icon(
                Icons.person,
                size: size * 0.5,
                color: Colors.white,
              ),
      ),
    );
  }
}