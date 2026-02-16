// File: lib/roles/visually_impaired/home/sections/home_screen/request_caretaker_form.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class RequestCaretakerForm extends StatefulWidget {
  final String userName;
  final String userId;
  final String caretakerId;
  final bool isDarkMode;
  final dynamic theme;

  const RequestCaretakerForm({
    super.key,
    required this.userName,
    required this.userId,
    required this.caretakerId,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<RequestCaretakerForm> createState() => _RequestCaretakerFormState();
}

class _RequestCaretakerFormState extends State<RequestCaretakerForm> with SingleTickerProviderStateMixin {
  late final AssistanceRequestService _assistanceRequestService;
  late final UserActivityService _userActivityService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedType;
  String _selectedPriority = 'Medium';
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _requestTypes = [
    {
      'label': 'General Assistance',
      'icon': Icons.help_outline_rounded,
      'color': Colors.blue,
      'description': 'General help and support',
    },
    {
      'label': 'Navigation Help',
      'icon': Icons.explore_rounded,
      'color': Colors.green,
      'description': 'Help with navigation and directions',
    },
    {
      'label': 'Reading Assistance',
      'icon': Icons.menu_book_rounded,
      'color': Colors.orange,
      'description': 'Help reading text or documents',
    },
    {
      'label': 'Emergency Help',
      'icon': Icons.warning_rounded,
      'color': Colors.red,
      'description': 'Urgent assistance needed',
    },
    {
      'label': 'Other',
      'icon': Icons.more_horiz_rounded,
      'color': Colors.purple,
      'description': 'Other type of assistance',
    },
  ];

  final List<Map<String, dynamic>> _priorityLevels = [
    {
      'label': 'Low',
      'icon': Icons.low_priority_rounded,
      'color': Colors.grey,
    },
    {
      'label': 'Medium',
      'icon': Icons.priority_high_rounded,
      'color': Colors.blue,
    },
    {
      'label': 'High',
      'icon': Icons.notification_important_rounded,
      'color': Colors.orange,
    },
    {
      'label': 'Emergency',
      'icon': Icons.emergency_rounded,
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _assistanceRequestService = assistanceRequestService;
    _userActivityService = userActivityService;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      // Set scaffold background color to match container
      backgroundColor: widget.isDarkMode ? const Color(0xFF0A0E27) : Colors.white,
      appBar: AppBar(
        // Force the AppBar background to be the same as the scaffold/container
        backgroundColor: widget.isDarkMode ? const Color(0xFF0A0E27) : Colors.white,
        // This prevents the color change when scrolling
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: widget.theme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Request Caretaker',
          style: h3.copyWith(
            fontSize: 18,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF0A0E27) : Colors.white,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ListView(
              padding: EdgeInsets.all(spacingLarge),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequestTypeSection(),
                    SizedBox(height: spacingLarge),
                    _buildPrioritySection(),
                    SizedBox(height: spacingLarge),
                    _buildMessageSection(),
                    SizedBox(height: spacingXLarge),
                    _buildSubmitButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  Widget _buildRequestTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type of Assistance',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingSmall),
        Text(
          'Select the type of help you need',
          style: caption.copyWith(
            fontSize: 13,
            color: widget.theme.subtextColor,
          ),
        ),
        SizedBox(height: spacingMedium),
        ..._requestTypes.asMap().entries.map((entry) {
          final index = entry.key;
          final type = entry.value;
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.only(bottom: spacingSmall),
              child: _buildRequestTypeCard(type),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRequestTypeCard(Map<String, dynamic> type) {
    final isSelected = _selectedType == type['label'];
    final color = type['color'] as Color;

    return Semantics(
      label: '${type['label']}. ${type['description']}',
      button: true,
      selected: isSelected,
      hint: 'Double tap to select',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedType = type['label'] as String;
            });
          },
          borderRadius: BorderRadius.circular(radiusMedium),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.1)
                  : widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusMedium),
              border: Border.all(
                color: isSelected
                    ? color
                    : widget.theme.subtextColor.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingSmall),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(radiusSmall),
                  ),
                  child: Icon(
                    type['icon'] as IconData,
                    color: color,
                    size: 22,
                  ),
                ),
                SizedBox(width: spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type['label'] as String,
                        style: bodyBold.copyWith(
                          fontSize: 15,
                          color: widget.theme.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        type['description'] as String,
                        style: caption.copyWith(
                          fontSize: 12,
                          color: widget.theme.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: color,
                    size: 24,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: widget.theme.subtextColor.withOpacity(0.3),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority Level',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingSmall),
        Text(
          'How urgent is your request?',
          style: caption.copyWith(
            fontSize: 13,
            color: widget.theme.subtextColor,
          ),
        ),
        SizedBox(height: spacingMedium),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _priorityLevels.map((priority) {
              return Padding(
                padding: EdgeInsets.only(right: spacingSmall),
                child: _buildPriorityChip(priority),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityChip(Map<String, dynamic> priority) {
    final isSelected = _selectedPriority == priority['label'];
    final color = priority['color'] as Color;

    return Semantics(
      label: '${priority['label']} priority',
      button: true,
      selected: isSelected,
      hint: 'Double tap to select',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedPriority = priority['label'] as String;
            });
          },
          borderRadius: BorderRadius.circular(radiusLarge),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: spacingMedium,
              vertical: spacingSmall,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? color
                  : widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(
                color: isSelected
                    ? color
                    : widget.theme.subtextColor.withOpacity(0.2),
                width: isSelected ? 0 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  priority['icon'] as IconData,
                  color: isSelected ? white : color,
                  size: 18,
                ),
                SizedBox(width: spacingSmall),
                Text(
                  priority['label'] as String,
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: isSelected ? white : widget.theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Message (Optional)',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingSmall),
        Text(
          'Provide more details about your request',
          style: caption.copyWith(
            fontSize: 13,
            color: widget.theme.subtextColor,
          ),
        ),
        SizedBox(height: spacingMedium),
        Container(
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusMedium),
            border: Border.all(
              color: widget.theme.subtextColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _messageController,
            maxLines: 4,
            style: body.copyWith(
              color: widget.theme.textColor,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Describe what you need help with...',
              hintStyle: caption.copyWith(
                color: widget.theme.subtextColor.withOpacity(0.5),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(spacingMedium),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _selectedType != null && !_isSubmitting;

    return Semantics(
      label: 'Send request button',
      button: true,
      enabled: canSubmit,
      hint: canSubmit ? 'Double tap to send request' : 'Please select assistance type first',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSubmit ? _handleSubmit : null,
          borderRadius: BorderRadius.circular(radiusMedium),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: spacingMedium),
            decoration: BoxDecoration(
              gradient: canSubmit
                  ? LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: canSubmit ? null : grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(radiusMedium),
              boxShadow: canSubmit
                  ? [
                      BoxShadow(
                        color: Color(0xFF8B5CF6).withOpacity(0.4),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: _isSubmitting
                ? Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(white),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        color: canSubmit ? white : grey,
                        size: 20,
                      ),
                      SizedBox(width: spacingSmall),
                      Text(
                        'Send Request',
                        style: bodyBold.copyWith(
                          fontSize: 16,
                          color: canSubmit ? white : grey,
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

  Future<void> _handleSubmit() async {
    if (_selectedType == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _assistanceRequestService.sendAssistanceRequest(
        patientId: widget.userId,
        patientName: widget.userName,
        caretakerId: widget.caretakerId,
        requestType: _selectedType!,
        message: _messageController.text.isNotEmpty
            ? _messageController.text
            : 'User needs $_selectedType',
        priority: _selectedPriority.toLowerCase(),
      );

      if (success) {
        await _userActivityService.logCaretakerRequest(
          userId: widget.userId,
          requestType: _selectedType!,
          priority: _selectedPriority,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: white,
                ),
                SizedBox(width: spacingSmall),
                Expanded(
                  child: Text(
                    success
                        ? 'Request sent successfully!'
                        : 'Failed to send request',
                    style: bodyBold.copyWith(color: white),
                  ),
                ),
              ],
            ),
            backgroundColor: success ? Colors.green : error,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: error,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
          ),
        );
      }
    }
  }
}