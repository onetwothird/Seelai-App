// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/themes/widgets.dart';
import 'package:seelai_app/roles/visually_impaired/home/home_screen.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/mobile/loading_overlay.dart';
import 'package:firebase_database/firebase_database.dart';

class CaretakerSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CaretakerSelectionScreen({
    super.key,
    required this.userData,
  });

  @override
  State<CaretakerSelectionScreen> createState() => _CaretakerSelectionScreenState();
}

class _CaretakerSelectionScreenState extends State<CaretakerSelectionScreen> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  bool _isAssigning = false;
  List<Map<String, dynamic>> _caretakers = [];
  String? _selectedCaretakerId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCaretakers();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));

    _fadeController.forward();
  }

  Future<void> _loadCaretakers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all caretakers from Firebase Realtime Database
      final DatabaseReference caretakerRef = databaseService.database.ref('user_info/caretaker');
      final DatabaseEvent event = await caretakerRef.once();

      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> caretakersMap = event.snapshot.value as Map;
        List<Map<String, dynamic>> caretakersList = [];

        caretakersMap.forEach((key, value) {
          if (value != null && value is Map) {
            Map<String, dynamic> caretaker = Map<String, dynamic>.from(value);
            caretaker['uid'] = key;
            
            // Only add active caretakers with role 'caretaker'
            if (caretaker['isActive'] == true && caretaker['role'] == 'caretaker') {
              caretakersList.add(caretaker);
            }
          }
        });

        // Sort by name alphabetically
        caretakersList.sort((a, b) {
          String nameA = (a['name'] ?? '').toString().toLowerCase();
          String nameB = (b['name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        });

        if (mounted) {
          setState(() {
            _caretakers = caretakersList;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _caretakers = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load caretakers. Please try again.'),
            backgroundColor: error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: white,
              onPressed: _loadCaretakers,
            ),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCaretakers {
    if (_searchQuery.isEmpty) {
      return _caretakers;
    }
    
    return _caretakers.where((caretaker) {
      final name = (caretaker['name'] ?? '').toString().toLowerCase();
      final relationship = (caretaker['relationship'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || relationship.contains(query);
    }).toList();
  }

  Future<void> _assignCaretaker() async {
    if (_selectedCaretakerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a caretaker'),
          backgroundColor: error,
        ),
      );
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      final patientId = widget.userData['uid'] ?? '';
      
      if (patientId.isEmpty) {
        throw Exception('Patient ID not found');
      }

      // Use the caretakerPatientService to assign the caretaker
      await caretakerPatientService.assignCaretakerToPatient(
        caretakerId: _selectedCaretakerId!,
        patientId: patientId,
      );

      // Log the activity
      await activityLogsService.logActivity(
        userId: patientId,
        action: 'caretaker_selected',
        details: 'Selected caretaker: $_selectedCaretakerId',
      );

      // Fetch the selected caretaker's name for display
      String caretakerName = 'Caretaker';
      final selectedCaretaker = _caretakers.firstWhere(
        (c) => c['uid'] == _selectedCaretakerId,
        orElse: () => {},
      );
      if (selectedCaretaker.isNotEmpty) {
        caretakerName = selectedCaretaker['name'] ?? 'Caretaker';
      }

      // Fetch updated user data with assigned caretaker
      Map<String, dynamic>? updatedUserData = await databaseService.getUserData(patientId);

      if (mounted && updatedUserData != null) {
        // Add uid to updated user data
        updatedUserData['uid'] = patientId;
        
        // Navigate to home screen with updated data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VisuallyImpairedHomeScreen(
              userData: updatedUserData,
            ),
          ),
        );

        // Show success message
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$caretakerName has been assigned as your caretaker!'),
                backgroundColor: success,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign caretaker. Please try again.'),
            backgroundColor: error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: white,
              onPressed: _assignCaretaker,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  void _skipForNow() {
    // Allow user to skip caretaker selection
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VisuallyImpairedHomeScreen(
          userData: widget.userData,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFAF5FF),
                  Color(0xFFFFF1F2),
                  Color(0xFFF0FDFA),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Background decorative images
          Positioned(
            top: -90,
            left: -30,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/bg_shape_3.png',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            bottom: -60,
            right: -60,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/bg_shape_1.png',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06,
                        vertical: screenHeight * 0.02,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Icon
                          Container(
                            padding: EdgeInsets.all(spacingLarge),
                            decoration: BoxDecoration(
                              gradient: primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              size: 48,
                              color: white,
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.03),

                          // Title
                          ShaderMask(
                            shaderCallback: (bounds) => primaryGradient.createShader(bounds),
                            child: Text(
                              "Select Your Caretaker",
                              style: h1.copyWith(
                                fontSize: screenWidth * 0.08,
                                color: white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.01),
                          
                          Text(
                            "Choose someone to help you on your journey",
                            style: body.copyWith(
                              fontSize: screenWidth * 0.04,
                              color: grey,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: screenHeight * 0.03),

                          // Search bar
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: softShadow,
                              borderRadius: BorderRadius.circular(radiusLarge),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              style: body.copyWith(
                                fontSize: 16,
                                color: black,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                fillColor: white,
                                filled: true,
                                hintText: 'Search caretakers...',
                                hintStyle: body.copyWith(
                                  color: greyLight.withOpacity(0.7),
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: Container(
                                  padding: EdgeInsets.all(14),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: primary,
                                    size: 24,
                                  ),
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          color: greyLight,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(radiusLarge),
                                  borderSide: BorderSide(color: greyLighter, width: 1.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(radiusLarge),
                                  borderSide: BorderSide(color: greyLighter, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(radiusLarge),
                                  borderSide: BorderSide(color: primary, width: 2.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Caretakers List
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                                  ),
                                  SizedBox(height: spacingLarge),
                                  Text(
                                    'Loading caretakers...',
                                    style: body.copyWith(
                                      color: grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _filteredCaretakers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline_rounded,
                                        size: 80,
                                        color: greyLight,
                                      ),
                                      SizedBox(height: spacingLarge),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'No caretakers available'
                                            : 'No caretakers found',
                                        style: bodyBold.copyWith(
                                          fontSize: 18,
                                          color: grey,
                                        ),
                                      ),
                                      SizedBox(height: spacingSmall),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'Please check back later'
                                            : 'Try a different search term',
                                        style: body.copyWith(
                                          color: greyLight,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.06,
                                    vertical: spacingMedium,
                                  ),
                                  itemCount: _filteredCaretakers.length,
                                  itemBuilder: (context, index) {
                                    final caretaker = _filteredCaretakers[index];
                                    final isSelected = _selectedCaretakerId == caretaker['uid'];

                                    return Padding(
                                      padding: EdgeInsets.only(bottom: spacingMedium),
                                      child: _buildCaretakerCard(
                                        caretaker: caretaker,
                                        isSelected: isSelected,
                                        screenWidth: screenWidth,
                                      ),
                                    );
                                  },
                                ),
                    ),

                    // Bottom Buttons
                    Padding(
                      padding: EdgeInsets.all(screenWidth * 0.06),
                      child: Column(
                        children: [
                          // Continue Button
                          if (_selectedCaretakerId != null)
                            CustomButton(
                              text: "Continue",
                              onPressed: _isAssigning ? null : _assignCaretaker,
                              isLarge: true,
                            ),
                          
                          // Skip Button
                          if (_selectedCaretakerId == null)
                            TextButton(
                              onPressed: _isAssigning ? null : _skipForNow,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                'Skip for now',
                                style: bodyBold.copyWith(
                                  fontSize: screenWidth * 0.04,
                                  color: greyLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isAssigning)
            LoadingOverlay(
              message: 'Assigning Caretaker',
              isVisible: _isAssigning,
            ),
        ],
      ),
    );
  }

 Widget _buildCaretakerCard({
    required Map<String, dynamic> caretaker,
    required bool isSelected,
    required double screenWidth,
  }) {
    final name = caretaker['name'] ?? 'Unknown';
    final relationship = caretaker['relationship'] ?? 'Caretaker';
    final age = caretaker['age']?.toString() ?? 'N/A';
    final phone = caretaker['phone'] ?? caretaker['contactNumber'] ?? 'No phone';
    final profileImageUrl = caretaker['profileImageUrl'] as String?;
    final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

 return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCaretakerId = isSelected ? null : caretaker['uid'];
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(radiusLarge),
          border: Border.all(
            color: isSelected ? primary : greyLighter,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : softShadow,
        ),
        padding: EdgeInsets.all(spacingLarge),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: !hasProfileImage && isSelected ? primaryGradient : null,
                color: !hasProfileImage && !isSelected ? primary.withOpacity(0.1) : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primary : primary.withOpacity(0.3),
                  width: isSelected ? 3 : 2,
                ),
                image: hasProfileImage
                    ? DecorationImage(
                        image: NetworkImage(profileImageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasProfileImage
                  ? Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: h1.copyWith(
                          fontSize: 32,
                          color: isSelected ? white : primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),

            SizedBox(width: spacingMedium),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: bodyBold.copyWith(
                      fontSize: 18,
                      color: black,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: spacingXSmall),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: accent,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          relationship,
                          style: body.copyWith(
                            fontSize: 14,
                            color: grey,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacingXSmall),
                  Row(
                    children: [
                      Icon(
                        Icons.cake_outlined,
                        size: 16,
                        color: greyLight,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Age: $age',
                        style: caption.copyWith(
                          fontSize: 13,
                          color: greyLight,
                        ),
                      ),
                      SizedBox(width: spacingMedium),
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: greyLight,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          phone,
                          style: caption.copyWith(
                            fontSize: 13,
                            color: greyLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: spacingMedium),

            // Selection indicator
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: isSelected ? primaryGradient : null,
                color: isSelected ? null : greyLighter,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? white : greyLight,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      color: white,
                      size: 20,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}