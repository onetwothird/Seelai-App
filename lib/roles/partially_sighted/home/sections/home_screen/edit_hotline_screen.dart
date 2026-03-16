// File: lib/roles/partially_sighted/home/sections/home_screen/edit_hotline_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/partially_sighted/models/emergency_hotline_model.dart';

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
  final Color _primaryColor = const Color(0xFF8B5CF6);
  final ImagePicker _picker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  
  String _selectedImageAsset = 'assets/emergency_images/pnp.png';
  Color _selectedColor = Colors.blue;
  
  final List<String> _customImages = [];
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<Map<String, String>> _availableImages = [
    {'path': 'assets/emergency_images/pnp.png', 'label': 'Police'},
    {'path': 'assets/emergency_images/bfp.png', 'label': 'Fire'},
    {'path': 'assets/emergency_images/mdrrmo.png', 'label': 'MDRRMO'},
    {'path': 'assets/emergency_images/dilg.png', 'label': 'DILG'},
    {'path': 'assets/emergency_images/mswd.png', 'label': 'MSWD'},
    {'path': 'assets/emergency_images/menro.png', 'label': 'MENRO'},
    {'path': 'assets/emergency_images/rural_health.png', 'label': 'RHU'},
    {'path': 'assets/emergency_images/office_mayor.png', 'label': 'Mayor'},
    {'path': 'assets/emergency_images/naic_doctors.jpg', 'label': 'Doctors'},
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
      if (widget.hotline!.imageAsset.isNotEmpty) {
        _selectedImageAsset = widget.hotline!.imageAsset;
        bool isDefault = _availableImages.any((img) => img['path'] == _selectedImageAsset);
        if (!isDefault && !_selectedImageAsset.startsWith('assets/')) {
           _customImages.add(_selectedImageAsset);
        }
      }
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

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _customImages.add(image.path);
          _selectedImageAsset = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: error),
        );
      }
    }
  }

  void _saveHotline() {
    if (_formKey.currentState!.validate()) {
      final hotline = EmergencyHotline(
        id: widget.hotline?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        departmentName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        icon: Icons.phone_in_talk_rounded, 
        color: _selectedColor,
        isActive: true, 
        imageAsset: _selectedImageAsset,
      );
      
      Navigator.pop(context, hotline);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.backgroundColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: widget.theme.cardColor,
        scrolledUnderElevation: 0,
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
        color: widget.theme.backgroundColor,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(spacingLarge),
                children: [
                  _buildPreviewAndSelection(),
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

  Widget _buildPreviewAndSelection() {
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
          'Choose an image and color for this hotline',
          style: caption.copyWith(
            fontSize: 13,
            color: widget.theme.subtextColor,
          ),
        ),
        SizedBox(height: spacingMedium),
        Container(
          padding: EdgeInsets.all(spacingLarge),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusLarge),
            boxShadow: widget.isDarkMode ? [] : softShadow,
            border: Border.all(
              color: widget.isDarkMode 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _selectedColor, width: 4),
                    image: DecorationImage(
                      image: _getImageProvider(_selectedImageAsset),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: widget.isDarkMode ? [] : softShadow,
                  ),
                ),
              ),
              SizedBox(height: spacingLarge),
              Divider(color: widget.theme.subtextColor.withOpacity(0.1)),
              SizedBox(height: spacingLarge),
              _buildImageSelection(),
              SizedBox(height: spacingLarge),
              _buildColorSelection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSelection() {
    final List<Map<String, String>> allImages = [
      ..._availableImages,
      ..._customImages.map((path) => {'path': path, 'label': 'Custom'}),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Image',
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
          children: [
            ...allImages.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final imagePath = item['path']!;
              final label = item['label']!;
              final isSelected = imagePath == _selectedImageAsset;
              
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 200 + (index * 30)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
                  );
                },
                child: Semantics(
                  label: '$label image',
                  button: true,
                  selected: isSelected,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedImageAsset = imagePath),
                      borderRadius: BorderRadius.circular(radiusMedium),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected ? _selectedColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(radiusMedium),
                          border: Border.all(
                            color: isSelected
                                ? _selectedColor
                                : widget.theme.subtextColor.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(radiusMedium - 2),
                          child: Image(
                            image: _getImageProvider(imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(radiusMedium),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.theme.backgroundColor,
                    borderRadius: BorderRadius.circular(radiusMedium),
                    border: Border.all(
                      color: widget.theme.subtextColor.withOpacity(0.2),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    color: widget.theme.subtextColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Theme Color',
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
                  child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
                );
              },
              child: Semantics(
                label: '$label color',
                button: true,
                selected: isSelected,
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
                          colors: [color, color.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected ? Icon(Icons.check_rounded, color: white, size: 24) : null,
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
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: widget.isDarkMode ? [] : softShadow,
            border: Border.all(
              color: widget.isDarkMode 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
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
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(radiusSmall),
                ),
                child: Icon(icon, color: _primaryColor, size: 20),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radiusMedium),
                borderSide: BorderSide.none,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saveHotline,
          borderRadius: BorderRadius.circular(radiusMedium),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: spacingMedium),
            decoration: BoxDecoration(
              color: _primaryColor, 
              borderRadius: BorderRadius.circular(radiusMedium),
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