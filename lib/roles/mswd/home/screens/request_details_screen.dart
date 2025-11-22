// File: lib/roles/mswd/screens/request_details_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class RequestDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final bool isDarkMode;
  final dynamic theme;

  const RequestDetailsScreen({
    super.key,
    required this.request,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final priority = widget.request['priority'] ?? 'Medium';
    final priorityColor = priority == 'High' ? error : priority == 'Medium' ? Colors.orange : Colors.green;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: widget.theme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(priorityColor),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(width * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRequestHeader(priorityColor),
                      SizedBox(height: spacingLarge),
                      _buildPatientCard(),
                      SizedBox(height: spacingMedium),
                      _buildCaretakerCard(),
                      SizedBox(height: spacingLarge),
                      _buildRequestDetails(),
                      SizedBox(height: spacingLarge),
                      _buildLocationSection(),
                      SizedBox(height: spacingLarge),
                      _buildStatusTimeline(),
                      SizedBox(height: spacingLarge),
                      _buildAdminNotes(),
                      SizedBox(height: spacingXLarge),
                    ],
                  ),
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Color priorityColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_rounded, color: widget.theme.textColor),
          ),
          Expanded(
            child: Text(
              'Request Details',
              style: h3.copyWith(color: widget.theme.textColor, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(radiusMedium),
              border: Border.all(color: priorityColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_rounded, color: priorityColor, size: 16),
                SizedBox(width: 4),
                Text(
                  widget.request['priority'] ?? 'Medium',
                  style: caption.copyWith(color: priorityColor, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestHeader(Color priorityColor) {
    final status = widget.request['status'] ?? 'Pending';
    final statusColor = status == 'Completed' ? Colors.green : status == 'In Progress' ? Colors.blue : Colors.orange;

    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode ? [BoxShadow(color: priorityColor.withOpacity(0.15), blurRadius: 20)] : softShadow,
        border: widget.isDarkMode ? Border.all(color: priorityColor.withOpacity(0.3), width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacingMedium),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [priorityColor, priorityColor.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Icon(_getRequestIcon(widget.request['type']), color: white, size: 28),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request['type'] ?? 'Assistance Request',
                      style: h3.copyWith(color: widget.theme.textColor, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ID: REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 11)}',
                      style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacingLarge),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(Icons.access_time_rounded, widget.request['time'] ?? '10 mins ago', widget.theme.subtextColor),
              ),
              SizedBox(width: spacingSmall),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    SizedBox(width: 6),
                    Text(status, style: caption.copyWith(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Text(text, style: caption.copyWith(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildPatientCard() {
    return _buildPersonCard(
      title: 'Patient',
      name: widget.request['patient'] ?? 'Maria Santos',
      subtitle: 'Visually Impaired',
      icon: Icons.visibility_off_rounded,
      color: primary,
    );
  }

  Widget _buildCaretakerCard() {
    final hasCaretaker = widget.request['caretaker'] != null;
    
    return _buildPersonCard(
      title: 'Assigned Caretaker',
      name: hasCaretaker ? widget.request['caretaker'] : 'Not Assigned',
      subtitle: hasCaretaker ? 'Family Caregiver' : 'Tap to assign',
      icon: Icons.favorite_rounded,
      color: accent,
      showAction: !hasCaretaker,
    );
  }

  Widget _buildPersonCard({
    required String title,
    required String name,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool showAction = false,
  }) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: widget.isDarkMode ? Border.all(color: color.withOpacity(0.2)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            ),
            child: Center(child: Icon(icon, color: white, size: 24)),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 11)),
                SizedBox(height: 2),
                Text(name, style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 15)),
                Text(subtitle, style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12)),
              ],
            ),
          ),
          if (showAction)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(Icons.add_rounded, color: color, size: 20),
            )
          else
            Row(
              children: [
                IconButton(icon: Icon(Icons.call_rounded, color: Colors.green, size: 22), onPressed: () {}),
                IconButton(icon: Icon(Icons.message_rounded, color: primary, size: 22), onPressed: () {}),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRequestDetails() {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: widget.isDarkMode ? Border.all(color: primary.withOpacity(0.2)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request Details', style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 16)),
          SizedBox(height: spacingMedium),
          _buildDetailRow('Type', widget.request['type'] ?? 'Navigation Help'),
          _buildDetailRow('Priority', widget.request['priority'] ?? 'High'),
          _buildDetailRow('Submitted', widget.request['time'] ?? '10 mins ago'),
          Divider(color: widget.theme.subtextColor.withOpacity(0.2), height: spacingLarge * 2),
          Text('Message', style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12)),
          SizedBox(height: spacingSmall),
          Text(
            widget.request['message'] ?? 'I need help navigating to the nearby pharmacy. I ran out of my medication and need to refill my prescription.',
            style: body.copyWith(color: widget.theme.textColor, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: body.copyWith(color: widget.theme.subtextColor, fontSize: 13)),
          Text(value, style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: widget.isDarkMode ? Border.all(color: Colors.blue.withOpacity(0.2)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Location', style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 16)),
              TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.open_in_new_rounded, size: 16),
                label: Text('View Map', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          SizedBox(height: spacingMedium),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, size: 40, color: widget.theme.subtextColor.withOpacity(0.5)),
                  SizedBox(height: spacingSmall),
                  Text('Map Preview', style: caption.copyWith(color: widget.theme.subtextColor)),
                ],
              ),
            ),
          ),
          SizedBox(height: spacingMedium),
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: error, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.request['location'] ?? '123 Rizal Avenue, Makati City',
                  style: body.copyWith(color: widget.theme.textColor, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final timeline = [
      {'status': 'Request Created', 'time': '10:30 AM', 'completed': true},
      {'status': 'Caretaker Assigned', 'time': '10:32 AM', 'completed': true},
      {'status': 'Caretaker En Route', 'time': '10:35 AM', 'completed': true},
      {'status': 'In Progress', 'time': '10:45 AM', 'completed': false},
      {'status': 'Completed', 'time': '--', 'completed': false},
    ];

    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: widget.isDarkMode ? Border.all(color: primary.withOpacity(0.2)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Timeline', style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 16)),
          SizedBox(height: spacingLarge),
          ...timeline.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            final isLast = i == timeline.length - 1;
            final completed = t['completed'] as bool;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: completed ? Colors.green : widget.theme.subtextColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        completed ? Icons.check_rounded : Icons.circle,
                        color: white,
                        size: completed ? 16 : 8,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: completed ? Colors.green.withOpacity(0.5) : widget.theme.subtextColor.withOpacity(0.2),
                      ),
                  ],
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : spacingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['status'] as String,
                          style: bodyBold.copyWith(
                            color: completed ? widget.theme.textColor : widget.theme.subtextColor,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          t['time'] as String,
                          style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdminNotes() {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: widget.isDarkMode ? Border.all(color: primary.withOpacity(0.2)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Notes', style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 16)),
          SizedBox(height: spacingMedium),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: body.copyWith(color: widget.theme.textColor),
            decoration: InputDecoration(
              hintText: 'Add notes about this request...',
              hintStyle: body.copyWith(color: widget.theme.subtextColor.withOpacity(0.5)),
              filled: true,
              fillColor: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: spacingMedium),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note saved')));
              },
              icon: Icon(Icons.save_rounded, size: 18),
              label: Text('Save Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showEscalateDialog(),
              icon: Icon(Icons.priority_high_rounded),
              label: Text('Escalate'),
              style: OutlinedButton.styleFrom(
                foregroundColor: error,
                side: BorderSide(color: error),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
              ),
            ),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showReassignDialog(),
              icon: Icon(Icons.swap_horiz_rounded),
              label: Text('Reassign'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
              ),
            ),
          ),
          SizedBox(width: spacingMedium),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.check_circle_rounded),
              label: Text('Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRequestIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'navigation help': return Icons.navigation_rounded;
      case 'reading assistance': return Icons.menu_book_rounded;
      case 'emergency': return Icons.emergency_rounded;
      default: return Icons.help_rounded;
    }
  }

  void _showEscalateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        title: Row(
          children: [
            Icon(Icons.priority_high_rounded, color: error),
            SizedBox(width: 8),
            Text('Escalate Request', style: bodyBold.copyWith(color: widget.theme.textColor)),
          ],
        ),
        content: Text('This will mark the request as high priority and notify senior staff.', style: body.copyWith(color: widget.theme.subtextColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request escalated')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: error),
            child: Text('Escalate'),
          ),
        ],
      ),
    );
  }

  void _showReassignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        title: Text('Reassign Caretaker', style: bodyBold.copyWith(color: widget.theme.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select a new caretaker:', style: body.copyWith(color: widget.theme.subtextColor)),
            SizedBox(height: spacingMedium),
            ListTile(
              leading: CircleAvatar(backgroundColor: accent, child: Text('RM', style: TextStyle(color: white))),
              title: Text('Rosa Martinez', style: body.copyWith(color: widget.theme.textColor)),
              subtitle: Text('Available', style: caption.copyWith(color: Colors.green)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reassigned to Rosa Martinez')));
              },
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: accent, child: Text('CR', style: TextStyle(color: white))),
              title: Text('Carlos Reyes', style: body.copyWith(color: widget.theme.textColor)),
              subtitle: Text('Available', style: caption.copyWith(color: Colors.green)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reassigned to Carlos Reyes')));
              },
            ),
          ],
        ),
      ),
    );
  }
}