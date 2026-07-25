import 'dart:async';
import 'dart:developer' as developer;

import 'nvp_platform_interface.dart';
import 'models/nvp_config.dart';
import 'models/nvp_notification.dart';
import 'models/nvp_notification_template.dart';
import 'models/nvp_call_event.dart';
import 'models/nvp_call_config.dart';
import 'models/nvp_call_state.dart';
import 'models/nvp_in_app_notification_style.dart';
/// Static-only API for notification_voip_plugin.
///
/// Call [init] once at app start, then use any method. All methods are
/// static - no `.instance` needed.
class NotificationVoipPlugin {
  NotificationVoipPlugin._();

  static NvpConfig? _config;
  static NvpPlatformInterface get _platform => NvpPlatformInterface.instance;

  /// The current plugin configuration, or `null` if [init] hasn't been called.
  static NvpConfig? get config => _config;

  // Cached typed streams
  static Stream<NvpNotification>? _notificationTapStream;
  static Stream<NvpCallEvent>? _callEventStream;
  static Stream<NvpCallState>? _callStateStream;
  static Stream<String>? _tokenRefreshStream;
  static Stream<Map<String, dynamic>>? _pushReceivedStream;

  // Callback subscriptions
  static StreamSubscription? _bannerTapSub;
  static StreamSubscription? _callEventSub;
  static StreamSubscription? _callStateSub;
  static StreamSubscription? _tokenRefreshSub;
  static StreamSubscription? _pushReceivedSub;

  // -- INIT --

  /// Call once at app start. Everything works with defaults.
  static Future<void> init([NvpConfig? config]) async {
    // Cancel previous callback subscriptions before re-wiring
    _bannerTapSub?.cancel();
    _bannerTapSub = null;
    _callEventSub?.cancel();
    _callEventSub = null;
    _callStateSub?.cancel();
    _callStateSub = null;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _pushReceivedSub?.cancel();
    _pushReceivedSub = null;

    _config = config;
    try {
      await _platform.init(config?.toMap());
      _wireCallbacks(config);
    } catch (e) {
      _log('init', e);
    }
  }

  /// Wire [NvpConfig] callbacks to the corresponding streams.
  static void _wireCallbacks(NvpConfig? config) {
    if (config == null) return;

    // -- Notification tap callbacks --
    if (config.onBannerTap != null || config.onSystemNotificationTap != null) {
      _bannerTapSub?.cancel();
      _bannerTapSub = onNotificationTap.listen((notification) {
        config.onBannerTap?.call(notification);
        config.onSystemNotificationTap?.call(notification);
      });
    }

    // -- Call event callbacks --
    if (config.onCallAnswered != null ||
        config.onCallDeclined != null ||
        config.onCallEnded != null ||
        config.onCallIncoming != null ||
        config.onCallTimeoutEnded != null) {
      _callEventSub?.cancel();
      _callEventSub = onCallEvent.listen((event) {
        switch (event.action) {
          case NvpCallAction.accept:
            config.onCallAnswered?.call(event);
            break;
          case NvpCallAction.decline:
            config.onCallDeclined?.call(event);
            break;
          case NvpCallAction.ended:
            config.onCallEnded?.call(event);
            break;
          case NvpCallAction.incoming:
            config.onCallIncoming?.call(event);
            break;
          case NvpCallAction.timeoutEnded:
            config.onCallTimeoutEnded?.call(event);
            break;
          case null:
            break;
        }
      });
    }

    // -- Call state changed callback --
    if (config.onCallStateChanged != null) {
      _callStateSub?.cancel();
      _callStateSub = onCallStateChanged.listen((state) {
        config.onCallStateChanged?.call(state);
      });
    }

    // -- Token refresh callback --
    if (config.onTokenRefresh != null) {
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = onTokenRefresh.listen((token) {
        config.onTokenRefresh?.call(token);
      });
    }

    // -- Push received callback (iOS foreground) --
    if (config.onPushReceived != null) {
      _pushReceivedSub?.cancel();
      _pushReceivedSub = onPushReceived.listen((payload) {
        config.onPushReceived?.call(payload);
      });
    }
  }

  // -- TOKENS --

  /// Get the push token. FCM on Android, APNs on iOS, null on others.
  static Future<String?> getPushToken() async {
    try { return await _platform.getPushToken(); }
    catch (e) { _log('getPushToken', e); return null; }
  }

  /// Get FCM token explicitly.
  static Future<String?> getFCMToken() async {
    try { return await _platform.getFCMToken(); }
    catch (e) { _log('getFCMToken', e); return null; }
  }

  /// Get APNs token (iOS only, null on others).
  static Future<String?> getAPNsToken() async {
    try { return await _platform.getAPNsToken(); }
    catch (e) { _log('getAPNsToken', e); return null; }
  }

  /// Get VoIP token (iOS only, null on others).
  static Future<String?> getVoIPToken() async {
    try { return await _platform.getVoIPToken(); }
    catch (e) { _log('getVoIPToken', e); return null; }
  }

  // -- PERMISSIONS --

  /// Request notification permission. Returns true if granted.
  static Future<bool> requestPermission() async {
    try { return await _platform.requestPermission(); }
    catch (e) { _log('requestPermission', e); return false; }
  }

  /// Check if notifications are enabled.
  static Future<bool> isPermissionGranted() async {
    try { return await _platform.isPermissionGranted(); }
    catch (e) { _log('isPermissionGranted', e); return false; }
  }

  /// Open the OS notification settings for this app.
  static Future<void> openSettings() async {
    try { await _platform.openSettings(); }
    catch (e) { _log('openSettings', e); }
  }

  // -- NOTIFICATIONS --

  /// Show an in-app banner notification (Flutter overlay).
  ///
  /// [style] customizes the banner's background and text colors. When
  /// omitted, the banner uses light/dark-mode-aware platform defaults.
  static Future<bool> showInAppNotification(
    NvpNotification notification, {
    NvpNotificationTemplate? template,
    NvpInAppNotificationStyle? style,
  }) async {
    try {
      return await _platform.showInAppNotification(
        notification.toMap(), template?.toMap(), style?.toMap());
    } catch (e) { _log('showInAppNotification', e); return false; }
  }

  /// Show a system notification (notification tray / status bar).
  static Future<bool> showNotification(
    NvpNotification notification, {
    NvpNotificationTemplate? template,
  }) async {
    try {
      return await _platform.showNotification(
        notification.toMap(), template?.toMap());
    } catch (e) { _log('showNotification', e); return false; }
  }

  /// Clear all notifications.
  static Future<void> clearAll() async {
    try { await _platform.clearAll(); }
    catch (e) { _log('clearAll', e); }
  }

  /// Cancel a specific notification by its [tag].
  ///
  /// Use this to dismiss a notification when the user navigates to the
  /// relevant content (e.g. opens the conversation that triggered it).
  static Future<void> cancelNotification(String tag) async {
    try { await _platform.cancelNotification(tag); }
    catch (e) { _log('cancelNotification', e); }
  }

  /// Suppress the next foreground notification display (iOS only).
  ///
  /// Call this after receiving an [onPushReceived] event to prevent the
  /// notification from being shown. Typical usage:
  /// ```dart
  /// NotificationVoipPlugin.onPushReceived.listen((payload) {
  ///   if (payload['conversationId'] == activeConversationId) {
  ///     NotificationVoipPlugin.suppressNextForegroundNotification();
  ///   }
  /// });
  /// ```
  static Future<void> suppressNextForegroundNotification() async {
    try { await _platform.suppressNextForegroundNotification(); }
    catch (e) { _log('suppressNextForegroundNotification', e); }
  }

  // -- BADGE --

  /// Set the app badge count. Pass 0 to clear.
  static Future<void> setBadgeCount(int count) async {
    try { await _platform.setBadgeCount(count); }
    catch (e) { _log('setBadgeCount', e); }
  }

  /// Get the current badge count.
  static Future<int> getBadgeCount() async {
    try { return await _platform.getBadgeCount(); }
    catch (e) { _log('getBadgeCount', e); return 0; }
  }

  // -- VOIP / CALLS --

  /// Show incoming call UI (native or custom Flutter screen).
  ///
  /// Throws [PlatformException] with code `PHONE_ACCOUNT_NOT_ENABLED` on
  /// Android when the VoIP phone account hasn't been enabled by the user.
  /// Callers should catch this and call [openPhoneAccountSettings].
  static Future<void> showIncomingCall(NvpCallConfig call) async {
    await _platform.showIncomingCall(call.toMap());
  }

  /// Show outgoing call UI.
  static Future<void> showOutgoingCall(NvpCallConfig call) async {
    try { await _platform.showOutgoingCall(call.toMap()); }
    catch (e) { _log('showOutgoingCall', e); }
  }

  /// End a call by session ID.
  static Future<void> endCall(String callId) async {
    try { await _platform.endCall(callId); }
    catch (e) { _log('endCall', e); }
  }

  /// End all active calls.
  ///
  /// Useful for cleanup on logout, crash recovery, or ensuring no stale
  /// call notifications persist.
  static Future<void> endAllCalls() async {
    try { await _platform.endAllCalls(); }
    catch (e) { _log('endAllCalls', e); }
  }

  /// Mark a call as connected after async setup (e.g. WebRTC negotiation).
  ///
  /// By default the plugin transitions to "connected" immediately on accept.
  /// Use this when you need to do async work (media server connection, SDP
  /// exchange) before the system UI should show "connected."
  static Future<void> setCallConnected(String callId) async {
    try { await _platform.setCallConnected(callId); }
    catch (e) { _log('setCallConnected', e); }
  }

  /// Get the list of currently active call IDs.
  ///
  /// Useful for debugging, crash recovery, or ensuring you can end all
  /// calls even if you lost track of a call ID.
  static Future<List<String>> getActiveCallIds() async {
    try { return await _platform.getActiveCallIds(); }
    catch (e) { _log('getActiveCallIds', e); return []; }
  }

  /// Toggle mute during an active call.
  static Future<void> toggleMute(String callId) async {
    try { await _platform.toggleMute(callId); }
    catch (e) { _log('toggleMute', e); }
  }

  /// Toggle speaker during an active call.
  static Future<void> toggleSpeaker(String callId) async {
    try { await _platform.toggleSpeaker(callId); }
    catch (e) { _log('toggleSpeaker', e); }
  }

  /// Toggle camera during an active video call.
  static Future<void> toggleCamera(String callId) async {
    try { await _platform.toggleCamera(callId); }
    catch (e) { _log('toggleCamera', e); }
  }

  // -- STREAMS --

  /// Fires when user taps a notification.
  static Stream<NvpNotification> get onNotificationTap {
    _notificationTapStream ??= _platform.onNotificationTapStream
        .map((data) => NvpNotification.fromMap(data))
        .handleError((e) => _log('onNotificationTap', e));
    return _notificationTapStream!;
  }

  /// Fires on VoIP call events.
  static Stream<NvpCallEvent> get onCallEvent {
    _callEventStream ??= _platform.onCallEventStream
        .map((data) => NvpCallEvent.fromMap(data))
        .handleError((e) => _log('onCallEvent', e));
    return _callEventStream!;
  }

  /// Fires on call state changes.
  static Stream<NvpCallState> get onCallStateChanged {
    _callStateStream ??= _platform.onCallStateChangedStream
        .map((data) => NvpCallState.fromMap(data))
        .handleError((e) => _log('onCallStateChanged', e));
    return _callStateStream!;
  }

  /// Fires when push token changes.
  static Stream<String> get onTokenRefresh {
    _tokenRefreshStream ??= _platform.onTokenRefreshStream
        .handleError((e) => _log('onTokenRefresh', e));
    return _tokenRefreshStream!;
  }

  /// Fires when a push notification is received in the foreground (iOS).
  ///
  /// The raw payload map is delivered before the notification is displayed.
  /// Use this to inspect the payload and decide whether to suppress display
  /// (e.g. skip if the notification matches the active conversation).
  static Stream<Map<String, dynamic>> get onPushReceived {
    _pushReceivedStream ??= _platform.onPushReceivedStream
        .handleError((e) => _log('onPushReceived', e));
    return _pushReceivedStream!;
  }

  // -- ANDROID-ONLY --

  /// Check if the VoIP phone account is enabled (Android only).
  static Future<bool> isPhoneAccountEnabled() async {
    try { return await _platform.isPhoneAccountEnabled(); }
    catch (e) { _log('isPhoneAccountEnabled', e); return false; }
  }

  /// Open phone account settings (Android only).
  static Future<void> openPhoneAccountSettings() async {
    try { await _platform.openPhoneAccountSettings(); }
    catch (e) { _log('openPhoneAccountSettings', e); }
  }

  // -- LIFECYCLE --

  /// Clean up resources.
  static Future<void> dispose() async {
    _notificationTapStream = null;
    _callEventStream = null;
    _callStateStream = null;
    _tokenRefreshStream = null;
    _pushReceivedStream = null;
    _bannerTapSub?.cancel();
    _bannerTapSub = null;
    _callEventSub?.cancel();
    _callEventSub = null;
    _callStateSub?.cancel();
    _callStateSub = null;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _pushReceivedSub?.cancel();
    _pushReceivedSub = null;
    _config = null;
    try { await _platform.dispose(); }
    catch (e) { _log('dispose', e); }
  }

  static void _log(String method, Object error) {
    // Using dart:developer for structured logging
    developer.log('Error in $method: $error', name: 'NVP', error: error);
  }
}
