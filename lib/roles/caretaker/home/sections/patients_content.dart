// ignore_for_file: unnecessary_to_list_in_spreads, deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/models/patient_model.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/roles/caretaker/screens/patient_details_screen.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// Real-Time Patients Content
/// Automatically updates when visually impaired users select this caretaker
class PatientsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final LocationService locationService;

  const PatientsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.locationService,
  });

  @override
  State<PatientsContent> createState() => _PatientsContentState();
}

class _PatientsContentState extends State<PatientsContent> {
  StreamSubscription? _patientsSubscription;
  List<PatientModel> _patients = [];
  bool _isLoading = true;
  String? _error;
  String? _caretakerId;

  @override
  void initState() {
    super.initState();
    _initializeCaretakerId();
  }

  Future<void> _initializeCaretakerId() async {
    // Try multiple ways to get the caretaker ID
    String? caretakerId;
    
    // Method 1: From userData
    caretakerId = widget.userData['uid'] as String?;
    
    // Method 2: From Firebase Auth
    if (caretakerId == null || caretakerId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      caretakerId = user?.uid;
    }
    
    if (caretakerId == null || caretakerId.isEmpty) {
      setState(() {
        _error = 'Caretaker ID not found. Please log in again.';
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
      setState(() {
        _error = 'Caretaker ID not found';
        _isLoading = false;
      });
      return;
    }

    // Listen to real-time updates from Firebase
    _patientsSubscription = caretakerPatientService
        .streamCaretakerPatients(_caretakerId!)
        .listen(
      (patientsData) {
        if (mounted) {
          setState(() {
            _patients = patientsData.map((patientData) {
              return PatientModel(
                id: patientData['userId'] ?? '',
                name: patientData['name'] ?? 'Unknown',
                age: patientData['age'] ?? 0,
                disabilityType: patientData['disabilityType'] ?? 'Not specified',
                contactNumber: patientData['contactNumber'] ?? patientData['phone'] ?? 'N/A',
                address: patientData['address'] ?? 'No address',
                isOnline: false, // You can implement online status tracking
                lastActive: DateTime.now(),
              );
            }).toList();
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading patients: $error');
        if (mounted) {
          setState(() {
            _error = 'Failed to load patients: $error';
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _patientsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshPatients() async {
    if (_caretakerId == null) {
      await _initializeCaretakerId();
      return;
    }
    
    setState(() => _isLoading = true);
    await Future.delayed(Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: _refreshPatients,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: width * 0.06,
          right: width * 0.06,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Patients',
                  style: h2.copyWith(
                    fontSize: 26,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: spacingSmall),
                Text(
                  'Visually impaired individuals who chose you',
                  style: body.copyWith(
                    color: widget.theme.subtextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacingLarge),
            
            _isLoading && _patients.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primary),
                          ),
                          SizedBox(height: spacingLarge),
                          Text(
                            'Loading patients...',
                            style: body.copyWith(
                              color: widget.theme.subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _error != null && _patients.isEmpty
                    ? _buildErrorState()
                    : _patients.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              // Patient count badge
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(spacingMedium),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primary.withOpacity(0.1),
                                      accent.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(radiusMedium),
                                  border: Border.all(
                                    color: primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.people_rounded,
                                      color: primary,
                                      size: 20,
                                    ),
                                    SizedBox(width: spacingSmall),
                                    Text(
                                      '${_patients.length} Patient${_patients.length != 1 ? 's' : ''} Under Your Care',
                                      style: bodyBold.copyWith(
                                        color: widget.theme.textColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: spacingMedium),
                              // Patient cards
                              ..._patients.map((patient) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: spacingMedium),
                                  child: _buildPatientCard(patient),
                                );
                              }).toList(),
                            ],
                          ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: error.withOpacity(0.5),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'Failed to load patients',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              _error ?? 'An error occurred',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacingLarge),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializeCaretakerId();
              },
              icon: Icon(Icons.refresh_rounded),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(
                  horizontal: spacingLarge,
                  vertical: spacingMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              'No patients yet',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: spacingSmall),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'When visually impaired users select you as their caretaker, they will appear here automatically',
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

  Widget _buildPatientCard(PatientModel patient) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: primary.withOpacity(0.15),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      child: Material(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsScreen(
                  patient: patient,
                  isDarkMode: widget.isDarkMode,
                  locationService: widget.locationService,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(radiusLarge),
          child: Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radiusLarge),
              border: widget.isDarkMode
                  // ignore: deprecated_member_use
                  ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacingLarge),
                          decoration: BoxDecoration(
                            gradient: primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: white,
                            size: 32,
                          ),
                        ),
                        if (patient.isOnline)
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
                            patient.name,
                            style: bodyBold.copyWith(
                              fontSize: 18,
                              color: widget.theme.textColor,
                            ),
                          ),
                          SizedBox(height: spacingXSmall),
                          Text(
                            '${patient.age} years • ${patient.disabilityType}',
                            style: caption.copyWith(
                              fontSize: 14,
                              color: widget.theme.subtextColor,
                            ),
                          ),
                          SizedBox(height: spacingXSmall),
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
                                  patient.address ?? 'No address',
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
                    Icon(
                      Icons.chevron_right_rounded,
                      color: widget.theme.subtextColor,
                      size: 24,
                    ),
                  ],
                ),
                SizedBox(height: spacingMedium),
                Divider(height: 1, color: widget.theme.subtextColor.withOpacity(0.2)),
                SizedBox(height: spacingMedium),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.phone_rounded,
                        label: 'Call',
                        color: Colors.green,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${patient.name}...')),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: spacingSmall),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.message_rounded,
                        label: 'Message',
                        color: primary,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening messages with ${patient.name}...')),
                          );
                        },
                      ),
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

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: white,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    );
  }
}