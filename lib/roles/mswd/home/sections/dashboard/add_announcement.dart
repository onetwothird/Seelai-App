// File: lib/roles/mswd/home/sections/dashboard/add_announcement.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; 
import 'package:shimmer/shimmer.dart'; 
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/mswd/announcement_service.dart';
import 'package:seelai_app/roles/mswd/home/model/announcement_model.dart';
import 'package:seelai_app/roles/mswd/home/model/announcement_icons.dart';
import 'package:seelai_app/firebase/mswd/user_fetch_service.dart';

class AddAnnouncementPage extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;

  const AddAnnouncementPage({
    super.key,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<AddAnnouncementPage> createState() => _AddAnnouncementPageState();
}

class _AddAnnouncementPageState extends State<AddAnnouncementPage> {
  final AnnouncementService _announcementService = AnnouncementService();
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts(); 
  
  String selectedAudience = 'All Users';
  List<String> selectedUserIds = [];
  String selectedIconCodePoint = '0xe047'; 
  int selectedColorValue = 0xFFFF9800;
  List<Map<String, dynamic>> availableUsers = [];
  
  // Loading states
  bool _isSimulatingLoad = true; 
  bool isLoadingUsers = false;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _initTts(); 
    _loadUsers();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isSimulatingLoad = false);
      }
    });
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US"); 
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    // Added this line to force the app to wait until the TTS finishes
    await _flutterTts.awaitSpeakCompletion(true); 
  }

  @override
  void dispose() {
    _flutterTts.stop(); 
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  // Updated to be asynchronous
  Future<void> _speakMessage(String message) async {
    await _flutterTts.speak(message);
  }

  Future<void> _loadUsers() async {
    setState(() => isLoadingUsers = true);
    final users = await userFetchService.getAllAppUsers();
    if (mounted) {
      setState(() {
        availableUsers = users;
        isLoadingUsers = false;
      });
    }
  }

  IconData _getSafeIcon(String hexCode) {
    final Map<String, IconData> safeIcons = {
      '0xef4c': Icons.notifications,
      '0xe000': Icons.warning,
      '0xe3fc': Icons.event,
      '0xe88a': Icons.home,
      '0xe3e3': Icons.info,
      '0xe047': Icons.campaign,
    };
    String formattedCode = hexCode.toLowerCase().trim();
    return safeIcons[formattedCode] ?? Icons.campaign; 
  }

  Widget _buildFullPageSkeleton() {
    final baseColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 100, height: 16, color: Colors.white),
            SizedBox(height: spacingSmall),
            Row(
              children: [
                Expanded(child: Container(height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radiusMedium)))),
                SizedBox(width: spacingSmall),
                Expanded(child: Container(height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radiusMedium)))),
              ],
            ),
            SizedBox(height: spacingLarge),
            Container(width: 120, height: 16, color: Colors.white),
            SizedBox(height: spacingSmall),
            Container(height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radiusMedium))),
            SizedBox(height: spacingLarge),
            Container(width: 60, height: 16, color: Colors.white),
            SizedBox(height: spacingSmall),
            Container(height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radiusMedium))),
            SizedBox(height: spacingLarge),
            Container(width: 80, height: 16, color: Colors.white),
            SizedBox(height: spacingSmall),
            Container(height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radiusMedium))),
            SizedBox(height: spacingLarge * 2),
            Container(height: 55, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radiusMedium))),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonUsersList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4, 
        itemBuilder: (context, index) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: spacingMedium, vertical: spacingSmall),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: Row(
              children: [
                Container(width: 20, height: 20, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                SizedBox(width: spacingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 14, color: Colors.white),
                      SizedBox(height: 4),
                      Container(width: 80, height: 10, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.backgroundColor, 
      appBar: AppBar(
        backgroundColor: widget.theme.cardColor, 
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: widget.theme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Announcement',
          style: h3.copyWith(
            fontSize: 18,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isSimulatingLoad 
        ? _buildFullPageSkeleton() 
        : SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.all(spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Icon & Color',
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacingSmall),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showIconPickerDialog(context),
                          borderRadius: BorderRadius.circular(radiusMedium),
                          child: Container(
                            padding: EdgeInsets.all(spacingMedium),
                            decoration: BoxDecoration(
                              color: widget.theme.cardColor, 
                              borderRadius: BorderRadius.circular(radiusMedium),
                              border: Border.all(
                                color: widget.theme.subtextColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getSafeIcon(selectedIconCodePoint),
                                  color: Color(selectedColorValue),
                                  size: 28,
                                ),
                                SizedBox(width: spacingSmall),
                                Text(
                                  'Select Icon',
                                  style: body.copyWith(
                                    fontSize: 13,
                                    color: widget.theme.textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: spacingSmall),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showColorPickerDialog(context),
                          borderRadius: BorderRadius.circular(radiusMedium),
                          child: Container(
                            padding: EdgeInsets.all(spacingMedium),
                            decoration: BoxDecoration(
                              color: widget.theme.cardColor, 
                              borderRadius: BorderRadius.circular(radiusMedium),
                              border: Border.all(
                                color: widget.theme.subtextColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Color(selectedColorValue),
                                    borderRadius: BorderRadius.circular(radiusSmall),
                                    border: Border.all(
                                      color: widget.theme.subtextColor.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                SizedBox(width: spacingSmall),
                                Text(
                                  'Select Color',
                                  style: body.copyWith(
                                    fontSize: 13,
                                    color: widget.theme.textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: spacingLarge),
                
                Text(
                  'Target Audience',
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacingSmall),
                Container(
                  decoration: BoxDecoration(
                    color: widget.theme.cardColor, 
                    borderRadius: BorderRadius.circular(radiusMedium),
                    border: Border.all(
                      color: widget.theme.subtextColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedAudience,
                      isExpanded: true,
                      padding: EdgeInsets.symmetric(horizontal: spacingMedium),
                      borderRadius: BorderRadius.circular(radiusMedium),
                      dropdownColor: widget.theme.cardColor, 
                      style: body.copyWith(color: widget.theme.textColor),
                      icon: Icon(Icons.arrow_drop_down, color: widget.theme.textColor),
                      items: [
                        DropdownMenuItem(
                          value: 'All Users',
                          child: Row(
                            children: [
                              Icon(Icons.people_rounded, color: Color(0xFFFF9800), size: 20),
                              SizedBox(width: spacingSmall),
                              Text('All Users'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Partially Sighted',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_off_rounded, color: Color(0xFF9C27B0), size: 20),
                              SizedBox(width: spacingSmall),
                              Text('Partially Sighted'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Caretakers',
                          child: Row(
                            children: [
                              Icon(Icons.volunteer_activism_rounded, color: Color(0xFF4CAF50), size: 20),
                              SizedBox(width: spacingSmall),
                              Text('Caretakers'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Specific Users',
                          child: Row(
                            children: [
                              Icon(Icons.person_rounded, color: Color(0xFF2196F3), size: 20),
                              SizedBox(width: spacingSmall),
                              Text('Specific Users'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedAudience = value!;
                          if (value != 'Specific Users') {
                            selectedUserIds.clear();
                          }
                        });
                      },
                    ),
                  ),
                ),
                
                if (selectedAudience == 'Specific Users') ...[
                  SizedBox(height: spacingLarge),
                  Text(
                    'Select Users (${selectedUserIds.length} selected)',
                    style: bodyBold.copyWith(
                      fontSize: 14,
                      color: widget.theme.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: spacingSmall),
                  Container(
                    constraints: BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: widget.theme.cardColor, 
                      borderRadius: BorderRadius.circular(radiusMedium),
                      border: Border.all(
                        color: widget.theme.subtextColor.withOpacity(0.2),
                        width: 1,
                    ),
                    ),
                    child: isLoadingUsers
                        ? _buildSkeletonUsersList()
                        : availableUsers.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(spacingLarge),
                                  child: Text(
                                    'No users found',
                                    style: body.copyWith(
                                      color: widget.theme.subtextColor,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: availableUsers.length,
                                itemBuilder: (context, index) {
                                  final user = availableUsers[index];
                                  final userId = user['userId'] as String;
                                  final userName = user['name'] as String? ?? 'Unknown';
                                  final userRole = user['role'] as String? ?? 'Unknown Role';
                                  final isSelected = selectedUserIds.contains(userId);
                                  
                                  if (userRole != 'Caretakers' && userRole != 'Partially Sighted') {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            selectedUserIds.remove(userId);
                                          } else {
                                            selectedUserIds.add(userId);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: spacingMedium,
                                          vertical: spacingSmall,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? primary.withValues(alpha: 0.1)
                                              : Colors.transparent,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: widget.theme.subtextColor.withOpacity(0.1),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected 
                                                  ? Icons.check_circle_rounded
                                                  : Icons.circle_outlined,
                                              color: isSelected ? primary : widget.theme.subtextColor,
                                              size: 20,
                                            ),
                                            SizedBox(width: spacingSmall),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    userName,
                                                    style: body.copyWith(
                                                      color: widget.theme.textColor,
                                                      fontWeight: isSelected 
                                                          ? FontWeight.w600 
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                  Text(
                                                    userRole,
                                                    style: caption.copyWith(
                                                      fontSize: 11,
                                                      color: widget.theme.subtextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
                
                SizedBox(height: spacingLarge),
                
                Text(
                  'Title',
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacingSmall),
                TextField(
                  controller: titleController,
                  style: body.copyWith(color: widget.theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter announcement title',
                    hintStyle: body.copyWith(
                      color: widget.theme.subtextColor.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: widget.theme.cardColor, 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                      borderSide: BorderSide(
                        color: widget.theme.subtextColor.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                      borderSide: BorderSide(
                        color: widget.theme.subtextColor.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                  ),
                ),
                
                SizedBox(height: spacingLarge),
                
                Text(
                  'Message',
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: widget.theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacingSmall),
                TextField(
                  controller: messageController,
                  maxLines: 6,
                  style: body.copyWith(color: widget.theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter announcement message',
                    hintStyle: body.copyWith(
                      color: widget.theme.subtextColor.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: widget.theme.cardColor, 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                      borderSide: BorderSide(
                        color: widget.theme.subtextColor.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                      borderSide: BorderSide(
                        color: widget.theme.subtextColor.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMedium),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                  ),
                ),
                
                SizedBox(height: spacingLarge * 2),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSending ? null : _sendAnnouncement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: widget.theme.subtextColor.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusMedium),
                      ),
                      padding: EdgeInsets.symmetric(vertical: spacingMedium),
                    ),
                    child: isSending
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Send Announcement',
                            style: bodyBold.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showIconPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.theme.cardColor, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          title: Text(
            'Select Icon',
            style: h3.copyWith(fontSize: 18, color: widget.theme.textColor, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: announcementIcons.length,
              itemBuilder: (context, index) {
                final iconItem = announcementIcons[index];
                final isSelected = selectedIconCodePoint == iconItem.iconCodePoint;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => selectedIconCodePoint = iconItem.iconCodePoint);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(radiusMedium),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? primary.withValues(alpha: 0.1) : widget.theme.cardColor, 
                        borderRadius: BorderRadius.circular(radiusMedium),
                        border: Border.all(
                          color: isSelected ? primary : widget.theme.subtextColor.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(iconItem.icon, color: isSelected ? primary : widget.theme.textColor, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            iconItem.label,
                            style: caption.copyWith(fontSize: 9, color: widget.theme.subtextColor),
                            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: bodyBold.copyWith(color: widget.theme.subtextColor)),
            ),
          ],
        );
      },
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    final List<Map<String, dynamic>> colors = [
      {'color': 0xFFF44336, 'name': 'Red'}, {'color': 0xFFE91E63, 'name': 'Pink'},
      {'color': 0xFF9C27B0, 'name': 'Purple'}, {'color': 0xFF673AB7, 'name': 'Deep Purple'},
      {'color': 0xFF3F51B5, 'name': 'Indigo'}, {'color': 0xFF2196F3, 'name': 'Blue'},
      {'color': 0xFF03A9F4, 'name': 'Light Blue'}, {'color': 0xFF00BCD4, 'name': 'Cyan'},
      {'color': 0xFF009688, 'name': 'Teal'}, {'color': 0xFF4CAF50, 'name': 'Green'},
      {'color': 0xFF8BC34A, 'name': 'Light Green'}, {'color': 0xFFCDDC39, 'name': 'Lime'},
      {'color': 0xFFFFEB3B, 'name': 'Yellow'}, {'color': 0xFFFFC107, 'name': 'Amber'},
      {'color': 0xFFFF9800, 'name': 'Orange'}, {'color': 0xFFFF5722, 'name': 'Deep Orange'},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.theme.cardColor, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
          title: Text(
            'Select Color',
            style: h3.copyWith(fontSize: 18, color: widget.theme.textColor, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final colorValue = colors[index]['color'] as int;
                final isSelected = selectedColorValue == colorValue;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => selectedColorValue = colorValue);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(radiusMedium),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        borderRadius: BorderRadius.circular(radiusMedium),
                        border: Border.all(
                          color: isSelected ? Colors.white : widget.theme.subtextColor.withOpacity(0.3),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Color(colorValue).withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)]
                            : null,
                      ),
                      child: Center(
                        child: isSelected ? Icon(Icons.check_rounded, color: Colors.white, size: 32) : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: bodyBold.copyWith(color: widget.theme.subtextColor)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendAnnouncement() async {
    if (titleController.text.isEmpty || messageController.text.isEmpty) {
      await _speakMessage('Please fill in all fields');
      return;
    }
    if (selectedAudience == 'Specific Users' && selectedUserIds.isEmpty) {
      await _speakMessage('Please select at least one user');
      return;
    }
    
    setState(() => isSending = true);
    
    final announcement = AnnouncementModel(
      id: '', 
      title: titleController.text,
      message: messageController.text,
      targetAudience: selectedAudience,
      specificUsers: List<String>.from(selectedUserIds),
      timestamp: DateTime.now(),
      createdBy: 'Admin', 
      iconCodePoint: selectedIconCodePoint,
      colorValue: selectedColorValue,
    );
    
    final announcementId = await _announcementService.createAnnouncement(announcement);
    setState(() => isSending = false);
    
    if (mounted) {
      if (announcementId != null) {
        String targetMessage = selectedAudience == 'Specific Users' ? '${selectedUserIds.length} specific users' : selectedAudience;
        
        // Wait for TTS to finish before popping the screen!
        await _speakMessage('Announcement sent to $targetMessage');
        
        if (mounted) {
          Navigator.of(context).pop(); 
        }
      } else {
        await _speakMessage('Failed to create announcement');
      }
    }
  }
}