import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class QuickActions extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;

  const QuickActions({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: h3.copyWith(
            fontSize: 20,
            color: theme.textColor,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(
              context,
              icon: Icons.person_add_rounded,
              label: 'Add User',
              color: const Color(0xFFF59E0B), // Amber
              onTap: () {
                // Navigate to register user
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.admin_panel_settings_rounded,
              label: 'Approvals',
              color: const Color(0xFFEC4899), // Pink
              onTap: () {
                // Navigate to pending caretakers
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.assessment_rounded,
              label: 'Reports',
              color: const Color(0xFF06B6D4), // Cyan
              onTap: () {
                // Navigate to reports
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.sos_rounded,
              label: 'Hotlines',
              color: const Color(0xFFEF4444), // Red
              onTap: () {
                // Navigate to hotline management
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDarkMode
                  ? [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              border: Border.all(
                color: isDarkMode ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: caption.copyWith(
              fontSize: 11,
              color: theme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}