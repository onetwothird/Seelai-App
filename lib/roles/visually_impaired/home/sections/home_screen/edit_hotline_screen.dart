// File: lib/roles/visually_impaired/home/sections/home_screen/edit_hotline_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/visually_impaired/models/emergency_hotline_model.dart';

class EditHotlineScreen extends StatefulWidget {
  final EmergencyHotline? hotline;
  final bool isDarkMode;
  final dynamic theme;

  const EditHotlineScreen({
    super.key,
    this.hotline,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<EditHotlineScreen> createState() => _EditHotlineScreenState();
}

class _EditHotlineScreenState extends State<EditHotlineScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  
  IconData _selectedIcon = Icons.phone_in_talk_rounded;
  Color _selectedColor = Colors.blue;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<Map<String, dynamic>> _availableIcons = [
    {'icon': Icons.local_police_rounded, 'label': 'Police'},
    {'icon': Icons.local_fire_department_rounded, 'label': 'Fire Dept'},
    {'icon': Icons.local_hospital_rounded, 'label': 'Hospital'},
    {'icon': Icons.phone_in_talk_rounded, 'label': 'Hotline'},
    {'icon': Icons.emergency_rounded, 'label': 'Emergency'},
    {'icon': Icons.medical_services_rounded, 'label': 'Medical'},
    {'icon': Icons.security_rounded, 'label': 'Security'},
    {'icon': Icons.shield_rounded, 'label': 'Shield'},
  ];
  
  final List<Map<String, dynamic>> _availableColors = [
    {'color': Colors.blue, 'label': 'Blue'},
    {'color': Colors.red, 'label': 'Red'},
    {'color': Colors.green, 'label': 'Green'},
    {'color': Colors.orange, 'label': 'Orange'},
    {'color': Colors.purple, 'label': 'Purple'},
    {'color': Colors.teal, 'label': 'Teal'},
    {'color': Colors.amber, 'label': 'Amber'},
    {'color': Colors.pink, 'label': 'Pink'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hotline?.departmentName ?? '');
    _phoneController = TextEditingController(text: widget.hotline?.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.hotline?.address ?? '');
    _descriptionController = TextEditingController(text: widget.hotline?.description ?? '');
    
    if (widget.hotline != null) {
      _selectedIcon = widget.hotline!.icon;
      _selectedColor = widget.hotline!.color;
    }
    
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
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveHotline() {
    if (_formKey.currentState!.validate()) {
      final hotline = EmergencyHotline(
        id: widget.hotline?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        departmentName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        isActive: true,
      );
      
      Navigator.pop(context, hotline);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: widget.theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: widget.theme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.hotline == null ? 'Add Hotline' : 'Edit Hotline',
          style: h3.copyWith(
            fontSize: 18,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: widget.isDarkMode
              ? LinearGradient(
                  colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF2A2F4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.5, 1.0],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [backgroundPrimary, backgroundSecondary, lightBlue.withOpacity(0.3)],
                  stops: [0.0, 0.5, 1.0],
                ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(spacingLarge),
                children: [
                  _buildIconColorSection(),
                  SizedBox(height: spacingLarge),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Department Name',
                    hint: 'e.g., Police Station',
                    icon: Icons.business_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter department name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacingMedium),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'e.g., 911',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacingMedium),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Full address',
                    icon: Icons.location_on_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacingMedium),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description (Optional)',
                    hint: 'Additional information',
                    icon: Icons.description_rounded,
                    maxLines: 3,
                  ),
                  SizedBox(height: spacingXLarge),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customize Appearance',
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingSmall),
        Text(
          'Choose an icon and color for this hotline',
          style: caption.copyWith(
            fontSize: 13,
            color: widget.theme.subtextColor,
          ),
        ),
        SizedBox(height: spacingMedium),
        Container(
          padding: EdgeInsets.all(spacingLarge),
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
                      color: _selectedColor.withOpacity(0.15),
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
                    color: _selectedColor.withOpacity(0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  padding: EdgeInsets.all(spacingXLarge),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_selectedColor, _selectedColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withOpacity(0.4),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(_selectedIcon, color: white, size: 56),
                ),
              ),
              SizedBox(height: spacingLarge),
              Divider(color: widget.theme.subtextColor.withOpacity(0.1)),
              SizedBox(height: spacingLarge),
              _buildIconSelection(),
              SizedBox(height: spacingLarge),
              _buildColorSelection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Icon',
          style: bodyBold.copyWith(
            fontSize: 15,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingSmall),
        Wrap(
          spacing: spacingSmall,
          runSpacing: spacingSmall,
          children: _availableIcons.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final icon = item['icon'] as IconData;
            final label = item['label'] as String;
            final isSelected = icon == _selectedIcon;
            
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 200 + (index * 30)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                );
              },
              child: Semantics(
                label: '$label icon',
                button: true,
                selected: isSelected,
                hint: 'Double tap to select',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _selectedIcon = icon),
                    borderRadius: BorderRadius.circular(radiusMedium),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.all(spacingSmall + 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withOpacity(0.15)
                            : widget.theme.cardColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(radiusMedium),
                        border: Border.all(
                          color: isSelected
                              ? _selectedColor
                              : widget.theme.subtextColor.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? _selectedColor : widget.theme.subtextColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Color',
          style: bodyBold.copyWith(
            fontSize: 15,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingSmall),
        Wrap(
          spacing: spacingSmall,
          runSpacing: spacingSmall,
          children: _availableColors.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final color = item['color'] as Color;
            final label = item['label'] as String;
            final isSelected = color == _selectedColor;
            
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 200 + (index * 30)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                );
              },
              child: Semantics(
                label: '$label color',
                button: true,
                selected: isSelected,
                hint: 'Double tap to select',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    borderRadius: BorderRadius.circular(100),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: isSelected
                          ? Icon(Icons.check_rounded, color: white, size: 24)
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: bodyBold.copyWith(
            fontSize: 16,
            color: widget.theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingSmall),
        Container(
          decoration: BoxDecoration(
            gradient: widget.isDarkMode
                ? LinearGradient(
                    colors: [Color(0xFF1A1F3A), Color(0xFF2A2F4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isDarkMode ? null : widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: widget.isDarkMode
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.1),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: body.copyWith(
              color: widget.theme.textColor,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: caption.copyWith(
                color: widget.theme.subtextColor.withOpacity(0.5),
                fontSize: 14,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(12),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(radiusSmall),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
                borderSide: BorderSide(
                  color: widget.theme.subtextColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
                borderSide: BorderSide(color: primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
                borderSide: BorderSide(color: error, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
                borderSide: BorderSide(color: error, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: spacingMedium,
                vertical: spacingMedium,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Semantics(
      label: widget.hotline == null ? 'Add hotline button' : 'Save changes button',
      button: true,
      hint: 'Double tap to save',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saveHotline,
          borderRadius: BorderRadius.circular(radiusMedium),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: spacingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withOpacity(0.4),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.hotline == null ? Icons.add_rounded : Icons.save_rounded,
                  color: white,
                  size: 20,
                ),
                SizedBox(width: spacingSmall),
                Text(
                  widget.hotline == null ? 'Add Hotline' : 'Save Changes',
                  style: bodyBold.copyWith(
                    fontSize: 16,
                    color: white,
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
}