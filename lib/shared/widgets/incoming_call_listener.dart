// File: lib/shared/widgets/incoming_call_listener.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

// Import all 4 call screens
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/communication/screens/video_call_screen.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/communication/screens/voice_call_screen.dart';
import 'package:seelai_app/roles/caretaker/home/sections/home_screen/communication/screens/caretaker_video_call_screen.dart';
import 'package:seelai_app/roles/caretaker/home/sections/home_screen/communication/screens/caretaker_voice_call_screen.dart';

class IncomingCallListener extends StatefulWidget {
  final Widget child;
  final String userRole; 

  const IncomingCallListener({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  StreamSubscription<DatabaseEvent>? _callSubscription;
  String? _currentRingingCallId;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() async {
    final currentUserId = databaseService.currentUserId;
    if (currentUserId == null) return;

    String listenPath = widget.userRole == 'caretaker' 
        ? 'partially_sighted_communication' 
        : 'caretaker_communication';

    _callSubscription = callTrackingService
        .listenForIncomingCalls(listenPath, currentUserId)
        .listen((event) async {
      if (!event.snapshot.exists) return;

      final calls = event.snapshot.value as Map<dynamic, dynamic>;
      
      for (var entry in calls.entries) {
        final callId = entry.key.toString();
        final callData = Map<String, dynamic>.from(entry.value as Map);

        if (callData['status'] == 'calling' && !_isDialogShowing) {
          await _showIncomingCallDialog(
            callId: callId,
            callerId: callData['callerId'],
            callType: callData['type'] ?? 'video',
            listenPath: listenPath,
          );
        } 
        else if ((callData['status'] == 'ended' || callData['status'] == 'cancelled' || callData['status'] == 'missed') && _currentRingingCallId == callId) {
          if (_isDialogShowing && mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _isDialogShowing = false;
            _currentRingingCallId = null;
          }
        }
      }
    });
  }

  Future<void> _showIncomingCallDialog({
    required String callId,
    required String callerId,
    required String callType,
    required String listenPath,
  }) async {
    _isDialogShowing = true;
    _currentRingingCallId = callId;

    String callerRole = widget.userRole == 'caretaker' ? 'partially_sighted' : 'caretaker';
    Map<String, dynamic>? callerData = await databaseService.getUserDataByRole(callerId, callerRole);
    
    String callerName = callerData?['name'] ?? 'Unknown Caller';
    String? callerImage = callerData?['profileImageUrl'];
    
    if (!mounted) return;

   showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                backgroundImage: callerImage != null && callerImage.isNotEmpty
                    ? NetworkImage(callerImage)
                    : null,
                child: callerImage == null || callerImage.isEmpty
                    ? const Icon(Icons.person, size: 40, color: Color(0xFF8B5CF6))
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Incoming ${callType == 'video' ? 'Video' : 'Voice'} Call',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                callerName,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            FloatingActionButton(
              heroTag: 'decline_btn_$callId',
              elevation: 0,
              backgroundColor: const Color(0xFFEF4444),
              onPressed: () async {
                await callTrackingService.updateCallStatus(
                  path: listenPath,
                  callId: callId,
                  status: 'rejected',
                );
                
                if (!dialogContext.mounted) return;
                
                Navigator.of(dialogContext).pop();
                _isDialogShowing = false;
                _currentRingingCallId = null;
              },
              child: const Icon(Icons.call_end_rounded, color: Colors.white),
            ),
            FloatingActionButton(
              heroTag: 'accept_btn_$callId',
              elevation: 0,
              backgroundColor: const Color(0xFF22C55E),
              onPressed: () {
                if (!dialogContext.mounted) return;
                
                Navigator.of(dialogContext).pop();
                _isDialogShowing = false;
                _currentRingingCallId = null;
                
                _navigateToCallScreen(
                  callId: callId, 
                  callType: callType, 
                  callerData: callerData ?? {'id': callerId, 'name': callerName},
                  listenPath: listenPath,
                );
              },
              child: const Icon(Icons.call_rounded, color: Colors.white),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCallScreen({
    required String callId,
    required String callType,
    required Map<String, dynamic> callerData,
    required String listenPath,
  }) {
    // FIX: Using .startCall() instead of Navigator.push so both users get the Dialog!
    if (widget.userRole == 'caretaker') {
      if (callType == 'video') {
        CaretakerVideoCallScreen.startCall(context, callerData, callId: callId, isCaller: false, callPath: listenPath);
      } else {
        CaretakerVoiceCallScreen.startCall(context, callerData, callId: callId, isCaller: false, callPath: listenPath);
      }
    } else {
      Map<String, dynamic> mockUserData = {
        'assignedCaretakers': {
          callerData['id'] ?? callerData['userId'] ?? 'caretaker': callerData
        }
      };

      if (callType == 'video') {
        VideoCallScreen.startCall(context, mockUserData, callId: callId, isCaller: false, callPath: listenPath);
      } else {
        VoiceCallScreen.startCall(context, mockUserData, callId: callId, isCaller: false, callPath: listenPath);
      }
    }
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}