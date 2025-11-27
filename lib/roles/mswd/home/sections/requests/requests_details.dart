// File: lib/roles/mswd/home/sections/requests/request_details.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/models/request_model.dart';
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
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              _buildRequestDetailsHeader(context),
              SizedBox(height: spacingLarge),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                ),
                child: _buildRequestDetailsContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestDetailsHeader(BuildContext context) {
    final profileImageUrl = _patientData?['profileImageUrl'] as String?;
    
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(radiusXLarge),
          bottomRight: Radius.circular(radiusXLarge),
        ),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: widget.theme.textColor,
                  size: 24,
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Text(
                  'Request Details',
                  style: h2.copyWith(
                    fontSize: 20,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacingSmall,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.request.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radiusSmall),
                ),
                child: Text(
                  widget.request.status.toString().split('.').last,
                  style: caption.copyWith(
                    fontSize: 11,
                    color: _getStatusColor(widget.request.status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacingLarge),
          
          // Patient Profile Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isDarkMode ? primary.withOpacity(0.3) : Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(widget.request.patientName),
                    )
                  : _buildDefaultAvatar(widget.request.patientName),
            ),
          ),
          
          SizedBox(height: spacingMedium),
          Text(
            widget.request.patientName,
            style: h2.copyWith(
              fontSize: 20,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Request ID: ${widget.request.id}',
            style: caption.copyWith(
              fontSize: 12,
              color: widget.theme.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: primaryGradient,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: h2.copyWith(
            color: white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestDetailsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBasicInfoSection(),
        SizedBox(height: spacingLarge),
        _buildCaretakerSection(),
        SizedBox(height: spacingLarge),
        _buildTimestampsSection(),
        SizedBox(height: spacingLarge),
        _buildLocationSection(),
        SizedBox(height: spacingLarge),
        _buildNotesSection(),
        SizedBox(height: spacingLarge),
        _buildActionButtons(),
        SizedBox(height: spacingLarge),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    final priorityColor = widget.request.getPriorityColor();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Information',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildDetailCard('Request Type', widget.request.requestType, widget.request.getIcon()),
        _buildDetailCard(
          'Priority Level',
          widget.request.priority.toString().split('.').last,
          Icons.priority_high_rounded,
          color: priorityColor,
        ),
        _buildDetailCard(
          'Status',
          widget.request.status.toString().split('.').last,
          _getStatusIcon(widget.request.status),
          color: _getStatusColor(widget.request.status),
        ),
      ],
    );
  }

  Widget _buildCaretakerSection() {
    final caretakerProfileUrl = _caretakerData?['profileImageUrl'] as String?;
    final caretakerName = _caretakerData?['name'] as String?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned Caretaker',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        if (widget.request.caretakerId != null && caretakerName != null)
          Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                // Caretaker Profile Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isDarkMode ? accent.withOpacity(0.3) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: caretakerProfileUrl != null && caretakerProfileUrl.isNotEmpty
                        ? Image.network(
                            caretakerProfileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildCaretakerDefaultAvatar(caretakerName),
                          )
                        : _buildCaretakerDefaultAvatar(caretakerName),
                  ),
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caretakerName,
                        style: bodyBold.copyWith(
                          fontSize: 15,
                          color: widget.theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.request.responseTime != null
                            ? 'Responded: ${_formatTimeAgo(widget.request.responseTime!)}'
                            : 'Not responded yet',
                        style: caption.copyWith(
                          fontSize: 12,
                          color: widget.theme.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: widget.theme.subtextColor,
                ),
              ],
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_off_rounded,
                  color: widget.theme.subtextColor,
                  size: 24,
                ),
                SizedBox(width: spacingMedium),
                Text(
                  'No caretaker assigned',
                  style: body.copyWith(
                    fontSize: 14,
                    color: widget.theme.subtextColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCaretakerDefaultAvatar(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withOpacity(0.7)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.favorite_rounded,
          color: white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildTimestampsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        _buildTimelineItem(
          'Created',
          widget.request.timestamp,
          Icons.add_circle_rounded,
          Colors.blue,
          isFirst: true,
        ),
        if (widget.request.responseTime != null)
          _buildTimelineItem(
            widget.request.status == RequestStatus.declined ? 'Declined' : 'Accepted',
            widget.request.responseTime!,
            widget.request.status == RequestStatus.declined
                ? Icons.cancel_rounded
                : Icons.check_circle_rounded,
            widget.request.status == RequestStatus.declined ? Colors.red : Colors.green,
          ),
        if (widget.request.completedTime != null)
          _buildTimelineItem(
            'Completed',
            widget.request.completedTime!,
            Icons.done_all_rounded,
            Colors.green,
            isLast: true,
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String label,
    DateTime timestamp,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: widget.theme.subtextColor.withOpacity(0.3),
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 18),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: widget.theme.subtextColor.withOpacity(0.3),
              ),
          ],
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp),
                  style: caption.copyWith(
                    fontSize: 12,
                    color: widget.theme.subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    if (widget.request.location == null) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        Container(
          padding: EdgeInsets.all(spacingMedium),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
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
                  color: primary.withOpacity(0.1),
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: primary,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Available',
                      style: bodyBold.copyWith(
                        fontSize: 14,
                        color: widget.theme.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lat: ${widget.request.location!['latitude']}, Long: ${widget.request.location!['longitude']}',
                      style: caption.copyWith(
                        fontSize: 12,
                        color: widget.theme.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacingMedium),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(spacingMedium),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusLarge),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Text(
            widget.request.message,
            style: body.copyWith(
              fontSize: 14,
              color: widget.theme.textColor,
              height: 1.5,
            ),
          ),
        ),
        if (widget.request.caretakerResponse != null) ...[
          SizedBox(height: spacingMedium),
          Text(
            'Caretaker Response',
            style: bodyBold.copyWith(
              fontSize: 16,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacingSmall),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Text(
              widget.request.caretakerResponse!,
              style: body.copyWith(
                fontSize: 14,
                color: widget.theme.textColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    final status = widget.request.status;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == RequestStatus.pending) ...[
          _buildActionButton(
            'Assign Caretaker',
            Icons.person_add_rounded,
            primary,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Assign caretaker feature coming soon')),
              );
            },
          ),
        ] else if (status == RequestStatus.inProgress) ...[
          _buildActionButton(
            'Track Location',
            Icons.my_location_rounded,
            primary,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Location tracking feature coming soon')),
              );
            },
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            'Contact Caretaker',
            Icons.phone_rounded,
            accent,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Contact feature coming soon')),
              );
            },
          ),
        ],
        SizedBox(height: spacingMedium),
        _buildActionButton(
          'View Patient Profile',
          Icons.account_circle_rounded,
          Colors.blue,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('View profile feature coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: outlined
            ? Border.all(color: color.withOpacity(0.3))
            : Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusLarge),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacingMedium,
              vertical: spacingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Container(
        padding: EdgeInsets.all(spacingMedium),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
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
                      color: widget.theme.subtextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: body.copyWith(
                      fontSize: 14,
                      color: widget.theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.accepted:
        return Colors.blue;
      case RequestStatus.inProgress:
        return Colors.purple;
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.declined:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.pending_actions_rounded;
      case RequestStatus.accepted:
        return Icons.check_circle_rounded;
      case RequestStatus.inProgress:
        return Icons.sync_rounded;
      case RequestStatus.completed:
        return Icons.done_all_rounded;
      case RequestStatus.declined:
        return Icons.cancel_rounded;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}