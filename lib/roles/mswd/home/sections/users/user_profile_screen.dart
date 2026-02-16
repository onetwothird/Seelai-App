// File: lib/roles/mswd/home/sections/users/user_profile_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> selectedUser;
  final VoidCallback? onDataChanged;
  final VoidCallback? onViewLocation;

  const UserProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.selectedUser,
    this.onDataChanged,
    this.onViewLocation,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _fullUserData;
  bool _isLoading = true;
  bool _isProcessingAction = false; // For approve/reject loading state
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFullUserData();
  }

  Future<void> _loadFullUserData() async {
    try {
      final userId = widget.selectedUser['userId'] ?? widget.selectedUser['uid'];
      final role = widget.selectedUser['role'];

      // If we don't have enough info to load detailed data, just use what we have
      if (userId == null || role == null) {
        setState(() {
          _fullUserData = widget.selectedUser;
          _isLoading = false;
        });
        return;
      }

      final data = await databaseService.getUserDataByRole(userId, role);
      if (mounted) {
        setState(() {
          _fullUserData = data;
          // Ensure ID is preserved if missing in fetched data but present in selectedUser
          _fullUserData?['userId'] = userId; 
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleCallUser() async {
    if (_fullUserData == null) return;
    
    await MswdCallService.call(
      context: context,
      user: _fullUserData!,
      isDarkMode: widget.isDarkMode,
      theme: widget.theme,
    );
  }

  // ==================== VERIFICATION HANDLERS ====================

  Future<void> _handleApproveCaretaker() async {
    final userId = _fullUserData?['userId'];
    if (userId == null) return;

    setState(() => _isProcessingAction = true);
    try {
      await adminService.approveCaretaker(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caretaker approved successfully'), backgroundColor: Colors.green),
        );
        // Refresh local data to show updated status
        await _loadFullUserData();
        if (widget.onDataChanged != null) widget.onDataChanged!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleRejectCaretaker() async {
    final userId = _fullUserData?['userId'];
    if (userId == null) return;

    // Show confirmation dialog for rejection
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: const Text('Are you sure you want to reject this caretaker? This action cannot be undone immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (shouldReject != true) return;

    setState(() => _isProcessingAction = true);
    try {
      await adminService.rejectCaretaker(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caretaker application rejected'), backgroundColor: Colors.orange),
        );
        Navigator.pop(context); // Close profile screen
        if (widget.onDataChanged != null) widget.onDataChanged!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isProcessingAction = false);
      }
    }
  }

  // ==================== UI BUILDER ====================

  @override
  Widget build(BuildContext context) {
    // Theme Colors matching PatientDetailsScreen logic
    final bgColor = widget.isDarkMode ? const Color(0xFF0A0E27) : const Color(0xFFFAFAFA);
    final cardColor = widget.theme.cardColor;
    final textColor = widget.theme.textColor;
    
    // Determine Role for UI logic
    final role = widget.selectedUser['role'];
    final isCaretaker = role == 'caretaker';
    
    // Check if Pending (Caretaker AND approved is explicitly false)
    final isPending = isCaretaker && (_fullUserData?['approved'] == false);

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
          isPending ? 'Verification Request' : (isCaretaker ? 'Caretaker Profile' : 'Patient Profile'),
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
              onPressed: _loadFullUserData,
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
                        // PENDING BANNER
                        if (isPending) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Pending Approval",
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                      ),
                                      Text(
                                        "This user is waiting for verification.",
                                        style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 1. Header Profile
                        _buildProfileHeader(textColor),
                        
                        const SizedBox(height: 24),
                        
                        // 2. Quick Info Row (Age/Gender)
                        _buildQuickInfoRow(cardColor, textColor),

                        const SizedBox(height: 20),

                        // 3. Medical Information Card (Only for Patients)
                        if (!isCaretaker) ...[
                          _buildSectionCard(
                            title: 'Medical Information',
                            icon: Icons.medical_services_rounded,
                            color: Colors.redAccent,
                            children: [
                              _buildInfoRow('Disability', _fullUserData?['disabilityType'] ?? 'N/A', textColor),
                              _buildInfoRow('Diagnosis', _fullUserData?['diagnosis'] ?? 'Not specified', textColor),
                            ],
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 4. Contact Information Card
                        _buildSectionCard(
                          title: 'Contact Details',
                          icon: Icons.contact_phone_rounded,
                          color: Colors.blueAccent,
                          children: [
                            _buildInfoRow('Phone', _fullUserData?['contactNumber'] ?? 'N/A', textColor),
                            _buildInfoRow('Address', _fullUserData?['address'] ?? 'N/A', textColor, isMultiline: true),
                            if (isCaretaker)
                              _buildInfoRow('Relationship', _fullUserData?['relationship'] ?? 'N/A', textColor),
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
                            _buildInfoRow('Status', (_fullUserData?['isActive'] ?? true) ? 'Active' : 'Inactive', textColor),
                             if (isCaretaker)
                              _buildInfoRow('Approval', (_fullUserData?['approved'] == true) ? 'Approved' : 'Pending', textColor),
                            _buildInfoRow('Member Since', _formatDate(_fullUserData?['createdAt']), textColor),
                            if (isCaretaker)
                              _buildInfoRow('Patients', '${(_fullUserData?['assignedPatients'] as Map?)?.length ?? 0} assigned', textColor),
                          ],
                          cardColor: cardColor,
                          textColor: textColor,
                        ),
                      ],
                    ),
                  ),
          ),
          
          // 6. Bottom Action Bar (Conditional)
          if (!_isLoading) 
             isPending 
                ? _buildVerificationBar(cardColor) // Show Approve/Reject
                : _buildBottomActionBar(cardColor, textColor), // Standard Call/Location
        ],
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildProfileHeader(Color textColor) {
    final profileImageUrl = _fullUserData?['profileImageUrl'];
    final isActive = _fullUserData?['isActive'] ?? true;
    final name = _fullUserData?['name'] ?? 'Unknown';

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
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
                        errorBuilder: (_, _, _) => _buildDefaultAvatar(name),
                      )
                    : _buildDefaultAvatar(name),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.isDarkMode ? const Color(0xFF0A0E27) : Colors.white, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
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

  Widget _buildDefaultAvatar(String name) {
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
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildQuickInfoRow(Color cardColor, Color textColor) {
    final sex = _fullUserData?['sex'] ?? 'N/A';
    
    return Row(
      children: [
        Expanded(
          child: _buildQuickInfoTile(
            label: 'Age',
            value: '${_fullUserData?['age'] ?? 'N/A'} yrs',
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
                  onPressed: _handleCallUser,
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
                  onPressed: () {
                    // Navigate to location if callback is provided
                    if (widget.onViewLocation != null) {
                      Navigator.pop(context); // Close profile first
                      widget.onViewLocation!(); // Then navigate
                    }
                  },
                  icon: const Icon(Icons.location_on_rounded),
                  label: const Text("Location"),
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

  // NEW: Bar for approving/rejecting caretakers
  Widget _buildVerificationBar(Color cardColor) {
    if (_isProcessingAction) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

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
                child: OutlinedButton.icon(
                  onPressed: _handleRejectCaretaker,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text("Decline"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
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
                  onPressed: _handleApproveCaretaker,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text("Approve"),
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
          ],
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

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