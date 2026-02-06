// ignore_for_file: deprecated_member_use, duplicate_ignore
// File: lib/roles/caretaker/home/sections/patients_screen/patient_details_screen.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patient_model.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:intl/intl.dart';

// Import communication functions
import 'call_patients.dart';
import 'message_patients.dart';

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
      if (mounted) {
        setState(() {
          _fullPatientData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading patient data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ==================== UI BUILDER ====================

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final bgColor = widget.isDarkMode ? const Color(0xFF0A0E27) : const Color(0xFFFAFAFA);
    final cardColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final subColor = widget.isDarkMode ? const Color(0xFFB0B8D4) : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardColor,
            shape: BoxShape.circle,
            boxShadow: widget.isDarkMode ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Patient Profile',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              boxShadow: widget.isDarkMode ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, color: textColor, size: 20),
              onPressed: _loadFullPatientData,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primary))
                : SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    child: Column(
                      children: [
                        // 1. Header Profile
                        _buildProfileHeader(textColor, subColor!),
                        
                        const SizedBox(height: 24),
                        
                        // 2. Quick Info Row (Age/Gender)
                        _buildQuickInfoRow(cardColor, textColor),

                        const SizedBox(height: 20),

                        // 3. Medical Information Card
                        _buildSectionCard(
                          title: 'Medical Information',
                          icon: Icons.medical_services_rounded,
                          color: Colors.redAccent,
                          children: [
                            _buildInfoRow('Disability', widget.patient.disabilityType, textColor),
                            _buildInfoRow('Diagnosis', _fullPatientData?['diagnosis'] ?? 'Not specified', textColor),
                          ],
                          cardColor: cardColor,
                          textColor: textColor,
                        ),

                        const SizedBox(height: 16),

                        // 4. Contact Information Card
                        _buildSectionCard(
                          title: 'Contact Details',
                          icon: Icons.contact_phone_rounded,
                          color: Colors.blueAccent,
                          children: [
                            _buildInfoRow('Phone', widget.patient.contactNumber ?? 'N/A', textColor),
                            _buildInfoRow('Address', widget.patient.address ?? 'N/A', textColor, isMultiline: true),
                            _buildInfoRow('Email', _fullPatientData?['email'] ?? 'N/A', textColor),
                          ],
                          cardColor: cardColor,
                          textColor: textColor,
                        ),

                        const SizedBox(height: 16),

                        // 5. Account/System Info
                        _buildSectionCard(
                          title: 'Account Info',
                          icon: Icons.shield_rounded,
                          color: Colors.orangeAccent,
                          children: [
                            _buildInfoRow('ID Number', _fullPatientData?['idNumber'] ?? 'N/A', textColor),
                            _buildInfoRow('Last Active', _formatLastActive(widget.patient.lastActive), textColor),
                            _buildInfoRow('Member Since', _formatDate(_fullPatientData?['createdAt']), textColor),
                          ],
                          cardColor: cardColor,
                          textColor: textColor,
                        ),
                      ],
                    ),
                  ),
          ),
          
          // 6. Bottom Action Bar
          if (!_isLoading) _buildBottomActionBar(cardColor, textColor),
        ],
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildProfileHeader(Color textColor, Color subColor) {
    final profileImageUrl = widget.patient.profileImageUrl;
    final isActive = _fullPatientData?['isActive'] ?? true;

    return Column(
      children: [
        Stack(
          children: [
            Hero(
              tag: 'patient_avatar_${widget.patient.id}',
              child: Material(
                color: Colors.transparent,
                type: MaterialType.transparency,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                    // Match the background color from the list screen
                    color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    // Note: Shadows can sometimes cause lag in Hero, but usually fine
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? Image.network(
                            profileImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildDefaultAvatar(),
                          )
                        : _buildDefaultAvatar(),
                  ),
                ),
              ),
            ),
            // Status Indicator (Outside Hero so it doesn't fly with the image)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isDarkMode ? const Color(0xFF0A0E27) : Colors.white, 
                    width: 3
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.patient.name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: (isActive ? Colors.green : Colors.grey).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isActive ? 'Active Status' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          widget.patient.name.isNotEmpty ? widget.patient.name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildQuickInfoRow(Color cardColor, Color textColor) {
    final sex = _fullPatientData?['sex'] ?? 'N/A';
    
    return Row(
      children: [
        Expanded(
          child: _buildQuickInfoTile(
            label: 'Age',
            value: '${widget.patient.age} yrs',
            icon: Icons.cake_rounded,
            color: Colors.orange,
            cardColor: cardColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickInfoTile(
            label: 'Gender',
            value: sex,
            icon: Icons.wc_rounded,
            color: Colors.blue,
            cardColor: cardColor,
            textColor: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white60 : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: widget.isDarkMode ? Colors.white54 : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              textAlign: TextAlign.right,
              maxLines: isMultiline ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => callPatient(context, patientName: widget.patient.name),
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text("Call"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => messagePatient(context, patientName: widget.patient.name),
                  icon: const Icon(Icons.message_rounded),
                  label: const Text("Message"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  String _formatLastActive(DateTime? lastActive) {
    if (lastActive == null) return 'Never';
    final diff = DateTime.now().difference(lastActive);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dt = date is int 
          ? DateTime.fromMillisecondsSinceEpoch(date)
          : DateTime.parse(date.toString());
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (e) {
      return 'Unknown';
    }
  }
}