// File: lib/roles/mswd/home/sections/dashboard/urgent_alerts_section.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/roles/mswd/home/sections/requests/requests_details.dart';

class UrgentAlertsSection extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Function(int) onNavigateToTab;

  const UrgentAlertsSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.onNavigateToTab,
  });

  @override
  State<UrgentAlertsSection> createState() => _UrgentAlertsSectionState();
}

class _UrgentAlertsSectionState extends State<UrgentAlertsSection> {
  late Stream<List<RequestModel>> _alertsStream;

  @override
  void initState() {
    super.initState();
    _alertsStream = assistanceRequestService.streamAllRequests();
  }

  String _formatShortTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Urgent Alerts',
              style: h3.copyWith(
                fontSize: 20,
                color: widget.theme.textColor,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateToTab(2), 
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All',
                style: bodyBold.copyWith(
                  color: const Color(0xFF3B82F6),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        // Increased spacing before the cards start
        const SizedBox(height: 16), 
        StreamBuilder<List<RequestModel>>(
          stream: _alertsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFEF4444))),
              );
            }

            if (snapshot.hasError) {
              return _buildEmptyState('Error loading alerts');
            }

            final allRequests = snapshot.data ?? [];
            
            final emergencies = allRequests.where((req) => 
              req.priority.toString().contains('emergency') && 
              req.status != RequestStatus.completed
            ).toList();

            emergencies.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            final topEmergencies = emergencies.take(3).toList();

            if (topEmergencies.isEmpty) {
              return _buildEmptyState('No active emergencies right now.');
            }

            return Column(
              children: topEmergencies.map((request) => _buildAlertCard(request)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded, 
            size: 32, 
            color: const Color(0xFF10B981).withValues(alpha: 0.5), 
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: body.copyWith(
              color: widget.theme.subtextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(RequestModel request) {
    const color = Color(0xFFEF4444); // Red icon/text color

    return Padding(
      // Increased spacing between the individual alert cards
      padding: const EdgeInsets.only(bottom: 16), 
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestDetailsScreen(
                  request: request,
                  isDarkMode: widget.isDarkMode,
                  theme: widget.theme,
                  userDataCache: const {}, 
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              // Removed the red border, replaced with standard subtle border
              border: Border.all(
                color: widget.isDarkMode 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
              // Removed the red shadow, replaced with standard soft shadow
              boxShadow: widget.isDarkMode ? [] : softShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              request.requestType,
                              style: bodyBold.copyWith(
                                fontSize: 15,
                                color: widget.theme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatShortTime(request.timestamp),
                            style: caption.copyWith(
                              fontSize: 11,
                              color: color, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient: ${request.patientName}',
                        style: caption.copyWith(
                          fontSize: 13,
                          color: widget.theme.subtextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: widget.theme.subtextColor.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}