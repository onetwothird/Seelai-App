import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:intl/intl.dart';

class ProfileContent extends StatefulWidget {
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
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Section
          _buildSectionTitle('Personal Information', Icons.person_rounded),
          SizedBox(height: spacingMedium),
          _buildMenuItem(
            'Full Name',
            _userData['name'] ?? 'Not provided',
            Icons.person_rounded,
            primary,
            onTap: () => _showSnackbar('Name: ${_userData['name']}'),
          ),
          _buildMenuItem(
            'Email Address',
            _userData['email'] ?? 'Not provided',
            Icons.email_rounded,
            accent,
            onTap: () => _showSnackbar('Email: ${_userData['email']}'),
          ),
          _buildMenuItem(
            'Phone Number',
            _userData['phone'] ?? _userData['contactNumber'] ?? 'Not provided',
            Icons.phone_rounded,
            Colors.green,
            onTap: () => _showSnackbar('Phone: ${_userData['phone']}'),
          ),
          _buildMenuItem(
            'Relationship',
            _userData['relationship'] ?? 'Not specified',
            Icons.people_rounded,
            Colors.purple,
            onTap: () => _showSnackbar('Role: ${_userData['relationship']}'),
          ),

          SizedBox(height: spacingXLarge),

          // Demographic Information Section
          _buildSectionTitle('Demographic Information', Icons.info_outline_rounded),
          SizedBox(height: spacingMedium),
          _buildMenuItem(
            'Age',
            _userData['age'] != null && _userData['age'] > 0
                ? '${_userData['age']} years old'
                : 'Not specified',
            Icons.cake_rounded,
            Colors.orange,
            onTap: () => _showSnackbar('Age: ${_userData['age']} years'),
          ),
          _buildMenuItem(
            'Gender',
            _userData['sex'] ?? 'Not specified',
            Icons.wc_rounded,
            Colors.cyan,
            onTap: () => _showSnackbar('Gender: ${_userData['sex']}'),
          ),
          if (_userData['birthdate'] != null && _userData['birthdate'].isNotEmpty)
            _buildMenuItem(
              'Date of Birth',
              _formatBirthdate(_userData['birthdate']),
              Icons.calendar_today_rounded,
              Colors.indigo,
              onTap: () => _showSnackbar('DOB: ${_formatBirthdate(_userData['birthdate'])}'),
            ),

          SizedBox(height: spacingXLarge),

          // Account Information Section
          _buildSectionTitle('Account Information', Icons.verified_user_rounded),
          SizedBox(height: spacingMedium),
          _buildMenuItem(
            'Account Type',
            'Caretaker',
            Icons.shield_rounded,
            primary,
            onTap: () => _showSnackbar('Account Type: Caretaker'),
          ),
          _buildMenuItem(
            'Account Status',
            _userData['status'] ?? 'Active',
            Icons.check_circle_rounded,
            Colors.green,
            onTap: () => _showSnackbar('Status: ${_userData['status'] ?? 'Active'}'),
          ),
          if (_userData['createdAt'] != null)
            _buildMenuItem(
              'Member Since',
              _formatDate(_userData['createdAt']),
              Icons.date_range_rounded,
              accent,
              onTap: () => _showSnackbar('Joined: ${_formatDate(_userData['createdAt'])}'),
            ),

          SizedBox(height: spacingXLarge),

          // Caretaking Information Section
          _buildSectionTitle('Caretaking Experience', Icons.favorite_rounded),
          SizedBox(height: spacingMedium),
          _buildMenuItem(
            'Total Patients',
            _userData['totalPatients']?.toString() ?? '0',
            Icons.people_rounded,
            primary,
            onTap: () => _showSnackbar('Total Patients: ${_userData['totalPatients'] ?? 0}'),
          ),
          _buildMenuItem(
            'Active Assignments',
            _userData['activeAssignments']?.toString() ?? '0',
            Icons.assignment_turned_in_rounded,
            Colors.green,
            onTap: () => _showSnackbar('Active: ${_userData['activeAssignments'] ?? 0}'),
          ),
          _buildMenuItem(
            'Completed Tasks',
            _userData['completedTasks']?.toString() ?? '0',
            Icons.task_alt_rounded,
            accent,
            onTap: () => _showSnackbar('Completed: ${_userData['completedTasks'] ?? 0}'),
          ),
          _buildMenuItem(
            'Average Rating',
            _userData['rating'] != null
                ? '${_userData['rating']}/5.0 ⭐'
                : 'No ratings yet',
            Icons.star_rounded,
            Colors.amber,
            onTap: () => _showSnackbar('Rating: ${_userData['rating'] ?? 'N/A'}'),
          ),

          SizedBox(height: spacingXLarge),

          // Availability & Preferences Section
          _buildSectionTitle('Availability & Preferences', Icons.schedule_rounded),
          SizedBox(height: spacingMedium),
          _buildMenuItem(
            'Availability Status',
            _userData['availabilityStatus'] ?? 'Available',
            Icons.access_time_rounded,
            Colors.green,
            onTap: () => _showSnackbar('Status: ${_userData['availabilityStatus'] ?? 'Available'}'),
          ),
          _buildMenuItem(
            'Preferred Hours',
            _userData['preferredHours'] ?? 'Flexible',
            Icons.schedule_rounded,
            primary,
            onTap: () => _showSnackbar('Hours: ${_userData['preferredHours'] ?? 'Flexible'}'),
          ),
          _buildMenuItem(
            'Service Types',
            _userData['serviceTypes'] ?? 'General Care',
            Icons.home_repair_service_rounded,
            accent,
            onTap: () => _showSnackbar('Services: ${_userData['serviceTypes'] ?? 'General Care'}'),
          ),

          SizedBox(height: spacingXLarge),

          // Account Actions Section
          _buildSectionTitle('Account Actions', Icons.settings_rounded),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            icon: Icons.edit_rounded,
            label: 'Edit Profile',
            subtitle: 'Update your personal information',
            color: primary,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Edit profile feature coming soon'),
                  backgroundColor: primary,
                ),
              );
            },
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            icon: Icons.lock_reset_rounded,
            label: 'Change Password',
            subtitle: 'Update your account password',
            color: accent,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Change password feature coming soon'),
                  backgroundColor: accent,
                ),
              );
            },
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            icon: Icons.notifications_rounded,
            label: 'Notification Settings',
            subtitle: 'Manage your notification preferences',
            color: Colors.blue,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notification settings coming soon'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),

          SizedBox(height: spacingXLarge),

          // Danger Zone Section
          _buildSectionTitle('Danger Zone', Icons.warning_amber_rounded),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            subtitle: 'Log out of your account',
            color: Colors.orange,
            onTap: () async {
              final confirm = await _showConfirmDialog(
                'Sign Out',
                'Are you sure you want to sign out?',
              );

              if (confirm == true) {
                await authService.value.signOut();
              }
            },
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            icon: Icons.delete_forever_rounded,
            label: 'Delete Account',
            subtitle: 'Permanently delete your account and data',
            color: Colors.red,
            isDanger: true,
            onTap: () async {
              final confirm = await _showConfirmDialog(
                'Delete Account',
                'This action cannot be undone. Are you sure you want to delete your account?',
                isDanger: true,
              );

              if (confirm == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Delete account feature coming soon'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),

          SizedBox(height: spacingLarge),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
            child: Icon(icon, color: primary, size: 16),
          ),
          SizedBox(width: spacingSmall),
          Text(
            title.toUpperCase(),
            style: caption.copyWith(
              fontSize: 11,
              color: widget.theme.subtextColor.withOpacity(0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    String value,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Container(
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          border: Border.all(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.06),
          ),
          boxShadow: widget.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radiusLarge),
            child: Padding(
              padding: EdgeInsets.all(spacingMedium),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(radiusMedium),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: caption.copyWith(
                            fontSize: 12,
                            color: widget.theme.subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          value,
                          style: bodyBold.copyWith(
                            fontSize: 15,
                            color: widget.theme.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: widget.theme.subtextColor.withOpacity(0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      child: Material(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusLarge),
          splashColor: color.withOpacity(0.2),
          child: Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              gradient: isDanger
                  ? LinearGradient(
                      colors: [
                        color.withOpacity(widget.isDarkMode ? 0.25 : 0.1),
                        color.withOpacity(widget.isDarkMode ? 0.15 : 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(radiusLarge),
              border: widget.isDarkMode
                  ? Border.all(color: color.withOpacity(0.4), width: 1.5)
                  : Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: bodyBold.copyWith(
                          fontSize: 16,
                          color: isDanger ? color : widget.theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: caption.copyWith(
                          fontSize: 13,
                          color: widget.theme.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    String title,
    String message, {
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        title: Row(
          children: [
            Icon(
              isDanger ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
              color: isDanger ? Colors.red : primary,
            ),
            SizedBox(width: spacingSmall),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? Colors.red : primary,
              foregroundColor: white,
            ),
            child: Text(isDanger ? 'Delete' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _formatBirthdate(String birthdate) {
    try {
      final date = DateTime.parse(birthdate);
      return DateFormat('MMMM dd, yyyy').format(date);
    } catch (e) {
      return birthdate;
    }
  }

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        return DateFormat('MMM dd, yyyy').format(parsedDate);
      } else if (date is DateTime) {
        return DateFormat('MMM dd, yyyy').format(date);
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
}