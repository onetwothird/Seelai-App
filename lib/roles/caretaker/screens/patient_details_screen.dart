// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/models/patient_model.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';

class PatientDetailsScreen extends StatelessWidget {
  final PatientModel patient;
  final bool isDarkMode;
  final LocationService locationService;

  const PatientDetailsScreen({
    super.key,
    required this.patient,
    required this.isDarkMode,
    required this.locationService,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? Color(0xFF0A0E27) : backgroundPrimary;
    final textColor = isDarkMode ? white : black;
    final subtextColor = isDarkMode ? Color(0xFFB0B8D4) : grey;
    final cardColor = isDarkMode ? Color(0xFF1A1F3A) : white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Patient Details',
          style: h2.copyWith(color: textColor, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacingLarge),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: EdgeInsets.all(spacingXLarge),
              decoration: BoxDecoration(
                gradient: primaryGradient,
                borderRadius: BorderRadius.circular(radiusLarge),
                boxShadow: glowShadow,
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      _buildProfileAvatar(),
                      if (patient.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: white, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: spacingLarge),
                  Text(
                    patient.name,
                    style: h1.copyWith(
                      fontSize: 26,
                      color: white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: spacingSmall),
                  Text(
                    '${patient.age} years old • ${patient.disabilityType}',
                    style: body.copyWith(
                      fontSize: 16,
                      color: white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.phone_rounded,
                    label: 'Call',
                    color: Colors.green,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${patient.name}...')),
                      );
                    },
                    cardColor: cardColor,
                  ),
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.message_rounded,
                    label: 'Message',
                    color: primary,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Message feature coming soon')),
                      );
                    },
                    cardColor: cardColor,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: spacingMedium),
            
            // Contact Information
            _buildInfoSection(
              'Contact Information',
              [
                _InfoRow(
                  icon: Icons.phone_rounded,
                  label: 'Phone',
                  value: patient.contactNumber ?? 'N/A',
                ),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Address',
                  value: patient.address ?? 'N/A',
                ),
              ],
              cardColor,
              textColor,
              subtextColor,
            ),
            
            SizedBox(height: spacingMedium),
            
            // Medical Information
            _buildInfoSection(
              'Medical Information',
              [
                _InfoRow(
                  icon: Icons.accessible_rounded,
                  label: 'Disability',
                  value: patient.disabilityType,
                ),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Last Active',
                  value: patient.lastActive != null
                      ? _formatLastActive(patient.lastActive!)
                      : 'Never',
                ),
              ],
              cardColor,
              textColor,
              subtextColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Build profile avatar - shows profile picture or fallback icon
  Widget _buildProfileAvatar() {
    final hasProfileImage = patient.profileImageUrl != null && 
                            patient.profileImageUrl!.isNotEmpty;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasProfileImage ? null : null,
        border: Border.all(
          color: white.withOpacity(0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: white.withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: hasProfileImage
            ? Image.network(
                patient.profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image fails to load
                  return Container(
                    padding: EdgeInsets.all(spacingXLarge),
                    decoration: BoxDecoration(
                      color: white.withOpacity(0.2),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 60,
                      color: white,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    padding: EdgeInsets.all(spacingXLarge),
                    decoration: BoxDecoration(
                      color: white.withOpacity(0.2),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(white),
                      ),
                    ),
                  );
                },
              )
            : Container(
                padding: EdgeInsets.all(spacingXLarge),
                decoration: BoxDecoration(
                  color: white.withOpacity(0.2),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 60,
                  color: white,
                ),
              ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required Color cardColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: isDarkMode
            ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 16, offset: Offset(0, 6))]
            : softShadow,
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusLarge),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: spacingLarge),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: spacingMedium),
                Text(
                  label,
                  style: bodyBold.copyWith(
                    fontSize: 16,
                    color: isDarkMode ? white : black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    List<_InfoRow> rows,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: bodyBold.copyWith(
            fontSize: 18,
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        Container(
          padding: EdgeInsets.all(spacingLarge),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(radiusLarge),
            boxShadow: isDarkMode
                ? [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 16)]
                : softShadow,
          ),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                _buildInfoRow(rows[i], textColor, subtextColor),
                if (i < rows.length - 1) ...[
                  SizedBox(height: spacingMedium),
                  Divider(height: 1, color: subtextColor.withOpacity(0.2)),
                  SizedBox(height: spacingMedium),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(_InfoRow row, Color textColor, Color subtextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(spacingSmall),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          child: Icon(row.icon, size: 20, color: primary),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: caption.copyWith(
                  fontSize: 12,
                  color: subtextColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                row.value,
                style: bodyBold.copyWith(
                  fontSize: 15,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatLastActive(DateTime lastActive) {
    final difference = DateTime.now().difference(lastActive);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}