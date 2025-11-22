// File: lib/roles/mswd/screens/location_tracking_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class LocationTrackingScreen extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;

  const LocationTrackingScreen({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<LocationTrackingScreen> createState() => _LocationTrackingScreenState();
}

class _LocationTrackingScreenState extends State<LocationTrackingScreen> {
  String _selectedFilter = 'All';
  bool _showLegend = true;
  final List<String> _filters = ['All', 'Visually Impaired', 'Caretakers', 'Emergency'];

  final List<Map<String, dynamic>> _users = [
    {'name': 'Maria Santos', 'type': 'vi', 'status': 'active', 'location': 'Makati City', 'lat': 14.5547, 'lng': 121.0244, 'lastUpdate': '2 mins ago'},
    {'name': 'Juan Dela Cruz', 'type': 'vi', 'status': 'emergency', 'location': 'Quezon City', 'lat': 14.6760, 'lng': 121.0437, 'lastUpdate': 'Just now'},
    {'name': 'Rosa Martinez', 'type': 'caretaker', 'status': 'active', 'location': 'Taguig City', 'lat': 14.5176, 'lng': 121.0509, 'lastUpdate': '5 mins ago'},
    {'name': 'Pedro Garcia', 'type': 'vi', 'status': 'active', 'location': 'Pasig City', 'lat': 14.5764, 'lng': 121.0851, 'lastUpdate': '10 mins ago'},
    {'name': 'Carlos Reyes', 'type': 'caretaker', 'status': 'active', 'location': 'Mandaluyong', 'lat': 14.5794, 'lng': 121.0359, 'lastUpdate': '3 mins ago'},
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    if (_selectedFilter == 'All') return _users;
    if (_selectedFilter == 'Visually Impaired') return _users.where((u) => u['type'] == 'vi').toList();
    if (_selectedFilter == 'Caretakers') return _users.where((u) => u['type'] == 'caretaker').toList();
    if (_selectedFilter == 'Emergency') return _users.where((u) => u['status'] == 'emergency').toList();
    return _users;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: widget.theme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Stack(
                  children: [
                    _buildMapView(),
                    Positioned(top: spacingMedium, left: spacingMedium, right: spacingMedium, child: _buildFilterChips()),
                    if (_showLegend) Positioned(bottom: spacingMedium, left: spacingMedium, child: _buildLegend()),
                    Positioned(bottom: spacingMedium, right: spacingMedium, child: _buildMapControls()),
                  ],
                ),
              ),
              _buildUserList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final emergencyCount = _users.where((u) => u['status'] == 'emergency').length;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_rounded, color: widget.theme.textColor),
          ),
          Expanded(
            child: Text('Location Tracking', style: h3.copyWith(color: widget.theme.textColor, fontWeight: FontWeight.w700)),
          ),
          if (emergencyCount > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: error, borderRadius: BorderRadius.circular(radiusMedium)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_rounded, color: white, size: 14),
                  SizedBox(width: 4),
                  Text('$emergencyCount Emergency', style: caption.copyWith(color: white, fontWeight: FontWeight.w700, fontSize: 11)),
                ],
              ),
            ),
          SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _showLegend = !_showLegend),
            icon: Icon(Icons.layers_rounded, color: widget.theme.textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final isSelected = _selectedFilter == f;
          final color = f == 'Emergency' ? error : f == 'Caretakers' ? accent : f == 'Visually Impaired' ? primary : widget.theme.subtextColor;
          
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : widget.theme.cardColor,
                  borderRadius: BorderRadius.circular(radiusLarge),
                  border: Border.all(color: isSelected ? color : widget.theme.subtextColor.withOpacity(0.3)),
                  boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)] : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (f == 'Emergency') Icon(Icons.warning_rounded, size: 14, color: isSelected ? white : color),
                    if (f == 'Caretakers') Icon(Icons.favorite_rounded, size: 14, color: isSelected ? white : color),
                    if (f == 'Visually Impaired') Icon(Icons.visibility_off_rounded, size: 14, color: isSelected ? white : color),
                    if (f == 'All') Icon(Icons.people_rounded, size: 14, color: isSelected ? white : widget.theme.subtextColor),
                    SizedBox(width: 6),
                    Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? white : widget.theme.textColor)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      color: widget.isDarkMode ? Color(0xFF1A1F3A) : Colors.grey[200],
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_rounded, size: 80, color: widget.theme.subtextColor.withOpacity(0.3)),
                SizedBox(height: spacingMedium),
                Text('Interactive Map', style: body.copyWith(color: widget.theme.subtextColor)),
                Text('Showing ${_filteredUsers.length} users', style: caption.copyWith(color: widget.theme.subtextColor.withOpacity(0.7))),
              ],
            ),
          ),
          ..._filteredUsers.asMap().entries.map((e) {
            final i = e.key;
            final user = e.value;
            final isEmergency = user['status'] == 'emergency';
            final isCaretaker = user['type'] == 'caretaker';
            final color = isEmergency ? error : isCaretaker ? accent : primary;
            
            return Positioned(
              left: 50.0 + (i * 60),
              top: 150.0 + (i * 40),
              child: GestureDetector(
                onTap: () => _showUserDetails(user),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: white, width: 2),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)],
                      ),
                      child: Icon(
                        isEmergency ? Icons.warning_rounded : isCaretaker ? Icons.favorite_rounded : Icons.visibility_off_rounded,
                        color: white,
                        size: 16,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.theme.cardColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Text(
                        user['name'].toString().split(' ')[0],
                        style: caption.copyWith(fontSize: 9, color: widget.theme.textColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(radiusMedium),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Legend', style: caption.copyWith(color: widget.theme.textColor, fontWeight: FontWeight.w700, fontSize: 11)),
          SizedBox(height: spacingSmall),
          _buildLegendItem(primary, 'Visually Impaired'),
          _buildLegendItem(accent, 'Caretaker'),
          _buildLegendItem(error, 'Emergency'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 6),
          Text(label, style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        _buildControlButton(Icons.add_rounded, () {}),
        SizedBox(height: 8),
        _buildControlButton(Icons.remove_rounded, () {}),
        SizedBox(height: 8),
        _buildControlButton(Icons.my_location_rounded, () {}),
        SizedBox(height: 8),
        _buildControlButton(Icons.refresh_rounded, () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Locations refreshed')));
        }),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: widget.theme.cardColor,
      borderRadius: BorderRadius.circular(radiusMedium),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Icon(icon, color: widget.theme.textColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXLarge)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Users (${_filteredUsers.length})', style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 14)),
                TextButton(onPressed: () {}, child: Text('View All', style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: spacingMedium),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
            ),
          ),
          SizedBox(height: spacingMedium),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isEmergency = user['status'] == 'emergency';
    final isCaretaker = user['type'] == 'caretaker';
    final color = isEmergency ? error : isCaretaker ? accent : primary;

    return GestureDetector(
      onTap: () => _showUserDetails(user),
      child: Container(
        width: 140,
        margin: EdgeInsets.only(right: spacingMedium),
        padding: EdgeInsets.all(spacingMedium),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? color.withOpacity(0.1) : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(radiusLarge),
          border: Border.all(color: color.withOpacity(isEmergency ? 0.5 : 0.2), width: isEmergency ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [color, color.withOpacity(0.7)])),
                  child: Center(child: Text(user['name'].toString().substring(0, 1), style: TextStyle(color: white, fontWeight: FontWeight.w700, fontSize: 14))),
                ),
                Spacer(),
                if (isEmergency)
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(color: error, shape: BoxShape.circle),
                    child: Icon(Icons.warning_rounded, color: white, size: 10),
                  ),
              ],
            ),
            Spacer(),
            Text(user['name'].toString().split(' ')[0], style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 13), overflow: TextOverflow.ellipsis),
            Text(user['location'], style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 10), overflow: TextOverflow.ellipsis),
            SizedBox(height: 2),
            Text(user['lastUpdate'], style: caption.copyWith(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final isEmergency = user['status'] == 'emergency';
    final isCaretaker = user['type'] == 'caretaker';
    final color = isEmergency ? error : isCaretaker ? accent : primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXLarge))),
      builder: (context) => Container(
        padding: EdgeInsets.all(spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.theme.subtextColor.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            SizedBox(height: spacingLarge),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [color, color.withOpacity(0.7)])),
                  child: Center(child: Text(user['name'].toString().substring(0, 1), style: h2.copyWith(color: white, fontSize: 24))),
                ),
                SizedBox(width: spacingLarge),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'], style: h3.copyWith(color: widget.theme.textColor)),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: widget.theme.subtextColor),
                          SizedBox(width: 4),
                          Text(user['location'], style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12)),
                        ],
                      ),
                      Text('Last updated: ${user['lastUpdate']}', style: caption.copyWith(color: color, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacingLarge),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.call_rounded, size: 18),
                    label: Text('Call'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: BorderSide(color: Colors.green), padding: EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.directions_rounded, size: 18),
                    label: Text('Navigate'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: BorderSide(color: Colors.blue), padding: EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.history_rounded, size: 18),
                    label: Text('History'),
                    style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: white, padding: EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacingLarge),
          ],
        ),
      ),
    );
  }
}