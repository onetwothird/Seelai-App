// File: lib/roles/mswd/home/sections/hotlines/mswd_manage_hotlines.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; 
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; 
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/partially_sighted/models/emergency_hotline_model.dart';
import 'package:seelai_app/firebase/partially_sighted/emergency_hotline_service.dart';
import 'package:seelai_app/roles/mswd/home/sections/hotlines/mswd_edit_hotline.dart';

class MswdManageHotlinesScreen extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;

  const MswdManageHotlinesScreen({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<MswdManageHotlinesScreen> createState() => _MswdManageHotlinesScreenState();
}

class _MswdManageHotlinesScreenState extends State<MswdManageHotlinesScreen> {
  final EmergencyHotlineService _service = emergencyHotlineService;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeGlobalHotlines();
  }

  Future<void> _initializeGlobalHotlines() async {
    setState(() => _isInitializing = true);
    
    try {
      final needsInit = await _service.needsPredefinedInitialization();
      
      if (needsInit) {
        final success = await _service.initializePredefinedHotlines();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Global hotlines synchronized successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Widget _buildSkeletonList() {
    final baseColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade100;

    return ListView.builder(
      padding: const EdgeInsets.all(spacingLarge),
      itemCount: 6, 
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: spacingMedium),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 92, 
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radiusLarge),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Forces pure white background in light mode
    final Color safeBgColor = widget.isDarkMode ? widget.theme.backgroundColor : Colors.white;

    return Scaffold(
      backgroundColor: safeBgColor,
      appBar: AppBar(
        // --- UPDATED APP BAR STYLING ---
        backgroundColor: safeBgColor,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: widget.theme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Manage Hotlines',
          style: h3.copyWith(
            fontSize: 18,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: widget.theme.textColor),
            onPressed: _addNewHotline,
            tooltip: 'Add new hotline',
          ),
        ],
      ),
      body: _isInitializing
          ? _buildSkeletonList()
          : StreamBuilder<List<EmergencyHotline>>(
              stream: _service.streamHotlines(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonList(); 
                }

                if (snapshot.hasError) {
                  debugPrint('Stream Error: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Error loading hotlines.\nCheck Firebase Rules.', 
                      style: body.copyWith(color: error),
                      textAlign: TextAlign.center,
                    )
                  );
                }

                final hotlines = snapshot.data ?? [];

                if (hotlines.isEmpty) {
                  return _buildEmptyState();
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(spacingLarge),
                    itemCount: hotlines.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildHotlineCard(hotlines[index]),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHotlineCard(EmergencyHotline hotline) {
    return Container(
      margin: const EdgeInsets.only(bottom: spacingMedium),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: widget.isDarkMode 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: widget.isDarkMode ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(spacingMedium),
        child: Row(
          children: [
            Container(
              width: 60, height: 60, 
              padding: hotline.imageAsset.isNotEmpty ? EdgeInsets.zero : const EdgeInsets.all(spacingMedium),
              decoration: BoxDecoration(
                color: hotline.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(radiusMedium),
                image: hotline.imageAsset.isNotEmpty
                    ? DecorationImage(image: AssetImage(hotline.imageAsset), fit: BoxFit.cover)
                    : null,
              ),
              child: hotline.imageAsset.isNotEmpty ? null : Icon(hotline.icon, color: hotline.color, size: 26),
            ),
            const SizedBox(width: spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hotline.departmentName,
                          style: bodyBold.copyWith(fontSize: 15, color: widget.theme.textColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (hotline.isPredefined)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: hotline.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(radiusSmall),
                          ),
                          child: Text(
                            'Official',
                            style: caption.copyWith(fontSize: 10, color: hotline.color, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hotline.phoneNumber,
                    style: body.copyWith(fontSize: 13, color: widget.theme.subtextColor),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: widget.theme.subtextColor),
              color: widget.theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  _editHotline(hotline);
                // ignore: curly_braces_in_flow_control_structures
                } else if (value == 'delete') _deleteHotline(hotline);
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 20, color: widget.theme.textColor), const SizedBox(width: spacingSmall), Text('Edit', style: TextStyle(color: widget.theme.textColor))])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 20, color: error), SizedBox(width: spacingSmall), Text('Delete', style: TextStyle(color: error))])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contact_phone_rounded, size: 80, color: widget.theme.subtextColor.withValues(alpha: 0.3)),
          const SizedBox(height: spacingMedium),
          Text('No hotlines configured', style: h3.copyWith(color: widget.theme.textColor)),
          const SizedBox(height: spacingSmall),
          Text('Add hotlines to broadcast to users.', style: body.copyWith(color: widget.theme.subtextColor)),
        ],
      ),
    );
  }

  Future<void> _addNewHotline() async {
    final result = await Navigator.push<EmergencyHotline>(
      context, 
      MaterialPageRoute(builder: (context) => MswdEditHotlineScreen(isDarkMode: widget.isDarkMode, theme: widget.theme)),
    );
    if (result != null) {
      final success = await _service.saveHotline(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Hotline published' : 'Failed to add hotline'), backgroundColor: success ? Colors.green : error)
        );
      }
    }
  }

  Future<void> _editHotline(EmergencyHotline hotline) async {
    final result = await Navigator.push<EmergencyHotline>(
      context, 
      MaterialPageRoute(builder: (context) => MswdEditHotlineScreen(hotline: hotline, isDarkMode: widget.isDarkMode, theme: widget.theme)),
    );
    if (result != null) {
      final success = await _service.updateHotline(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Hotline updated globally' : 'Failed to update hotline'), backgroundColor: success ? Colors.green : error)
        );
      }
    }
  }

  Future<void> _deleteHotline(EmergencyHotline hotline) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Hotline', style: TextStyle(color: widget.theme.textColor)),
        content: Text('Remove "${hotline.departmentName}" from all user devices?', style: TextStyle(color: widget.theme.subtextColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: error, foregroundColor: Colors.white),
            child: const Text('Delete')
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await _service.deleteHotline(hotline.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Hotline removed' : 'Failed to delete'), backgroundColor: success ? Colors.green : error)
        );
      }
    }
  }
}