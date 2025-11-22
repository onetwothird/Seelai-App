// File: lib/roles/mswd/home/sections/users_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

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
  int _selectedTab = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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

    return Padding(
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          
          SizedBox(height: spacingLarge),
          
          // Search Bar
          _buildSearchBar(),
          
          SizedBox(height: spacingLarge),
          
          // Tab Bar
          _buildTabBar(width),
          
          SizedBox(height: spacingLarge),
          
          // Tab Content
          Expanded(
            child: _selectedTab == 0
                ? _buildVisuallyImpairedList()
                : _buildCaretakersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(spacingMedium),
          decoration: BoxDecoration(
            gradient: primaryGradient,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.people_rounded,
            color: white,
            size: 24,
          ),
        ),
        SizedBox(width: spacingMedium),
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
    // Mock data - replace with actual data from Firebase
    final users = [
      {
        'name': 'Maria Santos',
        'age': 45,
        'disability': 'Total Blindness',
        'status': 'Active',
        'profileImage': null,
      },
      {
        'name': 'Juan Dela Cruz',
        'age': 52,
        'disability': 'Low Vision',
        'status': 'Active',
        'profileImage': null,
      },
      {
        'name': 'Pedro Garcia',
        'age': 38,
        'disability': 'Partial Blindness',
        'status': 'Pending',
        'profileImage': null,
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildUserCard(user, primary),
        );
      },
    );
  }

  Widget _buildCaretakersList() {
    // Mock data - replace with actual data from Firebase
    final caretakers = [
      {
        'name': 'Rosa Martinez',
        'age': 35,
        'relationship': 'Family Member',
        'patients': 2,
        'status': 'Active',
        'profileImage': null,
      },
      {
        'name': 'Carlos Reyes',
        'age': 42,
        'relationship': 'Professional Caregiver',
        'patients': 5,
        'status': 'Active',
        'profileImage': null,
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: caretakers.length,
      itemBuilder: (context, index) {
        final caretaker = caretakers[index];
        return Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildCaretakerCard(caretaker),
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, Color accentColor) {
    final isActive = user['status'] == 'Active';
    
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: accentColor.withOpacity(0.2), width: 1)
            : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('View ${user['name']} details')),
            );
          },
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                // Profile Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.7)],
                    ),
                    border: Border.all(
                      color: widget.isDarkMode 
                          ? accentColor.withOpacity(0.3) 
                          : Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.2),
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
                
                // User Info
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
                      SizedBox(height: 6),
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
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('View ${caretaker['name']} details')),
            );
          },
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                // Profile Avatar
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
                
                // Caretaker Info
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
                            Icons.badge_rounded,
                            size: 14,
                            color: widget.theme.subtextColor,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              caretaker['relationship'],
                              style: caption.copyWith(
                                fontSize: 13,
                                color: widget.theme.subtextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 14,
                            color: widget.theme.subtextColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${caretaker['patients']} patient${caretaker['patients'] != 1 ? 's' : ''}',
                            style: caption.copyWith(
                              fontSize: 13,
                              color: widget.theme.subtextColor,
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
}