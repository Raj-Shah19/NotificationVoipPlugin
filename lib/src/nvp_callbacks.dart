import 'models/nvp_notification.dart';
import 'models/nvp_call_event.dart';
import 'models/nvp_call_state.dart';

/// Callback when a notification banner is tapped.
typedef NvpBannerTapCallback = void Function(NvpNotification notification);

/// Callback when a notification banner is dismissed.
typedef NvpBannerDismissCallback = void Function(NvpNotification notification);

/// Callback when a system notification is tapped.
typedef NvpSystemNotificationTapCallback = void Function(
    NvpNotification notification);

/// Callback when a call is answered.
typedef NvpCallAnsweredCallback = void Function(NvpCallEvent event);

/// Callback when a call is declined.
typedef NvpCallDeclinedCallback = void Function(NvpCallEvent event);

/// Callback when a call ends.
typedef NvpCallEndedCallback = void Function(NvpCallEvent event);

/// Callback when an incoming call arrives (custom screen mode).
typedef NvpCallIncomingCallback = void Function(NvpCallEvent event);

/// Callback when a call times out without being answered.
typedef NvpCallTimeoutEndedCallback = void Function(NvpCallEvent event);

/// Callback when call state changes (mute, speaker, camera, status).
typedef NvpCallStateChangedCallback = void Function(NvpCallState state);

/// Callback when a push token refreshes.
typedef NvpTokenRefreshCallback = void Function(String token);

/// Callback when a push notification is received in the foreground (iOS).
typedef NvpPushReceivedCallback = void Function(Map<String, dynamic> payload);

/// Callback for chat payload.
typedef NvpChatPayloadCallback = void Function(NvpNotification notification);

/// Callback for call payload.
typedef NvpCallPayloadCallback = void Function(NvpCallEvent event);
