// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/models/request_model.dart';
import 'package:seelai_app/roles/caretaker/services/request_service.dart';
import 'package:intl/intl.dart';

class RequestDetailsScreen extends StatefulWidget {
  final RequestModel request;
  final bool isDarkMode;
  final RequestService requestService;

  const RequestDetailsScreen({
    super.key,
    required this.request,
    required this.isDarkMode,
    required this.requestService,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final TextEditingController _responseController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isProcessing = false;
  late RequestModel _currentRequest;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
  }

  @override
  void dispose() {
    _responseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _acceptRequest() async {
    setState(() => _isProcessing = true);
    
    final success = await widget.requestService.acceptRequest(
      _currentRequest.id,
      'caretaker_1', // Replace with actual caretaker ID
    );
    
    if (mounted) {
      setState(() => _isProcessing = false);
      
      if (success) {
        // Update local state
        setState(() {
          _currentRequest = _currentRequest.copyWith(
            status: RequestStatus.accepted,
            responseTime: DateTime.now(),
          );
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request accepted! You can now mark it in progress or complete it.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _markInProgress() async {
    setState(() => _isProcessing = true);
    
    final success = await widget.requestService.markInProgress(
      _currentRequest.id,
    );
    
    if (mounted) {
      setState(() => _isProcessing = false);
      
      if (success) {
        setState(() {
          _currentRequest = _currentRequest.copyWith(
            status: RequestStatus.inProgress,
          );
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request marked as in progress'),
            backgroundColor: accent,
          ),
        );
      }
    }
  }

  Future<void> _completeRequest() async {
    final notes = await _showNotesDialog();
    if (notes == null) return;
    
    setState(() => _isProcessing = true);
    
    final success = await widget.requestService.completeRequest(
      _currentRequest.id,
      'caretaker_1', // Replace with actual caretaker ID
      notes,
    );
    
    if (mounted) {
      setState(() => _isProcessing = false);
      
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _declineRequest() async {
    final reason = await _showDeclineDialog();
    if (reason == null) return;
    
    setState(() => _isProcessing = true);
    
    final success = await widget.requestService.declineRequest(
      _currentRequest.id,
      'caretaker_1', // Replace with actual caretaker ID
      reason,
    );
    
    if (mounted) {
      setState(() => _isProcessing = false);
      
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request declined'),
            backgroundColor: error,
          ),
        );
      }
    }
  }

  Future<String?> _showDeclineDialog() {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: error),
            SizedBox(width: spacingSmall),
            Text('Decline Request'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Reason for declining...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: error,
              foregroundColor: white,
            ),
            child: Text('Decline'),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: spacingSmall),
            Text('Complete Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add completion notes (optional)',
              style: body.copyWith(fontSize: 14),
            ),
            SizedBox(height: spacingMedium),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'What did you do to help?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.isEmpty ? 'Completed' : controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: white,
            ),
            child: Text('Complete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? Color(0xFF0A0E27) : backgroundPrimary;
    final textColor = widget.isDarkMode ? white : black;
    final subtextColor = widget.isDarkMode ? Color(0xFFB0B8D4) : grey;
    final cardColor = widget.isDarkMode ? Color(0xFF1A1F3A) : white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Request Details',
          style: h2.copyWith(color: textColor, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _currentRequest.getPriorityColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(radiusMedium),
                border: Border.all(
                  color: _currentRequest.getPriorityColor(),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag_rounded,
                    color: _currentRequest.getPriorityColor(),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _currentRequest.priority.toString().split('.').last.toUpperCase(),
                    style: bodyBold.copyWith(
                      color: _currentRequest.getPriorityColor(),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Patient Info Card
            Container(
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(radiusLarge),
                boxShadow: widget.isDarkMode
                    ? [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 16)]
                    : softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacingLarge),
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_rounded, color: white, size: 32),
                  ),
                  SizedBox(width: spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentRequest.patientName,
                          style: bodyBold.copyWith(
                            fontSize: 20,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: spacingXSmall),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(_currentRequest.timestamp),
                          style: caption.copyWith(
                            fontSize: 13,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Request Type
            Text('Request Type', style: bodyBold.copyWith(fontSize: 16, color: textColor)),
            SizedBox(height: spacingSmall),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(radiusMedium),
                border: Border.all(color: subtextColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(_currentRequest.getIcon(), color: primary, size: 24),
                  SizedBox(width: spacingMedium),
                  Text(
                    _currentRequest.requestType,
                    style: body.copyWith(fontSize: 16, color: textColor),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Message
            Text('Message', style: bodyBold.copyWith(fontSize: 16, color: textColor)),
            SizedBox(height: spacingSmall),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(radiusMedium),
                border: Border.all(color: subtextColor.withOpacity(0.3)),
              ),
              child: Text(
                _currentRequest.message,
                style: body.copyWith(fontSize: 15, color: textColor),
              ),
            ),
            
            if (_currentRequest.location != null) ...[
              SizedBox(height: spacingLarge),
              Text('Location', style: bodyBold.copyWith(fontSize: 16, color: textColor)),
              SizedBox(height: spacingSmall),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(spacingLarge),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(radiusMedium),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: Colors.green, size: 24),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Available',
                            style: bodyBold.copyWith(fontSize: 15, color: textColor),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Lat: ${_currentRequest.location!['latitude']}, Long: ${_currentRequest.location!['longitude']}',
                            style: caption.copyWith(fontSize: 13, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening map...')),
                        );
                      },
                      icon: Icon(Icons.map_rounded, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: spacingXLarge),
            
            // Action Buttons based on status
            _buildActionButtons(cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Color cardColor) {
    // PENDING: Show Accept/Decline buttons
    if (_currentRequest.status == RequestStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _declineRequest,
              icon: Icon(Icons.close_rounded),
              label: Text('Decline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor: error,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                  side: BorderSide(color: error),
                ),
              ),
            ),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _acceptRequest,
              icon: _isProcessing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: white,
                      ),
                    )
                  : Icon(Icons.check_rounded),
              label: Text(_isProcessing ? 'Processing...' : 'Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    // ACCEPTED: Show Mark In Progress and Complete buttons
    else if (_currentRequest.status == RequestStatus.accepted) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _markInProgress,
              icon: Icon(Icons.play_arrow_rounded),
              label: Text('Mark as In Progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
              ),
            ),
          ),
          SizedBox(height: spacingMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _completeRequest,
              icon: _isProcessing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: white,
                      ),
                    )
                  : Icon(Icons.check_circle_rounded),
              label: Text(_isProcessing ? 'Processing...' : 'Complete Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    // IN PROGRESS: Show Complete button only
    else if (_currentRequest.status == RequestStatus.inProgress) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isProcessing ? null : _completeRequest,
          icon: _isProcessing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: white,
                  ),
                )
              : Icon(Icons.check_circle_rounded),
          label: Text(_isProcessing ? 'Processing...' : 'Complete Request'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
          ),
        ),
      );
    }
    
    // COMPLETED or DECLINED: Show status badge
    else {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(spacingLarge),
        decoration: BoxDecoration(
          color: _getStatusColor(_currentRequest.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(radiusMedium),
          border: Border.all(
            color: _getStatusColor(_currentRequest.status),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(_currentRequest.status),
              color: _getStatusColor(_currentRequest.status),
            ),
            SizedBox(width: spacingSmall),
            Text(
              _currentRequest.status.toString().split('.').last.toUpperCase(),
              style: bodyBold.copyWith(
                color: _getStatusColor(_currentRequest.status),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.declined:
        return error;
      case RequestStatus.inProgress:
        return accent;
      default:
        return primary;
    }
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
        return Icons.check_circle_rounded;
      case RequestStatus.completed:
        return Icons.check_circle_outline_rounded;
      case RequestStatus.declined:
        return Icons.cancel_rounded;
      case RequestStatus.inProgress:
        return Icons.pending_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}