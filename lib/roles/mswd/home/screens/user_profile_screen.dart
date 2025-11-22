// File: lib/roles/mswd/screens/user_profile_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isDarkMode;
  final dynamic theme;
  final bool isCaretaker;

  const UserProfileScreen({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.theme,
    this.isCaretaker = false,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isCaretaker ? 3 : 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final name = widget.user['name'] ?? 'Unknown';
    final status = widget.user['status'] ?? 'Active';
    final isActive = status == 'Active';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: widget.theme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(name),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(width * 0.05),
                  child: Column(
                    children: [
                      _buildProfileHeader(name, status, isActive),
                      SizedBox(height: spacingLarge),
                      _buildTabSection(),
                      SizedBox(height: spacingLarge),
                      _buildActionButtons(),
                      SizedBox(height: spacingXLarge),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(String name) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_rounded, color: widget.theme.textColor),
          ),
          Expanded(
            child: Text(
              widget.isCaretaker ? 'Caretaker Profile' : 'User Profile',
              style: h3.copyWith(
                color: widget.theme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: widget.theme.textColor),
            color: widget.theme.cardColor,
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text('Edit Profile', style: body.copyWith(color: widget.theme.textColor))),
              PopupMenuItem(value: 'suspend', child: Text('Suspend Account', style: body.copyWith(color: error))),
              PopupMenuItem(value: 'delete', child: Text('Delete Account', style: body.copyWith(color: error))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String status, bool isActive) {
    final accentColor = widget.isCaretaker ? accent : primary;

    return Container(
      padding: EdgeInsets.all(spacingLarge * 1.5),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [BoxShadow(color: accentColor.withOpacity(0.15), blurRadius: 20, offset: Offset(0, 8))]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: accentColor.withOpacity(0.2), width: 1)
            : null,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [accentColor, accentColor.withOpacity(0.7)]),
                  border: Border.all(color: white, width: 4),
                  boxShadow: [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 16, offset: Offset(0, 6))],
                ),
                child: Center(
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: h1.copyWith(color: white, fontSize: 40, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.theme.cardColor, width: 3),
                  ),
                  child: Icon(
                    isActive ? Icons.check : Icons.pending,
                    color: white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacingLarge),
          Text(
            name,
            style: h2.copyWith(color: widget.theme.textColor, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: spacingSmall),
          Container(
            padding: EdgeInsets.symmetric(horizontal: spacingMedium, vertical: 6),
            decoration: BoxDecoration(
              color: (isActive ? Colors.green : Colors.orange).withOpacity(0.15),
              borderRadius: BorderRadius.circular(radiusLarge),
            ),
            child: Text(
              status.toUpperCase(),
              style: caption.copyWith(
                color: isActive ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(height: spacingMedium),
          if (!widget.isCaretaker) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility_off_rounded, size: 16, color: widget.theme.subtextColor),
                SizedBox(width: 6),
                Text(
                  widget.user['disability'] ?? 'Visual Impairment',
                  style: body.copyWith(color: widget.theme.subtextColor, fontSize: 14),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.badge_rounded, size: 16, color: widget.theme.subtextColor),
                SizedBox(width: 6),
                Text(
                  widget.user['relationship'] ?? 'Caregiver',
                  style: body.copyWith(color: widget.theme.subtextColor, fontSize: 14),
                ),
              ],
            ),
          ],
          SizedBox(height: spacingLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Age', '${widget.user['age'] ?? 'N/A'}'),
              _buildDivider(),
              _buildStatItem('Region', widget.user['region'] ?? 'Metro Manila'),
              _buildDivider(),
              _buildStatItem(
                widget.isCaretaker ? 'Patients' : 'Caretakers',
                widget.isCaretaker ? '${widget.user['patients'] ?? 0}' : '${widget.user['caretakers'] ?? 1}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: h3.copyWith(color: widget.theme.textColor, fontWeight: FontWeight.w800, fontSize: 20)),
        SizedBox(height: 4),
        Text(label, style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: widget.theme.subtextColor.withOpacity(0.2),
    );
  }

  Widget _buildTabSection() {
    final tabs = widget.isCaretaker
        ? ['Personal', 'Patients', 'Statistics']
        : ['Personal', 'Medical', 'Emergency', 'Activity'];

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: primary.withOpacity(0.2), width: 1)
            : null,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: primaryGradient,
                borderRadius: BorderRadius.circular(radiusMedium),
                boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))],
              ),
              labelColor: white,
              unselectedLabelColor: widget.theme.subtextColor,
              labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: widget.isCaretaker
                  ? [_buildPersonalInfo(), _buildAssignedPatients(), _buildStatistics()]
                  : [_buildPersonalInfo(), _buildMedicalInfo(), _buildEmergencyContacts(), _buildRecentActivity()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Padding(
      padding: EdgeInsets.all(spacingLarge),
      child: Column(
        children: [
          _buildInfoRow(Icons.email_rounded, 'Email', widget.user['email'] ?? 'user@example.com'),
          _buildInfoRow(Icons.phone_rounded, 'Phone', widget.user['phone'] ?? '+63 912 345 6789'),
          _buildInfoRow(Icons.location_on_rounded, 'Address', widget.user['address'] ?? '123 Main St, Makati City'),
          _buildInfoRow(Icons.calendar_today_rounded, 'Registered', widget.user['registeredDate'] ?? 'Jan 15, 2024'),
          _buildInfoRow(Icons.perm_identity_rounded, 'PWD ID', widget.user['pwdId'] ?? 'PWD-2024-001234'),
        ],
      ),
    );
  }

  Widget _buildMedicalInfo() {
    return Padding(
      padding: EdgeInsets.all(spacingLarge),
      child: Column(
        children: [
          _buildInfoRow(Icons.visibility_off_rounded, 'Condition', widget.user['disability'] ?? 'Total Blindness'),
          _buildInfoRow(Icons.medical_services_rounded, 'Cause', widget.user['cause'] ?? 'Congenital'),
          _buildInfoRow(Icons.local_hospital_rounded, 'Doctor', widget.user['doctor'] ?? 'Dr. Santos'),
          _buildInfoRow(Icons.medication_rounded, 'Medications', widget.user['medications'] ?? 'None'),
          _buildInfoRow(Icons.warning_rounded, 'Allergies', widget.user['allergies'] ?? 'None reported'),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    final contacts = [
      {'name': 'Rosa Martinez', 'relation': 'Mother', 'phone': '+63 912 111 2222'},
      {'name': 'Carlos Santos', 'relation': 'Brother', 'phone': '+63 912 333 4444'},
    ];

    return ListView.builder(
      padding: EdgeInsets.all(spacingMedium),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final c = contacts[index];
        return Container(
          margin: EdgeInsets.only(bottom: spacingMedium),
          padding: EdgeInsets.all(spacingMedium),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? primary.withOpacity(0.1) : primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(radiusMedium),
            border: Border.all(color: primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: primary.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.person_rounded, color: primary, size: 24),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['name']!, style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 15)),
                    Text(c['relation']!, style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12)),
                    Text(c['phone']!, style: caption.copyWith(color: primary, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.call_rounded, color: Colors.green),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {'action': 'Location shared', 'time': '2 hours ago', 'icon': Icons.location_on_rounded},
      {'action': 'Request completed', 'time': '1 day ago', 'icon': Icons.check_circle_rounded},
      {'action': 'Profile updated', 'time': '3 days ago', 'icon': Icons.edit_rounded},
    ];

    return ListView.builder(
      padding: EdgeInsets.all(spacingMedium),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final a = activities[index];
        return ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: primary.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(a['icon'] as IconData, color: primary, size: 20),
          ),
          title: Text(a['action'] as String, style: body.copyWith(color: widget.theme.textColor, fontSize: 14)),
          subtitle: Text(a['time'] as String, style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12)),
        );
      },
    );
  }

  Widget _buildAssignedPatients() {
    final patients = [
      {'name': 'Maria Santos', 'status': 'Active'},
      {'name': 'Juan Dela Cruz', 'status': 'Active'},
    ];

    return ListView.builder(
      padding: EdgeInsets.all(spacingMedium),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final p = patients[index];
        return Container(
          margin: EdgeInsets.only(bottom: spacingMedium),
          padding: EdgeInsets.all(spacingMedium),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? primary.withOpacity(0.1) : primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(radiusMedium),
            border: Border.all(color: primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: primaryGradient),
                child: Center(
                  child: Text(p['name']!.substring(0, 1), style: TextStyle(color: white, fontWeight: FontWeight.w700, fontSize: 18)),
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name']!, style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 15)),
                    Text(p['status']!, style: caption.copyWith(color: Colors.green, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: widget.theme.subtextColor, size: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatistics() {
    return Padding(
      padding: EdgeInsets.all(spacingLarge),
      child: Column(
        children: [
          _buildStatRow('Total Requests', '156'),
          _buildStatRow('Completed', '142'),
          _buildStatRow('Avg Response Time', '4.2 mins'),
          _buildStatRow('Rating', '4.8 / 5.0'),
          _buildStatRow('Active Since', 'Jan 2024'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: body.copyWith(color: widget.theme.subtextColor, fontSize: 14)),
          Text(value, style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacingSmall),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primary),
          SizedBox(width: spacingMedium),
          SizedBox(
            width: 80,
            child: Text(label, style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: body.copyWith(color: widget.theme.textColor, fontSize: 13), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.call_rounded,
            label: 'Call',
            color: Colors.green,
            onTap: () {},
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: _buildActionButton(
            icon: Icons.location_on_rounded,
            label: 'Location',
            color: Colors.blue,
            onTap: () {},
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: _buildActionButton(
            icon: Icons.message_rounded,
            label: 'Message',
            color: primary,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: widget.theme.cardColor,
      borderRadius: BorderRadius.circular(radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusLarge),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: spacingMedium),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radiusLarge),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(height: 6),
              Text(label, style: caption.copyWith(color: widget.theme.textColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit profile')));
        break;
      case 'suspend':
        _showConfirmDialog('Suspend Account', 'Are you sure you want to suspend this account?');
        break;
      case 'delete':
        _showConfirmDialog('Delete Account', 'This action cannot be undone. Are you sure?');
        break;
    }
  }

  Future<void> _showConfirmDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        title: Text(title, style: bodyBold.copyWith(color: error)),
        content: Text(message, style: body.copyWith(color: widget.theme.subtextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: body.copyWith(color: widget.theme.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: error),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}