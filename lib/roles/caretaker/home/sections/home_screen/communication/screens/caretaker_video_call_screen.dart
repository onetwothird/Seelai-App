// File: lib/roles/caretaker/home/sections/home_screen/communication/screens/caretaker_video_call_screen.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/shared/widgets/call_rating_dialog.dart';

class CaretakerVideoCallScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String? callId;
  final bool isCaller;
  final String callPath;
  final void Function(bool wasConnected)? onClose;

  const CaretakerVideoCallScreen({
    super.key, 
    required this.patientData,
    this.callId,
    this.isCaller = true,
    this.callPath = 'caretaker_communication',
    this.onClose,
  });

 static void startCall(
    BuildContext context, 
    Map<String, dynamic> patientData, {
    String? callId,
    bool isCaller = true,
    String callPath = 'caretaker_communication',
  }) {
    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (overlayContext) => CaretakerVideoCallScreen(
        patientData: patientData,
        callId: callId,          
        isCaller: isCaller,       
        callPath: callPath,      
        onClose: (bool wasConnected) {
          overlayEntry?.remove();

          if (wasConnected) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) {
                showDialog(
                  context: context, 
                  barrierDismissible: false,
                  builder: (dialogContext) => CallRatingDialog(
                    onDismissed: () {},
                  ),
                );
              }
            });
          }
        },
      ),
    );
    
    Overlay.of(context).insert(overlayEntry);
  }

  @override
  State<CaretakerVideoCallScreen> createState() => _CaretakerVideoCallScreenState();
}

class _CaretakerVideoCallScreenState extends State<CaretakerVideoCallScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _hasRemoteStream = false; 
  bool _isMinimized = false;     

  bool _isAccepted = false;
  bool _isEnding = false;
  bool _hasPopped = false;

  String? _currentCallId;
  StreamSubscription<DatabaseEvent>? _callSubscription;
  Timer? _ringingTimeout; 
  
  final WebRTCService _webrtcService = WebRTCService();
  bool _isConnectionReady = false;

  Offset _pipPosition = const Offset(20, 40);
  final Color _primaryColor = const Color(0xFF8B5CF6);

  String _patientName = 'Patient';
  String? _patientImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
    
    _patientName = widget.patientData['name'] ?? 'Patient';
    _patientImage = widget.patientData['profileImageUrl'];

    _startCallProcess();
  }

  @override
  Future<bool> didPopRoute() async {
    if (!_isMinimized && mounted) {
      setState(() => _isMinimized = true);
      return true; 
    }
    return false; 
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); 
    _callSubscription?.cancel();
    _ringingTimeout?.cancel(); 
    if (_currentCallId != null && !_isEnding) {
      _isEnding = true;
      callTrackingService.updateCallStatus(
        path: widget.callPath,
        callId: _currentCallId!,
        status: 'ended',
      );
      _webrtcService.hangUp(widget.callPath, _currentCallId!); 
    }
    super.dispose();
  }

  Future<void> _startCallProcess() async {
    await [Permission.camera, Permission.microphone].request();

    await _webrtcService.initRenderers();
    await _webrtcService.openUserMedia(true);

    _webrtcService.onAddRemoteStream = (stream) {
      if (mounted) setState(() => _hasRemoteStream = true);
    };
    
    _webrtcService.onConnectionClosed = () {
      if (mounted) _endCall();
    };

    if (mounted) setState(() => _isConnectionReady = true);

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

      _ringingTimeout = Timer(const Duration(seconds: 40), () {
        if (mounted) _endCall();
      });

    } else if (widget.callId != null) {
      _currentCallId = widget.callId;
      _isAccepted = true; 
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

          if (data['status'] == 'accepted') {
            if (mounted) setState(() => _isAccepted = true);
            _ringingTimeout?.cancel();
          }

          if (data['status'] == 'ended' || data['status'] == 'rejected' || data['status'] == 'missed') {
            if (mounted) _endCall();
          }
        }
      });
    }
  }

  Future<void> _endCall() async {
    if (_isEnding) return;
    
    // FIX: Using setState forces the screen to hide BEFORE WebRTC destroys the feed
    if (mounted) {
      setState(() => _isEnding = true);
    } else {
      _isEnding = true;
    }
    
    _ringingTimeout?.cancel();
    _cleanupAndPop();

    if (_currentCallId != null) {
      String finalStatus = (widget.isCaller && !_isAccepted) ? 'missed' : 'ended';
      try {
        await callTrackingService.updateCallStatus(
          path: widget.callPath,
          callId: _currentCallId!,
          status: finalStatus,
        );
        await _webrtcService.hangUp(widget.callPath, _currentCallId!);
      } catch (e) {
        debugPrint("Error ending call: $e");
      }
    }
  }

  void _cleanupAndPop() {
    if (!_hasPopped && widget.onClose != null) {
      _hasPopped = true;
      widget.onClose!(_hasRemoteStream); 
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEnding) return const SizedBox.shrink(); // FIX: Safely removes UI to stop the red screen crash

    final size = MediaQuery.of(context).size;
    
    double pipWidth = 120.0;
    double pipHeight = 180.0; 

    if (_hasRemoteStream) {
      final videoWidth = _webrtcService.remoteRenderer.videoWidth.toDouble();
      final videoHeight = _webrtcService.remoteRenderer.videoHeight.toDouble();
      if (videoWidth > 0 && videoHeight > 0 && videoWidth > videoHeight) {
        pipWidth = 180.0;
        pipHeight = 120.0;
      }
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
      left: _isMinimized ? _pipPosition.dx : 0,
      top: _isMinimized ? _pipPosition.dy : 0,
      width: _isMinimized ? pipWidth : size.width,
      height: _isMinimized ? pipHeight : size.height,
      child: Material(
        type: _isMinimized ? MaterialType.transparency : MaterialType.canvas,
        elevation: _isMinimized ? 15 : 0,
        borderRadius: BorderRadius.circular(_isMinimized ? 16 : 0),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isMinimized
              ? _buildMinimizedPiP(pipWidth, pipHeight)
              : Scaffold(
                  key: const ValueKey('full_screen'),
                  backgroundColor: Colors.black,
                  body: _buildFullScreenCall(),
                ),
        ),
      ),
    );
  }

  Widget _buildFullScreenCall() {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _hasRemoteStream
                ? RTCVideoView(
                    _webrtcService.remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    key: const ValueKey('remoteVideo'),
                  )
                : (_isConnectionReady && !_isVideoOff
                    ? RTCVideoView(
                        _webrtcService.localRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        key: const ValueKey('localVideoBackground'),
                      )
                    : Container(
                        key: const ValueKey('clearLocalBackground'),
                        child: _buildUserVideoFallback(null), 
                      )),
          ),
        ),

        if (!_hasRemoteStream)
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),

        if (!_hasRemoteStream)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _buildProfileAvatar(110),
                const SizedBox(height: 24),
                Text(
                  _patientName,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Calling...',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                onPressed: () => setState(() => _isMinimized = true),
              ),
            ),
          ),
        ),

        if (_hasRemoteStream && _isConnectionReady)
          Positioned(
            bottom: 120, 
            right: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 110,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16), 
                child: _isVideoOff
                    ? _buildUserVideoFallback(null)
                    : RTCVideoView(
                        _webrtcService.localRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
              ),
            ),
          ),

        Positioned(
          bottom: 32,
          left: 20,
          right: 20,
          child: Container(
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
                      onTap: () => _webrtcService.switchCamera(),
                    ),
                    _buildCallAction(
                      icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                      isActive: _isVideoOff,
                      onTap: () {
                        setState(() => _isVideoOff = !_isVideoOff);
                        _webrtcService.toggleVideo(_isVideoOff);
                      },
                    ),
                    _buildCallAction(
                      icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      isActive: _isMuted,
                      onTap: () {
                        setState(() => _isMuted = !_isMuted);
                        _webrtcService.toggleMic(_isMuted);
                      },
                    ),
                    _buildEndCallButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimizedPiP(double pipWidth, double pipHeight) {
    return GestureDetector(
      key: const ValueKey('pip_screen'),
      onPanUpdate: (details) {
        setState(() {
          final size = MediaQuery.of(context).size;
          double newX = _pipPosition.dx + details.delta.dx;
          double newY = _pipPosition.dy + details.delta.dy;
          
          newX = newX.clamp(10.0, size.width - pipWidth - 10.0);
          newY = newY.clamp(MediaQuery.of(context).padding.top + 10, size.height - pipHeight - 10.0);
          
          _pipPosition = Offset(newX, newY);
        });
      },
      onTap: () => setState(() => _isMinimized = false), 
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _hasRemoteStream
                  ? RTCVideoView(
                      _webrtcService.remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : _buildUserVideoFallback(_patientImage, iconSize: 0), 

              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 40,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8), 
                    child: (_isConnectionReady && !_isVideoOff)
                        ? RTCVideoView(
                            _webrtcService.localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          )
                        : _buildUserVideoFallback(null, iconSize: 0), 
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(double size) {
    final hasProfileImage = _patientImage != null && _patientImage!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipOval(
        child: hasProfileImage
            ? Image.network(
                _patientImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(size * 0.4),
              )
            : _buildAvatarFallback(size * 0.4),
      ),
    );
  }

  Widget _buildAvatarFallback(double iconSize) {
    return Container(
      color: const Color(0xFF334155),
      child: Center(
        child: Icon(Icons.person_rounded, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _buildUserVideoFallback(String? imageUrl, {double iconSize = 40}) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF334155)),
            )
          else
            Container(color: const Color(0xFF334155)),
          
          Container(color: Colors.black.withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  Widget _buildCallAction({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? _primaryColor : Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: _endCall,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ]
        ),
        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}