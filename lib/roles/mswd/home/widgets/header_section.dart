// File: lib/roles/mswd/home/widgets/header_section.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seelai_app/themes/constants.dart';

class HeaderSection extends StatelessWidget {
  final String adminName;
  final String? profileImageUrl;
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;
  final VoidCallback? onProfileTap;
  final Color textColor;
  final Color subtextColor;

  const HeaderSection({
    super.key,
    required this.adminName,
    this.profileImageUrl,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    this.onProfileTap,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(now);

    final profileSize = 56.0;
    final iconSize = 24.0;

    return Semantics(
      label: 'Header section. Hi $adminName. Today is $formattedDate',
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
                    const Color(0xFF0A0E27).withOpacity(0.5),
                    const Color(0xFF0A0E27).withOpacity(0.3),
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
                  tag: 'mswd_profile_picture',
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
                      border: Border.all(
                        color: Colors.white,
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: profileImageUrl != null &&
                              profileImageUrl!.isNotEmpty
                          ? Image.network(
                              profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return _buildDefaultAvatar(profileSize);
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
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

            // Greeting + Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                 
                  // SAME STYLE AS CARETAKER (Hello there, + name)
                  RichText(
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
                          text: adminName.split(' ')[0],
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

                  SizedBox(height: 2),

                  Text(
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
                ],
              ),
            ),

            // Dark Mode Toggle (same as caretaker)
            Semantics(
              label: isDarkMode
                  ? 'Dark mode is on'
                  : 'Light mode is on',
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
    String initials = '';

    if (adminName.isNotEmpty) {
      List<String> parts = adminName.trim().split(' ');
      if (parts.length >= 2) {
        initials =
            parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
      } else {
        initials = parts[0]
            .substring(0, parts[0].length >= 2 ? 2 : 1)
            .toUpperCase();
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
                ),
              )
            : Icon(
                Icons.admin_panel_settings_rounded,
                size: size * 0.5,
                color: Colors.white,
              ),
      ),
    );
  }
}
