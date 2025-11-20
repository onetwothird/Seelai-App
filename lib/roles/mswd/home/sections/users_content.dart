// File: lib/roles/mswd/home/sections/users_content.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/admin_service.dart';
import 'dart:async';

class UsersContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;

  const UsersContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
  });

  @override
  State<UsersContent> createState() => _UsersContentState();
}

class _UsersContentState extends State<UsersContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _usersSubscription;
  
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _currentFilter = 'all'; // all, visually_impaired, caretaker, admin
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _currentFilter = ['all', 'visually_impaired', 'caretaker', 'admin'][_tabController.index];
          _applyFilters();
        });
      }
    });
    _setupUsersStream();
  }

  void _setupUsersStream() {
    _usersSubscription = adminService.streamAllUsers().listen(
      (users) {
        if (mounted) {
          setState(() {
            _allUsers = users;
            _applyFilters();
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = 'Failed to load users: $error';
            _isLoading = false;
          });
        }
      },
    );
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _allUsers;
    
    // Filter by role
    if (_currentFilter != 'all') {
      filtered = filtered.where((user) => user['role'] == _currentFilter).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final role = (user['role'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        return name.contains(query) || email.contains(query) || role.contains(query);
      }).toList();
    }
    
    setState(() {
      _filteredUsers = filtered;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usersSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshUsers() async {
    setState(() => _isLoading = true);
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      child: Column(
        children: [
          // Header with search
          Container(
            padding: EdgeInsets.fromLTRB(
              width * 0.05,
              spacingMedium,
              width * 0.05,
              spacingSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Management',
                            style: h2.copyWith(
                              fontSize: 26,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _filteredUsers.isEmpty
                                ? 'No users found'
                                : '${_filteredUsers.length} user${_filteredUsers.length != 1 ? 's' : ''}',
                            style: body.copyWith(
                              color: widget.theme.subtextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add User Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.circular(radiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Add user feature coming soon'),
                                backgroundColor: primary,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(radiusLarge),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.person_add_rounded, color: white, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: spacingLarge),
                
                // Search Bar
                _buildSearchBar(),
                
                SizedBox(height: spacingMedium),
                
                // Tab Bar
                _buildTabBar(),
              ],
            ),
          ),
          
          // User List
          Expanded(
            child: _isLoading && _allUsers.isEmpty
                ? _buildLoadingState()
                : _error != null && _allUsers.isEmpty
                    ? _buildErrorState()
                    : _filteredUsers.isEmpty
                        ? _buildEmptyState()
                        : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: _searchController,
        style: body.copyWith(color: widget.theme.textColor),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilters();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search users...',
          hintStyle: body.copyWith(color: widget.theme.subtextColor),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: widget.theme.subtextColor,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: widget.theme.subtextColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
        border: widget.isDarkMode
            ? Border.all(color: primary.withOpacity(0.2), width: 1)
            : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.people_rounded, 'All'),
          _buildTab(1, Icons.visibility_off_rounded, 'VI'),
          _buildTab(2, Icons.favorite_rounded, 'Caretakers'),
          _buildTab(3, Icons.admin_panel_settings_rounded, 'Admins'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isSelected = _tabController.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(vertical: spacingMedium),
          decoration: BoxDecoration(
            gradient: isSelected ? primaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? white : widget.theme.subtextColor,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? white : widget.theme.subtextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primary),
            strokeWidth: 3,
          ),
          SizedBox(height: spacingLarge),
          Text(
            'Loading users...',
            style: body.copyWith(color: widget.theme.subtextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(spacingXLarge),
              decoration: BoxDecoration(
                color: error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: error,
              ),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'Failed to load users',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              _error ?? 'An error occurred',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacingLarge),
            ElevatedButton.icon(
              onPressed: () => _refreshUsers(),
              icon: Icon(Icons.refresh_rounded),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(
                  horizontal: spacingXLarge,
                  vertical: spacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(spacingXLarge),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: primary.withOpacity(0.5),
              ),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'No users found',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search'
                  : 'No users in this category yet',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width * 0.05,
        spacingMedium,
        MediaQuery.of(context).size.width * 0.05,
        100,
      ),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildUserCard(user),
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? '';
    final isActive = user['isActive'] ?? true;
    final name = user['name'] ?? 'Unknown';
    final email = user['email'] ?? 'No email';
    final profileImageUrl = user['profileImageUrl'] as String?;

    Color roleColor;
    IconData roleIcon;
    String roleLabel;

    switch (role) {
      case 'visually_impaired':
        roleColor = accent;
        roleIcon = Icons.visibility_off_rounded;
        roleLabel = 'VI User';
        break;
      case 'caretaker':
        roleColor = Colors.green;
        roleIcon = Icons.favorite_rounded;
        roleLabel = 'Caretaker';
        break;
      case 'admin':
        roleColor = Colors.purple;
        roleIcon = Icons.admin_panel_settings_rounded;
        roleLabel = 'Admin';
        break;
      default:
        roleColor = grey;
        roleIcon = Icons.person_rounded;
        roleLabel = 'User';
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: roleColor.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
        border: Border.all(
          color: widget.isDarkMode
              ? roleColor.withOpacity(0.2)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserDetails(user),
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                // Profile Avatar
                _buildProfileAvatar(profileImageUrl, roleColor),
                SizedBox(width: spacingMedium),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: bodyBold.copyWith(
                                fontSize: 18,
                                color: widget.theme.textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacingSmall,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isActive ? Colors.green : grey).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(radiusSmall),
                            ),
                            child: Text(
                              isActive ? 'ACTIVE' : 'INACTIVE',
                              style: caption.copyWith(
                                fontSize: 10,
                                color: isActive ? Colors.green : grey,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      // Email
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 14, color: widget.theme.subtextColor),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: caption.copyWith(
                                fontSize: 13,
                                color: widget.theme.subtextColor,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      // Role
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacingSmall,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(radiusSmall),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(roleIcon, size: 12, color: roleColor),
                                SizedBox(width: 4),
                                Text(
                                  roleLabel,
                                  style: caption.copyWith(
                                    fontSize: 12,
                                    color: roleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: widget.theme.subtextColor.withOpacity(0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String? profileImageUrl, Color roleColor) {
    final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasProfileImage
            ? null
            : LinearGradient(
                colors: [roleColor.withOpacity(0.2), roleColor.withOpacity(0.1)],
              ),
        border: Border.all(
          color: widget.isDarkMode ? roleColor.withOpacity(0.3) : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: roleColor.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: hasProfileImage
            ? Image.network(
                profileImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar(roleColor);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(roleColor),
                    ),
                  );
                },
              )
            : _buildDefaultAvatar(roleColor),
      ),
    );
  }

  Widget _buildDefaultAvatar(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: color,
          size: 28,
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final isActive = user['isActive'] ?? true;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXLarge)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.theme.subtextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: spacingLarge),
            Text(
              user['name'] ?? 'User Details',
              style: h2.copyWith(
                fontSize: 20,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: spacingLarge),
            ListTile(
              leading: Icon(Icons.info_outline_rounded, color: primary),
              title: Text('View Details', style: body.copyWith(color: widget.theme.textColor)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('View details feature coming soon'),
                    backgroundColor: primary,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                color: isActive ? error : Colors.green,
              ),
              title: Text(
                isActive ? 'Deactivate Account' : 'Activate Account',
                style: body.copyWith(color: widget.theme.textColor),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await _showConfirmDialog(
                  isActive ? 'Deactivate User' : 'Activate User',
                  'Are you sure you want to ${isActive ? 'deactivate' : 'activate'} this user?',
                  isDanger: isActive,
                );
                
                if (confirmed == true) {
                  try {
                    if (isActive) {
                      await adminService.deactivateUser(
                        user['userId'] ?? '',
                        user['role'] ?? '',
                      );
                    } else {
                      await adminService.reactivateUser(
                        user['userId'] ?? '',
                        user['role'] ?? '',
                      );
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('User ${isActive ? 'deactivated' : 'activated'} successfully'),
                          backgroundColor: success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: error,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            SizedBox(height: spacingSmall),
          ],
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
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        title: Row(
          children: [
            Icon(
              isDanger ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
              color: isDanger ? error : primary,
              size: 24,
            ),
            SizedBox(width: spacingSmall),
            Expanded(
              child: Text(
                title,
                style: bodyBold.copyWith(
                  fontSize: 16,
                  color: widget.theme.textColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: body.copyWith(
            fontSize: 14,
            color: widget.theme.subtextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: body.copyWith(color: widget.theme.subtextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? error : primary,
              foregroundColor: white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
              ),
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}