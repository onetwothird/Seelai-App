// File: lib/firebase/shared/webrtc_service.dart

import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class WebRTCService {
  final FirebaseDatabase _database = databaseService.database;
  
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  // Renderers to display the video in the UI
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // STUN servers help the phones find each other over the internet
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  // Callbacks for the UI
  Function(MediaStream stream)? onAddRemoteStream;
  Function()? onConnectionClosed;

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  /// 1. Open Camera and Microphone
  Future<void> openUserMedia(bool isVideo) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': isVideo ? {
        'mandatory': {
          'minWidth': '640', 
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
      } : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localRenderer.srcObject = _localStream;
  }

  /// 2. Initialize Peer Connection
  Future<void> _createPeerConnection(String path, String callId, bool isCaller) async {
    _peerConnection = await createPeerConnection(_configuration);

    // Add our local stream (camera/mic) to the connection
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }

    // Listen for the remote stream (the other person's camera/mic)
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        onAddRemoteStream?.call(_remoteStream!);
      }
    };

    // Listen for ICE candidates (network routing info) and send to Firebase
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

  /// 3. Caller Logic: Make the Call (Create Offer)
  Future<void> makeCall(String path, String callId, bool isVideo) async {
    await _createPeerConnection(path, callId, true);

    // Create Offer
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Save Offer to Firebase
    await _database.ref('$path/calls/$callId/offer').set({
      'type': offer.type,
      'sdp': offer.sdp,
    });

    // Listen for the Answer from the receiver
    // Listen for the Answer from the receiver
    _database.ref('$path/calls/$callId/answer').onValue.listen((event) async {
      if (event.snapshot.exists) {
        // Use the asynchronous getRemoteDescription() method instead
        final currentRemoteDesc = await _peerConnection?.getRemoteDescription();
        
        if (currentRemoteDesc == null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          var answer = RTCSessionDescription(data['sdp'], data['type']);
          await _peerConnection!.setRemoteDescription(answer);
        }
      }
    });

    // Listen for Receiver's ICE Candidates
    _database.ref('$path/calls/$callId/receiverCandidates').onChildAdded.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _peerConnection!.addCandidate(
          RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
        );
      }
    });
  }

  /// 4. Receiver Logic: Answer the Call (Create Answer)
  Future<void> answerCall(String path, String callId, bool isVideo) async {
    await _createPeerConnection(path, callId, false);

    // Get the Offer from Firebase
    DatabaseEvent offerEvent = await _database.ref('$path/calls/$callId/offer').once();
    if (offerEvent.snapshot.exists) {
      final offerData = Map<String, dynamic>.from(offerEvent.snapshot.value as Map);
      var offer = RTCSessionDescription(offerData['sdp'], offerData['type']);
      await _peerConnection!.setRemoteDescription(offer);

      // Create Answer
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Save Answer to Firebase
      await _database.ref('$path/calls/$callId/answer').set({
        'type': answer.type,
        'sdp': answer.sdp,
      });
    }

    // Listen for Caller's ICE Candidates
    _database.ref('$path/calls/$callId/callerCandidates').onChildAdded.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _peerConnection!.addCandidate(
          RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
        );
      }
    });
  }

  /// 5. Controls & Cleanup
  void toggleMic(bool mute) {
    if (_localStream != null) {
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
    // Update Firebase status
    await _database.ref('$path/calls/$callId').update({'status': 'ended'});
    
    // Stop tracks and close connection
    _localStream?.getTracks().forEach((track) => track.stop());
    _remoteStream?.getTracks().forEach((track) => track.stop());
    await _peerConnection?.close();
    
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    
    await localRenderer.dispose();
    await remoteRenderer.dispose();
  }
}