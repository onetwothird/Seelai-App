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

  // Stricter state management to prevent "Ghost Dialogs" and accidental screen pops
  String? _currentRingingCallId;
  bool _isDialogShowing = false;
  bool _isProcessingCall = false;
  BuildContext? _dialogContext;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() async {
    final currentUserId = databaseService.currentUserId;
    if (currentUserId == null) return;

    // We listen to the path where the OTHER user writes their calls
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

            if (callData['status'] == 'calling') {
              // Check if this is a recent call (prevent stale rings from past crashes)
              final timestamp = callData['timestamp'] as int? ?? 0;
              final now = DateTime.now().millisecondsSinceEpoch;

              if (now - timestamp < 45000) {
                // Call must be newer than 45 seconds
                if (!_isDialogShowing && !_isProcessingCall) {
                  await _showIncomingCallDialog(
                    callId: callId,
                    callerId: callData['callerId'],
                    callType: callData['type'] ?? 'video',
                    listenPath: listenPath,
                  );
                }
              }
            } else if (callData['status'] == 'ended' ||
                callData['status'] == 'cancelled' ||
                callData['status'] == 'missed') {
              // If the current ringing call was ended remotely, close the dialog safely
              if (_currentRingingCallId == callId) {
                _closeDialogSafely();
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
    _isProcessingCall = true;
    _currentRingingCallId = callId;

    String callerRole = widget.userRole == 'caretaker'
        ? 'partially_sighted'
        : 'caretaker';
    Map<String, dynamic>? callerData = await databaseService.getUserDataByRole(
      callerId,
      callerRole,
    );

    // Critical Check: Did the caller hang up while we were awaiting the database fetch?
    if (!mounted || _currentRingingCallId != callId) {
      _isProcessingCall = false;
      return;
    }

    String callerName = callerData?['name'] ?? 'Unknown Caller';
    String? callerImage = callerData?['profileImageUrl'];

    _isDialogShowing = true;
    _isProcessingCall = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        _dialogContext = dialogContext; // Store the exact context of the dialog

        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                backgroundImage: callerImage != null && callerImage.isNotEmpty
                    ? NetworkImage(callerImage)
                    : null,
                child: callerImage == null || callerImage.isNotEmpty == false
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFF8B5CF6),
                      )
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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
                _closeDialogSafely();
              },
              child: const Icon(Icons.call_end_rounded, color: Colors.white),
            ),
            FloatingActionButton(
              heroTag: 'accept_btn_$callId',
              elevation: 0,
              backgroundColor: const Color(0xFF22C55E),
              onPressed: () {
                _closeDialogSafely(); // Pops the dialog

                _navigateToCallScreen(
                  callId: callId,
                  callType: callType,
                  callerData:
                      callerData ?? {'id': callerId, 'name': callerName},
                  listenPath: listenPath,
                );
              },
              child: const Icon(Icons.call_rounded, color: Colors.white),
            ),
          ],
        );
      },
    ).then((_) {
      // Reset state automatically when the dialog is completely closed
      _isDialogShowing = false;
      _dialogContext = null;
      _currentRingingCallId = null;
    });
  }

  void _closeDialogSafely() {
    // Nullify the ringing ID immediately so pending awaits abort
    _currentRingingCallId = null;

    // Only pop if we have the specific dialog context to prevent popping the parent screen
    if (_isDialogShowing && _dialogContext != null && _dialogContext!.mounted) {
      Navigator.of(_dialogContext!).pop();
    }
  }

  void _navigateToCallScreen({
    required String callId,
    required String callType,
    required Map<String, dynamic> callerData,
    required String listenPath,
  }) {
    if (widget.userRole == 'caretaker') {
      if (callType == 'video') {
        CaretakerVideoCallScreen.startCall(
          context,
          callerData,
          callId: callId,
          isCaller: false,
          callPath: listenPath,
        );
      } else {
        CaretakerVoiceCallScreen.startCall(
          context,
          callerData,
          callId: callId,
          isCaller: false,
          callPath: listenPath,
        );
      }
    } else {
      // Wrap caller data so the Patient UI has the expected 'assignedCaretakers' structure
      Map<String, dynamic> mockUserData = {
        'assignedCaretakers': {
          callerData['id'] ?? callerData['userId'] ?? 'caretaker': callerData,
        },
      };

      if (callType == 'video') {
        VideoCallScreen.startCall(
          context,
          mockUserData,
          callId: callId,
          isCaller: false,
          callPath: listenPath,
        );
      } else {
        VoiceCallScreen.startCall(
          context,
          mockUserData,
          callId: callId,
          isCaller: false,
          callPath: listenPath,
        );
      }
    }
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _closeDialogSafely();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
