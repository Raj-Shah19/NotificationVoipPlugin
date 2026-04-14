/// Incoming/outgoing call configuration.
class NvpCallConfig {
  final String callId;
  final String callerName;
  final String? callerAvatar;
  final bool isVideo;
  final bool isOutgoing;
  final bool useNativeScreen;

  /// Call timeout duration in seconds. If set, the incoming call UI will
  /// auto-dismiss after this duration. Pass `null` for system default.
  final int? duration;

  /// Custom ringtone asset name (without extension). Platform-specific:
  /// - iOS: name of a sound file in the app bundle (e.g. `'ringtone'`)
  /// - Android: name of a raw resource (e.g. `'custom_ring'`)
  /// Pass `null` for the system default ringtone.
  final String? ringtone;

  final Map<String, dynamic> extra;

  const NvpCallConfig({
    required this.callId,
    required this.callerName,
    this.callerAvatar,
    this.isVideo = false,
    this.isOutgoing = false,
    this.useNativeScreen = true,
    this.duration,
    this.ringtone,
    this.extra = const {},
  });

  factory NvpCallConfig.fromMap(Map<String, dynamic> map) {
    return NvpCallConfig(
      callId: map['callId'] as String? ?? '',
      callerName: map['callerName'] as String? ?? '',
      callerAvatar: map['callerAvatar'] as String?,
      isVideo: map['isVideo'] as bool? ?? false,
      isOutgoing: map['isOutgoing'] as bool? ?? false,
      useNativeScreen: map['useNativeScreen'] as bool? ?? true,
      duration: map['duration'] as int?,
      ringtone: map['ringtone'] as String?,
      extra: map['extra'] is Map
          ? Map<String, dynamic>.from(map['extra'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toMap() => {
        'callId': callId,
        'callerName': callerName,
        if (callerAvatar != null) 'callerAvatar': callerAvatar,
        'isVideo': isVideo,
        'isOutgoing': isOutgoing,
        'useNativeScreen': useNativeScreen,
        if (duration != null) 'duration': duration,
        if (ringtone != null) 'ringtone': ringtone,
        'extra': extra,
      };

  /// Returns a copy with the given fields replaced.
  NvpCallConfig copyWith({
    String? callId,
    String? callerName,
    String? callerAvatar,
    bool? isVideo,
    bool? isOutgoing,
    bool? useNativeScreen,
    int? duration,
    String? ringtone,
    Map<String, dynamic>? extra,
  }) {
    return NvpCallConfig(
      callId: callId ?? this.callId,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      isVideo: isVideo ?? this.isVideo,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      useNativeScreen: useNativeScreen ?? this.useNativeScreen,
      duration: duration ?? this.duration,
      ringtone: ringtone ?? this.ringtone,
      extra: extra ?? this.extra,
    );
  }
}
