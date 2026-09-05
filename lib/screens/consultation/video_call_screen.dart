import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelId;
  final String clientName;
  final String? agoraToken;

  const VideoCallScreen({
    super.key,
    required this.channelId,
    required this.clientName,
    this.agoraToken,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _localUserJoined = false;

  bool _isMuted = false;
  bool _isVideoDisabled = false;

  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      const RtcEngineContext(
        appId: AppConstants.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (mounted) setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (mounted) setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (mounted) setState(() => _remoteUid = null);
          _endCall();
        },
      ),
    );

    await _engine!.enableVideo();
    await _engine!.startPreview();

    await _engine!.joinChannel(
      token: widget.agoraToken ?? '',
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine?.muteLocalAudioStream(_isMuted);
  }

  void _toggleVideo() {
    setState(() => _isVideoDisabled = !_isVideoDisabled);
    _engine?.muteLocalVideoStream(_isVideoDisabled);
  }

  void _switchCamera() {
    _engine?.switchCamera();
  }

  void _endCall() {
    _timer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video View (Main Fullscreen)
            Center(
              child: _remoteVideoView(),
            ),

            // Top Header Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.red, size: 10),
                        const SizedBox(width: 8),
                        Text(
                          widget.clientName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${_formatDuration(_secondsElapsed)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _switchCamera,
                    icon: const Icon(Icons.cameraswitch, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            // Local PIP View (Bottom Right Thumbnail)
            Positioned(
              right: 16,
              bottom: 110,
              width: 110,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Colors.grey[900],
                  child: _localUserJoined && !_isVideoDisabled
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.videocam_off, color: Colors.white54),
                        ),
                ),
              ),
            ),

            // Call Controls Toolbar
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.cardDark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: _toggleMute,
                      icon: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? Colors.red : Colors.white,
                        size: 26,
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleVideo,
                      icon: Icon(
                        _isVideoDisabled ? Icons.videocam_off : Icons.videocam,
                        color: _isVideoDisabled ? Colors.red : Colors.white,
                        size: 26,
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: _endCall,
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.call_end, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _remoteVideoView() {
    if (_remoteUid != null && _engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelId),
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryTeal),
          const SizedBox(height: 16),
          Text(
            'Waiting for ${widget.clientName} to connect...',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      );
    }
  }
}
