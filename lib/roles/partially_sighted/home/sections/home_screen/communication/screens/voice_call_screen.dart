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
  final VoidCallback? onClose;

  const VoiceCallScreen({
    super.key, 
    required this.userData,
    this.callId,
    this.isCaller = true,
    this.callPath = 'visually_impaired_communication',
    this.onClose,
  });

  static void startCall(
    BuildContext context, 
    Map<String, dynamic> userData, {
    String? callId,
    bool isCaller = true,
    String callPath = 'visually_impaired_communication',
  }) {
    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => VoiceCallScreen(
        userData: userData,
        callId: callId,
        isCaller: isCaller,
        callPath: callPath,
        onClose: () {
          overlayEntry?.remove();
        },
      ),
    );
    
    Overlay.of(context).insert(overlayEntry);
  }

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isMinimized = false; 

  String? _currentCallId;
  StreamSubscription<DatabaseEvent>? _callSubscription;
  
  final WebRTCService _webrtcService = WebRTCService();
  final Color _primaryColor = const Color(0xFF10B981); 
  Offset _pipPosition = const Offset(20, 40);

  String _caretakerName = 'Caretaker';
  String? _caretakerImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
    
    final ac = widget.userData['assignedCaretakers'];
    if (ac is Map && ac.isNotEmpty) {
      final firstVal = ac.values.first;
      if (firstVal is Map) {
        _caretakerName = firstVal['name'] ?? 'Caretaker';
        _caretakerImage = firstVal['profileImageUrl'];
      }
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

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
    if (_currentCallId != null) {
      _webrtcService.hangUp(widget.callPath, _currentCallId!);
    }
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startCallProcess() async {
    await Permission.microphone.request();
    
    await _webrtcService.initRenderers();
    await _webrtcService.openUserMedia(false); 
    
    _webrtcService.onConnectionClosed = () {
      if (mounted) _endCall();
    };

    await _handleCallConnection();
  }

  Future<void> _handleCallConnection() async {
    final currentUserId = databaseService.currentUserId ?? widget.userData['uid'] ?? widget.userData['userId'];
    if (currentUserId == null) return;

    String receiverId = ''; 
    final ac = widget.userData['assignedCaretakers'];
    if (ac is Map && ac.isNotEmpty) {
      receiverId = ac.keys.first.toString();

      final caretakerData = await databaseService.getUserData(receiverId);
      if (caretakerData != null && mounted) {
        setState(() {
          _caretakerName = caretakerData['name'] ?? _caretakerName;
          _caretakerImage = caretakerData['profileImageUrl'] ?? _caretakerImage;
        });
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
    if (mounted && widget.onClose != null) {
      widget.onClose!(); 
    }
  }

  Widget _buildProfileAvatar(double size) {
    final hasProfileImage = _caretakerImage != null && _caretakerImage!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipOval(
        child: hasProfileImage
            ? Image.network(
                _caretakerImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(size * 0.4),
              )
            : _buildAvatarFallback(size * 0.4),
      ),
    );
  }

  Widget _buildAvatarFallback(double iconSize) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF1E293B)),
      child: Center(child: Icon(Icons.person_rounded, color: Colors.white38, size: iconSize)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    double pipWidth = 120.0;
    double pipHeight = 180.0;

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
              ? _buildMinimizedPiPContent(pipWidth, pipHeight)
              : Scaffold(
                  key: const ValueKey('full_screen'),
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
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                    onPressed: () => setState(() => _isMinimized = true), 
                  ),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 180, 
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.15 * _pulseController.value), 
                          blurRadius: 50 * _pulseController.value,
                          spreadRadius: 20 * _pulseController.value,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: _buildProfileAvatar(180),
              ),
              const SizedBox(height: 40),
              Text(
                _caretakerName,
                style: h3.copyWith(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Connected',
                style: body.copyWith(color: _primaryColor, fontSize: 18, fontWeight: FontWeight.w500),
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
    );
  }

  Widget _buildMinimizedPiPContent(double pipWidth, double pipHeight) {
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
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildUserImageFallback(_caretakerImage),

              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, 
                    color: _primaryColor, 
                    size: 20
                  ), 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserImageFallback(String? imageUrl) {
    return Stack(
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
        
        Container(color: Colors.black.withValues(alpha: 0.3)), 
      ],
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
            color: isActive ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
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
              BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4)),
            ]
          ), 
          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}