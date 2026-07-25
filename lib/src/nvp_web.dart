import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'nvp_platform_interface.dart';

/// Web implementation using browser Notification API.
class NvpWeb extends NvpPlatformInterface {
  NvpWeb();

  static void registerWith(Registrar registrar) {
    NvpPlatformInterface.instance = NvpWeb();
  }

  StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<void> init(Map<String, dynamic>? config) async {}

  @override
  Future<String?> getPushToken() async => null;

  @override
  Future<String?> getFCMToken() async => null;

  @override
  Future<String?> getAPNsToken() async => null;

  @override
  Future<String?> getVoIPToken() async => null;

  @override
  Future<bool> requestPermission() async {
    final permission = await web.Notification.requestPermission().toDart;
    return permission.toDart == 'granted';
  }

  @override
  Future<bool> isPermissionGranted() async {
    return web.Notification.permission == 'granted';
  }

  @override
  Future<void> openSettings() async {
    // No-op on web
  }

  @override
  Future<bool> showNotification(
      Map<String, dynamic> notification, Map<String, dynamic>? template) async {
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final icon = notification['senderAvatar'] as String? ??
        notification['imageUrl'] as String?;
    final tag = notification['groupKey'] as String? ??
        notification['tag'] as String?;
    final imageUrl = template?['imageUrl'] as String?;

    final options = web.NotificationOptions(
      body: body,
      tag: tag ?? '',
    );

    if (icon != null) {
      options.icon = icon;
    }
    if (imageUrl != null) {
      options.image = imageUrl;
    }

    final n = web.Notification(title, options);
    n.onclick = ((web.Event event) {
      _notificationTapController.add(notification);
    }).toJS;

    return true;
  }

  @override
  Future<bool> showInAppNotification(
      Map<String, dynamic> notification, Map<String, dynamic>? template,
      [Map<String, dynamic>? style]) async {
    // In-app notifications on web fall back to system notification;
    // style is not applicable there.
    return showNotification(notification, template);
  }

  @override
  Future<void> clearAll() async {
    // No API to clear web notifications
  }

  @override
  Future<void> setBadgeCount(int count) async {
    // No standard badge API on web
  }

  @override
  Future<int> getBadgeCount() async => 0;

  // VoIP — all no-ops on web
  @override
  Future<void> showIncomingCall(Map<String, dynamic> call) async {}

  @override
  Future<void> showOutgoingCall(Map<String, dynamic> call) async {}

  @override
  Future<void> acceptCall(String callId) async {}

  @override
  Future<void> rejectCall(String callId) async {}

  @override
  Future<void> endCall(String callId) async {}

  @override
  Future<void> endAllCalls() async {}

  @override
  Future<void> setCallConnected(String callId) async {}

  @override
  Future<List<String>> getActiveCallIds() async => [];

  @override
  Future<void> cancelNotification(String tag) async {}

  @override
  Future<void> suppressNextForegroundNotification() async {}

  @override
  Future<void> toggleMute(String callId) async {}

  @override
  Future<void> toggleSpeaker(String callId) async {}

  @override
  Future<void> toggleCamera(String callId) async {}

  @override
  Future<bool> isPhoneAccountEnabled() async => false;

  @override
  Future<void> openPhoneAccountSettings() async {}

  @override
  Stream<Map<String, dynamic>> get onNotificationTapStream =>
      _notificationTapController.stream;

  @override
  Stream<Map<String, dynamic>> get onCallEventStream => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onCallStateChangedStream =>
      const Stream.empty();

  @override
  Stream<String> get onTokenRefreshStream => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onPushReceivedStream => const Stream.empty();

  @override
  Future<void> dispose() async {
    await _notificationTapController.close();
    // Re-create so the plugin can be re-initialized after dispose
    _notificationTapController =
        StreamController<Map<String, dynamic>>.broadcast();
  }
}
