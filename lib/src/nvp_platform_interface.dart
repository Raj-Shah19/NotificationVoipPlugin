import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nvp_method_channel.dart';

/// Abstract platform interface for notification_voip_plugin v2.
///
/// Platform implementations should extend this class and override
/// the methods relevant to their platform. Use [instance] to access
/// the current platform implementation.
abstract class NvpPlatformInterface extends PlatformInterface {
  NvpPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static NvpPlatformInterface _instance = NvpMethodChannel();

  /// The current platform implementation.
  static NvpPlatformInterface get instance => _instance;

  /// Set the platform implementation (verified via [PlatformInterface] token).
  static set instance(NvpPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // ── INIT ──

  /// Initialize the plugin with optional [config] map.
  Future<void> init(Map<String, dynamic>? config) {
    throw UnimplementedError('init() has not been implemented.');
  }

  // ── TOKENS ──

  /// Get the platform push token (FCM on Android, APNs on iOS).
  Future<String?> getPushToken() {
    throw UnimplementedError('getPushToken() has not been implemented.');
  }

  /// Get the Firebase Cloud Messaging token.
  Future<String?> getFCMToken() {
    throw UnimplementedError('getFCMToken() has not been implemented.');
  }

  /// Get the Apple Push Notification service token (iOS only).
  Future<String?> getAPNsToken() {
    throw UnimplementedError('getAPNsToken() has not been implemented.');
  }

  /// Get the VoIP push token (iOS only).
  Future<String?> getVoIPToken() {
    throw UnimplementedError('getVoIPToken() has not been implemented.');
  }

  // ── PERMISSIONS ──

  /// Request notification permission. Returns `true` if granted.
  Future<bool> requestPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  /// Check whether notification permission is currently granted.
  Future<bool> isPermissionGranted() {
    throw UnimplementedError(
        'isPermissionGranted() has not been implemented.');
  }

  /// Open the OS notification settings for this app.
  Future<void> openSettings() {
    throw UnimplementedError('openSettings() has not been implemented.');
  }

  // ── NOTIFICATIONS ──

  /// Show an in-app banner notification overlay.
  Future<bool> showInAppNotification(
      Map<String, dynamic> notification, Map<String, dynamic>? template,
      [Map<String, dynamic>? style]) {
    throw UnimplementedError(
        'showInAppNotification() has not been implemented.');
  }

  /// Show a system notification in the notification tray.
  Future<bool> showNotification(
      Map<String, dynamic> notification, Map<String, dynamic>? template) {
    throw UnimplementedError('showNotification() has not been implemented.');
  }

  /// Cancel a specific notification by [tag].
  Future<void> cancelNotification(String tag) {
    throw UnimplementedError('cancelNotification() has not been implemented.');
  }

  /// Suppress the next foreground notification display (iOS only).
  ///
  /// Call this after receiving an [onPushReceivedStream] event to prevent
  /// the notification from being shown (e.g. when the user is already
  /// viewing the relevant conversation).
  Future<void> suppressNextForegroundNotification() {
    throw UnimplementedError(
        'suppressNextForegroundNotification() has not been implemented.');
  }

  /// Clear all notifications and dismiss any in-app banners.
  Future<void> clearAll() {
    throw UnimplementedError('clearAll() has not been implemented.');
  }

  // ── BADGE ──

  /// Set the app badge count. Pass `0` to clear.
  Future<void> setBadgeCount(int count) {
    throw UnimplementedError('setBadgeCount() has not been implemented.');
  }

  /// Get the current app badge count.
  Future<int> getBadgeCount() {
    throw UnimplementedError('getBadgeCount() has not been implemented.');
  }

  // ── VOIP / CALLS ──

  /// Show the native incoming call UI (ConnectionService / CallKit).
  Future<void> showIncomingCall(Map<String, dynamic> call) {
    throw UnimplementedError('showIncomingCall() has not been implemented.');
  }

  /// Show the native outgoing call UI.
  Future<void> showOutgoingCall(Map<String, dynamic> call) {
    throw UnimplementedError('showOutgoingCall() has not been implemented.');
  }

  /// Accept an incoming call by [callId].
  Future<void> acceptCall(String callId) {
    throw UnimplementedError('acceptCall() has not been implemented.');
  }

  /// Reject an incoming call by [callId].
  Future<void> rejectCall(String callId) {
    throw UnimplementedError('rejectCall() has not been implemented.');
  }

  /// End an active call by [callId].
  Future<void> endCall(String callId) {
    throw UnimplementedError('endCall() has not been implemented.');
  }

  /// End all active calls. Useful for cleanup on logout or crash recovery.
  Future<void> endAllCalls() {
    throw UnimplementedError('endAllCalls() has not been implemented.');
  }

  /// Mark a call as connected after async setup (e.g. WebRTC negotiation).
  ///
  /// By default the plugin transitions to "connected" immediately on accept.
  /// Use this when you need a deferred connection flow.
  Future<void> setCallConnected(String callId) {
    throw UnimplementedError('setCallConnected() has not been implemented.');
  }

  /// Get the list of currently active call IDs.
  Future<List<String>> getActiveCallIds() {
    throw UnimplementedError('getActiveCallIds() has not been implemented.');
  }

  /// Toggle mute during an active call.
  Future<void> toggleMute(String callId) {
    throw UnimplementedError('toggleMute() has not been implemented.');
  }

  /// Toggle speaker during an active call.
  Future<void> toggleSpeaker(String callId) {
    throw UnimplementedError('toggleSpeaker() has not been implemented.');
  }

  /// Toggle camera during an active video call.
  Future<void> toggleCamera(String callId) {
    throw UnimplementedError('toggleCamera() has not been implemented.');
  }

  // ── ANDROID-ONLY ──

  /// Check if the VoIP phone account is enabled (Android only).
  Future<bool> isPhoneAccountEnabled() {
    throw UnimplementedError(
        'isPhoneAccountEnabled() has not been implemented.');
  }

  /// Open phone account settings (Android only).
  Future<void> openPhoneAccountSettings() {
    throw UnimplementedError(
        'openPhoneAccountSettings() has not been implemented.');
  }

  // ── STREAMS ──

  /// Stream of notification tap events as raw maps.
  Stream<Map<String, dynamic>> get onNotificationTapStream {
    throw UnimplementedError(
        'onNotificationTapStream has not been implemented.');
  }

  /// Stream of VoIP call events as raw maps.
  Stream<Map<String, dynamic>> get onCallEventStream {
    throw UnimplementedError('onCallEventStream has not been implemented.');
  }

  /// Stream of call state changes as raw maps.
  Stream<Map<String, dynamic>> get onCallStateChangedStream {
    throw UnimplementedError(
        'onCallStateChangedStream has not been implemented.');
  }

  /// Stream of push token refresh events.
  Stream<String> get onTokenRefreshStream {
    throw UnimplementedError(
        'onTokenRefreshStream has not been implemented.');
  }

  /// Stream of raw push payloads received in foreground (iOS).
  ///
  /// Fires before the notification is displayed, allowing the app to
  /// inspect the payload and optionally suppress display.
  Stream<Map<String, dynamic>> get onPushReceivedStream {
    throw UnimplementedError(
        'onPushReceivedStream has not been implemented.');
  }

  // ── LIFECYCLE ──

  /// Clean up all plugin resources.
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

}
