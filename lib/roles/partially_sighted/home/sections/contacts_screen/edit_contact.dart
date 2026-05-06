// File: lib/roles/partially_sighted/home/sections/contacts_screen/edit_contact.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:flutter_tts/flutter_tts.dart'; // ADDED TTS
import 'contact_model.dart';

class EditContactDialog extends StatefulWidget {
  final String patientId;
  final ContactModel contact;
  final bool isDarkMode;
  final dynamic theme;
  final VoidCallback? onContactUpdated;

  const EditContactDialog({
    super.key,
    required this.patientId,
    required this.contact,
    required this.isDarkMode,
    required this.theme,
    this.onContactUpdated,
  });

  @override
  State<EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<EditContactDialog> {
  late TextEditingController _nameController;
  late TextEditingController _relationshipController;
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  
  // TTS Instance
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    _nameController = TextEditingController(text: widget.contact.name);
    _relationshipController = TextEditingController(text: widget.contact.relationship);
    _phoneController = TextEditingController(text: widget.contact.phoneNumber);
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

  Future<void> _updateContact() async {
    if (_formKey.currentState!.validate()) {
      try {
        await emergencyContactsService.updateEmergencyContact(
          userId: widget.patientId,
          contactId: widget.contact.id,
          contactName: _nameController.text,
          contactPhone: _phoneController.text,
          relationship: _relationshipController.text,
        );

        if (!mounted) return;

        widget.onContactUpdated?.call();
        Navigator.pop(context);
      } catch (e) {
        await _flutterTts.speak('Failed to update contact.');
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update contact: $e'),
            backgroundColor: error, 
          ),
        );
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
          borderSide: BorderSide(color: primary, width: 2),
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
        'Edit Contact',
        style: h3.copyWith(color: widget.theme.textColor),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              SizedBox(height: spacingMedium),
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
              SizedBox(height: spacingMedium),
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
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: body.copyWith(color: widget.theme.subtextColor)),
        ),
        ElevatedButton(
          onPressed: _updateContact,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
          ),
          child: Text('Update Contact'),
        ),
      ],
    );
  }
}