// File: lib/roles/mswd/home/sections/requests/request_details.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _patientData = widget.userDataCache[widget.request.patientId];
    if (widget.request.caretakerId != null) {
      _caretakerData = widget.userDataCache[widget.request.caretakerId!];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine background color based on theme
    final bgColor = widget.isDarkMode ? const Color(0xFF0F1429) : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        title: Text(
          'Ref #${widget.request.id.substring(0, 6).toUpperCase()}',
          style: TextStyle(
            color: widget.theme.subtextColor, 
            fontSize: 14, 
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: _buildStatusPill()),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildKeyStatsGrid(),
            const SizedBox(height: 24),
            _buildMessageBubble(),
            const SizedBox(height: 24),
            _buildCaretakerCard(),
            const SizedBox(height: 24),
            _buildTimelineSection(),
            const SizedBox(height: 24),
            _buildLocationCard(),
            const SizedBox(height: 40),
            _buildPrimaryAction(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Profile Header with the specific Black Outline
  // ---------------------------------------------------------------------------
  Widget _buildProfileHeader() {
    final profileImageUrl = _patientData?['profileImageUrl'] as String?;

    return Column(
      children: [
        Hero(
          tag: 'avatar_${widget.request.id}',
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // SPECIFIC REQUEST: Black outline, not too thick (1.5)
              border: Border.all(
                color: Colors.black, 
                width: 1.5
              ),
              boxShadow: [
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
                      errorBuilder: (_, _, _) => _buildDefaultAvatar(widget.request.patientName),
                    )
                  : _buildDefaultAvatar(widget.request.patientName),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.request.patientName,
          style: h2.copyWith(
            fontSize: 24,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 14, color: widget.theme.subtextColor),
            const SizedBox(width: 4),
            Text(
              widget.request.location != null ? 'Location Attached' : 'No Location',
              style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Key Stats Grid (Replaces the vertical list)
  // ---------------------------------------------------------------------------
  Widget _buildKeyStatsGrid() {
    final priorityColor = widget.request.getPriorityColor();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: widget.request.getIcon(),
            color: primary,
            label: 'Type',
            value: widget.request.requestType,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            icon: Icons.priority_high_rounded,
            color: priorityColor,
            label: 'Priority',
            value: widget.request.priority.name.toUpperCase(),
            isBold: true,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            icon: Icons.access_time_filled_rounded,
            color: Colors.blueGrey,
            label: 'Time',
            value: _formatShortTime(widget.request.timestamp),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? color : widget.theme.textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: widget.theme.subtextColor),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() => Container(height: 30, width: 1, color: widget.theme.subtextColor.withOpacity(0.2));

  // ---------------------------------------------------------------------------
  // 3. Message Bubble
  // ---------------------------------------------------------------------------
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
            color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2F6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4), // Chat bubble effect
            ),
          ),
          child: Text(
            widget.request.message,
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

  // ---------------------------------------------------------------------------
  // 4. Caretaker Card
  // ---------------------------------------------------------------------------
  Widget _buildCaretakerCard() {
    final hasCaretaker = widget.request.caretakerId != null;
    final name = _caretakerData?['name'] ?? 'Unknown';
    final img = _caretakerData?['profileImageUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('RESPONDER', style: _sectionHeaderStyle()),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasCaretaker ? primary.withValues(alpha: 0.3) : widget.theme.subtextColor.withValues(alpha: 0.2),
            ),
          ),
          child: hasCaretaker
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: (img != null && img.isNotEmpty) ? NetworkImage(img) : null,
                      backgroundColor: primary.withValues(alpha: 0.1),
                      child: (img == null || img.isEmpty) ? Icon(Icons.person, color: primary) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.theme.textColor)),
                          const SizedBox(height: 2),
                          Text('Assigned Caretaker', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone_in_talk_rounded),
                      color: primary,
                      onPressed: () {}, // Action
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(Icons.person_search_rounded, color: widget.theme.subtextColor, size: 30),
                    const SizedBox(width: 16),
                    Text(
                      'No caretaker assigned yet',
                      style: TextStyle(color: widget.theme.subtextColor, fontSize: 14),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Clean Timeline
  // ---------------------------------------------------------------------------
  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('TIMELINE', style: _sectionHeaderStyle()),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildTimelineStep(
                title: 'Request Created',
                time: widget.request.timestamp,
                isActive: true,
                isTop: true,
              ),
              _buildTimelineStep(
                title: 'Caretaker Assigned',
                time: widget.request.responseTime,
                isActive: widget.request.status.index > RequestStatus.pending.index,
              ),
              _buildTimelineStep(
                title: 'Completed',
                time: widget.request.completedTime,
                isActive: widget.request.status == RequestStatus.completed,
                isBottom: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    DateTime? time,
    bool isActive = false,
    bool isTop = false,
    bool isBottom = false,
  }) {
    final color = isActive ? primary : widget.theme.subtextColor.withOpacity(0.3);
    
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
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? primary : Colors.transparent,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
                if (!isBottom) Expanded(child: Container(width: 2, color: color)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isBottom ? 0 : 24.0, top: isTop ? 0 : 0), // Adjust alignment
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start, // Align to top of step
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? widget.theme.textColor : widget.theme.subtextColor,
                      fontSize: 14,
                    ),
                  ),
                  if (time != null)
                    Text(
                      DateFormat('MMM dd, hh:mm a').format(time),
                      style: TextStyle(color: widget.theme.subtextColor, fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Components
  // ---------------------------------------------------------------------------
  Widget _buildLocationCard() {
    if (widget.request.location == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_rounded, color: Colors.blue),
          const SizedBox(width: 12),
          const Expanded(child: Text('GPS Location Available', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
          const Icon(Icons.arrow_forward_rounded, color: Colors.blue, size: 18),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction() {
    if (widget.request.status == RequestStatus.pending) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: primary.withValues(alpha: 0.4),
          ),
          child: const Text('Assign Caretaker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusPill() {
    final color = _getStatusColor(widget.request.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        widget.request.status.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      color: primary,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
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
      case RequestStatus.pending: return Colors.orange;
      case RequestStatus.accepted: return Colors.blue;
      case RequestStatus.inProgress: return Colors.purple;
      case RequestStatus.completed: return Colors.green;
      case RequestStatus.declined: return Colors.red;
    }
  }

  String _formatShortTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}