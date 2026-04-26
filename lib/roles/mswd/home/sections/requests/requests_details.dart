// File: lib/roles/mswd/home/sections/requests/requests_details.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class RequestDetailsScreen extends StatefulWidget {
  final RequestModel request;
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, Map<String, dynamic>> userDataCache;

  const RequestDetailsScreen({
    super.key,
    required this.request,
    required this.isDarkMode,
    required this.theme,
    required this.userDataCache,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  Map<String, dynamic>? _patientData;
  Map<String, dynamic>? _caretakerData;
  late RequestModel _currentRequest;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
    _patientData = widget.userDataCache[_currentRequest.patientId];
    if (_currentRequest.caretakerId != null) {
      _caretakerData = widget.userDataCache[_currentRequest.caretakerId!];
    }
  }

  // ==========================================
  // LAUNCHER ACTIONS (PHONE & MAPS)
  // ==========================================
  Future<void> _launchUrl(Uri uri, String fallbackMessage) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar(fallbackMessage);
      }
    } catch (e) {
      _showSnackBar('Action failed: $e');
    }
  }

  void _callPhone(String? phone) {
    if (phone == null || phone.isEmpty || phone == 'Not Provided') {
      _showSnackBar('No valid phone number available.');
      return;
    }
    // Remove any non-numeric characters for the dialer
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    _launchUrl(Uri(scheme: 'tel', path: cleanPhone), 'Could not open phone dialer.');
  }

  void _openMap() {
    final loc = _currentRequest.location;
    if (loc == null || loc['latitude'] == null || loc['longitude'] == null) {
      _showSnackBar('No exact GPS coordinates available.');
      return;
    }
    final lat = loc['latitude'];
    final lng = loc['longitude'];
    
    // Opens Google Maps or default map handler with a pin
    final url = Uri.parse('http://googleusercontent.com/maps.google.com/maps?q=$lat,$lng');
    _launchUrl(url, 'Could not open maps application.');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF7C3AED),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==========================================
  // ADMIN STATUS OVERRIDE
  // ==========================================
  void _showAdminStatusUpdateDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Override: Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Force a status update on this request. This will reflect in the database immediately.',
                style: TextStyle(fontSize: 13, color: widget.theme.subtextColor),
              ),
              const SizedBox(height: 24),
              // FIX: Removed the unnecessary .toList() at the end here
              ...RequestStatus.values.map((status) => _buildStatusOption(status)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption(RequestStatus status) {
    final isSelected = _currentRequest.status == status;
    final color = _getStatusColor(status);

    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        if (isSelected) return;

        setState(() => _isUpdating = true);
        try {
          // FIX: Passed arguments positionally instead of using named parameters
          // FIX: Passed the 'status' enum directly as required by your service
          await assistanceRequestService.updateRequestStatus(
            _currentRequest.id,
            status,
          );
          
          if (mounted) {
            setState(() {
              _currentRequest = _currentRequest.copyWith(status: status);
              _isUpdating = false;
            });
            _showSnackBar('Status forcefully updated to ${status.name.toUpperCase()}');
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isUpdating = false);
            _showSnackBar('Failed to update status.');
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : widget.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (widget.isDarkMode ? Colors.white10 : Colors.black12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? color : widget.theme.subtextColor,
            ),
            const SizedBox(width: 12),
            Text(
              status.name.toUpperCase(),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? color : widget.theme.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BUILDERS
  // ==========================================
  IconData _getRequestIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('medical') || t.contains('health')) return Icons.medical_services_rounded;
    if (t.contains('transport') || t.contains('ride') || t.contains('navigation')) return Icons.directions_car_rounded;
    if (t.contains('food') || t.contains('grocery')) return Icons.shopping_basket_rounded;
    if (t.contains('emergency')) return Icons.warning_rounded;
    if (t.contains('read')) return Icons.text_fields_rounded;
    return Icons.assignment_rounded;
  }

  Color _getPriorityColor(dynamic priority) {
    final p = priority.toString().toLowerCase();
    if (p.contains('emergency')) return const Color(0xFFEF4444);
    if (p.contains('high')) return const Color(0xFFF5A623);
    if (p.contains('medium')) return const Color(0xFF3B82F6);
    if (p.contains('low')) return const Color(0xFF10B981);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.theme.backgroundGradient.colors.last; 
    final primaryColor = const Color(0xFF8B5CF6); 

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent, 
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: widget.theme.cardColor,
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: widget.theme.textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              'Ref #${_currentRequest.id.length > 6 ? _currentRequest.id.substring(0, 6).toUpperCase() : _currentRequest.id.toUpperCase()}',
              style: TextStyle(
                color: widget.theme.textColor, 
                fontSize: 14, 
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0
              ),
            ),
            Text(
              'MSWD Admin',
              style: TextStyle(
                color: widget.theme.subtextColor, 
                fontSize: 10, 
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: _isUpdating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : _buildStatusPill(),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          children: [
            _buildPatientProfileHeader(primaryColor),
            const SizedBox(height: 24),
            _buildKeyStatsGrid(primaryColor),
            const SizedBox(height: 24),
            _buildMessageBubble(),
            const SizedBox(height: 24),
            _buildLocationCard(),
            const SizedBox(height: 24),
            _buildCaretakerCard(primaryColor),
            const SizedBox(height: 24),
            _buildTimelineSection(primaryColor),
            const SizedBox(height: 40),
            _buildAdminControls(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientProfileHeader(Color primaryColor) {
    final profileImageUrl = _patientData?['profileImageUrl'] as String?;
    final contactNumber = _patientData?['contactNumber'] ?? _patientData?['phone'] ?? 'Not Provided';

    return Column(
      children: [
        Hero(
          tag: 'avatar_${_currentRequest.id}',
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isDarkMode ? Colors.white30 : Colors.black, 
                width: 1.5
              ),
              boxShadow: widget.isDarkMode ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: ClipOval(
              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildDefaultAvatar(_currentRequest.patientName, primaryColor),
                    )
                  : _buildDefaultAvatar(_currentRequest.patientName, primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _currentRequest.patientName,
          style: TextStyle(
            fontSize: 24,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _callPhone(contactNumber),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.call_rounded, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  contactNumber,
                  style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyStatsGrid(Color primaryColor) {
    final priorityColor = _getPriorityColor(_currentRequest.priority);
    final icon = _getRequestIcon(_currentRequest.requestType);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: icon,
            color: primaryColor,
            label: 'Type',
            value: _currentRequest.requestType,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            icon: Icons.priority_high_rounded,
            color: priorityColor,
            label: 'Priority',
            value: _currentRequest.priority.name.toUpperCase(),
            isBold: true,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            icon: Icons.access_time_filled_rounded,
            color: Colors.blueGrey,
            label: 'Time',
            value: _formatShortTime(_currentRequest.timestamp),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon, 
    required Color color, 
    required String label, 
    required String value,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? color : widget.theme.textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: widget.theme.subtextColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() => Container(height: 40, width: 1, color: widget.theme.subtextColor.withValues(alpha: 0.15));

  Widget _buildMessageBubble() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('REQUEST MESSAGE', style: _sectionHeaderStyle()),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.white10 : const Color(0xFFF3F4F6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(6), 
            ),
          ),
          child: Text(
            _currentRequest.message,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: widget.theme.textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    if (_currentRequest.location == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('GPS LOCATION', style: _sectionHeaderStyle()),
        ),
        InkWell(
          onTap: _openMap, // Working Map Action
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map_rounded, color: Color(0xFF3B82F6), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Location Attached', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to open in Google Maps', 
                        style: TextStyle(color: const Color(0xFF3B82F6).withValues(alpha: 0.7), fontSize: 12)
                      ),
                    ],
                  )
                ),
                const Icon(Icons.open_in_new_rounded, color: Color(0xFF3B82F6), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaretakerCard(Color primaryColor) {
    final hasCaretaker = _currentRequest.caretakerId != null;
    final name = _caretakerData?['name'] ?? 'Unknown Responder';
    final img = _caretakerData?['profileImageUrl'];
    final caretakerPhone = _caretakerData?['contactNumber'] ?? _caretakerData?['phone'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('ASSIGNED RESPONDER', style: _sectionHeaderStyle()),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasCaretaker ? primaryColor.withValues(alpha: 0.3) : (widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
              width: hasCaretaker ? 1.5 : 1.0,
            ),
            boxShadow: widget.isDarkMode ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: hasCaretaker
              ? Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.1),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
                        image: (img != null && img.isNotEmpty) ? DecorationImage(image: NetworkImage(img), fit: BoxFit.cover) : null,
                      ),
                      child: (img == null || img.isEmpty) ? Icon(Icons.security_rounded, color: primaryColor) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.theme.textColor)),
                          const SizedBox(height: 2),
                          Text('Caretaker', style: TextStyle(color: widget.theme.subtextColor, fontSize: 11,)),
                        ],
                      ),
                    ),
                    if (caretakerPhone != null && caretakerPhone.toString().isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                          color: Colors.green,
                          onPressed: () => _callPhone(caretakerPhone), // Call caretaker
                        ),
                      ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? Colors.white10 : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_search_rounded, color: widget.theme.subtextColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'No caretaker assigned yet',
                      style: TextStyle(color: widget.theme.subtextColor, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection(Color primaryColor) {
    DateTime? responseTime;
    DateTime? completedTime;
    
    try { responseTime = _currentRequest.responseTime; } catch (_) {}
    try { completedTime = _currentRequest.completedTime; } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('LOG TIMELINE', style: _sectionHeaderStyle()),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
            boxShadow: widget.isDarkMode ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              _buildTimelineStep(
                primaryColor: primaryColor,
                title: 'Request Created',
                time: _currentRequest.timestamp,
                isActive: true,
                isTop: true,
              ),
              _buildTimelineStep(
                primaryColor: primaryColor,
                title: 'Caretaker Assigned / Accepted',
                time: responseTime,
                isActive: _currentRequest.status.index > RequestStatus.pending.index && _currentRequest.status != RequestStatus.declined,
              ),
              _buildTimelineStep(
                primaryColor: primaryColor,
                title: 'Request Completed',
                time: completedTime,
                isActive: _currentRequest.status == RequestStatus.completed,
                isBottom: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required Color primaryColor,
    required String title,
    DateTime? time,
    bool isActive = false,
    bool isTop = false,
    bool isBottom = false,
  }) {
    final color = isActive ? primaryColor : widget.theme.subtextColor.withValues(alpha: 0.3);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isTop) Expanded(child: Container(width: 2, color: color)),
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? primaryColor : widget.theme.cardColor,
                    border: Border.all(color: color, width: 2.5),
                  ),
                ),
                if (!isBottom) Expanded(child: Container(width: 2, color: color)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isBottom ? 0 : 24.0, top: isTop ? 0 : 0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start, 
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive ? widget.theme.textColor : widget.theme.subtextColor,
                      fontSize: 15,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (time != null)
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(time),
                      style: TextStyle(color: widget.theme.subtextColor, fontSize: 12, fontWeight: FontWeight.w500),
                    )
                  else if (isActive)
                     Text(
                      'Marked Active', 
                      style: TextStyle(color: widget.theme.subtextColor, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminControls(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('ADMIN ACTIONS', style: _sectionHeaderStyle()),
        ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _showAdminStatusUpdateDialog,
            icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
            label: const Text('MSWD Update Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.cardColor,
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor.withValues(alpha: 0.5), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0, 
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill() {
    final color = _getStatusColor(_currentRequest.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        _currentRequest.status.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name, Color primaryColor) {
    return Container(
      color: primaryColor,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  TextStyle _sectionHeaderStyle() => TextStyle(
    color: widget.theme.subtextColor,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.0,
  );

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending: return const Color(0xFFF5A623);
      case RequestStatus.accepted: return const Color(0xFF3B82F6);
      case RequestStatus.inProgress: return const Color(0xFF8B5CF6);
      case RequestStatus.completed: return const Color(0xFF10B981);
      case RequestStatus.declined: return const Color(0xFFEF4444);
    }
  }

  String _formatShortTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}