// File: lib/roles/mswd/home/sections/users/users_content.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:shimmer/shimmer.dart'; 
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; 
import 'user_profile_screen.dart';

class UsersContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final ScrollController? scrollController;
  final VoidCallback? onNavigateToLocation; 

  const UsersContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    this.scrollController,
    this.onNavigateToLocation,
  });

  @override
  State<UsersContent> createState() => _UsersContentState();
}

class _UsersContentState extends State<UsersContent> with TickerProviderStateMixin {
  final Color _primaryColor = const Color(0xFF8B5CF6);

  late TabController _tabController;
  int _selectedTab = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _partiallySightedUsers = [];
  List<Map<String, dynamic>> _caretakersUsers = [];
  List<Map<String, dynamic>> _pendingCaretakers = []; 
  
  bool _isLoadingVI = true;
  bool _isLoadingCT = true;
  bool _isLoadingPending = true;

  bool _isSimulatingLoad = true; 

  Timer? _messageTimer;
  int _currentMessageIndex = 0;

  // === ANIMATION CONTROLLERS (Header & Mascot Only) ===
  late AnimationController _entryController;
  late Animation<double> _headerOpacity;
  late Animation<Offset> _headerSlide;
  late Animation<double> _mascotScale;
  late Animation<double> _bubbleScale;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadUsers();
    _startMessageTimer();

    // === Initialize the staggered entry animation ===
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 1. Header Row - Fades & slides in from the left
    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );

    // 2. Mascot - Pops up playfully
    _mascotScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack)),
    );

    // 3. Speech Bubble - Pops out from the mascot
    _bubbleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack)),
    );

    // Start header animations immediately
    _entryController.forward();

    // Keep the skeleton animation for 600ms on load so it looks completely natural
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isSimulatingLoad = false);
      }
    });
  }
  
  void _startMessageTimer() {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex++;
        });
      }
    });
  }

  String _getFirstName() {
    final name = widget.userData['name'] as String? ?? 'Admin';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'Admin';
  }
  
  List<String> _getMascotMessages() {
    int totalUsers = _partiallySightedUsers.length + _caretakersUsers.length;
    int pendingCount = _pendingCaretakers.length;
    
    return [
      'Hello, ${_getFirstName()}! We have $totalUsers registered user${totalUsers != 1 ? 's' : ''} across the platform.',
      if (pendingCount > 0) 'Action required: There are $pendingCount pending caretaker accounts waiting for your approval.',
      'Tip: Use the tabs below to easily filter between Patients, Caretakers, and Requests.'
    ];
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _entryController.dispose(); 
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isSimulatingLoad = true;
    });
    
    await _loadUsers();
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isSimulatingLoad = false;
      });
      _entryController.reset();
      _entryController.forward();
    }
  }

  Future<void> _loadUsers() async {
    await _loadPartiallySightedUsers();
    await _loadCaretakersUsers();
    await _loadPendingCaretakers(); 
  }

  Future<void> _loadPartiallySightedUsers() async {
    try {
      final users = await adminService.getUsersByRole('partially_sighted');
      if (mounted) {
        setState(() {
          _partiallySightedUsers = users;
          _isLoadingVI = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVI = false);
    }
  }

  Future<void> _loadCaretakersUsers() async {
    try {
      final users = await adminService.getUsersByRole('caretaker');
      if (mounted) {
        setState(() {
          _caretakersUsers = users.where((u) => u['approved'] == true).toList();
          _isLoadingCT = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCT = false);
    }
  }

  Future<void> _loadPendingCaretakers() async {
    try {
      final users = await adminService.getPendingCaretakers();
      if (mounted) {
        setState(() {
          _pendingCaretakers = users;
          _isLoadingPending = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredUsers(List<Map<String, dynamic>> users) {
    var filtered = users.where((user) {
      if (_searchQuery.isNotEmpty) {
        final name = user['name']?.toString().toLowerCase() ?? '';
        if (!name.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    return filtered;
  }

  void _navigateToProfile(Map<String, dynamic> user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          isDarkMode: widget.isDarkMode,
          theme: widget.theme,
          selectedUser: user,
          onViewLocation: widget.onNavigateToLocation,
          onDataChanged: _loadUsers,
        ),
      ),
    );
    _loadUsers(); 
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
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
    );
  }

  Widget _buildSkeletonTabBar() {
    final baseColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: 68, 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    final baseColor = widget.isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey.shade300;
    final highlightColor = widget.isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(4, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(width: 60, height: 60, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 140, height: 16, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 100, height: 12, color: Colors.white),
                    ],
                  ),
                ),
                Container(width: 16, height: 16, color: Colors.white),
              ],
            ),
          ),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: _primaryColor,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HEADER ONLY SLIDE ===
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
            
            // === NO MORE CONTENT SLIDE - Skeleton shows instantly ===
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: spacingMedium),
                  
                  _isSimulatingLoad ? _buildSkeletonSearchBar() : _buildSearchBar(),
                  const SizedBox(height: 24),
                  
                  _isSimulatingLoad ? _buildSkeletonTabBar() : _buildTabBar(width),
                  const SizedBox(height: 24),
                  
                  _isSimulatingLoad ? _buildSkeletonList() : _buildTabContent(),
                  
                  const SizedBox(height: 120), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Management',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: widget.theme.textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage all registered users',
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
    final double mascotSize = (screenWidth * 0.32).clamp(90.0, 130.0);
    final double tailBottomMargin = mascotSize * 0.333; 
    final double bubbleBottomMargin = mascotSize * 0.166;

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
              // === MASCOT SCALE ===
              ScaleTransition(
                scale: _mascotScale,
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  'assets/seelai-icons/seelai2.png',
                  height: mascotSize, 
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: mascotSize * 0.8, 
                    width: mascotSize * 0.8,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.image_not_supported, 
                      color: widget.theme.subtextColor,
                      size: mascotSize * 0.3
                    ),
                  ),
                ),
              ),
              
              // === TAIL SCALE ===
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

              // === BUBBLE SCALE ===
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: bubbleBottomMargin), 
                  child: ScaleTransition(
                    scale: _bubbleScale,
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                    color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
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
          hintText: 'Search users...',
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

  Widget _buildTabBar(double width) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
        border: widget.isDarkMode
            ? Border.all(color: _primaryColor.withValues(alpha: 0.2), width: 1)
            : Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1),
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.visibility_off_rounded, 'Patients', _primaryColor),
          _buildTab(1, Icons.favorite_rounded, 'Caretakers', _primaryColor),
          _buildTab(2, Icons.verified_user_rounded, 'Requests', _primaryColor),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label, Color color) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: spacingMedium),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column( 
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? white : widget.theme.subtextColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? white : widget.theme.subtextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildPartiallySightedList();
      case 1:
        return _buildCaretakersList();
      case 2:
        return _buildPendingList();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPartiallySightedList() {
    if (_isLoadingVI) return _buildSkeletonList(); 

    final filteredUsers = _getFilteredUsers(_partiallySightedUsers);

    if (filteredUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            'No partially sighted users found',
            style: body.copyWith(color: widget.theme.subtextColor),
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: filteredUsers.map((user) {
            return Padding(
              padding: const EdgeInsets.only(bottom: spacingMedium),
              child: _buildUserCard(user),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCaretakersList() {
    if (_isLoadingCT) return _buildSkeletonList(); 

    final filteredCaretakers = _getFilteredUsers(_caretakersUsers);

    if (filteredCaretakers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            'No approved caretakers found',
            style: body.copyWith(color: widget.theme.subtextColor),
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: filteredCaretakers.map((caretaker) {
            return Padding(
              padding: const EdgeInsets.only(bottom: spacingMedium),
              child: _buildCaretakerCard(caretaker, isPending: false),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    if (_isLoadingPending) return _buildSkeletonList(); 

    final filteredPending = _getFilteredUsers(_pendingCaretakers);

    if (filteredPending.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.check_circle_outline_rounded, size: 48, color: widget.theme.subtextColor.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text(
              'No pending requests',
              style: body.copyWith(color: widget.theme.subtextColor),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: filteredPending.map((pending) {
            return Padding(
              padding: const EdgeInsets.only(bottom: spacingMedium),
              child: _buildCaretakerCard(pending, isPending: true),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final profileImageUrl = user['profileImageUrl'] as String?;
    final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: _primaryColor.withValues(alpha: 0.2), width: 1)
            : Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToProfile(user),
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: const EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade900,
                  ),
                  child: ClipOval(
                    child: hasProfileImage
                        ? Image.network(profileImageUrl, fit: BoxFit.cover, errorBuilder: (_,_,_) => _buildDefaultAvatarText(user['name'] ?? 'U', _primaryColor))
                        : _buildDefaultAvatarText(user['name'] ?? 'U', _primaryColor),
                  ),
                ),
                const SizedBox(width: spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? 'Unknown', style: bodyBold.copyWith(color: widget.theme.textColor)),
                      Text(user['disabilityType'] ?? 'Patient', style: caption.copyWith(color: widget.theme.subtextColor)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: widget.theme.subtextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaretakerCard(Map<String, dynamic> caretaker, {required bool isPending}) {
    final profileImageUrl = caretaker['profileImageUrl'] as String?;
    final hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;
    
    final color = isPending ? Colors.orange : _primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : softShadow,
        border: widget.isDarkMode
            ? Border.all(color: color.withValues(alpha: 0.2), width: 1)
            : Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToProfile(caretaker),
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: const EdgeInsets.all(spacingLarge),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: ClipOval(
                        child: hasProfileImage
                            ? Image.network(
                                profileImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildDefaultAvatarText(caretaker['name'] ?? 'U', color),
                              )
                            : _buildDefaultAvatarText(caretaker['name'] ?? 'U', color),
                      ),
                    ),
                    const SizedBox(width: spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  caretaker['name'] ?? 'Unknown',
                                  style: bodyBold.copyWith(
                                    fontSize: 16,
                                    color: widget.theme.textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isPending)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "PENDING",
                                    style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            caretaker['relationship'] ?? 'Caretaker',
                            style: caption.copyWith(
                              fontSize: 12,
                              color: widget.theme.subtextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: widget.theme.subtextColor.withOpacity(0.5),
                      size: 18,
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

  Widget _buildDefaultAvatarText(String name, Color baseColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [baseColor, baseColor.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: h2.copyWith(
            color: white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
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