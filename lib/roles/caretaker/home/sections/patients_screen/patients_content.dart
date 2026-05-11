// File: lib/roles/caretaker/home/sections/patients_screen/patients_content.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; 
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patient_model.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patient_details_screen.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'call_patients.dart';
import 'message_patients.dart';

class PatientsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final LocationService locationService;
  final ScrollController? scrollController; 

  const PatientsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.locationService,
    this.scrollController, 
  });

  @override
  State<PatientsContent> createState() => _PatientsContentState();
}

class _PatientsContentState extends State<PatientsContent> with SingleTickerProviderStateMixin {
  final Color _primaryColor = const Color(0xFF7C3AED);

  StreamSubscription? _patientsSubscription;
  List<PatientModel> _patients = [];
  bool _isLoading = true;
  String? _error;
  String? _caretakerId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Timer? _messageTimer;
  int _currentMessageIndex = 0;

  bool _isSimulatingLoad = true;

  // === ANIMATION CONTROLLERS (Header & Mascot Only) ===
  late AnimationController _entryController;
  late Animation<double> _headerOpacity;
  late Animation<Offset> _headerSlide;
  late Animation<double> _mascotScale;
  late Animation<double> _bubbleScale;

  @override
  void initState() {
    super.initState();
    _initializeCaretakerId();
    _startMessageTimer();

    // === Initialize Animations ===
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Header fades & slides in
    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));
    _headerSlide = Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)));
    
    // Mascot and Bubble pop in
    _mascotScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack)));
    _bubbleScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entryController, curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack)));

    // Start header animations immediately
    _entryController.forward();

    // Trigger the skeleton animation for 600ms on load
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isSimulatingLoad = false;
        });
      }
    });
  }

  String _getFirstName() {
    final name = widget.userData['name'] as String? ?? 'Caretaker';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'Caretaker';
  }

  void _startMessageTimer() {
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        final messagesCount = _getMascotMessages().length;
        if (messagesCount > 1) {
          setState(() {
            _currentMessageIndex = (_currentMessageIndex + 1) % messagesCount;
          });
        }
      }
    });
  }

  List<String> _getMascotMessages() {
    final onlineCount = _patients.where((p) => p.isOnline).length;
    final totalCount = _patients.length;
    
    return [
      'Hello, ${_getFirstName()}! You are currently caring for $totalCount patient${totalCount != 1 ? 's' : ''}${totalCount > 0 ? ', with $onlineCount online right now.' : '.'}',
      'Did you know? You can tap on a patient\'s card to view their full details and location.',
      'Need to reach out? Use the quick action buttons to call or message your patients directly.',
    ];
  }

  Future<void> _initializeCaretakerId() async {
    String? caretakerId = widget.userData['userId'] as String? ?? widget.userData['uid'] as String?;
    
    if (caretakerId == null || caretakerId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      caretakerId = user?.uid;
    }
    
    if (caretakerId == null || caretakerId.isEmpty) {
      setState(() {
        _error = 'Caretaker ID not found. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    setState(() => _caretakerId = caretakerId);
    _setupPatientsStream();
  }

  void _setupPatientsStream() {
    if (_caretakerId == null) return;

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });

    _patientsSubscription = caretakerPatientService
        .streamCaretakerPatients(_caretakerId!)
        .listen(
      (patientsData) {
        if (mounted) {
          setState(() {
            _patients = patientsData.map((patientData) {
              int parsedAge = 0;
              if (patientData['age'] != null) {
                parsedAge = patientData['age'] is int 
                    ? patientData['age'] 
                    : int.tryParse(patientData['age'].toString()) ?? 0;
              }

              return PatientModel(
                id: patientData['userId']?.toString() ?? '',
                name: patientData['name']?.toString() ?? 'Unknown',
                age: parsedAge,
                disabilityType: patientData['disabilityType']?.toString() ?? 'Not specified',
                contactNumber: (patientData['contactNumber'] ?? patientData['phone'])?.toString() ?? 'N/A',
                address: patientData['address']?.toString() ?? 'No address',
                isOnline: false, 
                lastActive: DateTime.now(),
                profileImageUrl: patientData['profileImageUrl']?.toString(),
              );
            }).toList();
            
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading patients: $error');
        if (mounted) {
          setState(() {
            _error = 'Failed to load patients: $error';
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _messageTimer?.cancel();
    _patientsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPatients() async {
    if (_caretakerId == null) {
      await _initializeCaretakerId();
      return;
    }
    
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<PatientModel> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    
    return _patients.where((patient) {
      return patient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             patient.disabilityType.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // ==========================================
  // WIDGETS: Skeleton Loaders
  // ==========================================
  Widget _buildSkeletonSearchBar() {
    final baseColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade100;
    
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: 56, 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildSkeletonPatientsList() {
    final baseColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 180, 
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(24)
            ),
          ),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool showSkeleton = _isSimulatingLoad || (_isLoading && _patients.isEmpty);

    return RefreshIndicator(
      onRefresh: _refreshPatients,
      color: _primaryColor,
      child: CustomScrollView(
        controller: widget.scrollController, 
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Top Section (Header & Mascot) - Always Animates In
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _headerOpacity,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.05,
                        right: width * 0.05,
                        top: spacingLarge,
                      ),
                      child: _buildHeader(),
                    ),
                  ),
                ),
                const SizedBox(height: spacingMedium),
                _buildMascotBanner(),
              ],
            ),
          ),
          
          // 2. Middle Section (Search & List) - Skeleton shows instantly
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: spacingMedium),
                  
                  // Search Bar conditionally shows skeleton
                  if (showSkeleton) 
                    _buildSkeletonSearchBar()
                  else if (_patients.isNotEmpty)
                    _buildSearchBar(),
                  
                  const SizedBox(height: spacingLarge),
                  
                  // Content conditionally shows skeleton
                  if (_error != null && _patients.isEmpty && !showSkeleton)
                    _buildErrorState()
                  else if (showSkeleton)
                    _buildSkeletonPatientsList()
                  else if (_patients.isEmpty)
                    _buildEmptyState()
                  else
                    _buildPatientsList(),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Patients',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: widget.theme.textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage and monitor your paired users',
          style: TextStyle(
            fontSize: 14,
            color: widget.theme.subtextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMascotBanner() {
    final messages = _getMascotMessages();
    final safeIndex = _currentMessageIndex % messages.length;
    final displayMessage = messages[safeIndex];
    
    final longestMessage = messages.isNotEmpty 
        ? messages.reduce((a, b) => a.length > b.length ? a : b) 
        : '';

    final double screenWidth = MediaQuery.of(context).size.width;
    final double mascotSize = (screenWidth * 0.32).clamp(100.0, 140.0);
    final double tailBottomMargin = mascotSize * 0.285; 
    final double bubbleBottomMargin = mascotSize * 0.142;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _headerOpacity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor.withValues(alpha: widget.isDarkMode ? 0.25 : 0.15),
                    _primaryColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ScaleTransition(
                scale: _mascotScale,
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  'assets/seelai-icons/seelai2.png',
                  height: mascotSize, 
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: mascotSize * 0.7, 
                    width: mascotSize * 0.7,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.image_not_supported, 
                      color: widget.theme.subtextColor, 
                      size: mascotSize * 0.25
                    ),
                  ),
                ),
              ),
              
              Container(
                margin: EdgeInsets.only(bottom: tailBottomMargin), 
                child: ScaleTransition(
                  scale: _bubbleScale,
                  alignment: Alignment.bottomRight,
                  child: CustomPaint(
                    size: const Size(12, 16),
                    painter: _TailPainter(
                      color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: bubbleBottomMargin), 
                  child: ScaleTransition(
                    scale: _bubbleScale,
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: widget.isDarkMode ? [] : [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          Text(
                            'Seelai',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          
                          Stack(
                            children: [
                              Text(
                                longestMessage,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.transparent, 
                                  height: 1.4,
                                ),
                              ),
                              Positioned.fill(
                                child: TypewriterText(
                                  key: ValueKey(displayMessage),
                                  text: displayMessage,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: widget.isDarkMode
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : Colors.black87,
                                    height: 1.4,
                                  ),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: widget.isDarkMode 
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: widget.isDarkMode
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: TextField(
        controller: _searchController,
        style: body.copyWith(color: widget.theme.textColor),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search patients...',
          hintStyle: body.copyWith(color: widget.theme.subtextColor),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: widget.theme.subtextColor,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear_rounded, color: widget.theme.subtextColor),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(spacingXLarge),
              decoration: BoxDecoration(
                color: error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: error.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: spacingLarge),
            Text(
              'Failed to load patients',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: spacingSmall),
            Text(
              _error ?? 'An error occurred',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: spacingLarge),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializeCaretakerId();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(
                  horizontal: spacingXLarge,
                  vertical: spacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(spacingXLarge * 1.5),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        border: Border.all(
          color: widget.isDarkMode 
            ? _primaryColor.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(spacingXLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withValues(alpha: 0.2),
                  _primaryColor.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: _primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: spacingLarge),
          Text(
            'No patients yet',
            style: bodyBold.copyWith(
              color: widget.theme.textColor,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: spacingSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'When partially sighted users select you as their caretaker, they will appear here automatically',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    final filteredPatients = _filteredPatients;
    
    if (filteredPatients.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: widget.theme.subtextColor.withOpacity(0.3),
              ),
              const SizedBox(height: spacingLarge),
              Text(
                'No patients found',
                style: bodyBold.copyWith(
                  color: widget.theme.textColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: spacingSmall),
              Text(
                'Try a different search term',
                style: body.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: filteredPatients.map((patient) {
        return Padding(
          padding: const EdgeInsets.only(bottom: spacingMedium),
          child: _buildPatientCard(patient),
        );
      }).toList(),
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
        border: Border.all(
          color: widget.isDarkMode
              ? _primaryColor.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsScreen(
                  patient: patient,
                  isDarkMode: widget.isDarkMode,
                  locationService: widget.locationService,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: const EdgeInsets.all(spacingLarge),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        _buildProfileAvatar(patient),
                        if (patient.isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.theme.cardColor,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: spacingMedium),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: bodyBold.copyWith(
                              fontSize: 18,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Colors.white, Colors.white, Colors.transparent],
                                  stops: [0.0, 0.85, 1.0], 
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.dstIn,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 32.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _primaryColor.withValues(alpha: 0.2),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.cake_rounded, size: 12, color: _primaryColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${patient.age} y/o',
                                              style: caption.copyWith(
                                                fontSize: 12,
                                                color: _primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 8),
                                      
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: accent.withValues(alpha: 0.2),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.visibility_off_rounded, size: 12, color: accent),
                                            const SizedBox(width: 4),
                                            Text(
                                              patient.disabilityType,
                                              style: caption.copyWith(
                                                fontSize: 12,
                                                color: accent,
                                                fontWeight: FontWeight.w600,
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
                          ),

                          if (patient.address != null && patient.address != 'No address') ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: widget.theme.subtextColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    patient.address!,
                                    style: caption.copyWith(
                                      fontSize: 13,
                                      color: widget.theme.subtextColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: widget.theme.subtextColor.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ],
                ),
                
                const SizedBox(height: spacingMedium),
                Divider(height: 1, color: widget.theme.subtextColor.withValues(alpha: 0.15)),
                const SizedBox(height: spacingMedium),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.phone_rounded,
                        label: 'Call',
                        color: Colors.green,
                        onTap: () => callPatient(context, patientName: patient.name),
                      ),
                    ),
                    const SizedBox(width: spacingSmall),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.message_rounded,
                        label: 'Message',
                        color: _primaryColor,
                        isOutlined: true,
                        onTap: () => messagePatient(context, patientName: patient.name),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    bool isOutlined = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isOutlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: isOutlined ? Border.all(color: color, width: 1.5) : null,
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isOutlined ? color : white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: bodyBold.copyWith(
                  fontSize: 14,
                  color: isOutlined ? color : white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(PatientModel patient) {
    final hasProfileImage = patient.profileImageUrl != null && 
                            patient.profileImageUrl!.isNotEmpty;

    return Hero(
      tag: 'patient_avatar_${patient.id}',
      child: Material(
        color: Colors.transparent,
        type: MaterialType.transparency,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isDarkMode 
                ? Colors.white.withValues(alpha: 0.1) 
                : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
          ),
          child: ClipOval(
            child: hasProfileImage
                ? Image.network(
                    patient.profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildAvatarPlaceholder(),
                    loadingBuilder: (context, child, loadingProgress) {
                       if (loadingProgress == null) return child;
                       return _buildAvatarPlaceholder(isLoading: true);
                    },
                  )
                : _buildAvatarPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder({bool isLoading = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9333EA), 
            Color(0xFF7C3AED), 
          ],
        ),
      ),
      child: Center(
        child: isLoading 
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.person_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color color;

  _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    
    path.moveTo(size.width, 0); 
    path.lineTo(0, size.height / 2); 
    path.lineTo(size.width, size.height); 
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    int msDuration = widget.text.length * 40; 
    
    _controller = AnimationController(
      vsync: this, 
      duration: Duration(milliseconds: msDuration),
    );
    _setupAnimation();
    
    // Sync with bubble pop-in
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      int msDuration = widget.text.length * 40; 
      _controller.duration = Duration(milliseconds: msDuration);
      _setupAnimation();
      _controller.reset();
      _controller.forward();
    }
  }

  void _setupAnimation() {
    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        int end = _characterCount.value;
        if (end > widget.text.length) end = widget.text.length;
        if (end < 0) end = 0;
        
        return Text(
          widget.text.substring(0, end),
          style: widget.style,
        );
      },
    );
  }
}