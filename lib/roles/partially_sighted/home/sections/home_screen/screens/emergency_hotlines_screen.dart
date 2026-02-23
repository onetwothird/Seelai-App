// File: lib/roles/visually_impaired/home/sections/home_screen/screens/emergency_hotlines_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/partially_sighted/models/emergency_hotline_model.dart';
import 'package:seelai_app/firebase/partially_sighted/emergency_hotline_service.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/edit_hotline_screen.dart';

class EmergencyHotlinesScreen extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;

  const EmergencyHotlinesScreen({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<EmergencyHotlinesScreen> createState() => _EmergencyHotlinesScreenState();
}

class _EmergencyHotlinesScreenState extends State<EmergencyHotlinesScreen> {
  final EmergencyHotlineService _service = emergencyHotlineService;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializePredefinedHotlines();
  }

  /// Initialize predefined hotlines if needed
  Future<void> _initializePredefinedHotlines() async {
    setState(() => _isInitializing = true);
    
    try {
      final needsInit = await _service.needsPredefinedInitialization();
      
      if (needsInit) {
        debugPrint('🔄 User needs predefined hotlines initialization');
        
        final success = await _service.initializePredefinedHotlines();
        
        if (success) {
          debugPrint('✅ Predefined hotlines initialized successfully');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Emergency hotlines have been set up for you'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        debugPrint('ℹ️ Predefined hotlines already initialized');
      }
    } catch (e) {
      debugPrint('❌ Error during initialization: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set scaffold background to match container
      backgroundColor: widget.isDarkMode ? const Color(0xFF0A0E27) : Colors.white,
      appBar: AppBar(
        // Force solid background matching the body
        backgroundColor: widget.isDarkMode ? const Color(0xFF0A0E27) : Colors.white,
        // Disable the color change on scroll
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: widget.theme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Emergency Hotlines',
          style: h3.copyWith(
            fontSize: 18,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: widget.theme.textColor),
            onPressed: () => _addNewHotline(),
            tooltip: 'Add new hotline',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          // Ensure container matches the white background
          color: widget.isDarkMode ? const Color(0xFF0A0E27) : Colors.white,
        ),
        child: _isInitializing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primary),
                    SizedBox(height: spacingMedium),
                    Text(
                      'Setting up emergency hotlines...',
                      style: body.copyWith(color: widget.theme.textColor),
                    ),
                  ],
                ),
              )
            : StreamBuilder<List<EmergencyHotline>>(
                stream: _service.streamHotlines(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading hotlines',
                        style: body.copyWith(color: error),
                      ),
                    );
                  }

                  final hotlines = snapshot.data ?? [];

                  if (hotlines.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(spacingLarge),
                    itemCount: hotlines.length,
                    itemBuilder: (context, index) {
                      final hotline = hotlines[index];
                      return _buildHotlineCard(hotline);
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHotlineCard(EmergencyHotline hotline) {
    return Semantics(
      label: '${hotline.departmentName} hotline',
      button: true,
      hint: 'Double tap to call ${hotline.phoneNumber}',
      child: Container(
        margin: EdgeInsets.only(bottom: spacingMedium),
        decoration: BoxDecoration(
          gradient: widget.isDarkMode
              ? LinearGradient(
                  colors: [Color(0xFF1A1F3A), Color(0xFF2A2F4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: widget.isDarkMode ? null : widget.theme.cardColor,
          borderRadius: BorderRadius.circular(radiusLarge),
          boxShadow: widget.isDarkMode
              ? [
                  BoxShadow(
                    color: hotline.color.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
          border: widget.isDarkMode
              ? Border.all(
                  color: hotline.color.withOpacity(0.3),
                  width: 1.5,
                )
              : Border.all(
                  color: Colors.grey.withOpacity(0.15),
                  width: 1.0,
                ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _callHotline(hotline),
            borderRadius: BorderRadius.circular(radiusLarge),
            child: Padding(
              padding: EdgeInsets.all(spacingMedium),
              child: Row(
                children: [
                  // --- IMAGE/ICON CONTAINER START ---
                  Container(
                    width: 60, // Fixed width for consistency
                    height: 60, // Fixed height for consistency
                    padding: hotline.imageAsset.isNotEmpty 
                        ? EdgeInsets.zero // No padding if it's an image, let it fill
                        : EdgeInsets.all(spacingMedium),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [hotline.color, hotline.color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(radiusMedium),
                      image: hotline.imageAsset.isNotEmpty
                          ? DecorationImage(
                              image: AssetImage(hotline.imageAsset),
                              fit: BoxFit.cover, // Fills the box nicely
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: hotline.color.withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    // Only show Icon if no image is provided
                    child: hotline.imageAsset.isNotEmpty
                        ? null 
                        : Icon(hotline.icon, color: white, size: 26),
                  ),
                  // --- IMAGE/ICON CONTAINER END ---
                  
                  SizedBox(width: spacingMedium),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                hotline.departmentName,
                                style: bodyBold.copyWith(
                                  fontSize: 16,
                                  color: widget.theme.textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (hotline.isPredefined)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacingSmall,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: hotline.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(radiusSmall),
                                ),
                                child: Text(
                                  'Official',
                                  style: caption.copyWith(
                                    fontSize: 10,
                                    color: hotline.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          hotline.phoneNumber,
                          style: body.copyWith(
                            fontSize: 14,
                            color: widget.theme.subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions (Edit/Delete)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: widget.theme.subtextColor,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editHotline(hotline);
                      } else if (value == 'delete') {
                        _deleteHotline(hotline);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 20),
                            SizedBox(width: spacingSmall),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, size: 20, color: error),
                            SizedBox(width: spacingSmall),
                            Text('Delete', style: TextStyle(color: error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_in_talk_rounded, size: 80, color: widget.theme.subtextColor),
          SizedBox(height: spacingMedium),
          Text(
            'No emergency hotlines yet',
            style: h3.copyWith(color: widget.theme.textColor),
          ),
          SizedBox(height: spacingSmall),
          Text(
            'Add your first emergency hotline',
            style: body.copyWith(color: widget.theme.subtextColor),
          ),
          SizedBox(height: spacingLarge),
          ElevatedButton.icon(
            onPressed: _addNewHotline,
            icon: Icon(Icons.add_rounded),
            label: Text('Add Hotline'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: white,
              padding: EdgeInsets.symmetric(
                horizontal: spacingLarge,
                vertical: spacingMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callHotline(EmergencyHotline hotline) async {
    final success = await _service.makeEmergencyCall(
      hotline.phoneNumber,
      hotline.departmentName,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to make call'),
          backgroundColor: error,
        ),
      );
    }
  }

  Future<void> _addNewHotline() async {
    final result = await Navigator.push<EmergencyHotline>(
      context,
      MaterialPageRoute(
        builder: (context) => EditHotlineScreen(
          isDarkMode: widget.isDarkMode,
          theme: widget.theme,
        ),
      ),
    );

    if (result != null) {
      final success = await _service.saveHotline(result);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Hotline added successfully' : 'Failed to add hotline',
            ),
            backgroundColor: success ? Colors.green : error,
          ),
        );
      }
    }
  }

  Future<void> _editHotline(EmergencyHotline hotline) async {
    final result = await Navigator.push<EmergencyHotline>(
      context,
      MaterialPageRoute(
        builder: (context) => EditHotlineScreen(
          hotline: hotline,
          isDarkMode: widget.isDarkMode,
          theme: widget.theme,
        ),
      ),
    );

    if (result != null) {
      final success = await _service.updateHotline(result);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Hotline updated successfully' : 'Failed to update hotline',
            ),
            backgroundColor: success ? Colors.green : error,
          ),
        );
      }
    }
  }

  Future<void> _deleteHotline(EmergencyHotline hotline) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Hotline'),
        content: Text(
          'Are you sure you want to delete "${hotline.departmentName}"?${hotline.isPredefined ? '\n\nThis is an official hotline.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _service.deleteHotline(hotline.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Hotline deleted successfully' : 'Failed to delete hotline',
            ),
            backgroundColor: success ? Colors.green : error,
          ),
        );
      }
    }
  }
}