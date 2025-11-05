import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/models/patient_model.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/roles/caretaker/screens/patient_details_screen.dart';

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
  List<PatientModel> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    
    // TODO: Load from database
    await Future.delayed(Duration(milliseconds: 500));
    
    // Sample data
    _patients = [
      PatientModel(
        id: 'p1',
        name: 'Maria Santos',
        age: 65,
        disabilityType: 'Visually Impaired',
        contactNumber: '+63 917 123 4567',
        address: 'Calamba, Laguna',
        isOnline: true,
        lastActive: DateTime.now(),
      ),
      PatientModel(
        id: 'p2',
        name: 'Juan Dela Cruz',
        age: 58,
        disabilityType: 'Visually Impaired',
        contactNumber: '+63 918 234 5678',
        address: 'Los Baños, Laguna',
        isOnline: false,
        lastActive: DateTime.now().subtract(Duration(hours: 2)),
      ),
    ];
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        bottom: 100,
      ),
      child: Column(
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
            'People under your care',
            style: body.copyWith(
              color: widget.theme.subtextColor,
              fontSize: 14,
            ),
          ),
          SizedBox(height: spacingLarge),
          
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _patients.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: _patients.map((patient) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: spacingMedium),
                          child: _buildPatientCard(patient),
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 60),
          Icon(
            Icons.people_outline_rounded,
            size: 80,
            color: widget.theme.subtextColor.withOpacity(0.3),
          ),
          SizedBox(height: spacingLarge),
          Text(
            'No patients assigned',
            style: body.copyWith(
              color: widget.theme.subtextColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
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