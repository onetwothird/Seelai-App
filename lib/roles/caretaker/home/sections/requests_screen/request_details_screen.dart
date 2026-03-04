// File: lib/roles/caretaker/home/sections/requests_screen/request_details_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/firebase/caretaker/request_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:intl/intl.dart';

class RequestDetailsScreen extends StatefulWidget {
  final RequestModel request;
  final bool isDarkMode;
  final RequestService requestService;
  final String? preloadedProfileImage;

  const RequestDetailsScreen({
    super.key,
    required this.request,
    required this.isDarkMode,
    required this.requestService,
    this.preloadedProfileImage,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  bool _isProcessing = false;
  late RequestModel _currentRequest;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
    _profileImageUrl = widget.preloadedProfileImage;
    
    if (_profileImageUrl == null) {
      _loadProfileImage();
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final userData = await databaseService.getUserData(_currentRequest.patientId);
      if (mounted) {
        setState(() {
          _profileImageUrl = userData?['profileImageUrl'] as String?;
        });
      }
    } catch (e) {
      debugPrint("Error loading image: $e");
    }
  }

  // ==================== LOGIC METHODS ====================

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _acceptRequest() async {
    setState(() => _isProcessing = true);
    final success = await widget.requestService.acceptRequest(
      _currentRequest.id,
      _currentUserId, 
    );
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        setState(() {
          _currentRequest = _currentRequest.copyWith(
            status: RequestStatus.accepted,
            responseTime: DateTime.now(),
          );
        });
        _showSnackbar('Request accepted!', Colors.green);
      }
    }
  }

  Future<void> _markInProgress() async {
    setState(() => _isProcessing = true);
    final success = await widget.requestService.markInProgress(_currentRequest.id);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        setState(() {
          _currentRequest = _currentRequest.copyWith(status: RequestStatus.inProgress);
        });
        _showSnackbar('Marked as in progress', accent);
      }
    }
  }

  Future<void> _completeRequest() async {
    final notes = await _showNotesDialog();
    if (notes == null) return;
    setState(() => _isProcessing = true);
    final success = await widget.requestService.completeRequest(
      _currentRequest.id,
      _currentUserId,
      notes,
    );
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.pop(context);
        _showSnackbar('Request completed!', Colors.green);
      }
    }
  }

  Future<void> _declineRequest() async {
    final reason = await _showDeclineDialog();
    if (reason == null) return;
    setState(() => _isProcessing = true);
    final success = await widget.requestService.declineRequest(
      _currentRequest.id,
      _currentUserId,
      reason,
    );
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.pop(context);
        _showSnackbar('Request declined', error);
      }
    }
  }

  // ==================== UI BUILDER ====================

  @override
  Widget build(BuildContext context) {
    // --- UPDATED: FORCED WHITE BACKGROUND THEME ---
    const bgColor = Colors.white; 
    const cardColor = Colors.white; 
    const textColor = Colors.black87; 
    final subColor = Colors.grey[600];
    
    // Responsive calculations
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey[100], // Slight contrast for back button
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Ref #${_currentRequest.id.substring(0, 6).toUpperCase()}',
          style: TextStyle(
            color: subColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
           Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: _buildStatusPill(textColor)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 20),
                    child: Column(
                      children: [
                        // 1. MSWD Style Profile Header (Hero)
                        _buildProfileHeader(textColor, subColor!),
                        
                        const SizedBox(height: 24),
                        
                        // 2. MSWD Style Stats Grid
                        _buildKeyStatsGrid(cardColor, textColor, subColor),
                        
                        const SizedBox(height: 24),
                        
                        // 3. Message Bubble
                        _buildMessageBubble(cardColor, textColor, subColor),
                        
                        const SizedBox(height: 24),

                        // 4. Location Card
                        if (_currentRequest.location != null)
                          _buildLocationCard(cardColor, textColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 5. Fixed Bottom Action Area
          _buildBottomActionArea(cardColor),
        ],
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildProfileHeader(Color textColor, Color subColor) {
    return Column(
      children: [
        Hero(
          tag: 'avatar_${_currentRequest.id}',
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              border: Border.all(
                color: Colors.black,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: _profileImageUrl != null
                  ? Image.network(
                      _profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            _currentRequest.patientName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time_rounded, size: 14, color: subColor),
            const SizedBox(width: 6),
            Text(
              DateFormat('MMM dd • hh:mm a').format(_currentRequest.timestamp),
              style: TextStyle(
                fontSize: 14,
                color: subColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyStatsGrid(Color cardColor, Color textColor, Color subColor) {
    final priorityColor = _currentRequest.getPriorityColor();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        // Force shadow for white-on-white contrast
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildStatItem(
                icon: _currentRequest.getIcon(),
                color: primary,
                label: 'Type',
                value: _currentRequest.requestType.split(' ').first,
                textColor: textColor,
                subColor: subColor,
              ),
            ),
            _buildVerticalDivider(subColor),
            Expanded(
              child: _buildStatItem(
                icon: Icons.flag_rounded,
                color: priorityColor,
                label: 'Priority',
                value: _currentRequest.priority.name.toUpperCase(),
                textColor: textColor,
                subColor: subColor,
                isBold: true,
              ),
            ),
            _buildVerticalDivider(subColor),
            Expanded(
              child: _buildStatItem(
                icon: Icons.timer_rounded,
                color: Colors.blueGrey,
                label: 'Time Ago',
                value: _getTimeAgo(_currentRequest.timestamp),
                textColor: textColor,
                subColor: subColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required Color textColor,
    required Color subColor,
    bool isBold = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: isBold ? color : textColor,
              ),
            ),
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: subColor),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(Color color) => Container(
    width: 1, 
    color: color.withValues(alpha: 0.2),
    margin: const EdgeInsets.symmetric(vertical: 4),
  );

  Widget _buildMessageBubble(Color cardColor, Color textColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'REQUEST MESSAGE', 
            style: TextStyle(
              color: subColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            )
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // Use light grey for message bubble to stand out on white bg
            color: const Color(0xFFF3F4F6), 
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Text(
            _currentRequest.message,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening Maps...')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to view on map',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(Color textColor) {
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
        style: TextStyle(
          color: color, 
          fontWeight: FontWeight.bold, 
          fontSize: 10, 
          letterSpacing: 0.5
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.person, size: 40, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildBottomActionArea(Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false, 
        child: _buildActionButtons(),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentRequest.status == RequestStatus.pending) {
      return Row(
        children: [
          // DECLINE BUTTON
          Expanded(
            flex: 1, 
            child: _buildButton(
              label: 'Decline',
              icon: Icons.close_rounded,
              color: Colors.transparent,
              textColor: error,
              borderColor: error, 
              onTap: _declineRequest,
            ),
          ),
          const SizedBox(width: 16),
          // ACCEPT BUTTON
          Expanded(
            flex: 1, 
            child: _buildButton(
              label: 'Accept',
              icon: Icons.check_rounded,
              color: Colors.green,
              textColor: Colors.white,
              onTap: _acceptRequest,
              isFilled: true,
            ),
          ),
        ],
      );
    } else if (_currentRequest.status == RequestStatus.accepted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            label: 'Mark In Progress',
            icon: Icons.play_arrow_rounded,
            color: accent,
            textColor: Colors.white,
            onTap: _markInProgress,
            isFilled: true,
            isFullWidth: true,
          ),
          const SizedBox(height: 12),
          _buildButton(
            label: 'Complete Request',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
            textColor: Colors.white,
            onTap: _completeRequest,
            isFilled: true,
            isFullWidth: true,
          ),
        ],
      );
    } else if (_currentRequest.status == RequestStatus.inProgress) {
      return _buildButton(
        label: 'Complete Request',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        textColor: Colors.white,
        onTap: _completeRequest,
        isFilled: true,
        isFullWidth: true,
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Request ${_currentRequest.status.name.toUpperCase()}',
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    Color? borderColor,
    bool isFilled = false,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      height: 56,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFilled ? color : Colors.transparent,
          foregroundColor: textColor,
          elevation: isFilled ? 4 : 0,
          shadowColor: isFilled ? color.withValues(alpha: 0.4) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: borderColor != null 
                ? BorderSide(color: borderColor, width: 1.5) 
                : BorderSide.none,
          ),
        ),
        child: _isProcessing && isFilled
            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: textColor, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Flexible( 
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ==================== DIALOGS ====================
  
  Future<String?> _showDeclineDialog() {
    final controller = TextEditingController();
    // Enforced white dialogs
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Decline Request'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Reason for declining...',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Decline', style: TextStyle(color: error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showNotesDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Complete Request'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Add notes (optional)...',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.isEmpty ? 'Completed' : controller.text),
            child: const Text('Complete', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
      case RequestStatus.completed: return Colors.green;
      case RequestStatus.declined: return error;
      case RequestStatus.inProgress: return accent;
      default: return primary;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}