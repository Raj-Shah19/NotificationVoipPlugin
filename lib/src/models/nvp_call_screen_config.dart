import 'package:flutter/widgets.dart';

import 'nvp_call_event.dart';
import '../ui/nvp_call_screen_controller.dart';

/// Configuration for the VoIP call screen.
class NvpCallScreenConfig {
  final bool useNativeCallScreen;
  final Widget Function(NvpCallEvent event, NvpCallScreenController controller)?
      callScreenBuilder;
  final Color? backgroundColor;
  final Widget? avatarPlaceholder;
  final void Function(NvpCallEvent event)? onCallInitiated;
  final void Function(bool isMuted, NvpCallEvent event)? onMuteToggled;
  final void Function(bool isSpeakerOn, NvpCallEvent event)? onSpeakerToggled;
  final void Function(bool isCameraOn, NvpCallEvent event)? onCameraToggled;

  const NvpCallScreenConfig({
    this.useNativeCallScreen = true,
    this.callScreenBuilder,
    this.backgroundColor,
    this.avatarPlaceholder,
    this.onCallInitiated,
    this.onMuteToggled,
    this.onSpeakerToggled,
    this.onCameraToggled,
  });
}
