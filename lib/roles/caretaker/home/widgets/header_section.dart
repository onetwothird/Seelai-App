// File: lib/roles/caretaker/home/widgets/header_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:seelai_app/themes/constants.dart';

class HeaderSection extends StatefulWidget {
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
    if (widget.caretakerName.isEmpty) return '';
    final parts = widget.caretakerName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(now);
    
    final profileSize = 56.0;
    final double notificationSize = 55.0; 
    final double themeToggleSize = 60.0; 
    
    final badgeYellow = const Color(0xFFFDCB58);
    final badgeBorderColor = const Color(0xFF1A1A40);
    
    return Semantics(
      label: 'Header section. Hi ${widget.caretakerName}. Today is $formattedDate',
      child: Container(
        padding: EdgeInsets.fromLTRB(
          width * 0.05,        // Left padding
          height * 0.015,      // Top padding
          width * 0.02,        // Right padding (Reduced to 0.02 to push icons closer to edge)
          height * 0.015,      // Bottom padding
        ),
        decoration: BoxDecoration(
          gradient: widget.isDarkMode
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A0E27).withValues(alpha: 0.5),
                    const Color(0xFF0A0E27).withValues(alpha: 0.3),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundPrimary,
                    backgroundPrimary.withValues(alpha: 0.9),
                  ],
                ),
        ),
        child: Row(
          children: [
            // --- Profile Picture ---
            Semantics(
              label: 'Profile picture, Caretaker role',
              hint: 'Double tap to view profile',
              button: true,
              child: GestureDetector(
                onTap: widget.onProfileTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Hero(
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
                              const Color.fromARGB(255, 0, 0, 0),
                              const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.7),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: ClipOval(
                          child: widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty
                              ? Image.network(
                                  widget.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(profileSize),
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
                                const Color(0xFF7C3AED).withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: widget.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.1),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Caretaker',
                            style: TextStyle(
                              color: Colors.white,
                              overflow: TextOverflow.visible,
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
                        color: widget.subtextColor.withValues(alpha: 0.8),
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
                
                // Reduced spacing from 10 to 4 to make them "a lil bit close"
                const SizedBox(width: 1),
                
                // --- CUSTOM NOTIFICATION BELL (Lottie) for Pending Requests ---
                Semantics(
                  label: widget.pendingRequestsCount > 0 
                    ? 'Pending requests. You have ${widget.pendingRequestsCount} pending request${widget.pendingRequestsCount > 1 ? 's' : ''}' 
                    : 'Pending requests',
                  hint: 'Double tap to view pending requests',
                  button: true,
                  child: InkWell(
                    onTap: widget.onNotificationTap,
                    borderRadius: BorderRadius.circular(50),
                    child: SizedBox(
                      width: notificationSize,
                      height: notificationSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Bell Lottie
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Lottie.asset(
                              'assets/icons/Notification.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                          
                          // Badge
                          if (widget.pendingRequestsCount > 0)
                            Positioned(
                              right: 8,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: badgeYellow,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: badgeBorderColor,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.pendingRequestsCount > 9 
                                        ? '9+' 
                                        : widget.pendingRequestsCount.toString(),
                                    style: TextStyle(
                                      color: badgeBorderColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
    final trimmedName = widget.caretakerName.trim();
    
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
            primary.withValues(alpha: 0.7),
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