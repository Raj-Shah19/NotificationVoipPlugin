/// Actions that can occur during a VoIP call lifecycle.
enum NvpCallAction {
  /// User accepted the call.
  accept,

  /// User declined the call.
  decline,

  /// Call ended (was previously connected).
  ended,

  /// Incoming call received.
  incoming,

  /// Call timed out without being answered.
  timeoutEnded;

  /// Parse a string from the native platform into an [NvpCallAction].
  ///
  /// Returns `null` for unrecognised values so callers can decide how to
  /// handle unknown actions gracefully.
  static NvpCallAction? fromString(String? value) {
    if (value == null) return null;
    // Support both camelCase (Dart) and snake_case (native) formats.
    switch (value) {
      case 'accept':
        return NvpCallAction.accept;
      case 'decline':
        return NvpCallAction.decline;
      case 'ended':
        return NvpCallAction.ended;
      case 'incoming':
        return NvpCallAction.incoming;
      case 'timeoutEnded':
      case 'timeout_ended':
        return NvpCallAction.timeoutEnded;
      default:
        return null;
    }
  }
}

/// VoIP call event model.
class NvpCallEvent {
  final NvpCallAction? action;
  final String callId;
  final String? callerName;
  final String? callerAvatar;
  final bool isVideo;
  final String? callType;
  final String? conversationId;
  final Map<String, dynamic> payload;

  const NvpCallEvent({
    required this.action,
    required this.callId,
    this.callerName,
    this.callerAvatar,
    this.isVideo = false,
    this.callType,
    this.conversationId,
    this.payload = const {},
  });

  factory NvpCallEvent.fromMap(Map<String, dynamic> map) {
    return NvpCallEvent(
      action: NvpCallAction.fromString(map['action'] as String?),
      callId: map['callId'] as String? ?? '',
      callerName: map['callerName'] as String?,
      callerAvatar: map['callerAvatar'] as String?,
      isVideo: map['isVideo'] as bool? ?? false,
      callType: map['callType'] as String?,
      conversationId: map['conversationId'] as String?,
      payload: map['payload'] is Map
          ? Map<String, dynamic>.from(map['payload'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toMap() => {
        'action': action?.name,
        'callId': callId,
        if (callerName != null) 'callerName': callerName,
        if (callerAvatar != null) 'callerAvatar': callerAvatar,
        'isVideo': isVideo,
        if (callType != null) 'callType': callType,
        if (conversationId != null) 'conversationId': conversationId,
        'payload': payload,
      };
}
