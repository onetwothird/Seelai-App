// File: lib/roles/mswd/home/sections/dashboard/user_breakdown.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:firebase_database/firebase_database.dart';

class UserBreakdownSection extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;

  const UserBreakdownSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<UserBreakdownSection> createState() => _UserBreakdownSectionState();
}

class _UserBreakdownSectionState extends State<UserBreakdownSection> {
  int _totalUsers = 0;
  int _visuallyImpairedUsers = 0;
  int _caretakerUsers = 0;
  int _mswdUsers = 0;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserBreakdown();
  }

  /// Fetch user breakdown data
  Future<void> _fetchUserBreakdown() async {
    setState(() => _isLoading = true);
    
    try {
      await _fetchAllUsers();
    } catch (e) {
      debugPrint('Error fetching user breakdown: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Fetch all users categorized by role
  Future<void> _fetchAllUsers() async {
    try {
      debugPrint('🔍 Fetching all users from Firebase...');
      
      // Fetch all user counts in parallel
      final viCountFuture = _countUsersInPath('user_info/visually_impaired');
      final ctCountFuture = _countUsersInPath('user_info/caretaker');
      final mswdCountFuture = _countUsersInPath('user_info/mswd');
      
      final viCount = await viCountFuture;
      final ctCount = await ctCountFuture;
      final mswdCount = await mswdCountFuture;
      final totalCount = viCount + ctCount + mswdCount;
      
      if (mounted) {
        setState(() {
          _visuallyImpairedUsers = viCount;
          _caretakerUsers = ctCount;
          _mswdUsers = mswdCount;
          _totalUsers = totalCount;
        });
      }
      
      debugPrint('✅ Total System Users: $totalCount');
      debugPrint('   └─ Visually Impaired: $viCount');
      debugPrint('   └─ Caretakers: $ctCount');
      debugPrint('   └─ MSWD Staff: $mswdCount');
      
    } catch (e) {
      debugPrint('❌ Error fetching users: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        setState(() {
          _totalUsers = 0;
          _visuallyImpairedUsers = 0;
          _caretakerUsers = 0;
          _mswdUsers = 0;
        });
      }
    }
  }

  /// Helper method to count users in a specific path
  Future<int> _countUsersInPath(String path) async {
    try {
      debugPrint('   🔎 Querying path: $path');
      
      final snapshot = await FirebaseDatabase.instance
          .ref(path)
          .once();
      
      if (!snapshot.snapshot.exists) {
        debugPrint('   🔭 $path: 0 users (path empty)');
        return 0;
      }
      
      final data = snapshot.snapshot.value;
      
      // Handle different data types
      if (data is Map) {
        final count = data.length;
        debugPrint('   ✔️ $path: $count users found');
        return count;
      } else if (data is List) {
        final count = data.length;
        debugPrint('   ✔️ $path: $count users found (list format)');
        return count;
      } else {
        debugPrint('   ⚠️ $path: Unexpected data type: ${data.runtimeType}');
        return 0;
      }
      
    } catch (e) {
      debugPrint('   ❌ Error counting users in $path: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Breakdown',
          style: h3.copyWith(
            fontSize: 20,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildUserTypeCard(
          icon: Icons.visibility_off_rounded,
          label: 'Visually Impaired',
          value: _isLoading ? '...' : _visuallyImpairedUsers.toString(),
          color: Colors.purple,
          percentage: _totalUsers > 0 
              ? ((_visuallyImpairedUsers / _totalUsers) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
        SizedBox(height: spacingMedium),
        _buildUserTypeCard(
          icon: Icons.volunteer_activism_rounded,
          label: 'Caretakers',
          value: _isLoading ? '...' : _caretakerUsers.toString(),
          color: Colors.green,
          percentage: _totalUsers > 0 
              ? ((_caretakerUsers / _totalUsers) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
        SizedBox(height: spacingMedium),
        _buildUserTypeCard(
          icon: Icons.admin_panel_settings_rounded,
          label: 'MSWD Staff',
          value: _isLoading ? '...' : _mswdUsers.toString(),
          color: Colors.teal,
          percentage: _totalUsers > 0 
              ? ((_mswdUsers / _totalUsers) * 100).toStringAsFixed(1) 
              : '0.0',
        ),
      ],
    );
  }

  Widget _buildUserTypeCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String percentage,
  }) {
    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: color.withOpacity(0.2), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacingSmall),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: bodyBold.copyWith(
                    fontSize: 15,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$percentage% of total users',
                  style: caption.copyWith(
                    fontSize: 12,
                    color: widget.theme.subtextColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: h2.copyWith(
              fontSize: 28,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}