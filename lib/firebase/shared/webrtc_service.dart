// File: lib/firebase/shared/webrtc_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class WebRTCService {
  final FirebaseDatabase _database = databaseService.database;
  
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun.relay.metered.ca:80'},
      {
        'urls': 'turn:global.relay.metered.ca:80',
        'username': '39bd9edd6bd07b93b59e2a7c',
        'credential': 'eFiAfnch2oDDz6R5',
      },
      {
        'urls': 'turn:global.relay.metered.ca:443',
        'username': '39bd9edd6bd07b93b59e2a7c',
        'credential': 'eFiAfnch2oDDz6R5',
      },
      {
        'urls': 'turns:global.relay.metered.ca:443?transport=tcp',
        'username': '39bd9edd6bd07b93b59e2a7c',
        'credential': 'eFiAfnch2oDDz6R5',
      }
    ],
    'sdpSemantics': 'unified-plan', 
  };

  Function(MediaStream stream)? onAddRemoteStream;
  Function()? onConnectionClosed;

  final List<RTCIceCandidate> _remoteCandidatesQueue = [];
  bool _isRemoteDescriptionSet = false;

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  // ========================================================================
  // FIXED CAMERA INITIALIZATION (Ideal Constraints + Safe Fallback)
  // ========================================================================
  Future<void> openUserMedia(bool isVideo) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': isVideo ? {
        'facingMode': 'user',
        // Using 'ideal' asks the OS to provide this resolution if possible. 
        // If it's a low-dimension screen, it gracefully downscales without crashing!
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      } : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    } catch (e) {
      debugPrint("Ideal camera request failed: $e. Retrying with basic constraints...");
      // Safe Fallback: If 'ideal' somehow fails on a very strict device, 
      // we ask for the bare minimum to guarantee the camera turns on.
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': isVideo ? {'facingMode': 'user'} : false,
      });
    }
    
    localRenderer.srcObject = _localStream;
  }

  Future<void> _createPeerConnection(String path, String callId, bool isCaller) async {
    _remoteCandidatesQueue.clear();
    _isRemoteDescriptionSet = false;
    
    _peerConnection = await createPeerConnection(_configuration);

    // FIXED: Removed explicit 'addTransceiver' calls that were creating ghost tracks.
    // In Unified Plan, simply adding the tracks automatically creates the correct transceivers.
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        onAddRemoteStream?.call(_remoteStream!);
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      String candidateType = isCaller ? 'callerCandidates' : 'receiverCandidates';
      _database.ref('$path/calls/$callId/$candidateType').push().set({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        onConnectionClosed?.call();
      }
    };
  }

  Future<void> makeCall(String path, String callId, bool isVideo) async {
    await _createPeerConnection(path, callId, true);

    // FIXED: Enforced string constraints ('true'/'false') which are significantly 
    // more reliable across different Android/iOS versions of WebRTC.
    final Map<String, dynamic> offerConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': 'true',
        'OfferToReceiveVideo': isVideo ? 'true' : 'false',
      },
    };

    RTCSessionDescription offer = await _peerConnection!.createOffer(offerConstraints);
    await _peerConnection!.setLocalDescription(offer);

    await _database.ref('$path/calls/$callId/offer').set({
      'type': offer.type,
      'sdp': offer.sdp,
    });

    _database.ref('$path/calls/$callId/answer').onValue.listen((event) async {
      if (event.snapshot.exists) {
        final currentRemoteDesc = await _peerConnection?.getRemoteDescription();
        
        if (currentRemoteDesc == null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          var answer = RTCSessionDescription(data['sdp'], data['type']);
          
          await _peerConnection!.setRemoteDescription(answer);
          _isRemoteDescriptionSet = true;

          for (var candidate in _remoteCandidatesQueue) {
            await _peerConnection!.addCandidate(candidate);
          }
          _remoteCandidatesQueue.clear();
        }
      }
    });

    _database.ref('$path/calls/$callId/receiverCandidates').onChildAdded.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        var candidate = RTCIceCandidate(
          data['candidate'], 
          data['sdpMid'], 
          int.tryParse(data['sdpMLineIndex'].toString()) ?? 0,
        );
        
        if (_isRemoteDescriptionSet) {
          _peerConnection!.addCandidate(candidate);
        } else {
          _remoteCandidatesQueue.add(candidate);
        }
      }
    });
  }

  Future<void> answerCall(String path, String callId, bool isVideo) async {
    await _createPeerConnection(path, callId, false);

    _database.ref('$path/calls/$callId/offer').onValue.listen((event) async {
      if (event.snapshot.exists) {
        final currentRemoteDesc = await _peerConnection?.getRemoteDescription();
        
        if (currentRemoteDesc == null) {
          final offerData = Map<String, dynamic>.from(event.snapshot.value as Map);
          var offer = RTCSessionDescription(offerData['sdp'], offerData['type']);
          
          await _peerConnection!.setRemoteDescription(offer);
          _isRemoteDescriptionSet = true;

          final Map<String, dynamic> answerConstraints = {
            'mandatory': {
              'OfferToReceiveAudio': 'true',
              'OfferToReceiveVideo': isVideo ? 'true' : 'false',
            },
          };

          RTCSessionDescription answer = await _peerConnection!.createAnswer(answerConstraints);
          await _peerConnection!.setLocalDescription(answer);

          await _database.ref('$path/calls/$callId/answer').set({
            'type': answer.type,
            'sdp': answer.sdp,
          });

          for (var candidate in _remoteCandidatesQueue) {
            await _peerConnection!.addCandidate(candidate);
          }
          _remoteCandidatesQueue.clear();
        }
      }
    });

    _database.ref('$path/calls/$callId/callerCandidates').onChildAdded.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        var candidate = RTCIceCandidate(
          data['candidate'], 
          data['sdpMid'], 
          int.tryParse(data['sdpMLineIndex'].toString()) ?? 0,
        );
        
        if (_isRemoteDescriptionSet) {
          _peerConnection!.addCandidate(candidate);
        } else {
          _remoteCandidatesQueue.add(candidate);
        }
      }
    });
  }

  void toggleMic(bool mute) {
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      _localStream!.getAudioTracks()[0].enabled = !mute;
    }
  }

  void toggleVideo(bool turnOff) {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      _localStream!.getVideoTracks()[0].enabled = !turnOff;
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      Helper.switchCamera(_localStream!.getVideoTracks()[0]);
    }
  }

  Future<void> hangUp(String path, String callId) async {
    try {
      final event = await _database.ref('$path/calls/$callId/status').once();
      final currentStatus = event.snapshot.value as String?;

      if (currentStatus != 'missed' && currentStatus != 'rejected') {
        await _database.ref('$path/calls/$callId').update({'status': 'ended'});
      }
    } catch (e) {
      debugPrint("Hangup status update failed: $e");
    }
    
    _localStream?.getTracks().forEach((track) => track.stop());
    _remoteStream?.getTracks().forEach((track) => track.stop());
    
    await _peerConnection?.close();
    
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    _remoteCandidatesQueue.clear();
    
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
  }
}