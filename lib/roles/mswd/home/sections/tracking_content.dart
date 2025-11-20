// File: lib/roles/mswd/home/sections/tracking_content.dart
// ignore_for_file: deprecated_member_use, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/admin_service.dart';
import 'dart:async';

class TrackingContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;

  const TrackingContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
  });

  @override
  State<TrackingContent> createState() => _TrackingContentState();
}

class _TrackingContentState extends State<TrackingContent> {
  StreamSubscription? _usersSubscription;
  List<Map<String, dynamic>> _viUsers = [];
  List<Map<String, dynamic>> _caretakers = [];
  bool _isLoading = true;
  String _selectedView = 'all'; // all, vi, caretakers

  @override
  void initState() {
    super.initState();
    _setupUsersStream();
  }

  void _setupUsersStream() {
    _usersSubscription = adminService.streamAllUsers().listen(
      (users) {
        if (mounted) {
          setState(() {
            _viUsers = users.where((u) => u['role'] == 'visually_impaired').toList();
            _caretakers = users.where((u) => u['role'] == 'caretaker').toList();
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // Header
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
              Text(
                'Live Tracking',
                style: h2.copyWith(
                  fontSize: 26,
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Real-time location monitoring',
                style: body.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 14,
                ),
              ),
              
              SizedBox(height: spacingLarge),
              
              // View Selector
              _buildViewSelector(),
            ],
          ),
        ),
        
        // Map Placeholder & User List
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : _buildTrackingView(),
        ),
      ],
    );
  }

  Widget _buildViewSelector() {
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
          _buildViewTab('all', Icons.people_rounded, 'All Users'),
          _buildViewTab('vi', Icons.visibility_off_rounded, 'VI Users'),
          _buildViewTab('caretakers', Icons.favorite_rounded, 'Caretakers'),
        ],
      ),
    );
  }

  Widget _buildViewTab(String value, IconData icon, String label) {
    final isSelected = _selectedView == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = value),
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
            'Loading tracking data...',
            style: body.copyWith(color: widget.theme.subtextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingView() {
    List<Map<String, dynamic>> displayUsers;
    
    switch (_selectedView) {
      case 'vi':
        displayUsers = _viUsers;
        break;
      case 'caretakers':
        displayUsers = _caretakers;
        break;
      default:
        displayUsers = [..._viUsers, ..._caretakers];
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width * 0.05,
        spacingMedium,
        MediaQuery.of(context).size.width * 0.05,
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Placeholder
          _buildMapPlaceholder(),
          
          SizedBox(height: spacingXLarge),
          
          // Active Users Stats
          _buildActiveUsersStats(displayUsers),
          
          SizedBox(height: spacingLarge),
          
          // User List
          if (displayUsers.isEmpty)
            _buildEmptyState()
          else
            ...displayUsers.map((user) {
              return Padding(
                padding: EdgeInsets.only(bottom: spacingMedium),
                child: _buildUserLocationCard(user),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
        border: widget.isDarkMode
            ? Border.all(color: primary.withOpacity(0.2), width: 1)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radiusXLarge),
        child: Stack(
          children: [
            // Map placeholder image or gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withOpacity(0.1),
                    accent.withOpacity(0.1),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      size: 64,
                      color: primary.withOpacity(0.3),
                    ),
                    SizedBox(height: spacingMedium),
                    Text(
                      'Interactive Map View',
                      style: bodyBold.copyWith(
                        fontSize: 16,
                        color: widget.theme.textColor,
                      ),
                    ),
                    SizedBox(height: spacingSmall),
                    Text(
                      'Real-time location tracking coming soon',
                      style: body.copyWith(
                        fontSize: 13,
                        color: widget.theme.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Map Controls Overlay
            Positioned(
              top: spacingMedium,
              right: spacingMedium,
              child: Column(
                children: [
                  _buildMapControl(Icons.add_rounded),
                  SizedBox(height: spacingSmall),
                  _buildMapControl(Icons.remove_rounded),
                  SizedBox(height: spacingSmall),
                  _buildMapControl(Icons.my_location_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(radiusMedium),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Icon(icon, color: primary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveUsersStats(List<Map<String, dynamic>> users) {
    final activeCount = users.where((u) => u['isActive'] == true).length;
    final inactiveCount = users.length - activeCount;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_rounded,
            label: 'Active',
            value: activeCount.toString(),
            color: Colors.green,
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule_rounded,
            label: 'Inactive',
            value: inactiveCount.toString(),
            color: grey,
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_rounded,
            label: 'Total',
            value: users.length.toString(),
            color: primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
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
              ? color.withOpacity(0.2)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: spacingSmall),
          Text(
            value,
            style: h2.copyWith(
              fontSize: 24,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: caption.copyWith(
              fontSize: 11,
              color: widget.theme.subtextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserLocationCard(Map<String, dynamic> user) {
    final role = user['role'] ?? '';
    final isActive = user['isActive'] ?? false;
    final name = user['name'] ?? 'Unknown';
    
    Color roleColor = role == 'visually_impaired' ? accent : Colors.green;
    IconData roleIcon = role == 'visually_impaired' 
        ? Icons.visibility_off_rounded 
        : Icons.favorite_rounded;

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
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('View $name on map'),
                backgroundColor: primary,
              ),
            );
          },
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                // Status Indicator
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            roleColor.withOpacity(0.2),
                            roleColor.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: roleColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          roleIcon,
                          color: roleColor,
                          size: 24,
                        ),
                      ),
                    ),
                    if (isActive)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.theme.cardColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                SizedBox(width: spacingMedium),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: bodyBold.copyWith(
                          fontSize: 17,
                          color: widget.theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: widget.theme.subtextColor,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isActive ? 'Last seen: Just now' : 'Location unavailable',
                              style: caption.copyWith(
                                fontSize: 13,
                                color: widget.theme.subtextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(radiusMedium),
                  ),
                  child: Icon(
                    Icons.navigation_rounded,
                    color: primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
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
                Icons.location_off_rounded,
                size: 64,
                color: primary.withOpacity(0.5),
              ),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'No users to track',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              'Users will appear here when they enable location tracking',
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
}