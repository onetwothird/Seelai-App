// File: lib/roles/mswd/home/sections/mswd_patients_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class MSWDPatientsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;

  const MSWDPatientsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
  });

  @override
  State<MSWDPatientsContent> createState() => _MSWDPatientsContentState();
}

class _MSWDPatientsContentState extends State<MSWDPatientsContent> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  
  final List<String> _filterOptions = ['All', 'Verified', 'Pending', 'Visual', 'Hearing', 'Physical'];
  
  // Mock patient data
  final List<Map<String, dynamic>> _patients = [
    {
      'name': 'Juan Dela Cruz',
      'age': 45,
      'disabilityType': 'Visual Impairment',
      'status': 'Verified',
      'idNumber': 'PWD-2024-001',
      'lastVisit': '2 days ago',
    },
    {
      'name': 'Maria Santos',
      'age': 32,
      'disabilityType': 'Hearing Impairment',
      'status': 'Verified',
      'idNumber': 'PWD-2024-002',
      'lastVisit': '1 week ago',
    },
    {
      'name': 'Pedro Garcia',
      'age': 58,
      'disabilityType': 'Physical Disability',
      'status': 'Pending',
      'idNumber': 'PWD-2024-003',
      'lastVisit': '3 days ago',
    },
    {
      'name': 'Ana Reyes',
      'age': 29,
      'disabilityType': 'Visual Impairment',
      'status': 'Verified',
      'idNumber': 'PWD-2024-004',
      'lastVisit': '1 day ago',
    },
    {
      'name': 'Carlos Lopez',
      'age': 41,
      'disabilityType': 'Hearing Impairment',
      'status': 'Pending',
      'idNumber': 'PWD-2024-005',
      'lastVisit': '5 days ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final filteredPatients = _getFilteredPatients();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patients',
                      style: h2.copyWith(
                        fontSize: 26,
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: spacingSmall),
                    Text(
                      '${filteredPatients.length} patient${filteredPatients.length != 1 ? 's' : ''} found',
                      style: body.copyWith(
                        color: widget.theme.subtextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(radiusMedium),
                  boxShadow: glowShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Add patient feature coming soon'),
                          backgroundColor: primary,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(radiusMedium),
                    child: Padding(
                      padding: EdgeInsets.all(spacingMedium),
                      child: Icon(Icons.add_rounded, color: white, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: spacingLarge),
          
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusLarge),
              boxShadow: widget.isDarkMode 
                ? [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 12)]
                : softShadow,
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: body.copyWith(color: widget.theme.textColor),
              decoration: InputDecoration(
                hintText: 'Search patients...',
                hintStyle: body.copyWith(
                  color: widget.theme.subtextColor.withOpacity(0.5),
                ),
                prefixIcon: Icon(Icons.search_rounded, color: primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radiusLarge),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          
          SizedBox(height: spacingMedium),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: EdgeInsets.only(right: spacingSmall),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(filter),
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: widget.theme.cardColor,
                    selectedColor: primary.withOpacity(0.2),
                    checkmarkColor: primary,
                    labelStyle: bodyBold.copyWith(
                      color: isSelected ? primary : widget.theme.textColor,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected 
                        ? primary 
                        : widget.theme.subtextColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          SizedBox(height: spacingLarge),
          
          // Patients List
          if (filteredPatients.isEmpty)
            _buildEmptyState()
          else
            ...filteredPatients.map((patient) => Padding(
              padding: EdgeInsets.only(bottom: spacingMedium),
              child: _buildPatientCard(patient),
            )),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredPatients() {
    return _patients.where((patient) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          patient['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          patient['idNumber'].toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Status/Type filter
      final matchesFilter = _selectedFilter == 'All' ||
          patient['status'] == _selectedFilter ||
          patient['disabilityType'].contains(_selectedFilter);
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(spacingXLarge),
              decoration: BoxDecoration(
                color: widget.theme.subtextColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 80,
                color: widget.theme.subtextColor.withOpacity(0.3),
              ),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'No patients found',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: spacingSmall),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Try adjusting your search or filters',
                style: body.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final isVerified = patient['status'] == 'Verified';
    final statusColor = isVerified ? Colors.green : Colors.orange;
    
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.15),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ]
          : softShadow,
        border: widget.isDarkMode 
          ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
          : Border.all(color: greyLighter, width: 1.5),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(spacingLarge),
            leading: Container(
              padding: EdgeInsets.all(spacingMedium),
              decoration: BoxDecoration(
                gradient: primaryGradient,
                borderRadius: BorderRadius.circular(radiusMedium),
              ),
              child: Icon(Icons.person_rounded, color: white, size: 28),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    patient['name'],
                    style: bodyBold.copyWith(fontSize: 18, color: widget.theme.textColor),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(radiusSmall),
                  ),
                  child: Text(
                    patient['status'],
                    style: caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: spacingXSmall),
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 16, color: widget.theme.subtextColor),
                    SizedBox(width: 6),
                    Text(
                      patient['idNumber'],
                      style: body.copyWith(color: widget.theme.subtextColor, fontSize: 13),
                    ),
                  ],
                ),
                SizedBox(height: spacingXSmall),
                Row(
                  children: [
                    Icon(Icons.accessible_rounded, size: 16, color: widget.theme.subtextColor),
                    SizedBox(width: 6),
                    Text(
                      patient['disabilityType'],
                      style: body.copyWith(color: widget.theme.subtextColor, fontSize: 13),
                    ),
                  ],
                ),
                SizedBox(height: spacingXSmall),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: widget.theme.subtextColor),
                    SizedBox(width: 6),
                    Text(
                      'Last visit: ${patient['lastVisit']}',
                      style: body.copyWith(color: widget.theme.subtextColor, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: widget.theme.subtextColor,
              size: 24,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('View patient details feature coming soon'),
                  backgroundColor: primary,
                ),
              );
            },
          ),
          Divider(height: 1, color: widget.theme.subtextColor.withOpacity(0.2)),
          Padding(
            padding: EdgeInsets.all(spacingMedium),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('View profile feature coming soon'),
                          backgroundColor: primary,
                        ),
                      );
                    },
                    icon: Icon(Icons.visibility_rounded, size: 18),
                    label: Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusMedium),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacingSmall),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Edit profile feature coming soon'),
                          backgroundColor: accent,
                        ),
                      );
                    },
                    icon: Icon(Icons.edit_rounded, size: 18),
                    label: Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusMedium),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}