import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/themes/widgets.dart';
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
  bool _isProcessing = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _acceptRequest() async {
    setState(() => _isProcessing = true);
    
    final success = await widget.requestService.acceptRequest(
      widget.request.id,
      'caretaker_1', // TODO: Use actual caretaker ID
    );
    
    if (mounted) {
      setState(() => _isProcessing = false);
      
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request accepted'),
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
      widget.request.id,
      'caretaker_1',
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
        title: Text('Decline Request'),
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
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Decline', style: TextStyle(color: error)),
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
                color: widget.request.getPriorityColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(radiusMedium),
                border: Border.all(
                  color: widget.request.getPriorityColor(),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag_rounded,
                    color: widget.request.getPriorityColor(),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    widget.request.priority.toString().split('.').last.toUpperCase(),
                    style: bodyBold.copyWith(
                      color: widget.request.getPriorityColor(),
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
                          widget.request.patientName,
                          style: bodyBold.copyWith(
                            fontSize: 20,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: spacingXSmall),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(widget.request.timestamp),
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
                  Icon(widget.request.getIcon(), color: primary, size: 24),
                  SizedBox(width: spacingMedium),
                  Text(
                    widget.request.requestType,
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
                widget.request.message,
                style: body.copyWith(fontSize: 15, color: textColor),
              ),
            ),
            
            if (widget.request.location != null) ...[
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
                            'Lat: ${widget.request.location!['latitude']}, Long: ${widget.request.location!['longitude']}',
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
            
            // Action Buttons
            if (widget.request.status == RequestStatus.pending) ...[
              Row(
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
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(spacingLarge),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.request.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(radiusMedium),
                  border: Border.all(
                    color: _getStatusColor(widget.request.status),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getStatusIcon(widget.request.status),
                      color: _getStatusColor(widget.request.status),
                    ),
                    SizedBox(width: spacingSmall),
                    Text(
                      widget.request.status.toString().split('.').last.toUpperCase(),
                      style: bodyBold.copyWith(
                        color: _getStatusColor(widget.request.status),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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