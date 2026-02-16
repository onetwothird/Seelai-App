// File: lib/roles/mswd/home/widgets/header_section.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:seelai_app/themes/constants.dart';

class HeaderSection extends StatefulWidget {
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
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> with SingleTickerProviderStateMixin {
  late final AnimationController _themeController;

  @override
  void initState() {
    super.initState();
    // The provided Lottie file is 180 frames.
    // Frame 0 is Day. Frame 90 (0.5 progress) is Night.
    _themeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: widget.isDarkMode ? 0.5 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant HeaderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      if (widget.isDarkMode) {
        // Animate to Night (Frame 90 / 50%)
        _themeController.animateTo(0.5);
      } else {
        // Animate back to Day (Frame 0 / 0%)
        _themeController.animateBack(0.0);
      }
    }
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  // Helper to safely extract the first name
  String _getFirstName() {
    if (widget.adminName.isEmpty) return '';
    final parts = widget.adminName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(now);

    final profileSize = 56.0;
    final double themeToggleSize = 60.0;

    return Semantics(
      label: 'Header section. Hi ${widget.adminName}. Today is $formattedDate',
      child: Container(
        padding: EdgeInsets.fromLTRB(
          width * 0.05,      // Left padding
          height * 0.015,    // Top padding
          width * 0.02,      // Right padding (Reduced to 0.02 to match other headers)
          height * 0.015,    // Bottom padding
        ),
        decoration: BoxDecoration(
          gradient: widget.isDarkMode
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
            // --- Profile Picture ---
            Semantics(
              label: 'Profile picture, MSWD role',
              hint: 'Double tap to view profile',
              button: true,
              child: GestureDetector(
                onTap: widget.onProfileTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Hero(
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
                              const Color.fromARGB(255, 0, 0, 0),
                              const Color.fromARGB(255, 0, 0, 0).withOpacity(0.7),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.25),
                            width: 1.2,
                          ),
                        ),
                        child: ClipOval(
                          child: widget.profileImageUrl != null &&
                                  widget.profileImageUrl!.isNotEmpty
                              ? Image.network(
                                  widget.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(profileSize),
                                )
                              : _buildDefaultAvatar(profileSize),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF7C3AED),
                                const Color(0xFF7C3AED).withOpacity(0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: widget.isDarkMode
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.black.withOpacity(0.1),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.35),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'MSWD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 14),

            // --- Greeting and Date ---
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
                              color: widget.subtextColor,
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                            ),
                          ),
                          TextSpan(
                            text: _getFirstName(),
                            style: h2.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: widget.textColor,
                              letterSpacing: -0.3,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Semantics(
                    label: 'Today\'s date',
                    child: Text(
                      formattedDate,
                      style: caption.copyWith(
                        fontSize: 12,
                        color: widget.subtextColor.withOpacity(0.8),
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

            // --- Action Buttons Row ---
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- CUSTOM DAY/NIGHT TOGGLE (Lottie) ---
                Semantics(
                  label: widget.isDarkMode ? 'Dark mode is on' : 'Light mode is on',
                  hint: 'Double tap to toggle theme mode',
                  button: true,
                  child: InkWell(
                    onTap: widget.onToggleDarkMode,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: themeToggleSize,
                      height: themeToggleSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: Lottie.asset(
                        'assets/icons/light-dark.json',
                        controller: _themeController,
                        fit: BoxFit.contain,
                        animate: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(double size) {
    String initials = '';
    final trimmedName = widget.adminName.trim();

    if (trimmedName.isNotEmpty) {
      List<String> nameParts = trimmedName.split(RegExp(r'\s+'));

      if (nameParts.length >= 2) {
        String first = nameParts[0].isNotEmpty ? nameParts[0][0] : '';
        String second = nameParts[1].isNotEmpty ? nameParts[1][0] : '';
        initials = (first + second).toUpperCase();
      } else if (nameParts.isNotEmpty) {
        String name = nameParts[0];
        if (name.length >= 2) {
          initials = name.substring(0, 2).toUpperCase();
        } else {
          initials = name.toUpperCase();
        }
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
                Icons.admin_panel_settings_rounded,
                size: size * 0.5,
                color: Colors.white,
              ),
      ),
    );
  }
}