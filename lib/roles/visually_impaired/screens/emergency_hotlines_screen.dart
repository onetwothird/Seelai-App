// File: lib/roles/visually_impaired/screens/emergency_hotlines_screen.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/models/emergency_hotline_model.dart';
import 'package:seelai_app/roles/visually_impaired/services/emergency_service.dart';
import 'package:seelai_app/roles/visually_impaired/screens/edit_hotline_screen.dart';

class EmergencyHotlinesScreen extends StatefulWidget {
  final bool isDarkMode;

  const EmergencyHotlinesScreen({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<EmergencyHotlinesScreen> createState() => _EmergencyHotlinesScreenState();
}

class _EmergencyHotlinesScreenState extends State<EmergencyHotlinesScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  List<EmergencyHotline> _hotlines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHotlines();
  }

  Future<void> _loadHotlines() async {
    setState(() => _isLoading = true);
    
    // TODO: Load from database
    await Future.delayed(Duration(milliseconds: 500));
    
    setState(() {
      _hotlines = _emergencyService.getDefaultHotlines();
      _isLoading = false;
    });
  }

  Future<void> _makeCall(EmergencyHotline hotline) async {
    final callSuccess = await _emergencyService.makeEmergencyCall(hotline.phoneNumber);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            callSuccess 
              ? 'Calling ${hotline.departmentName}...' 
              : 'Unable to make call'
          ),
          backgroundColor: callSuccess ? Colors.green : error,
        ),
      );
    }
  }

  Future<void> _openLocation(EmergencyHotline hotline) async {
    final locationSuccess = await _emergencyService.openLocation(hotline.address);
    
    if (mounted && !locationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open location'),
          backgroundColor: error,
        ),
      );
    }
  }

  Future<void> _editHotline(EmergencyHotline hotline) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHotlineScreen(
          hotline: hotline,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        final index = _hotlines.indexWhere((h) => h.id == result.id);
        if (index != -1) {
          _hotlines[index] = result;
        }
      });
    }
  }

  Future<void> _addNewHotline() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHotlineScreen(
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _hotlines.add(result);
      });
    }
  }

  void _deleteHotline(EmergencyHotline hotline) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Hotline'),
        content: Text('Are you sure you want to delete ${hotline.departmentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _hotlines.removeWhere((h) => h.id == hotline.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hotline deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: error)),
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
          'Emergency Hotlines',
          style: h2.copyWith(color: textColor, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: primary, size: 28),
            onPressed: _addNewHotline,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hotlines.isEmpty
              ? _buildEmptyState(textColor, subtextColor)
              : ListView.builder(
                  padding: EdgeInsets.all(spacingLarge),
                  itemCount: _hotlines.length,
                  itemBuilder: (context, index) {
                    return _buildHotlineCard(
                      _hotlines[index],
                      cardColor,
                      textColor,
                      subtextColor,
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subtextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_disabled_rounded, size: 80, color: subtextColor),
          SizedBox(height: spacingLarge),
          Text(
            'No Emergency Hotlines',
            style: h2.copyWith(color: textColor),
          ),
          SizedBox(height: spacingSmall),
          Text(
            'Tap + to add a new hotline',
            style: body.copyWith(color: subtextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineCard(
    EmergencyHotline hotline,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacingMedium),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: widget.isDarkMode 
            ? [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 16, offset: Offset(0, 6))]
            : softShadow,
          border: widget.isDarkMode 
            ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
            : null,
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.all(spacingLarge),
              leading: Container(
                padding: EdgeInsets.all(spacingMedium),
                decoration: BoxDecoration(
                  color: hotline.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Icon(hotline.icon, color: hotline.color, size: 28),
              ),
              title: Text(
                hotline.departmentName,
                style: bodyBold.copyWith(fontSize: 18, color: textColor),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: spacingXSmall),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 16, color: subtextColor),
                      SizedBox(width: 6),
                      Text(hotline.phoneNumber, style: body.copyWith(color: subtextColor)),
                    ],
                  ),
                  SizedBox(height: spacingXSmall),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 16, color: subtextColor),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hotline.address,
                          style: body.copyWith(color: subtextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                icon: Icon(Icons.more_vert_rounded, color: textColor),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20, color: primary),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                    onTap: () => Future.delayed(
                      Duration.zero,
                      () => _editHotline(hotline),
                    ),
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 20, color: error),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                    onTap: () => Future.delayed(
                      Duration.zero,
                      () => _deleteHotline(hotline),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: subtextColor.withOpacity(0.2)),
            Padding(
              padding: EdgeInsets.all(spacingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makeCall(hotline),
                      icon: Icon(Icons.phone_rounded, size: 20),
                      label: Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hotline.color,
                        foregroundColor: white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radiusMedium),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: spacingSmall),
                  ElevatedButton(
                    onPressed: () => _openLocation(hotline),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardColor,
                      foregroundColor: hotline.color,
                      padding: EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusMedium),
                        side: BorderSide(color: hotline.color),
                      ),
                    ),
                    child: Icon(Icons.location_on_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}