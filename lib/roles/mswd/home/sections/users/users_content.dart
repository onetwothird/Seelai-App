// File: lib/roles/mswd/home/sections/users_content.dart
// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'user_profile_screen.dart';

class UsersContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final ScrollController? scrollController;

  const UsersContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    this.scrollController,
  });

  @override
  State<UsersContent> createState() => _UsersContentState();
}

class _UsersContentState extends State<UsersContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFilter;
  bool _showProfileScreen = false;
  Map<String, dynamic>? _selectedUser;
  List<Map<String, dynamic>> _visuallyImpairedUsers = [];
  List<Map<String, dynamic>> _caretakersUsers = [];
  bool _isLoadingVI = true;
  bool _isLoadingCT = true;
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    await _loadVisuallyImpairedUsers();
    await _loadCaretakersUsers();
  }

  Future<void> _loadVisuallyImpairedUsers() async {
    try {
      final users = await adminService.getUsersByRole('visually_impaired');
      if (mounted) {
        setState(() {
          _visuallyImpairedUsers = users;
          _isLoadingVI = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingVI = false);
      }
      print('Error loading visually impaired users: $e');
    }
  }

  Future<void> _loadCaretakersUsers() async {
    try {
      final users = await adminService.getUsersByRole('caretaker');
      if (mounted) {
        setState(() {
          _caretakersUsers = users;
          _isLoadingCT = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCT = false);
      }
      print('Error loading caretakers: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredUsers(List<Map<String, dynamic>> users) {
    var filtered = users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = user['name']?.toString().toLowerCase() ?? '';
        if (!name.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // Status filter
      if (_selectedFilter != null && _selectedFilter!.contains('Status:')) {
        final status = user['isActive'] ?? true
            ? 'Active'
            : (user['deactivatedAt'] != null ? 'Suspended' : 'Pending');
        if (!_selectedFilter!.contains(status)) {
          return false;
        }
      }

      // Region filter
      if (_selectedFilter != null && _selectedFilter!.contains('Region:')) {
        final region = user['region'] ?? user['address'] ?? '';
        if (!_selectedFilter!.contains(region)) {
          return false;
        }
      }

      // Verified filter
      if (_selectedFilter == 'Verified Only') {
        if (user['verified'] != true) {
          return false;
        }
      }

      return true;
    }).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_showProfileScreen && _selectedUser != null) {
      return UserProfileScreen(
        isDarkMode: widget.isDarkMode,
        theme: widget.theme,
        selectedUser: _selectedUser!,
        scrollController: widget.scrollController,
        onBackPressed: () => setState(() => _showProfileScreen = false),
      );
    }

    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: spacingLarge),
          _buildSearchBar(),
          SizedBox(height: spacingMedium),
          _buildFilterButton(),
          SizedBox(height: spacingLarge),
          _buildTabBar(width),
          SizedBox(height: spacingLarge),
          _selectedTab == 0
              ? _buildVisuallyImpairedList()
              : _buildCaretakersList(),
          SizedBox(height: spacingLarge),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Management',
                style: h2.copyWith(
                  fontSize: 24,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage all registered users',
                style: body.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
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
        onChanged: (value) => setState(() => _searchQuery = value),
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
                  icon:
                      Icon(Icons.clear_rounded, color: widget.theme.subtextColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
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

  Widget _buildFilterButton() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusLarge),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showFilterOptions,
              borderRadius: BorderRadius.circular(radiusLarge),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacingMedium,
                  vertical: spacingMedium,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      color: primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Filter',
                      style: bodyBold.copyWith(
                        fontSize: 14,
                        color: widget.theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_selectedFilter != null) ...[
          SizedBox(width: spacingMedium),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacingMedium,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(color: primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Text(
                  _selectedFilter ?? '',
                  style: caption.copyWith(
                    fontSize: 12,
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _selectedFilter = null),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.cardColor,
      builder: (context) => Container(
        padding: EdgeInsets.all(spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by',
              style: h2.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: spacingMedium),
            _buildFilterOption('Status: Active'),
            _buildFilterOption('Status: Suspended'),
            SizedBox(height: spacingMedium),
            _buildFilterOption('Verified Only'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedFilter = label);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(radiusMedium),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: spacingMedium,
            horizontal: spacingMedium,
          ),
          child: Text(
            label,
            style: body.copyWith(
              color: widget.theme.textColor,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(double width) {
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
          _buildTab(0, Icons.visibility_off_rounded, 'Visually Impaired', primary),
          _buildTab(1, Icons.favorite_rounded, 'Caretakers', accent),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label, Color color) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(vertical: spacingMedium),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? white : widget.theme.subtextColor,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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

  Widget _buildVisuallyImpairedList() {
    if (_isLoadingVI) {
      return Center(child: CircularProgressIndicator());
    }

    final filteredUsers = _getFilteredUsers(_visuallyImpairedUsers);

    if (filteredUsers.isEmpty) {
      return Center(
        child: Text(
          'No visually impaired users found',
          style: body.copyWith(color: widget.theme.subtextColor),
        ),
      );
    }

    return Column(
      children: List.generate(
        filteredUsers.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildUserCard(filteredUsers[index]),
        ),
      ),
    );
  }

  Widget _buildCaretakersList() {
    if (_isLoadingCT) {
      return Center(child: CircularProgressIndicator());
    }

    final filteredCaretakers = _getFilteredUsers(_caretakersUsers);

    if (filteredCaretakers.isEmpty) {
      return Center(
        child: Text(
          'No caretakers found',
          style: body.copyWith(color: widget.theme.subtextColor),
        ),
      );
    }

    return Column(
      children: List.generate(
        filteredCaretakers.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildCaretakerCard(filteredCaretakers[index]),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['isActive'] ?? true;
    final status = isActive ? 'Active' : 'Inactive';
    final profileImageUrl = user['profileImageUrl'] as String?;
    final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: primary.withOpacity(0.2), width: 1)
            : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _selectedUser = user;
            _showProfileScreen = true;
          }),
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: hasProfileImage
                            ? null
                            : LinearGradient(
                                colors: [primary, primary.withOpacity(0.7)],
                              ),
                        border: Border.all(
                          color: widget.isDarkMode
                              ? primary.withOpacity(0.3)
                              : Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                        image: hasProfileImage
                            ? DecorationImage(
                                image: NetworkImage(profileImageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: !hasProfileImage
                          ? Center(
                              child: Text(
                                (user['name'] ?? 'U')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: h2.copyWith(
                                  color: white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user['name'] ?? 'Unknown',
                                  style: bodyBold.copyWith(
                                    fontSize: 16,
                                    color: widget.theme.textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacingSmall,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(radiusSmall),
                                ),
                                child: Text(
                                  status,
                                  style: caption.copyWith(
                                    fontSize: 10,
                                    color: isActive ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.cake_rounded,
                                size: 14,
                                color: widget.theme.subtextColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${user['age'] ?? 'N/A'} y/o',
                                style: caption.copyWith(
                                  fontSize: 13,
                                  color: widget.theme.subtextColor,
                                ),
                              ),
                              SizedBox(width: spacingMedium),
                              Icon(
                                Icons.visibility_off_rounded,
                                size: 14,
                                color: widget.theme.subtextColor,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  user['disabilityType'] ?? 'N/A',
                                  style: caption.copyWith(
                                    fontSize: 13,
                                    color: widget.theme.subtextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                if (user['verified'] == true) ...[
                  SizedBox(height: spacingMedium),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Verified',
                        style: caption.copyWith(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaretakerCard(Map<String, dynamic> caretaker) {
    final profileImageUrl = caretaker['profileImageUrl'] as String?;
    final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: accent.withOpacity(0.2), width: 1)
            : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _selectedUser = caretaker;
            _showProfileScreen = true;
          }),
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: hasProfileImage
                            ? null
                            : LinearGradient(
                                colors: [accent, accent.withOpacity(0.7)],
                              ),
                        border: Border.all(
                          color: widget.isDarkMode
                              ? accent.withOpacity(0.3)
                              : Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                        image: hasProfileImage
                            ? DecorationImage(
                                image: NetworkImage(profileImageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: !hasProfileImage
                          ? Center(
                              child: Icon(
                                Icons.favorite_rounded,
                                color: white,
                                size: 28,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caretaker['name'] ?? 'Unknown',
                            style: bodyBold.copyWith(
                              fontSize: 16,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${caretaker['age'] ?? 'N/A'} • ${(caretaker['assignedPatients'] as Map?)?.length ?? 0} patients',
                                style: caption.copyWith(
                                  fontSize: 12,
                                  color: widget.theme.subtextColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            caretaker['relationship'] ?? 'Caretaker',
                            style: caption.copyWith(
                              fontSize: 12,
                              color: widget.theme.subtextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}