import 'package:flutter/services.dart';

import 'nvp_platform_interface.dart';

/// MethodChannel + EventChannel implementation of [NvpPlatformInterface].
class NvpMethodChannel extends NvpPlatformInterface {
  static const MethodChannel _channel =
      MethodChannel('notification_voip_plugin');
  static const EventChannel _inappEventChannel =
      EventChannel('notification_voip_plugin/inapp_events');
  static const EventChannel _voipEventChannel =
      EventChannel('notification_voip_plugin/voip_events');
  static const EventChannel _callStateChannel =
      EventChannel('notification_voip_plugin/call_state');
  static const EventChannel _tokenRefreshChannel =
      EventChannel('notification_voip_plugin/token_refresh');
  static const EventChannel _pushReceivedChannel =
      EventChannel('notification_voip_plugin/push_received');

  Stream<Map<String, dynamic>>? _notificationTapStream;
  Stream<Map<String, dynamic>>? _callEventStream;
  Stream<Map<String, dynamic>>? _callStateStream;
  Stream<String>? _tokenRefreshStream;
  Stream<Map<String, dynamic>>? _pushReceivedStream;

  @override
  Future<void> init(Map<String, dynamic>? config) async {
    await _channel.invokeMethod('init', config);
  }

  @override
  Future<String?> getPushToken() async {
    return await _channel.invokeMethod<String>('getPushToken');
  }

  @override
  Future<String?> getFCMToken() async {
    return await _channel.invokeMethod<String>('getFCMToken');
  }

  @override
  Future<String?> getAPNsToken() async {
    return await _channel.invokeMethod<String>('getAPNsToken');
  }

  @override
  Future<String?> getVoIPToken() async {
    return await _channel.invokeMethod<String>('getVoIPToken');
  }

  @override
  Future<bool> requestPermission() async {
    final result = await _channel.invokeMethod<bool>('requestPermission');
    return result ?? false;
  }

  @override
  Future<bool> isPermissionGranted() async {
    final result = await _channel.invokeMethod<bool>('isPermissionGranted');
    return result ?? false;
  }

  @override
  Future<void> openSettings() async {
    await _channel.invokeMethod('openSettings');
  }

  @override
  Future<bool> showInAppNotification(
      Map<String, dynamic> notification, Map<String, dynamic>? template) async {
    final result = await _channel.invokeMethod<bool>('showInAppNotification', {
      'notification': notification,
      'template': template,
    });
    return result ?? false;
  }

  @override
  Future<bool> showNotification(
      Map<String, dynamic> notification, Map<String, dynamic>? template) async {
    final result = await _channel.invokeMethod<bool>('showNotification', {
      'notification': notification,
      'template': template,
    });
    return result ?? false;
  }

  @override
  Future<void> clearAll() async {
    await _channel.invokeMethod('clearAll');
  }

  @override
  Future<void> cancelNotification(String tag) async {
    await _channel.invokeMethod('cancelNotification', {'tag': tag});
  }

  @override
  Future<void> suppressNextForegroundNotification() async {
    await _channel.invokeMethod('suppressNextForegroundNotification');
  }

  @override
  Future<void> setBadgeCount(int count) async {
    await _channel.invokeMethod('setBadgeCount', {'count': count});
  }

  @override
  Future<int> getBadgeCount() async {
    final result = await _channel.invokeMethod<int>('getBadgeCount');
    return result ?? 0;
  }

  @override
  Future<void> showIncomingCall(Map<String, dynamic> call) async {
    await _channel.invokeMethod('showIncomingCall', call);
  }

  @override
  Future<void> showOutgoingCall(Map<String, dynamic> call) async {
    await _channel.invokeMethod('showOutgoingCall', call);
  }

  @override
  Future<void> acceptCall(String callId) async {
    await _channel.invokeMethod('acceptCall', {'callId': callId});
  }

  @override
  Future<void> rejectCall(String callId) async {
    await _channel.invokeMethod('rejectCall', {'callId': callId});
  }

  @override
  Future<void> endCall(String callId) async {
    await _channel.invokeMethod('endCall', {'callId': callId});
  }

  @override
  Future<void> endAllCalls() async {
    await _channel.invokeMethod('endAllCalls');
  }

  @override
  Future<void> setCallConnected(String callId) async {
    await _channel.invokeMethod('setCallConnected', {'callId': callId});
  }

  @override
  Future<List<String>> getActiveCallIds() async {
    final result = await _channel.invokeMethod<List>('getActiveCallIds');
    return result?.cast<String>() ?? [];
  }

  @override
  Future<void> toggleMute(String callId) async {
    await _channel.invokeMethod('toggleMute', {'callId': callId});
  }

  @override
  Future<void> toggleSpeaker(String callId) async {
    await _channel.invokeMethod('toggleSpeaker', {'callId': callId});
  }

  @override
  Future<void> toggleCamera(String callId) async {
    await _channel.invokeMethod('toggleCamera', {'callId': callId});
  }

  @override
  Future<bool> isPhoneAccountEnabled() async {
    final result = await _channel.invokeMethod<bool>('isPhoneAccountEnabled');
    return result ?? false;
  }

  @override
  Future<void> openPhoneAccountSettings() async {
    await _channel.invokeMethod('openPhoneAccountSettings');
  }

  @override
  Stream<Map<String, dynamic>> get onNotificationTapStream {
    _notificationTapStream ??= _inappEventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
    return _notificationTapStream!;
  }

  @override
  Stream<Map<String, dynamic>> get onCallEventStream {
    _callEventStream ??= _voipEventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
    return _callEventStream!;
  }

  @override
  Stream<Map<String, dynamic>> get onCallStateChangedStream {
    _callStateStream ??= _callStateChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
    return _callStateStream!;
  }

  @override
  Stream<String> get onTokenRefreshStream {
    _tokenRefreshStream ??= _tokenRefreshChannel
        .receiveBroadcastStream()
        .map((event) => event as String);
    return _tokenRefreshStream!;
  }

  @override
  Stream<Map<String, dynamic>> get onPushReceivedStream {
    _pushReceivedStream ??= _pushReceivedChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
    return _pushReceivedStream!;
  }

  @override
  Future<void> dispose() async {
    _notificationTapStream = null;
    _callEventStream = null;
    _callStateStream = null;
    _tokenRefreshStream = null;
    _pushReceivedStream = null;
    await _channel.invokeMethod('dispose');
  }

}
