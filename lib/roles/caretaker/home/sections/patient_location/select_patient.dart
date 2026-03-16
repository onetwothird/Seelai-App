
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patient_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'dart:async';

class SelectPatient extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final PatientModel? selectedPatient;
  final Function(PatientModel) onPatientSelected;

  const SelectPatient({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.selectedPatient,
    required this.onPatientSelected,
  });

  @override
  State<SelectPatient> createState() => _SelectPatientState();
}

class _SelectPatientState extends State<SelectPatient> {
  List<PatientModel> _patients = [];
  Map<String, String> _patientProfileImages = {}; // Store profile images
  bool _isLoading = true;
  String? _caretakerId;
  StreamSubscription? _patientsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCaretakerId();
  }

  Future<void> _initializeCaretakerId() async {
    String? caretakerId = widget.userData['uid'] as String?;
    
    if (caretakerId == null || caretakerId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      caretakerId = user?.uid;
    }
    
    if (caretakerId == null || caretakerId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _caretakerId = caretakerId;
    });

    _setupPatientsStream();
  }

  void _setupPatientsStream() {
    if (_caretakerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _patientsSubscription = caretakerPatientService
        .streamCaretakerPatients(_caretakerId!)
        .listen(
      (patientsData) async {
        if (mounted) {
          // Convert patient data to models
          List<PatientModel> patients = patientsData.map((patientData) {
            return PatientModel(
              id: patientData['userId'] ?? '',
              name: patientData['name'] ?? 'Unknown',
              age: patientData['age'] ?? 0,
              disabilityType: patientData['disabilityType'] ?? 'Not specified',
              contactNumber: patientData['contactNumber'] ?? patientData['phone'] ?? 'N/A',
              address: patientData['address'] ?? 'No address',
              isOnline: false,
              lastActive: DateTime.now(),
            );
          }).toList();

          // Fetch profile images for each patient
          Map<String, String> profileImages = {};
          for (var patient in patients) {
            try {
              var userData = await databaseService.getUserDataByRole(
                patient.id, 
                'partially_sighted'
              );
              if (userData != null && userData['profileImageUrl'] != null) {
                String imageUrl = userData['profileImageUrl'] as String;
                if (imageUrl.isNotEmpty) {
                  profileImages[patient.id] = imageUrl;
                }
              }
            } catch (e) {
              // If fetching profile image fails, continue without it
            }
          }

          if (mounted) {
            setState(() {
              _patients = patients;
              _patientProfileImages = profileImages;
              _isLoading = false;
            });
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _patientsSubscription?.cancel();
    super.dispose();
  }

  Widget _buildPatientsListHeader() {
    return Row(
      children: [
        Text(
          'Select Patient to Track',
          style: bodyBold.copyWith(
            fontSize: 18,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        Spacer(),
        if (_patients.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacingSmall,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(radiusSmall),
              border: Border.all(
                color: primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${_patients.length} Patient${_patients.length != 1 ? 's' : ''}',
              style: caption.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPatientsList() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: spacingXLarge),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
        ),
      );
    }

    if (_patients.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _patients.map((patient) {
        final isSelected = widget.selectedPatient?.id == patient.id;
        return Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildPatientTrackCard(patient, isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildPatientTrackCard(PatientModel patient, bool isSelected) {
    String? profileImageUrl = _patientProfileImages[patient.id];
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: -2,
                ),
              ]
            : widget.isDarkMode
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.2),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : softShadow,
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      child: Material(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        child: InkWell(
          onTap: () => widget.onPatientSelected(patient),
          borderRadius: BorderRadius.circular(radiusLarge),
          child: Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        primary.withValues(alpha: 0.15),
                        accent.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(
                color: isSelected
                    ? primary.withValues(alpha: 0.6)
                    : widget.theme.subtextColor.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    // Profile image or icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: isSelected && profileImageUrl == null ? primaryGradient : null,
                        color: profileImageUrl == null && !isSelected
                            ? widget.theme.subtextColor.withOpacity(0.1)
                            : null,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: primary.withValues(alpha: 0.3), width: 2)
                            : null,
                      ),
                      child: profileImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                profileImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to icon if image fails to load
                                  return _buildProfileIcon(isSelected);
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isSelected ? primary : widget.theme.subtextColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : _buildProfileIcon(isSelected),
                    ),
                    // Online indicator
                    if (patient.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
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
                        patient.name,
                        style: bodyBold.copyWith(
                          fontSize: 16,
                          color: widget.theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.accessible_rounded,
                            size: 14,
                            color: widget.theme.subtextColor,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              patient.disabilityType,
                              style: caption.copyWith(
                                fontSize: 13,
                                color: widget.theme.subtextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: EdgeInsets.all(spacingSmall),
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: white,
                      size: 20,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: widget.theme.subtextColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIcon(bool isSelected) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        color: isSelected ? white : widget.theme.subtextColor,
        size: 28,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacingXLarge * 2),
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
                size: 60,
                color: widget.theme.subtextColor.withOpacity(0.3),
              ),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'No patients to track',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 16,
              ),
            ),
            SizedBox(height: spacingSmall),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Patients will appear here when they select you as their caretaker',
                style: body.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPatientsListHeader(),
        SizedBox(height: spacingMedium),
        _buildPatientsList(),
      ],
    );
  }
}