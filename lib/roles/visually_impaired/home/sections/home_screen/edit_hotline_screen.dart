// File: lib/roles/visually_impaired/screens/edit_hotline_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/themes/widgets.dart';
import 'package:seelai_app/roles/visually_impaired/models/emergency_hotline_model.dart';

class EditHotlineScreen extends StatefulWidget {
  final EmergencyHotline? hotline;
  final bool isDarkMode;

  const EditHotlineScreen({
    super.key,
    this.hotline,
    required this.isDarkMode,
  });

  @override
  State<EditHotlineScreen> createState() => _EditHotlineScreenState();
}

class _EditHotlineScreenState extends State<EditHotlineScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  
  IconData _selectedIcon = Icons.phone_in_talk_rounded;
  Color _selectedColor = Colors.blue;
  
  final List<IconData> _availableIcons = [
    Icons.local_police_rounded,
    Icons.local_fire_department_rounded,
    Icons.local_hospital_rounded,
    Icons.phone_in_talk_rounded,
    Icons.emergency_rounded,
    Icons.medical_services_rounded,
    Icons.security_rounded,
    Icons.shield_rounded,
  ];
  
  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.pink,
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
  }

  @override
  void dispose() {
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
          widget.hotline == null ? 'Add Hotline' : 'Edit Hotline',
          style: h2.copyWith(color: textColor, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and color selection
              Container(
                padding: EdgeInsets.all(spacingLarge),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(radiusLarge),
                  boxShadow: widget.isDarkMode 
                    ? [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 16)]
                    : softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Icon & Color', style: bodyBold.copyWith(fontSize: 16, color: textColor)),
                    SizedBox(height: spacingMedium),
                    
                    // Preview
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(spacingLarge),
                        decoration: BoxDecoration(
                          color: _selectedColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(radiusMedium),
                        ),
                        child: Icon(_selectedIcon, color: _selectedColor, size: 48),
                      ),
                    ),
                    
                    SizedBox(height: spacingLarge),
                    
                    // Icon selection
                    Text('Select Icon', style: caption.copyWith(color: subtextColor)),
                    SizedBox(height: spacingSmall),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableIcons.map((icon) {
                        final isSelected = icon == _selectedIcon;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIcon = icon),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? primary.withOpacity(0.2) : cardColor,
                              borderRadius: BorderRadius.circular(radiusMedium),
                              border: Border.all(
                                color: isSelected ? primary : subtextColor.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(icon, color: isSelected ? primary : subtextColor, size: 24),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    SizedBox(height: spacingLarge),
                    
                    // Color selection
                    Text('Select Color', style: caption.copyWith(color: subtextColor)),
                    SizedBox(height: spacingSmall),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableColors.map((color) {
                        final isSelected = color == _selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected 
                                ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                                : [],
                            ),
                            child: isSelected 
                              ? Icon(Icons.check_rounded, color: white, size: 24)
                              : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: spacingLarge),
              
              // Form fields
              _buildTextField(
                controller: _nameController,
                label: 'Department Name',
                hint: 'e.g., Police Station',
                icon: Icons.business_rounded,
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
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
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
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
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
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
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
              ),
              
              SizedBox(height: spacingXLarge),
              
              // Save button
              CustomButton(
                text: widget.hotline == null ? 'Add Hotline' : 'Save Changes',
                onPressed: _saveHotline,
                isLarge: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: bodyBold.copyWith(fontSize: 15, color: textColor)),
        SizedBox(height: spacingSmall),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: widget.isDarkMode 
              ? [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 12)]
              : softShadow,
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: body.copyWith(color: textColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: body.copyWith(color: subtextColor.withOpacity(0.5)),
              prefixIcon: Icon(icon, color: primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
                borderSide: BorderSide(color: subtextColor.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
                borderSide: BorderSide(color: subtextColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
                borderSide: BorderSide(color: primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
                borderSide: BorderSide(color: error),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}