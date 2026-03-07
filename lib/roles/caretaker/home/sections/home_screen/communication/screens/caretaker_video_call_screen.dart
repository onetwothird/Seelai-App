// File: lib/roles/caretaker/home/sections/home_screen/communication/screens/caretaker_video_call_screen.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';


class CaretakerVideoCallScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String? callId;
  final bool isCaller;
  final String callPath;

  const CaretakerVideoCallScreen({
    super.key, 
    required this.patientData,
    this.callId,
    this.isCaller = true,
    this.callPath = 'caretaker_communication',
  });

  @override
  State<CaretakerVideoCallScreen> createState() => _CaretakerVideoCallScreenState();
}

class _CaretakerVideoCallScreenState extends State<CaretakerVideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;

  String? _currentCallId;
  StreamSubscription<DatabaseEvent>? _callSubscription;
  
  // Initialize WebRTC Service
  final WebRTCService _webrtcService = WebRTCService();
  bool _isConnectionReady = false;

  final Color _primaryColor = const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _startCallProcess();
  }

  Future<void> _startCallProcess() async {
    // 1. Initialize Video Renderers & Camera
    await _webrtcService.initRenderers();
    await _webrtcService.openUserMedia(true);

    _webrtcService.onAddRemoteStream = (stream) {
      if (mounted) setState(() {}); // Refresh to show remote video
    };
    
    _webrtcService.onConnectionClosed = () {
      if (mounted) _endCall();
    };

    if (mounted) setState(() => _isConnectionReady = true);

    // 2. Handle Database Signaling
    await _handleCallConnection();
  }

  Future<void> _handleCallConnection() async {
    final currentUserId = databaseService.currentUserId ?? widget.patientData['caretakerId'];
    if (currentUserId == null) return;

    final String receiverId = widget.patientData['userId'] ?? widget.patientData['id'] ?? ''; 

    if (widget.isCaller && widget.callId == null) {
      if (receiverId.isEmpty) return;
      
      _currentCallId = await callTrackingService.initiateCall(
        callerId: currentUserId,
        receiverId: receiverId,
        type: 'video',
        path: widget.callPath,
      );
      
      await _webrtcService.makeCall(widget.callPath, _currentCallId!, true);
    } else if (widget.callId != null) {
      _currentCallId = widget.callId;
      
      await callTrackingService.updateCallStatus(
        path: widget.callPath,
        callId: _currentCallId!,
        status: 'accepted',
      );
      
      await _webrtcService.answerCall(widget.callPath, _currentCallId!, true);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String patientName = widget.patientData['name'] ?? 'Patient';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // REMOTE VIDEO (Patient's Camera)
          Positioned.fill(
            child: _isConnectionReady
                ? RTCVideoView(
                    _webrtcService.remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.white54)),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Text(
                        patientName,
                        style: h3.copyWith(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, shadows: [const Shadow(color: Colors.black54, blurRadius: 10)]),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),

                // LOCAL VIDEO (Caretaker PiP)
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 20, bottom: 24),
                    width: 110,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _primaryColor.withValues(alpha: 0.6), width: 2),
                    ),
                    child: _isVideoOff
                        ? const Center(child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 40))
                        : (_isConnectionReady)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18), 
                                child: RTCVideoView(
                                  _webrtcService.localRenderer,
                                  mirror: true,
                                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                ),
                              )
                            : const Center(child: CircularProgressIndicator(color: Colors.white54)),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(left: 20, right: 20, bottom: 32),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCallAction(
                            icon: Icons.flip_camera_ios_rounded,
                            isActive: false,
                            label: 'Flip Camera',
                            onTap: () => _webrtcService.switchCamera(),
                          ),
                          _buildCallAction(
                            icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                            isActive: _isVideoOff,
                            label: 'Toggle Video',
                            onTap: () {
                              setState(() => _isVideoOff = !_isVideoOff);
                              _webrtcService.toggleVideo(_isVideoOff);
                            },
                          ),
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isActive ? _primaryColor : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildEndCallButton(BuildContext context) {
    return Semantics(
      label: 'End Video Call',
      button: true,
      child: GestureDetector(
        onTap: _endCall,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
            ]
          ),
          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}