import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/models/request_model.dart';
import 'package:seelai_app/roles/caretaker/services/request_service.dart';
import 'package:seelai_app/roles/caretaker/screens/request_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class RequestsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final RequestService requestService;
  final Function(int) onRequestCountChange;

  const RequestsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.requestService,
    required this.onRequestCountChange,
  });

  @override
  State<RequestsContent> createState() => _RequestsContentState();
}

class _RequestsContentState extends State<RequestsContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RequestModel> _pendingRequests = [];
  List<RequestModel> _activeRequests = [];
  List<RequestModel> _completedRequests = [];
  bool _isLoading = true;
  String? _error;
  String? _caretakerId;
  StreamSubscription<List<RequestModel>>? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeCaretakerId();
  }

  Future<void> _initializeCaretakerId() async {
    // Try multiple ways to get the caretaker ID
    String? caretakerId;
    
    // Method 1: From userData
    caretakerId = widget.userData['uid'] as String?;
    
    // Method 2: From Firebase Auth
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

    setState(() {
      _caretakerId = caretakerId;
    });

    _setupRequestsStream();
  }

  void _setupRequestsStream() {
    if (_caretakerId == null) {
      setState(() {
        _error = 'Caretaker ID not found';
        _isLoading = false;
      });
      return;
    }

    // Listen to real-time updates from Firebase
    _requestsSubscription = widget.requestService
        .streamRequests(_caretakerId!)
        .listen(
      (requests) {
        if (mounted) {
          setState(() {
            // Filter requests by status
            _pendingRequests = requests
                .where((req) => req.status == RequestStatus.pending)
                .toList();
            
            _activeRequests = requests
                .where((req) => 
                    req.status == RequestStatus.accepted ||
                    req.status == RequestStatus.inProgress)
                .toList();
            
            _completedRequests = requests
                .where((req) => 
                    req.status == RequestStatus.completed ||
                    req.status == RequestStatus.declined)
                .toList();
            
            _isLoading = false;
            _error = null;
            
            // Update pending request count
            widget.onRequestCountChange(_pendingRequests.length);
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading requests: $error');
        if (mounted) {
          setState(() {
            _error = 'Failed to load requests: $error';
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshRequests() async {
    if (_caretakerId == null) {
      await _initializeCaretakerId();
      return;
    }
    
    setState(() => _isLoading = true);
    
    // The stream will automatically update the data
    await Future.delayed(Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return RefreshIndicator(
      onRefresh: _refreshRequests,
      child: Container(
        height: height - 200,
        padding: EdgeInsets.symmetric(horizontal: width * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: spacingSmall),  
            
            // Modern Segmented Tab Bar
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.isDarkMode 
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(radiusLarge),
                border: Border.all(
                  color: widget.isDarkMode 
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, 'Pending', _pendingRequests.length, Colors.orange),
                  SizedBox(width: 4),
                  _buildTabButton(1, 'Active', _activeRequests.length, Colors.blue),
                  SizedBox(width: 4),
                  _buildTabButton(2, 'Completed', _completedRequests.length, Colors.green),
                ],
              ),
            ),
            
            SizedBox(height: spacingLarge),
            
            // Error State
            if (_error != null && !_isLoading)
              Expanded(
                child: _buildErrorState(),
              )
            // Loading State (only on initial load)
            else if (_isLoading && _pendingRequests.isEmpty && _activeRequests.isEmpty && _completedRequests.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: spacingLarge),
                      Text(
                        'Loading requests...',
                        style: body.copyWith(
                          color: widget.theme.subtextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // Tab Content
            else
              Flexible(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsList(_pendingRequests, width),
                    _buildRequestsList(_activeRequests, width),
                    _buildRequestsList(_completedRequests, width),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: error.withOpacity(0.5),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'Failed to load requests',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              _error ?? 'An error occurred',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacingLarge),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializeCaretakerId();
              },
              icon: Icon(Icons.refresh_rounded),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: white,
                padding: EdgeInsets.symmetric(
                  horizontal: spacingLarge,
                  vertical: spacingMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, int count, Color accentColor) {
    final isSelected = _tabController.index == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(radiusMedium),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? white
                          : widget.theme.subtextColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (count > 0) ...[
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? white.withOpacity(0.25)
                            : accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(radiusSmall),
                        border: Border.all(
                          color: isSelected
                              ? white.withOpacity(0.4)
                              : accentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? white : accentColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<RequestModel> requests, double width) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(spacingXLarge * 1.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.theme.subtextColor.withOpacity(0.08),
                    widget.theme.subtextColor.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.theme.subtextColor.withOpacity(0.15),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 72,
                color: widget.theme.subtextColor.withOpacity(0.4),
              ),
            ),
            SizedBox(height: spacingXLarge),
            Text(
              'No requests yet',
              style: h2.copyWith(
                color: widget.theme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: spacingSmall),
            Container(
              padding: EdgeInsets.symmetric(horizontal: spacingLarge),
              child: Text(
                'When new requests arrive, they will appear here',
                style: body.copyWith(
                  color: widget.theme.subtextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 100, top: spacingSmall),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacingLarge),
          child: _buildRequestCard(requests[index]),
        );
      },
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    final priorityColor = request.getPriorityColor();
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: priorityColor.withOpacity(widget.isDarkMode ? 0.3 : 0.18),
            blurRadius: 24,
            offset: Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      child: Material(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestDetailsScreen(
                  request: request,
                  isDarkMode: widget.isDarkMode,
                  requestService: widget.requestService,
                ),
              ),
            ).then((_) {
              // No need to manually refresh - stream handles it
            });
          },
          borderRadius: BorderRadius.circular(radiusLarge),
          splashColor: priorityColor.withOpacity(0.1),
          child: Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  priorityColor.withOpacity(widget.isDarkMode ? 0.15 : 0.06),
                  priorityColor.withOpacity(widget.isDarkMode ? 0.08 : 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radiusLarge),
              border: Border.all(
                color: priorityColor.withOpacity(widget.isDarkMode ? 0.5 : 0.4),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(spacingMedium * 1.2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            priorityColor.withOpacity(0.3),
                            priorityColor.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(radiusMedium),
                        border: Border.all(
                          color: priorityColor.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: priorityColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        request.getIcon(),
                        color: priorityColor,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  request.patientName,
                                  style: bodyBold.copyWith(
                                    fontSize: 18,
                                    color: widget.theme.textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacingSmall * 1.2,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      priorityColor,
                                      priorityColor.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(radiusSmall),
                                  boxShadow: [
                                    BoxShadow(
                                      color: priorityColor.withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  request.priority.toString().split('.').last.toUpperCase(),
                                  style: caption.copyWith(
                                    color: white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacingXSmall),
                          Text(
                            request.requestType,
                            style: body.copyWith(
                              fontSize: 14,
                              color: widget.theme.subtextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: spacingMedium),
                
                // Request Message with Visual Impaired Badge
                Container(
                  padding: EdgeInsets.all(spacingMedium),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(radiusMedium),
                    border: Border.all(
                      color: widget.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacingSmall,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(radiusSmall),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.accessibility_new_rounded,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'VISUALLY IMPAIRED',
                                  style: caption.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacingSmall),
                      Text(
                        request.message,
                        style: body.copyWith(
                          fontSize: 15,
                          color: widget.theme.textColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: spacingMedium),
                
                // Time and Location Info
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacingSmall,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.theme.subtextColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: widget.theme.subtextColor,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _getTimeAgo(request.timestamp),
                            style: caption.copyWith(
                              fontSize: 13,
                              color: widget.theme.subtextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (request.location != null) ...[
                      SizedBox(width: spacingSmall),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacingSmall,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(radiusSmall),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: Colors.green,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Location',
                              style: caption.copyWith(
                                fontSize: 13,
                                color: Colors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: priorityColor,
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

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}