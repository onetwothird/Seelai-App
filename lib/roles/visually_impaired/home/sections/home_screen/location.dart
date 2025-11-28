// File: lib/roles/visually_impaired/home/sections/home_screen/location.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/widgets/location_map_widget.dart';

class LocationSection extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final String userId;
  final Map<String, dynamic> userData;

  const LocationSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return _buildLocationUnavailable();
    }
    
    return _buildLocationSection();
  }

  Widget _buildLocationSection() {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
        border: isDarkMode
            ? Border.all(color: primary.withOpacity(0.2), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Location',
                  style: bodyBold.copyWith(
                    fontSize: 16,
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Share with Caretaker',
                  style: caption.copyWith(
                    fontSize: 12,
                    color: theme.subtextColor,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(radiusXLarge),
              bottomRight: Radius.circular(radiusXLarge),
            ),
            child: LocationMapWidget(
              isDarkMode: isDarkMode,
              theme: theme,
              userId: userId,
              userData: userData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationUnavailable() {
    return Container(
      padding: EdgeInsets.all(spacingXLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: isDarkMode
            ? [
                BoxShadow(
                  color: error.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
        border: isDarkMode
            ? Border.all(color: error.withOpacity(0.2), width: 1)
            : Border.all(color: error.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              color: error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_rounded,
              size: 48,
              color: error,
            ),
          ),
          SizedBox(height: spacingLarge),
          Text(
            'Location Unavailable',
            style: bodyBold.copyWith(
              fontSize: 16,
              color: theme.textColor,
            ),
          ),
          SizedBox(height: spacingSmall),
          Text(
            'Please log in to use location tracking',
            style: body.copyWith(
              fontSize: 13,
              color: theme.subtextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}