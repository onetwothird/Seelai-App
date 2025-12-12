// File: lib/roles/mswd/home/sections/user_profile_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class UserProfileScreen extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> selectedUser;
  final ScrollController? scrollController;
  final VoidCallback onBackPressed;
  final VoidCallback? onDataChanged; 

  const UserProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.selectedUser,
    required this.onBackPressed,
    this.scrollController,
    this.onDataChanged,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Map<String, dynamic> _fullUserData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFullUserData();
  }



  Future<void> _loadFullUserData() async {
    try {
      final userId = widget.selectedUser['userId'];
      final role = widget.selectedUser['role'];

      if (userId == null || role == null) {
        setState(() {
          _error = 'Missing user ID or role';
          _isLoading = false;
        });
        return;
      }

      // Fetch complete user data from database
      final userData = await databaseService.getUserDataByRole(userId, role);

      if (userData != null) {
        setState(() {
          _fullUserData = userData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading user data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: body.copyWith(color: Colors.red),
        ),
      );
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: ClampingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          _buildProfileHeader(),
          SizedBox(height: spacingLarge),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
            child: _buildProfileContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _fullUserData['name'] ?? 'Unknown';
    final isActive = _fullUserData['isActive'] ?? true;
    final statusColor = isActive ? Colors.green : Colors.orange;
    final profileImageUrl = _fullUserData['profileImageUrl'] as String?;
    final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

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
                onTap: widget.onBackPressed,
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color.fromARGB(255, 0, 0, 0),
                  const Color.fromARGB(255, 0, 0, 0).withOpacity(0.7),
                ],
              ),
              border: Border.all(
                color: Colors.black.withOpacity(0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: hasProfileImage
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, primary.withOpacity(0.7)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              name.substring(0, 1).toUpperCase(),
                              style: h2.copyWith(
                                color: white,
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, primary.withOpacity(0.7)],
                            ),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(white),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, primary.withOpacity(0.7)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: h2.copyWith(
                            color: white,
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
              isActive ? 'Active' : 'Inactive',
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
  
  Widget _buildProfileContent() {
    final role = _fullUserData['role'];
    final isCaretaker = role == 'caretaker';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCaretaker)
          _buildPersonalInfoSection()
        else
          _buildCaretakerPersonalInfo(),
        SizedBox(height: spacingLarge),
        if (!isCaretaker) _buildMedicalInfoSection(),
        if (!isCaretaker) _buildEmergencyContactSection(),
        if (!isCaretaker)
          _buildAssignedCaretakersSection()
        else
          _buildAssignedPatientsSection(),
        if (isCaretaker) _buildRequestStatisticsSection(),
        SizedBox(height: spacingLarge),
        _buildActionButtons(isCaretaker),
        SizedBox(height: spacingLarge),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
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
        _buildInfoCard('Age', '${_fullUserData['age'] ?? 'N/A'} years old', Icons.cake_rounded),
        _buildInfoCard('Sex', _fullUserData['sex'] ?? 'N/A', Icons.wc_rounded),
        _buildInfoCard('Address', _fullUserData['address'] ?? 'N/A', Icons.home_rounded),
        _buildInfoCard('Contact Number', _fullUserData['contactNumber'] ?? 'N/A', Icons.phone_rounded),
        if (_fullUserData['idNumber'] != null)
          _buildInfoCard('ID Number', _fullUserData['idNumber'], Icons.badge_rounded),
      ],
    );
  }

  Widget _buildCaretakerPersonalInfo() {
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
        _buildInfoCard('Age', '${_fullUserData['age'] ?? 'N/A'} years old', Icons.cake_rounded),
        _buildInfoCard('Relationship', _fullUserData['relationship'] ?? 'N/A', Icons.badge_rounded),
        _buildInfoCard('Contact Number', _fullUserData['contactNumber'] ?? 'N/A', Icons.phone_rounded),
        _buildInfoCard('Sex', _fullUserData['sex'] ?? 'N/A', Icons.wc_rounded),
        _buildInfoCard('Address', _fullUserData['address'] ?? 'N/A', Icons.home_rounded),
      ],
    );
  }

  Widget _buildMedicalInfoSection() {
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
          _fullUserData['disabilityType'] ?? 'N/A',
          Icons.visibility_off_rounded,
        ),
        _buildInfoCard(
          'Diagnosis',
          _fullUserData['diagnosis'] ?? 'N/A',
          Icons.medical_services_rounded,
        ),
      ],
    );
  }

  Widget _buildEmergencyContactSection() {
    final emergencyContacts = _fullUserData['emergencyContacts'] as Map? ?? {};

    if (emergencyContacts.isEmpty) {
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
          Text(
            'No emergency contacts added',
            style: body.copyWith(
              fontSize: 13,
              color: widget.theme.subtextColor,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Contacts',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        Column(
          children: List.generate(
            emergencyContacts.length,
            (index) {
              final contact = emergencyContacts.values.elementAt(index) as Map;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['name'] ?? 'N/A',
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
                            contact['phoneNumber'] ?? 'N/A',
                            style: body.copyWith(
                              fontSize: 13,
                              color: widget.theme.subtextColor,
                            ),
                          ),
                        ],
                      ),
                      if (contact['relationship'] != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Relationship: ${contact['relationship']}',
                          style: body.copyWith(
                            fontSize: 12,
                            color: widget.theme.subtextColor,
                          ),
                        ),
                      ],
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

  Widget _buildAssignedCaretakersSection() {
    final assignedCaretakers = _fullUserData['assignedCaretakers'] as Map? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned Caretakers (${assignedCaretakers.length})',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        if (assignedCaretakers.isEmpty)
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
              assignedCaretakers.length,
              (index) {
                final caretakerId = assignedCaretakers.keys.elementAt(index);
                return Padding(
                  padding: EdgeInsets.only(bottom: spacingMedium),
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: databaseService.getUserDataByRole(caretakerId, 'caretaker'),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return SizedBox.shrink();
                      
                      final caretaker = snapshot.data ?? {};
                      final caretakerName = caretaker['name'] ?? 'Unknown';
                      final profileImageUrl = caretaker['profileImageUrl'] as String?;
                      final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

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
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: hasProfileImage
                                    ? null
                                    : LinearGradient(
                                        colors: [accent, accent.withOpacity(0.7)],
                                      ),
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
                                        size: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: spacingMedium),
                            Expanded(
                              child: Text(
                                caretakerName,
                                style: body.copyWith(
                                  fontSize: 13,
                                  color: widget.theme.textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAssignedPatientsSection() {
    final assignedPatients = _fullUserData['assignedPatients'] as Map? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned Patients (${assignedPatients.length})',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        if (assignedPatients.isEmpty)
          Text(
            'No patients assigned',
            style: body.copyWith(
              fontSize: 13,
              color: widget.theme.subtextColor,
            ),
          )
        else
          Column(
            children: List.generate(
              assignedPatients.length,
              (index) {
                final patientId = assignedPatients.keys.elementAt(index);
                return Padding(
                  padding: EdgeInsets.only(bottom: spacingMedium),
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: databaseService.getUserDataByRole(patientId, 'visually_impaired'),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return SizedBox.shrink();
                      
                      final patient = snapshot.data ?? {};
                      final patientName = patient['name'] ?? 'Unknown';
                      final profileImageUrl = patient['profileImageUrl'] as String?;
                      final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

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
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: hasProfileImage
                                    ? null
                                    : LinearGradient(
                                        colors: [primary, primary.withOpacity(0.7)],
                                      ),
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
                                        patientName.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          color: white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: spacingMedium),
                            Expanded(
                              child: Text(
                                patientName,
                                style: body.copyWith(
                                  fontSize: 13,
                                  color: widget.theme.textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRequestStatisticsSection() {
    // For caretakers, you can calculate stats from their assigned patients
    final assignedPatients = _fullUserData['assignedPatients'] as Map? ?? {};

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
                'Assigned Patients',
                '${assignedPatients.length}',
                Icons.people_rounded,
                primary,
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
                    maxLines: 2,
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

