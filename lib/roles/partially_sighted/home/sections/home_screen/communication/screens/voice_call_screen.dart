// File: lib/roles/partially_sighted/home/sections/home_screen/communication/screens/voice_call_screen.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class VoiceCallScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? callId;
  final bool isCaller;
  final String callPath;

  const VoiceCallScreen({
    super.key, 
    required this.userData,
    this.callId,
    this.isCaller = true,
    this.callPath = 'visually_impaired_communication',
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isMuted = false;
  bool _isSpeaker = false;

  String? _currentCallId;
  StreamSubscription<DatabaseEvent>? _callSubscription;
  
  // Initialize WebRTC Service
  final WebRTCService _webrtcService = WebRTCService();
  
  final Color _primaryColor = const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startCallProcess();
  }

  Future<void> _startCallProcess() async {
    await Permission.microphone.request();
    
    // 1. Initialize Audio Media (false = no video)
    await _webrtcService.initRenderers();
    await _webrtcService.openUserMedia(false);
    
    _webrtcService.onConnectionClosed = () {
      if (mounted) _endCall();
    };

    // 2. Handle Database Signaling
    await _handleCallConnection();
  }

  Future<void> _handleCallConnection() async {
    final currentUserId = databaseService.currentUserId ?? widget.userData['uid'] ?? widget.userData['userId'];
    if (currentUserId == null) return;

    String receiverId = ''; 
    if (widget.userData['assignedCaretakers'] is Map) {
      final map = widget.userData['assignedCaretakers'] as Map;
      if (map.isNotEmpty) {
        receiverId = map.keys.first.toString();
      }
    }

    if (widget.isCaller && widget.callId == null) {
      if (receiverId.isEmpty) return;
      _currentCallId = await callTrackingService.initiateCall(
        callerId: currentUserId,
        receiverId: receiverId,
        type: 'voice',
        path: widget.callPath,
      );
      
      await _webrtcService.makeCall(widget.callPath, _currentCallId!, false);
    } else if (widget.callId != null) {
      _currentCallId = widget.callId;
      await callTrackingService.updateCallStatus(
        path: widget.callPath,
        callId: _currentCallId!,
        status: 'accepted',
      );
      
      await _webrtcService.answerCall(widget.callPath, _currentCallId!, false);
    }

    if (_currentCallId != null) {
      _callSubscription = callTrackingService.listenToCallStatus(widget.callPath, _currentCallId!).listen((event) {
        if (event.snapshot.exists) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          if (data['status'] == 'ended' || data['status'] == 'rejected') {
            if (mounted) _cleanupAndPop();
          }
        }
      });
    }
  }

  Future<void> _endCall() async {
    if (_currentCallId != null) {
      await callTrackingService.updateCallStatus(
        path: widget.callPath,
        callId: _currentCallId!,
        status: 'ended',
      );
      await _webrtcService.hangUp(widget.callPath, _currentCallId!);
    }
    _cleanupAndPop();
  }

  void _cleanupAndPop() {
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    if (_currentCallId != null) {
      _webrtcService.hangUp(widget.callPath, _currentCallId!);
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<dynamic, dynamic>? assignedCaretakers;
    if (widget.userData['assignedCaretakers'] is Map) {
      assignedCaretakers = widget.userData['assignedCaretakers'] as Map<dynamic, dynamic>;
    }

    String caretakerName = 'Caretaker';
    String? caretakerImage;
    if (assignedCaretakers != null && assignedCaretakers.isNotEmpty) {
      final firstValue = assignedCaretakers.values.first;
      if (firstValue is Map) {
        caretakerName = firstValue['name'] ?? 'Caretaker';
        caretakerImage = firstValue['profileImageUrl'];
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF2E1065)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.3 * _pulseController.value),
                            blurRadius: 60 * _pulseController.value,
                            spreadRadius: 30 * _pulseController.value,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _primaryColor, width: 4),
                      image: caretakerImage != null && caretakerImage.isNotEmpty
                          ? DecorationImage(image: NetworkImage(caretakerImage), fit: BoxFit.cover)
                          : null,
                      color: const Color(0xFF334155),
                    ),
                    child: (caretakerImage == null || caretakerImage.isEmpty)
                        ? const Icon(Icons.person_rounded, size: 80, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  caretakerName,
                  style: h3.copyWith(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connected',
                  style: body.copyWith(color: _primaryColor.withValues(alpha: 0.9), fontSize: 18),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCallAction(
                            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            isActive: _isMuted,
                            label: 'Mute',
                            onTap: () {
                              setState(() => _isMuted = !_isMuted);
                              _webrtcService.toggleMic(_isMuted);
                            },
                          ),
                          _buildEndCallButton(context),
                          _buildCallAction(
                            icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                            isActive: _isSpeaker,
                            label: 'Speaker',
                            onTap: () {
                              setState(() => _isSpeaker = !_isSpeaker);
                              // Note: flutter_webrtc uses system audio routing, you may need 
                              // native plugins like 'audio_session' to force speakerphone
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallAction({required IconData icon, required bool isActive, required String label, required VoidCallback onTap}) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? _primaryColor : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildEndCallButton(BuildContext context) {
    return Semantics(
      label: 'End Call',
      button: true,
      child: GestureDetector(
        onTap: _endCall,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4)),
            ]
          ), 
          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}