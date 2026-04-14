/// Call status enum.
enum NvpCallStatus { ringing, connected, onHold, ended }

/// Call state model with real-time tracking.
class NvpCallState {
  final String callId;
  final NvpCallStatus status;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOn;
  final DateTime? connectedAt;
  final Map<String, dynamic> extra;

  const NvpCallState({
    required this.callId,
    required this.status,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isCameraOn = true,
    this.connectedAt,
    this.extra = const {},
  });

  factory NvpCallState.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'ended';
    final status = NvpCallStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => NvpCallStatus.ended,
    );
    return NvpCallState(
      callId: map['callId'] as String? ?? '',
      status: status,
      isMuted: map['isMuted'] as bool? ?? false,
      isSpeakerOn: map['isSpeakerOn'] as bool? ?? false,
      isCameraOn: map['isCameraOn'] as bool? ?? true,
      connectedAt: map['connectedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['connectedAt'] as int)
          : null,
      extra: (map['extra'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toMap() => {
        'callId': callId,
        'status': status.name,
        'isMuted': isMuted,
        'isSpeakerOn': isSpeakerOn,
        'isCameraOn': isCameraOn,
        if (connectedAt != null)
          'connectedAt': connectedAt!.millisecondsSinceEpoch,
        'extra': extra,
      };
}
