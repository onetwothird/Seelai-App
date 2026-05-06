// File: lib/roles/partially_sighted/home/sections/contacts_screen/adding_contact.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/storage/cloudinary_service.dart'; 
import 'package:flutter_tts/flutter_tts.dart'; // ADDED TTS

class AddContactDialog extends StatefulWidget {
  final String patientId;
  final bool isDarkMode;
  final dynamic theme;
  final VoidCallback? onContactAdded;

  const AddContactDialog({
    super.key,
    required this.patientId,
    required this.isDarkMode,
    required this.theme,
    this.onContactAdded,
  });

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Image Picker State
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  
  // TTS Instance
  final FlutterTts _flutterTts = FlutterTts();
  
  // Brand Color
  final Color _primaryColor = const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("fil-PH");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _addContact() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        String? imageUrl;

        if (_selectedImage != null) {
          imageUrl = await cloudinaryService.uploadContactImage(
            _selectedImage!, 
            widget.patientId,
          );
        }

        await emergencyContactsService.addEmergencyContact(
          userId: widget.patientId,
          contactName: _nameController.text,
          contactPhone: _phoneController.text,
          relationship: _relationshipController.text,
          profileImageUrl: imageUrl, 
        );

        if (!mounted) return;

        widget.onContactAdded?.call();
        Navigator.pop(context);
      } catch (e) {
        await _flutterTts.speak('Failed to add contact.');
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add contact: $e'),
            backgroundColor: error, 
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: body.copyWith(color: widget.theme.textColor),
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: body.copyWith(color: widget.theme.subtextColor),
        prefixIcon: Icon(icon, color: widget.theme.subtextColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: widget.theme.subtextColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: widget.theme.subtextColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: _primaryColor, width: 2), 
        ),
        filled: true,
        fillColor: widget.isDarkMode 
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.02),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXLarge),
      ),
      title: Text(
        'Add Emergency Contact',
        style: h3.copyWith(color: widget.theme.textColor),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                        shape: BoxShape.circle,
                        border: Border.all(color: _primaryColor.withValues(alpha: 0.5), width: 2),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? Icon(Icons.person_outline_rounded, size: 40, color: widget.theme.subtextColor)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: widget.theme.cardColor, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _relationshipController,
                label: 'Relationship',
                icon: Icons.family_restroom_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a relationship';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  if (!RegExp(r'^[0-9+]{10,15}$').hasMatch(value)) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: body.copyWith(color: widget.theme.subtextColor)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addContact,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor, 
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : const Text('Add Contact'),
        ),
      ],
    );
  }
}