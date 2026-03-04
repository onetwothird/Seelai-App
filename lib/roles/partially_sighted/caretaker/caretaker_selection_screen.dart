
import 'package:flutter/material.dart';
import 'package:seelai_app/roles/partially_sighted/home/home_screen.dart';
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
  State<CaretakerSelectionScreen> createState() =>
      _CaretakerSelectionScreenState();
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

  // Unified Theme Color
  final Color _primaryColor = const Color(0xFF8B5CF6);
  final Color _slateDark = const Color(0xFF1E293B);
  final Color _slateLight = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCaretakers();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));

    _fadeController.forward();
  }

  Future<void> _loadCaretakers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final DatabaseReference caretakerRef =
          databaseService.database.ref('user_info/caretaker');
      final DatabaseEvent event = await caretakerRef.once();

      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> caretakersMap = event.snapshot.value as Map;
        List<Map<String, dynamic>> caretakersList = [];

        caretakersMap.forEach((key, value) {
          if (value != null && value is Map) {
            Map<String, dynamic> caretaker = Map<String, dynamic>.from(value);
            caretaker['uid'] = key;

            if (caretaker['isActive'] == true &&
                caretaker['role'] == 'caretaker') {
              caretakersList.add(caretaker);
            }
          }
        });

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
          const SnackBar(content: Text('Failed to load caretakers.')),
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
      final relationship =
          (caretaker['relationship'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || relationship.contains(query);
    }).toList();
  }

  Future<void> _assignCaretaker() async {
    if (_selectedCaretakerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a caretaker')),
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

      await caretakerPatientService.assignCaretakerToPatient(
        caretakerId: _selectedCaretakerId!,
        patientId: patientId,
      );

      await activityLogsService.logActivity(
        userId: patientId,
        action: 'caretaker_selected',
        details: 'Selected caretaker: $_selectedCaretakerId',
      );

      Map<String, dynamic>? updatedUserData =
          await databaseService.getUserData(patientId);

      if (mounted && updatedUserData != null) {
        updatedUserData['uid'] = patientId;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VisuallyImpairedHomeScreen(
              userData: updatedUserData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to assign caretaker.'),
            action: SnackBarAction(
              label: 'Retry',
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // HEADER SECTION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          // Back/Skip header row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Optional back button if needed, otherwise spacer
                              const SizedBox(width: 40),
                              TextButton(
                                onPressed: _isAssigning ? null : _skipForNow,
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Select Your\nCaretaker",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -1.0,
                              color: _slateDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Choose a verified caretaker to help you navigate your daily life safely.",
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: _slateLight,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9), // Slate 100
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              style: TextStyle(
                                fontSize: 16,
                                color: _slateDark,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search by name...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: _slateLight,
                                  size: 24,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear_rounded,
                                            color: _slateLight, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // LIST SECTION
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: _primaryColor,
                              ),
                            )
                          : _filteredCaretakers.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  itemCount: _filteredCaretakers.length,
                                  itemBuilder: (context, index) {
                                    final caretaker =
                                        _filteredCaretakers[index];
                                    final isSelected =
                                        _selectedCaretakerId ==
                                            caretaker['uid'];

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: _buildCaretakerCard(
                                        caretaker: caretaker,
                                        isSelected: isSelected,
                                      ),
                                    );
                                  },
                                ),
                    ),

                    // BOTTOM BUTTON SECTION
                    // Only show container if not loading to avoid jumping
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white,
                            ],
                            stops: const [0.0, 0.3],
                          ),
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _selectedCaretakerId != null ? 1.0 : 0.5,
                          child: ElevatedButton(
                            onPressed: _selectedCaretakerId == null || _isAssigning
                                ? null
                                : _assignCaretaker,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 8,
                              shadowColor: _primaryColor.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Confirm Selection",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_isAssigning) ...[
                                  const SizedBox(width: 12),
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          if (_isAssigning)
             LoadingOverlay(
              message: 'Assigning...',
              isVisible: _isAssigning,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No caretakers found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaretakerCard({
    required Map<String, dynamic> caretaker,
    required bool isSelected,
  }) {
    final name = caretaker['name'] ?? 'Unknown';
    final relationship = caretaker['relationship'] ?? 'Caretaker';
    final age = caretaker['age']?.toString() ?? 'N/A';
    final phone =
        caretaker['phone'] ?? caretaker['contactNumber'] ?? 'No phone';
    final profileImageUrl = caretaker['profileImageUrl'] as String?;
    final hasProfileImage =
        profileImageUrl != null && profileImageUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCaretakerId = isSelected ? null : caretaker['uid'];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? _primaryColor.withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
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
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? _primaryColor : _slateLight,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _slateDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded,
                          size: 14, color: _primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        relationship,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _slateLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$phone • Age: $age",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            // Checkbox
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}