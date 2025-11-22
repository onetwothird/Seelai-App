// File: lib/roles/mswd/home/sections/users_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (_showProfileScreen && _selectedUser != null) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        physics: ClampingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            _buildProfileHeader(),
            SizedBox(height: spacingLarge),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: _buildProfileContent(),
            ),
          ],
        ),
      );
    }

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
            _buildFilterOption('Status: Pending'),
            _buildFilterOption('Status: Suspended'),
            SizedBox(height: spacingMedium),
            _buildFilterOption('Region: Metro Manila'),
            _buildFilterOption('Region: Luzon'),
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
    final users = [
      {
        'name': 'Maria Santos',
        'age': 45,
        'disability': 'Total Blindness',
        'status': 'Active',
        'profileImage': null,
        'region': 'Metro Manila',
        'verified': true,
        'emergencyContact': 'Rosa Santos',
        'contactNumber': '0912-345-6789',
        'address': '123 Main St, Manila',
        'assignedCaregivers': ['Rosa Martinez', 'Juan Reyes'],
        'recentActivities': [
          {'date': '2024-01-15', 'activity': 'Check-up completed'},
          {'date': '2024-01-14', 'activity': 'Appointment scheduled'},
        ],
      },
      {
        'name': 'Juan Dela Cruz',
        'age': 52,
        'disability': 'Low Vision',
        'status': 'Active',
        'profileImage': null,
        'region': 'Luzon',
        'verified': true,
        'emergencyContact': 'Maria Dela Cruz',
        'contactNumber': '0912-123-4567',
        'address': '456 Oak Ave, Quezon City',
        'assignedCaregivers': ['Carlos Reyes'],
        'recentActivities': [
          {'date': '2024-01-16', 'activity': 'Location shared'},
        ],
      },
      {
        'name': 'Pedro Garcia',
        'age': 38,
        'disability': 'Partial Blindness',
        'status': 'Pending',
        'profileImage': null,
        'region': 'Metro Manila',
        'verified': false,
        'emergencyContact': 'Anna Garcia',
        'contactNumber': '0912-789-0123',
        'address': '789 Pine Rd, Manila',
        'assignedCaregivers': [],
        'recentActivities': [],
      },
    ];

    return Column(
      children: List.generate(
        users.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildUserCard(users[index]),
        ),
      ),
    );
  }

  Widget _buildCaretakersList() {
    final caretakers = [
      {
        'name': 'Rosa Martinez',
        'age': 35,
        'relationship': 'Family Member',
        'patients': 2,
        'status': 'Active',
        'profileImage': null,
        'rating': 4.8,
        'responseTime': '2.5 hrs',
        'assignedPatients': ['Maria Santos', 'Juan Dela Cruz'],
        'requestStats': {
          'total': 145,
          'completed': 140,
          'pending': 5,
        },
      },
      {
        'name': 'Carlos Reyes',
        'age': 42,
        'relationship': 'Professional Caregiver',
        'patients': 5,
        'status': 'Active',
        'profileImage': null,
        'rating': 4.9,
        'responseTime': '1.8 hrs',
        'assignedPatients': [
          'Pedro Garcia',
          'Ana Santos',
          'Luis Cruz',
          'Marta Lopez',
          'Diego Fernandez'
        ],
        'requestStats': {
          'total': 312,
          'completed': 305,
          'pending': 7,
        },
      },
    ];

    return Column(
      children: List.generate(
        caretakers.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildCaretakerCard(caretakers[index]),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['status'] == 'Active';

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
                        gradient: LinearGradient(
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
                      ),
                      child: Center(
                        child: Text(
                          user['name'].toString().substring(0, 1).toUpperCase(),
                          style: h2.copyWith(
                            color: white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                                  user['name'],
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
                                  user['status'],
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
                                '${user['age']} y/o',
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
                                  user['disability'],
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
                        gradient: LinearGradient(
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
                      ),
                      child: Center(
                        child: Icon(
                          Icons.favorite_rounded,
                          color: white,
                          size: 28,
                        ),
                      ),
                    ),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caretaker['name'],
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
                                '${caretaker['rating']} • ${caretaker['patients']} patients',
                                style: caption.copyWith(
                                  fontSize: 12,
                                  color: widget.theme.subtextColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            caretaker['relationship'],
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

  Widget _buildProfileContent() {
    final isCaretaker = _selectedUser!.containsKey('rating');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCaretaker)
          _buildPersonalInfoSection(_selectedUser!)
        else
          _buildCaretakerPersonalInfo(_selectedUser!),
        SizedBox(height: spacingLarge),
        if (!isCaretaker) _buildMedicalInfoSection(_selectedUser!),
        if (!isCaretaker)
          _buildEmergencyContactSection(_selectedUser!)
        else
          _buildAssignedPatientsSection(_selectedUser!),
        if (!isCaretaker)
          _buildAssignedCaretakersSection(_selectedUser!)
        else
          _buildRequestStatisticsSection(_selectedUser!),
        if (!isCaretaker) _buildRecentActivitiesSection(_selectedUser!),
        SizedBox(height: spacingLarge),
        _buildActionButtons(isCaretaker),
        SizedBox(height: spacingLarge),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final name = _selectedUser!['name'];
    final statusColor =
        _selectedUser!['status'] == 'Active' ? Colors.green : Colors.orange;

    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(radiusXLarge),
          bottomRight: Radius.circular(radiusXLarge),
        ),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showProfileScreen = false),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: widget.theme.textColor,
                  size: 24,
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Text(
                  'Profile',
                  style: h2.copyWith(
                    fontSize: 20,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacingLarge),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primary, primary.withOpacity(0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.toString().substring(0, 1).toUpperCase(),
                style: h2.copyWith(
                  color: white,
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: spacingMedium),
          Text(
            name,
            style: h2.copyWith(
              fontSize: 22,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: spacingMedium, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Text(
              _selectedUser!['status'],
              style: caption.copyWith(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(Map<String, dynamic> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildInfoCard('Age', '${user['age']} years old', Icons.cake_rounded),
        _buildInfoCard('Region', user['region'] ?? 'N/A', Icons.location_on_rounded),
        _buildInfoCard('Address', user['address'] ?? 'N/A', Icons.home_rounded),
      ],
    );
  }

  Widget _buildCaretakerPersonalInfo(Map<String, dynamic> caretaker) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildInfoCard('Age', '${caretaker['age']} years old', Icons.cake_rounded),
        _buildInfoCard('Type', caretaker['relationship'] ?? 'N/A', Icons.badge_rounded),
        _buildInfoCard('Status', caretaker['status'] ?? 'Active', Icons.check_circle_rounded),
      ],
    );
  }

  Widget _buildMedicalInfoSection(Map<String, dynamic> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical Information',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildInfoCard(
          'Disability Type',
          user['disability'] ?? 'N/A',
          Icons.visibility_off_rounded,
        ),
        _buildInfoCard(
          'Verification Status',
          user['verified'] == true ? 'Verified' : 'Unverified',
          Icons.verified_rounded,
          color: user['verified'] == true ? Colors.blue : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildEmergencyContactSection(Map<String, dynamic> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Contact',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        Container(
          padding: EdgeInsets.all(spacingMedium),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusLarge),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['emergencyContact'] ?? 'N/A',
                style: bodyBold.copyWith(
                  fontSize: 14,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.phone_rounded,
                    size: 16,
                    color: primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    user['contactNumber'] ?? 'N/A',
                    style: body.copyWith(
                      fontSize: 13,
                      color: widget.theme.subtextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedCaretakersSection(Map<String, dynamic> user) {
    final caregivers = user['assignedCaregivers'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned Caretakers (${caregivers.length})',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        if (caregivers.isEmpty)
          Text(
            'No caretakers assigned',
            style: body.copyWith(
              fontSize: 13,
              color: widget.theme.subtextColor,
            ),
          )
        else
          Column(
            children: List.generate(
              caregivers.length,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: spacingMedium),
                child: Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    color: widget.theme.cardColor,
                    borderRadius: BorderRadius.circular(radiusLarge),
                    border: Border.all(
                      color: widget.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [accent, accent.withOpacity(0.7)],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.favorite_rounded,
                            color: white,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: spacingMedium),
                      Expanded(
                        child: Text(
                          caregivers[index].toString(),
                          style: body.copyWith(
                            fontSize: 13,
                            color: widget.theme.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssignedPatientsSection(Map<String, dynamic> caretaker) {
    final patients = caretaker['assignedPatients'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned Patients (${patients.length})',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        Column(
          children: List.generate(
            patients.length,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: spacingMedium),
              child: Container(
                padding: EdgeInsets.all(spacingMedium),
                decoration: BoxDecoration(
                  color: widget.theme.cardColor,
                  borderRadius: BorderRadius.circular(radiusLarge),
                  border: Border.all(
                    color: widget.isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [primary, primary.withOpacity(0.7)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          patients[index].toString().substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: Text(
                        patients[index].toString(),
                        style: body.copyWith(
                          fontSize: 13,
                          color: widget.theme.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestStatisticsSection(Map<String, dynamic> caretaker) {
    final stats = caretaker['requestStats'] as Map<String, dynamic>? ?? {};
    final responseTime = caretaker['responseTime'] as String? ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Requests',
                '${stats['total'] ?? 0}',
                Icons.list_rounded,
                primary,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildStatCard(
                'Completed',
                '${stats['completed'] ?? 0}',
                Icons.check_circle_rounded,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: spacingMedium),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending',
                '${stats['pending'] ?? 0}',
                Icons.schedule_rounded,
                Colors.orange,
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: _buildStatCard(
                'Avg Response Time',
                responseTime,
                Icons.timer_rounded,
                accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: caption.copyWith(
                    fontSize: 11,
                    color: widget.theme.subtextColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: h2.copyWith(
              fontSize: 18,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesSection(Map<String, dynamic> user) {
    final activities = user['recentActivities'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        if (activities.isEmpty)
          Text(
            'No recent activities',
            style: body.copyWith(
              fontSize: 13,
              color: widget.theme.subtextColor,
            ),
          )
        else
          Column(
            children: List.generate(
              activities.length,
              (index) {
                final activity = activities[index] as Map<String, dynamic>;
                return Padding(
                  padding: EdgeInsets.only(bottom: spacingMedium),
                  child: Container(
                    padding: EdgeInsets.all(spacingMedium),
                    decoration: BoxDecoration(
                      color: widget.theme.cardColor,
                      borderRadius: BorderRadius.circular(radiusLarge),
                      border: Border.all(
                        color: widget.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary.withOpacity(0.1),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: primary,
                            ),
                          ),
                        ),
                        SizedBox(width: spacingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity['activity'] ?? 'Activity',
                                style: body.copyWith(
                                  fontSize: 13,
                                  color: widget.theme.textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                activity['date'] ?? 'N/A',
                                style: caption.copyWith(
                                  fontSize: 11,
                                  color: widget.theme.subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Container(
        padding: EdgeInsets.all(spacingMedium),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          border: Border.all(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (color ?? primary).withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: color ?? primary,
                ),
              ),
            ),
            SizedBox(width: spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: caption.copyWith(
                      fontSize: 11,
                      color: widget.theme.subtextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: body.copyWith(
                      fontSize: 13,
                      color: widget.theme.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isCaretaker) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isCaretaker) ...[
          _buildActionButton(
            'Call User',
            Icons.call_rounded,
            primary,
            () {},
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            'View Location',
            Icons.location_on_rounded,
            accent,
            () {},
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            'Suspend Account',
            Icons.block_rounded,
            Colors.red,
            () {},
            outlined: true,
          ),
        ] else ...[
          _buildActionButton(
            'View Performance',
            Icons.analytics_rounded,
            primary,
            () {},
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            'Message Caretaker',
            Icons.message_rounded,
            accent,
            () {},
          ),
        ],
        SizedBox(height: spacingMedium),
        _buildActionButton(
          'More Options',
          Icons.more_horiz_rounded,
          Colors.grey,
          () {},
          outlined: true,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: outlined
            ? Border.all(color: color.withOpacity(0.3))
            : Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusLarge),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacingMedium,
              vertical: spacingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
                SizedBox(width: 8),
                Text(
                  label,
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}