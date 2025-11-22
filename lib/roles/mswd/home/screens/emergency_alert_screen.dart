// File: lib/roles/mswd/screens/emergency_alert_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class EmergencyAlertScreen extends StatefulWidget {
  final Map<String, dynamic> alert;
  final bool isDarkMode;
  final dynamic theme;

  const EmergencyAlertScreen({
    super.key,
    required this.alert,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isResolved = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isEmergency = widget.alert['type'] == 'emergency';
    final alertColor = isEmergency ? error : Colors.orange;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: widget.theme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(alertColor),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(width * 0.05),
                  child: Column(
                    children: [
                      _buildAlertHeader(alertColor, isEmergency),
                      SizedBox(height: spacingLarge),
                      _buildUserInfo(),
                      SizedBox(height: spacingLarge),
                      _buildLocationMap(),
                      SizedBox(height: spacingLarge),
                      _buildEmergencyDetails(alertColor),
                      SizedBox(height: spacingLarge),
                      _buildEmergencyContacts(),
                      SizedBox(height: spacingLarge),
                      _buildActionLog(),
                      SizedBox(height: spacingXLarge),
                    ],
                  ),
                ),
              ),
              if (!_isResolved) _buildQuickActions(alertColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Color alertColor) {
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
              'Emergency Alert',
              style: h3.copyWith(color: widget.theme.textColor, fontWeight: FontWeight.w700),
            ),
          ),
          if (!_isResolved)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: alertColor,
                      borderRadius: BorderRadius.circular(radiusMedium),
                      boxShadow: [BoxShadow(color: alertColor.withOpacity(0.5), blurRadius: 12)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_rounded, color: white, size: 14),
                        SizedBox(width: 4),
                        Text('ACTIVE', style: caption.copyWith(color: white, fontWeight: FontWeight.w800, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(radiusMedium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: white, size: 14),
                  SizedBox(width: 4),
                  Text('RESOLVED', style: caption.copyWith(color: white, fontWeight: FontWeight.w800, fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertHeader(Color alertColor, bool isEmergency) {
    return Container(
      padding: EdgeInsets.all(spacingLarge * 1.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [alertColor, alertColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: [BoxShadow(color: alertColor.withOpacity(0.4), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isResolved ? 1.0 : _pulseAnimation.value,
                child: Container(
                  padding: EdgeInsets.all(spacingLarge),
                  decoration: BoxDecoration(
                    color: white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEmergency ? Icons.emergency_rounded : Icons.warning_rounded,
                    color: white,
                    size: 48,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: spacingLarge),
          Text(
            widget.alert['title'] ?? 'SOS Activated',
            style: h2.copyWith(color: white, fontSize: 24, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacingSmall),
          Text(
            'Activated ${widget.alert['time'] ?? '2 mins ago'}',
            style: body.copyWith(color: white.withOpacity(0.9), fontSize: 14),
          ),
          if (!_isResolved) ...[
            SizedBox(height: spacingMedium),
            Container(
              padding: EdgeInsets.symmetric(horizontal: spacingMedium, vertical: spacingSmall),
              decoration: BoxDecoration(
                color: white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(radiusLarge),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded, color: white, size: 16),
                  SizedBox(width: 6),
                  Text('Response needed immediately', style: caption.copyWith(color: white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: widget.isDarkMode ? Border.all(color: primary.withOpacity(0.2)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Information', style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 16)),
          SizedBox(height: spacingLarge),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: primaryGradient,
                  border: Border.all(color: widget.isDarkMode ? primary.withOpacity(0.3) : white, width: 3),
                ),
                child: Center(
                  child: Text(
                    (widget.alert['user'] ?? 'M').substring(0, 1).toUpperCase(),
                    style: h2.copyWith(color: white, fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SizedBox(width: spacingLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.alert['user'] ?? 'Maria Santos',
                      style: h3.copyWith(color: widget.theme.textColor, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.visibility_off_rounded, size: 14, color: widget.theme.subtextColor),
                        SizedBox(width: 4),
                        Text('Total Blindness', style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone_rounded, size: 14, color: widget.theme.subtextColor),
                        SizedBox(width: 4),
                        Text('+63 912 345 6789', style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.call_rounded, color: Colors.green, size: 24),
              ),
            ],
          ),
          Divider(color: widget.theme.subtextColor.withOpacity(0.2), height: spacingLarge * 2),
          Text('Assigned Caretaker', style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12)),
          SizedBox(height: spacingSmall),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                child: Center(child: Icon(Icons.favorite_rounded, color: white, size: 20)),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rosa Martinez', style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 14)),
                    Text('Family Member • +63 912 111 2222', style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(icon: Icon(Icons.call_rounded, color: Colors.green, size: 22), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: widget.isDarkMode ? Border.all(color: error.withOpacity(0.3), width: 2) : Border.all(color: error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(color: error.withOpacity(0.15), borderRadius: BorderRadius.circular(radiusSmall)),
                      child: Icon(Icons.location_on_rounded, color: error, size: 20),
                    ),
                    SizedBox(width: spacingMedium),
                    Text('Live Location', style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 16)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.directions_rounded, size: 18),
                  label: Text('Navigate', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            decoration: BoxDecoration(color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[200]),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_rounded, size: 48, color: widget.theme.subtextColor.withOpacity(0.5)),
                      SizedBox(height: spacingSmall),
                      Text('Interactive Map', style: caption.copyWith(color: widget.theme.subtextColor)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: error,
                      borderRadius: BorderRadius.circular(radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gps_fixed_rounded, color: white, size: 14),
                        SizedBox(width: 4),
                        Text('Live', style: caption.copyWith(color: white, fontWeight: FontWeight.w700, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                Icon(Icons.place_rounded, color: error, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.alert['location'] ?? 'Rizal Avenue, Makati City, Metro Manila',
                    style: body.copyWith(color: widget.theme.textColor, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyDetails(Color alertColor) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: widget.isDarkMode ? Border.all(color: alertColor.withOpacity(0.2)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Emergency Details', style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 16)),
          SizedBox(height: spacingLarge),
          _buildDetailRow('Type', widget.alert['title'] ?? 'SOS Activation', alertColor),
          _buildDetailRow('Trigger', 'Triple tap on device', widget.theme.subtextColor),
          _buildDetailRow('Time', DateTime.now().toString().substring(11, 16), widget.theme.subtextColor),
          _buildDetailRow('Duration', '${_isResolved ? '5' : '2'} minutes', widget.theme.subtextColor),
          _buildDetailRow('Battery', '78%', widget.theme.subtextColor),
          _buildDetailRow('Network', 'Mobile Data (4G)', widget.theme.subtextColor),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: body.copyWith(color: widget.theme.subtextColor, fontSize: 13)),
          Text(value, style: bodyBold.copyWith(color: valueColor, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    final contacts = [
      {'name': 'PNP Makati', 'number': '(02) 8899-1111', 'icon': Icons.local_police_rounded, 'color': Colors.blue},
      {'name': 'MMDA Hotline', 'number': '136', 'icon': Icons.traffic_rounded, 'color': Colors.orange},
      {'name': 'Emergency Medical', 'number': '911', 'icon': Icons.local_hospital_rounded, 'color': error},
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
          Text('Emergency Hotlines', style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 16)),
          SizedBox(height: spacingMedium),
          ...contacts.map((c) => Padding(
            padding: EdgeInsets.symmetric(vertical: spacingSmall),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: (c['color'] as Color).withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(c['icon'] as IconData, color: c['color'] as Color, size: 20),
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['name'] as String, style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 14)),
                      Text(c['number'] as String, style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.call_rounded, color: c['color'] as Color),
                  onPressed: () {},
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionLog() {
    final logs = [
      {'action': 'Alert received', 'time': '10:30:15 AM', 'by': 'System'},
      {'action': 'Caretaker notified', 'time': '10:30:18 AM', 'by': 'System'},
      {'action': 'Alert viewed', 'time': '10:30:45 AM', 'by': 'Admin'},
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
          Text('Action Log', style: bodyBold.copyWith(color: widget.theme.textColor, fontSize: 16)),
          SizedBox(height: spacingMedium),
          ...logs.map((l) => Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
                SizedBox(width: spacingMedium),
                Expanded(child: Text(l['action'] as String, style: body.copyWith(color: widget.theme.textColor, fontSize: 13))),
                Text(l['time'] as String, style: caption.copyWith(color: widget.theme.subtextColor, fontSize: 11)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Color alertColor) {
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(Icons.call_rounded, 'Call User', Colors.green, () {}),
              ),
              SizedBox(width: spacingSmall),
              Expanded(
                child: _buildActionBtn(Icons.family_restroom_rounded, 'Call Caretaker', primary, () {}),
              ),
              SizedBox(width: spacingSmall),
              Expanded(
                child: _buildActionBtn(Icons.local_hospital_rounded, 'Dispatch Help', Colors.orange, () {}),
              ),
            ],
          ),
          SizedBox(height: spacingMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showResolveDialog(),
              icon: Icon(Icons.check_circle_rounded),
              label: Text('Mark as Resolved'),
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

  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusMedium),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(height: 4),
              Text(label, style: caption.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 10), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  void _showResolveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Resolve Alert', style: bodyBold.copyWith(color: widget.theme.textColor)),
          ],
        ),
        content: Text('Mark this emergency as resolved?', style: body.copyWith(color: widget.theme.subtextColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isResolved = true);
              _pulseController.stop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Alert marked as resolved'), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Resolve'),
          ),
        ],
      ),
    );
  }
}