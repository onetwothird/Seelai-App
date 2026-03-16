// File: lib/roles/mswd/home/sections/users/users_content.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'user_profile_screen.dart';

class UsersContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final ScrollController? scrollController;
  final VoidCallback? onNavigateToLocation; 

  const UsersContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    this.scrollController,
    this.onNavigateToLocation,
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
  
  List<Map<String, dynamic>> _partiallySightedUsers = [];
  List<Map<String, dynamic>> _caretakersUsers = [];
  List<Map<String, dynamic>> _pendingCaretakers = []; // New List for Pending
  
  bool _isLoadingVI = true;
  bool _isLoadingCT = true;
  bool _isLoadingPending = true;

  @override
  void initState() {
    super.initState();
    // CHANGED: Increased length to 3 to accommodate the "Requests" tab
    _tabController = TabController(length: 3, vsync: this);
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
    await _loadPendingCaretakers(); // Load pending
  }

  Future<void> _loadVisuallyImpairedUsers() async {
    try {
      final users = await adminService.getUsersByRole('partially_sighted');
      if (mounted) {
        setState(() {
          _partiallySightedUsers = users;
          _isLoadingVI = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVI = false);
    }
  }

  Future<void> _loadCaretakersUsers() async {
    try {
      // We load all caretakers, then filter for APPROVED ones
      final users = await adminService.getUsersByRole('caretaker');
      if (mounted) {
        setState(() {
          // Only show approved caretakers in the main list
          _caretakersUsers = users.where((u) => u['approved'] == true).toList();
          _isLoadingCT = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCT = false);
    }
  }

  Future<void> _loadPendingCaretakers() async {
    try {
      // Use the specific service method for pending
      final users = await adminService.getPendingCaretakers();
      if (mounted) {
        setState(() {
          _pendingCaretakers = users;
          _isLoadingPending = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredUsers(List<Map<String, dynamic>> users) {
    var filtered = users.where((user) {
      if (_searchQuery.isNotEmpty) {
        final name = user['name']?.toString().toLowerCase() ?? '';
        if (!name.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    return filtered;
  }

  void _navigateToProfile(Map<String, dynamic> user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          isDarkMode: widget.isDarkMode,
          theme: widget.theme,
          selectedUser: user,
          onViewLocation: widget.onNavigateToLocation,
          // Callback to refresh list when returning (in case a user was approved)
          onDataChanged: _loadUsers,
        ),
      ),
    );
    // Reload users when coming back
    _loadUsers(); 
  }

 @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const ClampingScrollPhysics(),
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
          SizedBox(height: spacingLarge),
          _buildTabBar(width),
          SizedBox(height: spacingLarge),
          _buildTabContent(), // Refactored to switch statement
          SizedBox(height: spacingLarge),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildVisuallyImpairedList();
      case 1:
        return _buildCaretakersList();
      case 2:
        return _buildPendingList();
      default:
        return const SizedBox();
    }
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
              const SizedBox(height: 4),
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
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: widget.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                  icon: Icon(Icons.clear_rounded, color: widget.theme.subtextColor),
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

  Widget _buildTabBar(double width) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
        border: widget.isDarkMode
            ? Border.all(color: primary.withValues(alpha: 0.2), width: 1)
            : Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1),
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.visibility_off_rounded, 'Patients', primary),
          _buildTab(1, Icons.favorite_rounded, 'Caretakers', accent),
          _buildTab(2, Icons.verified_user_rounded, 'Requests', Colors.orange),
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(vertical: spacingMedium),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column( // Changed Row to Column for small screens, or keep Row if space permits
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? white : widget.theme.subtextColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10, // Slightly smaller to fit 3 tabs
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? white : widget.theme.subtextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisuallyImpairedList() {
    if (_isLoadingVI) return const Center(child: CircularProgressIndicator());

    final filteredUsers = _getFilteredUsers(_partiallySightedUsers);

    if (filteredUsers.isEmpty) {
      return Center(
        child: Text(
          'No partially sighted users found',
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
    if (_isLoadingCT) return const Center(child: CircularProgressIndicator());

    final filteredCaretakers = _getFilteredUsers(_caretakersUsers);

    if (filteredCaretakers.isEmpty) {
      return Center(
        child: Text(
          'No approved caretakers found',
          style: body.copyWith(color: widget.theme.subtextColor),
        ),
      );
    }

    return Column(
      children: List.generate(
        filteredCaretakers.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildCaretakerCard(filteredCaretakers[index], isPending: false),
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    if (_isLoadingPending) return const Center(child: CircularProgressIndicator());

    final filteredPending = _getFilteredUsers(_pendingCaretakers);

    if (filteredPending.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(Icons.check_circle_outline_rounded, size: 48, color: widget.theme.subtextColor.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text(
              'No pending requests',
              style: body.copyWith(color: widget.theme.subtextColor),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(
        filteredPending.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildCaretakerCard(filteredPending[index], isPending: true),
        ),
      ),
    );
  }

 Widget _buildUserCard(Map<String, dynamic> user) {
    // ... [Logic for User Card - Same as previous, kept brief for focus] ...
    // Note: Copied from your original file, no logic changes needed here
    final profileImageUrl = user['profileImageUrl'] as String?;
    final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: primary.withValues(alpha: 0.2), width: 1)
            : Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToProfile(user),
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade900,
                  ),
                  child: ClipOval(
                    child: hasProfileImage
                        ? Image.network(profileImageUrl, fit: BoxFit.cover, errorBuilder: (_,_,_) => _buildDefaultAvatarText(user['name'] ?? 'U', primary))
                        : _buildDefaultAvatarText(user['name'] ?? 'U', primary),
                  ),
                ),
                SizedBox(width: spacingMedium),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? 'Unknown', style: bodyBold.copyWith(color: widget.theme.textColor)),
                      Text(user['disabilityType'] ?? 'Patient', style: caption.copyWith(color: widget.theme.subtextColor)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: widget.theme.subtextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaretakerCard(Map<String, dynamic> caretaker, {required bool isPending}) {
    final profileImageUrl = caretaker['profileImageUrl'] as String?;
    final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;
    final color = isPending ? Colors.orange : accent;

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: color.withValues(alpha: 0.2), width: 1)
            : Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToProfile(caretaker),
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
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: ClipOval(
                        child: hasProfileImage
                            ? Image.network(
                                profileImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildDefaultAvatarText(caretaker['name'] ?? 'U', color),
                              )
                            : _buildDefaultAvatarText(caretaker['name'] ?? 'U', color),
                      ),
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
                                  caretaker['name'] ?? 'Unknown',
                                  style: bodyBold.copyWith(
                                    fontSize: 16,
                                    color: widget.theme.textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isPending)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "PENDING",
                                    style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
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

  Widget _buildDefaultAvatarText(String name, Color baseColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [baseColor, baseColor.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: h2.copyWith(
            color: white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}