// ignore_for_file: deprecated_member_use, duplicate_ignore
// File: lib/roles/caretaker/home/sections/patients_screen/patient_details_screen.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patient_model.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:intl/intl.dart';

class PatientDetailsScreen extends StatefulWidget {
  final PatientModel patient;
  final bool isDarkMode;
  final LocationService locationService;

  const PatientDetailsScreen({
    super.key,
    required this.patient,
    required this.isDarkMode,
    required this.locationService,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  Map<String, dynamic>? _fullPatientData;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFullPatientData();
  }

  Future<void> _loadFullPatientData() async {
    try {
      final data = await databaseService.getUserDataByRole(
        widget.patient.id,
        'visually_impaired',
      );
      setState(() {
        _fullPatientData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading patient data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color get _cardColor => widget.isDarkMode ? Color(0xFF1A1F3A) : white;
  Color get _bgColor => widget.isDarkMode ? Color(0xFF0A0E27) : backgroundPrimary;
  Color get _textColor => widget.isDarkMode ? white : black;
  Color get _subtextColor => widget.isDarkMode ? Color(0xFFB0B8D4) : grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Patient Details',
          style: h3.copyWith(
            fontSize: 18,
            color: _textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: _textColor),
            onPressed: _loadFullPatientData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              physics: ClampingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  SizedBox(height: spacingLarge),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                    ),
                    child: _buildProfileContent(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final isActive = _fullPatientData?['isActive'] ?? true;
    final statusColor = isActive ? Colors.green : Colors.orange;
    final profileImageUrl = widget.patient.profileImageUrl;
    final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: spacingXLarge),
      decoration: BoxDecoration(
        color: _cardColor,
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
          // Profile Picture
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
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
                                  widget.patient.name.substring(0, 1).toUpperCase(),
                                  style: h1.copyWith(
                                    color: white,
                                    fontSize: 52,
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
                              widget.patient.name.substring(0, 1).toUpperCase(),
                              style: h1.copyWith(
                                color: white,
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              if (widget.patient.isOnline)
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: _cardColor, width: 3),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: spacingMedium + 4),
          Text(
            widget.patient.name,
            style: h2.copyWith(
              fontSize: 22,
              color: _textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: spacingSmall),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacingMedium,
              vertical: 6,
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPersonalInfoSection(),
        SizedBox(height: spacingLarge),
        _buildContactSection(),
        SizedBox(height: spacingLarge),
        _buildMedicalSection(),
        SizedBox(height: spacingLarge),
        _buildAccountSection(),
        SizedBox(height: spacingLarge),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    final birthdateStr = _fullPatientData?['birthdate'] as String?;
    final idNumber = _fullPatientData?['idNumber'] as String? ?? 'Not provided';
    final sex = _fullPatientData?['sex'] as String? ?? 'Not specified';
    final email = _fullPatientData?['email'] as String? ?? 'Not provided';
    
    String formattedBirthdate = 'Not provided';
    if (birthdateStr != null) {
      try {
        final date = DateTime.parse(birthdateStr);
        formattedBirthdate = DateFormat('MMMM dd, yyyy').format(date);
      } catch (e) {
        formattedBirthdate = birthdateStr;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: _textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildInfoCard('Age', '${widget.patient.age} years old', Icons.cake_rounded),
        _buildInfoCard('Sex', sex, Icons.wc_rounded),
        _buildInfoCard('Birthdate', formattedBirthdate, Icons.calendar_today_rounded),
        _buildInfoCard('ID Number', idNumber, Icons.badge_rounded),
        _buildInfoCard('Email', email, Icons.email_rounded),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: _textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildInfoCard(
          'Phone Number',
          widget.patient.contactNumber ?? 'Not provided',
          Icons.phone_rounded,
        ),
        _buildInfoCard(
          'Address',
          widget.patient.address ?? 'Not provided',
          Icons.home_rounded,
        ),
      ],
    );
  }

  Widget _buildMedicalSection() {
    final diagnosis = _fullPatientData?['diagnosis'] as String? ?? 'Not provided';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical Information',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: _textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildInfoCard(
          'Disability Type',
          widget.patient.disabilityType,
          Icons.visibility_off_rounded,
        ),
        _buildInfoCard(
          'Diagnosis',
          diagnosis,
          Icons.medical_services_rounded,
        ),
        _buildInfoCard(
          'Last Active',
          widget.patient.lastActive != null
              ? _formatLastActive(widget.patient.lastActive!)
              : 'Never',
          Icons.access_time_rounded,
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    final createdAtTimestamp = _fullPatientData?['createdAt'] as int?;
    final updatedAtTimestamp = _fullPatientData?['updatedAt'] as int?;
    final isActive = _fullPatientData?['isActive'] as bool? ?? true;
    
    String formattedCreatedAt = 'Not available';
    if (createdAtTimestamp != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(createdAtTimestamp);
      formattedCreatedAt = DateFormat('MMM dd, yyyy HH:mm').format(date);
    }
    
    String formattedUpdatedAt = 'Not available';
    if (updatedAtTimestamp != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(updatedAtTimestamp);
      formattedUpdatedAt = DateFormat('MMM dd, yyyy HH:mm').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Information',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: _textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildInfoCard(
          'Account Status',
          isActive ? 'Active' : 'Deactivated',
          Icons.verified_user_rounded,
          color: isActive ? Colors.green : Colors.red,
        ),
        _buildInfoCard(
          'Account Created',
          formattedCreatedAt,
          Icons.person_add_rounded,
        ),
        _buildInfoCard(
          'Last Updated',
          formattedUpdatedAt,
          Icons.update_rounded,
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Container(
        padding: EdgeInsets.all(spacingMedium),
        decoration: BoxDecoration(
          color: _cardColor,
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
                      color: _subtextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: body.copyWith(
                      fontSize: 13,
                      color: _textColor,
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

  String _formatLastActive(DateTime lastActive) {
    final difference = DateTime.now().difference(lastActive);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }
}