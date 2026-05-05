// File: lib/roles/caretaker/home/sections/home_screen/my_patients.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart';
import 'communication/screens/caretaker_voice_call_screen.dart';
import 'communication/screens/caretaker_video_call_screen.dart';

class MyPatientsSection extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final bool isLoadingPatients;
  final List<Map<String, dynamic>> assignedPatients;

  const MyPatientsSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.isLoadingPatients,
    required this.assignedPatients,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Assistance', // FIXED: Typo in "Assistance"
              style: TextStyle(
                fontSize: 20,
                color: theme.textColor,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () => _showAllPatientsBottomSheet(context), 
              child: Text(
                'See All',
                style: TextStyle(color: primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Added AnimatedSwitcher to prevent UI from "jumping" or "bugging" between states
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isLoadingPatients
              ? Center(
                  key: const ValueKey('loading'),
                  child: Padding(
                    padding: EdgeInsets.all(spacingLarge), 
                    child: CircularProgressIndicator(color: primary),
                  ),
                )
              : assignedPatients.isEmpty
                  ? Container(
                      key: const ValueKey('empty'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.subtextColor.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.group_off_rounded, size: 40, color: theme.subtextColor.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No patients assigned yet',
                            style: TextStyle(color: theme.subtextColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      key: const ValueKey('list'),
                      height: 175, // INCREASED: Gives slightly more room to prevent text overflow bugs
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: assignedPatients.length,
                        itemBuilder: (context, index) {
                          final patient = assignedPatients[index];
                          return _PatientCard(
                            patient: patient,
                            theme: theme,
                            isDarkMode: isDarkMode,
                            isBottomSheet: false, 
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // Bottom Sheet to view all patients
  void _showAllPatientsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: theme.backgroundGradient.colors.last, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: theme.subtextColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'All Assigned Patients',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${assignedPatients.length}',
                        style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65, // DECREASED: Prevents bottom overflow crash in grid
                  ),
                  itemCount: assignedPatients.length,
                  itemBuilder: (context, index) {
                    return _PatientCard(
                      patient: assignedPatients[index],
                      theme: theme,
                      isDarkMode: isDarkMode,
                      isBottomSheet: true, 
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Extracted Widget for Patient Card to handle Real-Time Online Status and Images
class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final dynamic theme;
  final bool isDarkMode;
  final bool isBottomSheet;

  const _PatientCard({
    required this.patient,
    required this.theme,
    required this.isDarkMode,
    required this.isBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    final patientName = patient['name'] ?? 'Unknown';
    final patientId = patient['userId'] ?? '';
    final profileImageUrl = patient['profileImageUrl'] as String?; 
    
    final Color primaryPurple = const Color(0xFF8B5CF6);

    return Container(
      width: 120, 
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // === FIXED PROFILE IMAGE ===
          // Removed DecorationImage to prevent crashes on broken network URLs
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                  ? (isDarkMode ? Colors.white10 : Colors.grey[200])
                  : primaryPurple, 
              border: Border.all(
                color: isDarkMode ? Colors.white30 : Colors.black, 
                width: 1.0,
              ), 
            ),
            child: ClipOval(
              child: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      // Gracefully handles missing/broken images without crashing the UI
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: primaryPurple,
                        child: const Center(
                          child: Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          
          Text(
            patientName,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.textColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          
          // === REAL-TIME STATUS CHECKER ===
          StreamBuilder<Map<String, dynamic>?>(
            stream: locationTrackingService.trackPatientLocation(patientId),
            builder: (context, snapshot) {
              bool isOnline = false;

              if (snapshot.hasData && snapshot.data != null) {
                isOnline = locationTrackingService.isLocationRecent(snapshot.data!);
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey, 
                      shape: BoxShape.circle
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: isOnline ? theme.subtextColor : Colors.grey, 
                      fontSize: 11,
                      fontWeight: isOnline ? FontWeight.w600 : FontWeight.w400,
                    ),
                  )
                ],
              );
            },
          ),
          
          const SizedBox(height: 10),
          
          // === ACTION BUTTONS ===
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSmallActionButton(
                icon: Icons.call_rounded,
                color: primaryPurple,
                isDarkMode: isDarkMode, 
                onTap: () {
                  if (isBottomSheet) Navigator.pop(context); 
                  CaretakerVoiceCallScreen.startCall(context, patient);
                },
              ),
              const SizedBox(width: 12),
              _buildSmallActionButton(
                icon: Icons.videocam_rounded,
                color: primaryPurple,
                isDarkMode: isDarkMode, 
                onTap: () {
                  if (isBottomSheet) Navigator.pop(context); 
                  CaretakerVideoCallScreen.startCall(context, patient);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6), 
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.transparent : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(
          icon,
          size: 16, 
          color: color, 
        ),
      ),
    );
  }
}