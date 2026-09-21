// File: lib/roles/partially_sighted/home/sections/home_screen/screens/emergency_hotlines_screen.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/partially_sighted/models/emergency_hotline_model.dart';
import 'package:seelai_app/firebase/partially_sighted/emergency_hotline_service.dart';

class EmergencyHotlinesScreen extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;

  const EmergencyHotlinesScreen({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<EmergencyHotlinesScreen> createState() =>
      _EmergencyHotlinesScreenState();
}

class _EmergencyHotlinesScreenState extends State<EmergencyHotlinesScreen> {
  final EmergencyHotlineService _service = emergencyHotlineService;

  // Single broadcast stream to prevent "Stream has already been listened to" errors
  late Stream<List<EmergencyHotline>> _hotlinesStream;

  @override
  void initState() {
    super.initState();
    // Simply listen to the global hotlines managed by MSWD
    _hotlinesStream = _service.streamHotlines().asBroadcastStream();
  }

  Widget _buildSkeletonList() {
    final baseColor = widget.isDarkMode
        ? const Color(0xFF1A1F3A)
        : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode
        ? const Color(0xFF2A2F4A)
        : Colors.grey.shade100;

    return ListView.builder(
      padding: const EdgeInsets.all(spacingLarge),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: spacingMedium),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radiusLarge),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- UPDATED: Forces pure white background in light mode ---
    final Color safeBgColor = widget.isDarkMode
        ? widget.theme.backgroundColor
        : Colors.white;

    return Scaffold(
      backgroundColor: safeBgColor,
      appBar: AppBar(
        backgroundColor: widget.theme.cardColor,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: widget.theme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Emergency Hotlines',
          style: h3.copyWith(
            fontSize: 18,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        color: safeBgColor, // Applied white background here too
        child: StreamBuilder<List<EmergencyHotline>>(
          stream: _hotlinesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeletonList();
            }

            if (snapshot.hasError) {
              debugPrint('Stream Error: ${snapshot.error}');

              // Show on screen
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final hotlines = snapshot.data ?? [];

            if (hotlines.isEmpty) {
              return _buildEmptyState();
            }

            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(spacingLarge),
                itemCount: hotlines.length,
                itemBuilder: (context, index) {
                  final hotline = hotlines[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: _buildHotlineCard(hotline)),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHotlineCard(EmergencyHotline hotline) {
    return Semantics(
      label: '${hotline.departmentName} hotline',
      button: true,
      hint: 'Double tap to call ${hotline.phoneNumber}',
      child: Container(
        margin: const EdgeInsets.only(bottom: spacingMedium),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _callHotline(hotline),
            borderRadius: BorderRadius.circular(radiusLarge),
            child: Padding(
              padding: const EdgeInsets.all(spacingMedium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Avatar (Using BoxShape.circle to perfectly match screenshot)
                  Container(
                    width: 60,
                    height: 60,
                    padding: hotline.imageAsset.isNotEmpty
                        ? EdgeInsets.zero
                        : const EdgeInsets.all(spacingMedium),
                    decoration: BoxDecoration(
                      color: hotline.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      image: hotline.imageAsset.isNotEmpty
                          ? DecorationImage(
                              image: AssetImage(hotline.imageAsset),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hotline.imageAsset.isNotEmpty
                        ? null
                        : Icon(hotline.icon, color: hotline.color, size: 26),
                  ),
                  const SizedBox(width: spacingMedium),

                  // 2. Text Column (Only the text now)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hotline.departmentName,
                          style: bodyBold.copyWith(
                            fontSize: 16,
                            color: widget.theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hotline.phoneNumber,
                          style: body.copyWith(
                            fontSize: 14,
                            color: widget.theme.subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Trailing Elements (Badge + Call Icon aligned side-by-side)
                  if (hotline.isPredefined) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: spacingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: hotline.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(radiusSmall),
                      ),
                      child: Text(
                        'Official',
                        style: caption.copyWith(
                          fontSize: 10,
                          color: hotline.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ), // Snug spacing between badge and phone icon
                  ],
                  Icon(
                    Icons.call_rounded,
                    color: widget.theme.subtextColor.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone_in_talk_rounded,
            size: 80,
            color: widget.theme.subtextColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: spacingMedium),
          Text(
            'No hotlines available',
            style: h3.copyWith(color: widget.theme.textColor),
          ),
          const SizedBox(height: spacingSmall),
          Text(
            'Your MSWD officer will add contacts soon.',
            style: body.copyWith(color: widget.theme.subtextColor),
          ),
        ],
      ),
    );
  }

  Future<void> _callHotline(EmergencyHotline hotline) async {
    final success = await _service.makeEmergencyCall(
      hotline.phoneNumber,
      hotline.departmentName,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to make call'),
          backgroundColor: error,
        ),
      );
    }
  }
}
