import '../nvp_platform_interface.dart';

/// Controller for the custom Flutter call screen.
///
/// Routes all actions through [NvpPlatformInterface] to maintain
/// clean architecture layering. Local state (mute, speaker, camera)
/// is tracked here for immediate UI updates.
class NvpCallScreenController {
  final String callId;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCameraOn = true;

  /// Whether the microphone is currently muted.
  bool get isMuted => _isMuted;

  /// Whether the speaker is currently on.
  bool get isSpeakerOn => _isSpeakerOn;

  /// Whether the camera is currently on.
  bool get isCameraOn => _isCameraOn;

  NvpCallScreenController({required this.callId});

  /// Accept an incoming call.
  Future<void> accept() async {
    await NvpPlatformInterface.instance.acceptCall(callId);
  }

  /// Reject an incoming call.
  Future<void> reject() async {
    await NvpPlatformInterface.instance.rejectCall(callId);
  }

  /// End the current call.
  Future<void> end() async {
    await NvpPlatformInterface.instance.endCall(callId);
  }

  /// Toggle mute and return the new state.
  ///
  /// If the platform call fails, the local state is rolled back.
  Future<bool> toggleMute() async {
    _isMuted = !_isMuted;
    try {
      await NvpPlatformInterface.instance.toggleMute(callId);
    } catch (_) {
      _isMuted = !_isMuted; // rollback on failure
    }
    return _isMuted;
  }

  /// Toggle speaker and return the new state.
  ///
  /// If the platform call fails, the local state is rolled back.
  Future<bool> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    try {
      await NvpPlatformInterface.instance.toggleSpeaker(callId);
    } catch (_) {
      _isSpeakerOn = !_isSpeakerOn; // rollback on failure
    }
    return _isSpeakerOn;
  }

  /// Toggle camera and return the new state.
  ///
  /// If the platform call fails, the local state is rolled back.
  Future<bool> toggleCamera() async {
    _isCameraOn = !_isCameraOn;
    try {
      await NvpPlatformInterface.instance.toggleCamera(callId);
    } catch (_) {
      _isCameraOn = !_isCameraOn; // rollback on failure
    }
    return _isCameraOn;
  }
}
