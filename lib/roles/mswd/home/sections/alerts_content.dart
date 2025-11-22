// File: lib/roles/mswd/home/sections/alerts_content.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:intl/intl.dart';

class AlertsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final Function(int)? onAlertsCountChanged;
  final ScrollController? scrollController;

  const AlertsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    this.onAlertsCountChanged,
    this.scrollController,
  });

  @override
  State<AlertsContent> createState() => _AlertsContentState();
}

class _AlertsContentState extends State<AlertsContent> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  int _selectedTab = 0;
  bool _showAlertDetails = false;
  Map<String, dynamic>? _selectedAlert;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    
    // Use post-frame callback to update parent after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAlertsCount();
    });
  }

  void _updateAlertsCount() {
    final pendingCount = _getPendingAlertsCount();
    if (widget.onAlertsCountChanged != null) {
      widget.onAlertsCountChanged!(pendingCount);
    }
  }

  int _getPendingAlertsCount() {
    // Count only unread/pending alerts
    final alerts = _getAllAlerts();
    return alerts.where((alert) => alert['status'] == 'Pending').length;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (_showAlertDetails && _selectedAlert != null) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        physics: ClampingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            _buildAlertDetailsHeader(),
            SizedBox(height: spacingLarge),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: _buildAlertDetailsContent(),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        left: width * 0.05,
        right: width * 0.05,
        top: spacingMedium,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: spacingLarge),
          _buildStatsOverview(),
          SizedBox(height: spacingLarge),
          _buildSearchBar(),
          SizedBox(height: spacingLarge),
          _buildTabBar(),
          SizedBox(height: spacingLarge),
          _buildCurrentTabContent(),
          SizedBox(height: spacingLarge),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerts & Notifications',
          style: h2.copyWith(
            fontSize: 24,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Monitor emergency and system alerts',
          style: body.copyWith(
            color: widget.theme.subtextColor,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.warning_rounded,
            label: 'Pending',
            count: _getPendingAlertsCount(),
            color: Colors.orange,
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: _buildStatCard(
            icon: Icons.emergency_rounded,
            label: 'Critical',
            count: 2,
            color: error,
          ),
        ),
        SizedBox(width: spacingMedium),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_rounded,
            label: 'Resolved',
            count: 28,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: spacingLarge,
        horizontal: spacingSmall,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: color.withOpacity(widget.isDarkMode ? 0.3 : 0.25),
          width: 1,
        ),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: spacingSmall),
          Text(
            count.toString(),
            style: h2.copyWith(
              fontSize: 24,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: caption.copyWith(
              fontSize: 12,
              color: widget.theme.subtextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: widget.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: _searchController,
        style: body.copyWith(color: widget.theme.textColor),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search alerts...',
          hintStyle: body.copyWith(color: widget.theme.subtextColor),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: widget.theme.subtextColor,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: widget.theme.subtextColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
        border: widget.isDarkMode
            ? Border.all(color: primary.withOpacity(0.2), width: 1)
            : Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.warning_rounded, 'Pending', Colors.orange),
          _buildTab(1, Icons.emergency_rounded, 'Critical', error),
          _buildTab(2, Icons.history_rounded, 'History', Colors.green),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label, Color accentColor) {
    final isSelected = _tabController.index == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(vertical: spacingMedium),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? white : widget.theme.subtextColor,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? white : widget.theme.subtextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    final alerts = _getAlertsForTab(_selectedTab);

    if (alerts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: List.generate(
        alerts.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildAlertCard(alerts[index]),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAllAlerts() {
    return [
      {
        'id': 'ALT-001',
        'type': 'Emergency',
        'severity': 'Critical',
        'title': 'Emergency Hotline Call',
        'description': 'Incoming emergency call from Maria Santos',
        'patient': 'Maria Santos',
        'location': 'Manila City Hall',
        'status': 'Pending',
        'timestamp': DateTime.now().subtract(Duration(minutes: 5)),
      },
      {
        'id': 'ALT-002',
        'type': 'System',
        'severity': 'High',
        'title': 'Patient Location Alert',
        'description': 'Juan Dela Cruz has been stationary for 2 hours',
        'patient': 'Juan Dela Cruz',
        'location': 'Quezon City',
        'status': 'Pending',
        'timestamp': DateTime.now().subtract(Duration(minutes: 15)),
      },
      {
        'id': 'ALT-003',
        'type': 'Emergency',
        'severity': 'Critical',
        'title': 'SOS Button Pressed',
        'description': 'Pedro Garcia pressed the emergency SOS button',
        'patient': 'Pedro Garcia',
        'location': 'Makati CBD',
        'status': 'Critical',
        'timestamp': DateTime.now().subtract(Duration(minutes: 2)),
      },
      {
        'id': 'ALT-004',
        'type': 'System',
        'severity': 'Medium',
        'title': 'Medication Reminder Missed',
        'description': 'Ana Santos missed medication reminder',
        'patient': 'Ana Santos',
        'location': 'Patient Home',
        'status': 'Resolved',
        'timestamp': DateTime.now().subtract(Duration(hours: 2)),
      },
    ];
  }

  List<Map<String, dynamic>> _getAlertsForTab(int tab) {
    final allAlerts = _getAllAlerts();
    
    switch (tab) {
      case 0: // Pending
        return allAlerts.where((a) => a['status'] == 'Pending').toList();
      case 1: // Critical
        return allAlerts.where((a) => a['status'] == 'Critical').toList();
      case 2: // History
        return allAlerts.where((a) => a['status'] == 'Resolved').toList();
      default:
        return allAlerts;
    }
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severityColor = _getSeverityColor(alert['severity']);
    _getStatusColor(alert['status']);

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: severityColor.withOpacity(0.2),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
        border: Border.all(
          color: severityColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedAlert = alert;
              _showAlertDetails = true;
            });
          },
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(spacingMedium),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [severityColor, severityColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: severityColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getAlertIcon(alert['type']),
                        color: white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert['title'],
                            style: bodyBold.copyWith(
                              fontSize: 16,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            alert['patient'],
                            style: caption.copyWith(
                              fontSize: 13,
                              color: widget.theme.subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacingSmall,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(radiusSmall),
                      ),
                      child: Text(
                        alert['severity'].toString().toUpperCase(),
                        style: caption.copyWith(
                          color: severityColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacingMedium),
                Text(
                  alert['description'],
                  style: body.copyWith(
                    fontSize: 14,
                    color: widget.theme.textColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: spacingMedium),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.access_time_rounded,
                        _formatTimeAgo(alert['timestamp']),
                      ),
                    ),
                    SizedBox(width: spacingSmall),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.location_on_rounded,
                        alert['location'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacingSmall,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: widget.theme.subtextColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: widget.theme.subtextColor,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: caption.copyWith(
                fontSize: 11,
                color: widget.theme.subtextColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedTab) {
      case 0:
        message = 'No pending alerts';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 1:
        message = 'No critical alerts';
        icon = Icons.shield_outlined;
        break;
      case 2:
        message = 'No alert history';
        icon = Icons.history_rounded;
        break;
      default:
        message = 'No alerts';
        icon = Icons.inbox_rounded;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacingXLarge * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(spacingXLarge),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? primary.withOpacity(0.1)
                    : primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: primary.withOpacity(0.5),
              ),
            ),
            SizedBox(height: spacingLarge),
            Text(
              message,
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Alert Details Screen
  Widget _buildAlertDetailsHeader() {
    final severityColor = _getSeverityColor(_selectedAlert!['severity']);
    
    return Container(
      padding: EdgeInsets.all(spacingLarge),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(radiusXLarge),
          bottomRight: Radius.circular(radiusXLarge),
        ),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: severityColor.withOpacity(0.2),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showAlertDetails = false),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: widget.theme.textColor,
                  size: 24,
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Text(
                  'Alert Details',
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
                  color: severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radiusSmall),
                ),
                child: Text(
                  _selectedAlert!['severity'],
                  style: caption.copyWith(
                    fontSize: 11,
                    color: severityColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacingLarge),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [severityColor, severityColor.withOpacity(0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: severityColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _getAlertIcon(_selectedAlert!['type']),
                color: white,
                size: 40,
              ),
            ),
          ),
          SizedBox(height: spacingMedium),
          Text(
            _selectedAlert!['title'],
            style: h2.copyWith(
              fontSize: 20,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            'Alert ID: ${_selectedAlert!['id']}',
            style: caption.copyWith(
              fontSize: 12,
              color: widget.theme.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertDetailsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAlertInfoSection(),
        SizedBox(height: spacingLarge),
        _buildPatientInfoSection(),
        SizedBox(height: spacingLarge),
        _buildLocationSection(),
        SizedBox(height: spacingLarge),
        _buildTimestampSection(),
        SizedBox(height: spacingLarge),
        _buildActionButtons(),
        SizedBox(height: spacingLarge),
      ],
    );
  }

  Widget _buildAlertInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alert Information',
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
            _selectedAlert!['description'],
            style: body.copyWith(
              fontSize: 14,
              color: widget.theme.textColor,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patient Information',
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: primaryGradient,
                ),
                child: Center(
                  child: Text(
                    _selectedAlert!['patient'].toString().substring(0, 1).toUpperCase(),
                    style: h2.copyWith(
                      color: white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacingMedium),
              Expanded(
                child: Text(
                  _selectedAlert!['patient'],
                  style: bodyBold.copyWith(
                    fontSize: 15,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: widget.theme.subtextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
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
                child: Text(
                  _selectedAlert!['location'],
                  style: body.copyWith(
                    fontSize: 14,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
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

  Widget _buildTimestampSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timestamp',
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
                  color: Colors.blue.withOpacity(0.1),
                ),
                child: Center(
                  child: Icon(
                    Icons.schedule_rounded,
                    color: Colors.blue,
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
                      DateFormat('MMM dd, yyyy • hh:mm a').format(_selectedAlert!['timestamp']),
                      style: body.copyWith(
                        fontSize: 14,
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatTimeAgo(_selectedAlert!['timestamp']),
                      style: caption.copyWith(
                        fontSize: 12,
                        color: widget.theme.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedAlert!['status'] == 'Pending' || _selectedAlert!['status'] == 'Critical') ...[
          _buildActionButton(
            'Respond to Alert',
            Icons.check_circle_rounded,
            Colors.green,
            () {
              // Mark as resolved and update count
              setState(() {
                _selectedAlert!['status'] = 'Resolved';
                _showAlertDetails = false;
              });
              _updateAlertsCount();
            },
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            'Contact Patient',
            Icons.phone_rounded,
            primary,
            () {},
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            'View Location',
            Icons.location_on_rounded,
            accent,
            () {},
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            'Assign to Staff',
            Icons.person_add_rounded,
            Colors.blue,
            () {},
          ),
        ] else ...[
          _buildActionButton(
            'View Report',
            Icons.description_rounded,
            primary,
            () {},
          ),
          SizedBox(height: spacingMedium),
          _buildActionButton(
            'Contact Patient',
            Icons.phone_rounded,
            accent,
            () {},
          ),
        ],
        SizedBox(height: spacingMedium),
        _buildActionButton(
          'More Options',
          Icons.more_horiz_rounded,
          Colors.grey,
          () {},
          outlined: true,
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
                SizedBox(width: 8),
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

  // Helper methods
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return error;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Critical':
        return error;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'Emergency':
        return Icons.emergency_rounded;
      case 'System':
        return Icons.info_rounded;
      case 'Warning':
        return Icons.warning_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hrs ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}