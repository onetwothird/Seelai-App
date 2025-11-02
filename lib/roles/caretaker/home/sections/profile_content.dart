// File: lib/roles/caretaker/home/sections/profile_content.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/themes/widgets.dart';
import 'package:seelai_app/service/auth_service.dart';

class ProfileContent extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isDarkMode;
  final dynamic theme;

  const ProfileContent({
    super.key,
    required this.userData,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final userName = userData['name'] ?? 'Caretaker';
    final userEmail = userData['email'] ?? '';
    final userAge = userData['age'] ?? 0;
    final userPhone = userData['phone'] ?? 'Not provided';
    final relationship = userData['relationship'] ?? 'Not specified';
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        bottom: 100,
      ),
      child: Column(
        children: [
          // Profile Card
          Container(
            padding: EdgeInsets.all(spacingXLarge),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(radiusXLarge),
              boxShadow: isDarkMode 
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.15),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ]
                : cardShadow,
              border: isDarkMode 
                ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
                : Border.all(color: greyLighter.withOpacity(0.5), width: 1),
            ),
            child: Column(
              children: [
                // Profile Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: glowShadow,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: white,
                  ),
                ),
                
                SizedBox(height: spacingLarge),
                
                Text(
                  userName,
                  style: h2.copyWith(
                    fontSize: 28,
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: spacingSmall),
                
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_rounded, color: white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Caretaker',
                        style: bodyBold.copyWith(
                          color: white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: spacingXLarge),
                
                Divider(color: theme.subtextColor.withOpacity(0.3)),
                
                SizedBox(height: spacingLarge),
                
                // Profile Information
                _buildInfoRow('Email', userEmail, theme.textColor, theme.subtextColor),
                _buildInfoRow('Age', '$userAge years old', theme.textColor, theme.subtextColor),
                _buildInfoRow('Phone', userPhone, theme.textColor, theme.subtextColor),
                _buildInfoRow('Relationship', relationship, theme.textColor, theme.subtextColor),
                
                SizedBox(height: spacingXLarge),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement edit profile
                        },
                        icon: Icon(Icons.edit_rounded),
                        label: Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDarkMode ? primaryLight : primary,
                          side: BorderSide(
                            color: isDarkMode ? primaryLight : primary,
                            width: 2,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(radiusMedium),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: spacingMedium),
                
                CustomButton(
                  text: 'Sign Out',
                  isLarge: true,
                  onPressed: () async {
                    await authService.value.signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, Color subtextColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingLarge),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: body.copyWith(
                fontSize: 16,
                color: subtextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: bodyBold.copyWith(
                fontSize: 16,
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}