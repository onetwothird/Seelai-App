// File: lib/roles/caretaker/home/sections/settings_content.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class SettingsContent extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isDarkMode;
  final dynamic theme;
  final VoidCallback onToggleDarkMode;

  const SettingsContent({
    super.key,
    required this.userData,
    required this.isDarkMode,
    required this.theme,
    required this.onToggleDarkMode,
  });

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  bool _notificationsEnabled = true;
  bool _locationTrackingEnabled = true;
  bool _emergencyAlertsEnabled = true;
  bool _soundEnabled = true;
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: h2.copyWith(
              fontSize: 26,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          SizedBox(height: spacingLarge),
          
          // Appearance Settings
          _buildSettingsCard(
            title: 'Appearance',
            icon: Icons.palette_rounded,
            children: [
              _buildSwitchTile(
                title: 'Dark Mode',
                subtitle: 'Use dark theme for comfortable viewing',
                value: widget.isDarkMode,
                onChanged: (value) => widget.onToggleDarkMode(),
                icon: Icons.dark_mode_rounded,
              ),
            ],
          ),
          
          SizedBox(height: spacingLarge),
          
          // Notification Settings
          _buildSettingsCard(
            title: 'Notifications',
            icon: Icons.notifications_rounded,
            children: [
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive alerts and updates',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
                icon: Icons.notifications_active_rounded,
              ),
              Divider(height: 1, color: widget.theme.subtextColor.withOpacity(0.2)),
              _buildSwitchTile(
                title: 'Emergency Alerts',
                subtitle: 'Receive immediate emergency notifications',
                value: _emergencyAlertsEnabled,
                onChanged: (value) {
                  setState(() => _emergencyAlertsEnabled = value);
                },
                icon: Icons.emergency_rounded,
              ),
              Divider(height: 1, color: widget.theme.subtextColor.withOpacity(0.2)),
              _buildSwitchTile(
                title: 'Sound',
                subtitle: 'Play sound for notifications',
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                },
                icon: Icons.volume_up_rounded,
              ),
            ],
          ),
          
          SizedBox(height: spacingLarge),
          
          // Privacy & Security
          _buildSettingsCard(
            title: 'Privacy & Security',
            icon: Icons.security_rounded,
            children: [
              _buildSwitchTile(
                title: 'Location Tracking',
                subtitle: 'Track patient locations in real-time',
                value: _locationTrackingEnabled,
                onChanged: (value) {
                  setState(() => _locationTrackingEnabled = value);
                },
                icon: Icons.location_on_rounded,
              ),
            ],
          ),
          
          SizedBox(height: spacingLarge),
          
          // About Section
          _buildSettingsCard(
            title: 'About',
            icon: Icons.info_rounded,
            children: [
              _buildActionTile(
                title: 'Help & Support',
                icon: Icons.help_outline_rounded,
                onTap: () {
                  // TODO: Open help
                },
              ),
              Divider(height: 1, color: widget.theme.subtextColor.withOpacity(0.2)),
              _buildActionTile(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
              Divider(height: 1, color: widget.theme.subtextColor.withOpacity(0.2)),
              _buildActionTile(
                title: 'Terms of Service',
                icon: Icons.description_outlined,
                onTap: () {
                  // TODO: Open terms
                },
              ),
            ],
          ),
          
          SizedBox(height: spacingLarge),
          
          // App Version
          Center(
            child: Text(
              'SeelAI Caretaker v1.0.0',
              style: caption.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 12,
              ),
            ),
          ),
          
          SizedBox(height: spacingXLarge),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.15),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ]
          : cardShadow,
        border: widget.isDarkMode 
          ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
          : Border.all(color: greyLighter.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  child: Icon(icon, color: white, size: 20),
                ),
                SizedBox(width: spacingMedium),
                Text(
                  title,
                  style: bodyBold.copyWith(
                    fontSize: 18,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingSmall),
      leading: Icon(icon, color: widget.theme.subtextColor, size: 24),
      title: Text(
        title,
        style: bodyBold.copyWith(
          fontSize: 16,
          color: widget.theme.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: caption.copyWith(
          fontSize: 13,
          color: widget.theme.subtextColor,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: primary,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingSmall),
      leading: Icon(icon, color: widget.theme.subtextColor, size: 24),
      title: Text(
        title,
        style: bodyBold.copyWith(
          fontSize: 16,
          color: widget.theme.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: widget.theme.subtextColor,
        size: 24,
      ),
      onTap: onTap,
    );
  }
}