import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/models/request_model.dart';
import 'package:seelai_app/roles/caretaker/services/request_service.dart';
import 'package:seelai_app/roles/caretaker/screens/request_details_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    
    // TODO: Load from database
    await Future.delayed(Duration(milliseconds: 500));
    
    // Sample data
    _pendingRequests = [
      RequestModel(
        id: '1',
        patientId: 'p1',
        patientName: 'Maria Santos',
        requestType: 'Navigation Help',
        message: 'Need help getting to the pharmacy',
        status: RequestStatus.pending,
        priority: RequestPriority.high,
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        location: {'latitude': 14.2456, 'longitude': 121.1234},
      ),
      RequestModel(
        id: '2',
        patientId: 'p2',
        patientName: 'Juan Dela Cruz',
        requestType: 'Reading Assistance',
        message: 'Need help reading medicine label',
        status: RequestStatus.pending,
        priority: RequestPriority.medium,
        timestamp: DateTime.now().subtract(Duration(minutes: 15)),
      ),
    ];
    
    _activeRequests = [];
    _completedRequests = [];
    
    setState(() {
      _isLoading = false;
      widget.onRequestCountChange(_pendingRequests.length);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // Tab Bar
        Container(
          margin: EdgeInsets.symmetric(horizontal: width * 0.06),
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.theme.cardColor,
            borderRadius: BorderRadius.circular(radiusLarge),
            boxShadow: widget.isDarkMode
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.15),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ]
                : softShadow,
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            labelColor: white,
            unselectedLabelColor:
                widget.isDarkMode ? widget.theme.subtextColor : grey,
            tabs: [
              Tab(text: 'Pending (${_pendingRequests.length})'),
              Tab(text: 'Active (${_activeRequests.length})'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        
        SizedBox(height: spacingLarge),
        
        // Tab Content
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsList(_pendingRequests, width),
                    _buildRequestsList(_activeRequests, width),
                    _buildRequestsList(_completedRequests, width),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildRequestsList(List<RequestModel> requests, double width) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 80,
              color: widget.theme.subtextColor.withOpacity(0.3),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'No requests yet',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        bottom: 100,
      ),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacingMedium),
          child: _buildRequestCard(requests[index]),
        );
      },
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: request.getPriorityColor().withOpacity(0.2),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : softShadow,
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
            ).then((_) => _loadRequests());
          },
          borderRadius: BorderRadius.circular(radiusLarge),
          child: Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radiusLarge),
              border: widget.isDarkMode
                  ? Border.all(
                      color: request.getPriorityColor().withOpacity(0.4),
                      width: 1.5,
                    )
                  : Border.all(
                      color: request.getPriorityColor().withOpacity(0.3),
                      width: 1.5,
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(spacingMedium),
                      decoration: BoxDecoration(
                        color: request.getPriorityColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(radiusMedium),
                      ),
                      child: Icon(
                        request.getIcon(),
                        color: request.getPriorityColor(),
                        size: 24,
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
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacingSmall,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: request.getPriorityColor().withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(radiusSmall),
                                ),
                                child: Text(
                                  request.priority.toString().split('.').last.toUpperCase(),
                                  style: caption.copyWith(
                                    color: request.getPriorityColor(),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacingXSmall),
                          Text(
                            request.requestType,
                            style: caption.copyWith(
                              fontSize: 14,
                              color: widget.theme.subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacingMedium),
                Text(
                  request.message,
                  style: body.copyWith(
                    fontSize: 15,
                    color: widget.theme.textColor,
                  ),
                ),
                SizedBox(height: spacingMedium),
                Row(
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
                      ),
                    ),
                    if (request.location != null) ...[
                      SizedBox(width: spacingMedium),
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Colors.green,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Location available',
                        style: caption.copyWith(
                          fontSize: 13,
                          color: Colors.green,
                        ),
                      ),
                    ],
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
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }
}