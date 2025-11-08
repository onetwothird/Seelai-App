// File: lib/roles/visually_impaired/screens/emergency_hotlines_screen.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/models/emergency_hotline_model.dart';
import 'package:seelai_app/firebase/visually_impaired/emergency_hotline_service.dart';
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
  final EmergencyHotlineService _service = emergencyHotlineService;
  List<EmergencyHotline> _hotlines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHotlines();
  }

  Future<void> _loadHotlines() async {
    setState(() => _isLoading = true);
    
    try {
      final hotlines = await _service.getHotlines();
      
      if (mounted) {
        setState(() {
          _hotlines = hotlines;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading hotlines: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load hotlines'),
            backgroundColor: error,
          ),
        );
      }
    }
  }

  Future<void> _makeCall(EmergencyHotline hotline) async {
    final callSuccess = await _service.makeEmergencyCall(
      hotline.phoneNumber,
      hotline.departmentName,
    );
    
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
    final locationSuccess = await _service.openLocation(hotline.address);
    
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
    final result = await Navigator.push<EmergencyHotline>(
      context,
      MaterialPageRoute(
        builder: (context) => EditHotlineScreen(
          hotline: hotline,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );

    if (result != null) {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: white),
                ),
                SizedBox(width: 12),
                Text('Updating hotline...'),
              ],
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Update in Firebase
      final success = await _service.updateHotline(result);

      if (mounted) {
        if (success) {
          // Reload hotlines
          await _loadHotlines();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hotline updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update hotline'),
              backgroundColor: error,
            ),
          );
        }
      }
    }
  }

  Future<void> _addNewHotline() async {
    final result = await Navigator.push<EmergencyHotline>(
      context,
      MaterialPageRoute(
        builder: (context) => EditHotlineScreen(
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );

    if (result != null) {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: white),
                ),
                SizedBox(width: 12),
                Text('Adding hotline...'),
              ],
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Save to Firebase
      final success = await _service.saveHotline(result);

      if (mounted) {
        if (success) {
          // Reload hotlines
          await _loadHotlines();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hotline added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add hotline'),
              backgroundColor: error,
            ),
          );
        }
      }
    }
  }

  void _deleteHotline(EmergencyHotline hotline) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: error),
            SizedBox(width: spacingSmall),
            Text('Delete Hotline'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${hotline.departmentName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: white),
                      ),
                      SizedBox(width: 12),
                      Text('Deleting hotline...'),
                    ],
                  ),
                  duration: Duration(seconds: 1),
                ),
              );

              // Delete from Firebase
              final success = await _service.deleteHotline(hotline.id);

              if (mounted) {
                if (success) {
                  // Reload hotlines
                  await _loadHotlines();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hotline deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete hotline'),
                      backgroundColor: error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: error,
              foregroundColor: white,
            ),
            child: Text('Delete'),
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
            tooltip: 'Add new hotline',
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor, size: 24),
            onPressed: _loadHotlines,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: spacingLarge),
                  Text(
                    'Loading hotlines...',
                    style: body.copyWith(color: subtextColor),
                  ),
                ],
              ),
            )
          : _hotlines.isEmpty
              ? _buildEmptyState(textColor, subtextColor)
              : RefreshIndicator(
                  onRefresh: _loadHotlines,
                  child: ListView.builder(
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
                ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subtextColor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(spacingXLarge),
              decoration: BoxDecoration(
                color: subtextColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_disabled_rounded,
                size: 80,
                color: subtextColor,
              ),
            ),
            SizedBox(height: spacingXLarge),
            Text(
              'No Emergency Hotlines',
              style: h2.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacingSmall),
            Text(
              'Tap the + button above to add your first emergency hotline',
              style: body.copyWith(color: subtextColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacingXLarge),
            ElevatedButton.icon(
              onPressed: _addNewHotline,
              icon: Icon(Icons.add_rounded),
              label: Text('Add Hotline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(
                  horizontal: spacingXLarge,
                  vertical: spacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusLarge),
                ),
              ),
            ),
          ],
        ),
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