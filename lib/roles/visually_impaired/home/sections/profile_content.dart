// File: lib/roles/visually_impaired/home/sections/profile_content.dart
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
    final userName = userData['name'] ?? 'User';
    final userEmail = userData['email'] ?? '';
    final userAge = userData['age'] ?? 0;
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        bottom: 100,
      ),
      child: Semantics(
        label: 'Profile information section',
        child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              _buildProfileHeader(theme),
              
              SizedBox(height: spacingXLarge),
              
              // Profile info
              _buildInfoRow('Name', userName, theme.textColor, theme.subtextColor),
              _buildInfoRow('Email', userEmail, theme.textColor, theme.subtextColor),
              _buildInfoRow('Age', '$userAge years old', theme.textColor, theme.subtextColor),
              _buildInfoRow('Role', 'Visually Impaired', theme.textColor, theme.subtextColor),
              
              SizedBox(height: spacingXLarge),
              
              // Sign out button
              Semantics(
                label: 'Sign out button',
                button: true,
                hint: 'Double tap to sign out of your account',
                child: CustomButton(
                  text: 'Sign Out',
                  isLarge: true,
                  onPressed: () async {
                    await authService.value.signOut();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic theme) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(spacingLarge),
          decoration: BoxDecoration(
            gradient: primaryGradient,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: glowShadow,
          ),
          child: Icon(Icons.person_rounded, color: white, size: 36),
        ),
        SizedBox(width: spacingLarge),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: h2.copyWith(
                  fontSize: 26,
                  color: theme.textColor,
                ),
              ),
              SizedBox(height: spacingXSmall),
              Text(
                'Your account information',
                style: caption.copyWith(
                  color: theme.subtextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, Color subtextColor) {
    return Semantics(
      label: '$label: $value',
      child: Padding(
        padding: EdgeInsets.only(bottom: spacingLarge),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
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
      ),
    );
  }
}