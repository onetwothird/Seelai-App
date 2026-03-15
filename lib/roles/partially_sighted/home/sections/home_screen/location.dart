// File: lib/roles/visually_impaired/home/sections/home_screen/location.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/widgets/location_map_widget.dart';

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
        boxShadow: isDarkMode ? [] : softShadow,
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
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
        boxShadow: isDarkMode ? [] : softShadow,
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              color: error.withValues(alpha: 0.1),
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