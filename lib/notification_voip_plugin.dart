import 'dart:async';
import 'package:flutter/services.dart';

/// Plugin for handling notifications and VoIP features on Android and iOS.
class NotificationVoipPlugin {
  static const MethodChannel _channel = MethodChannel(
    'notification_voip_plugin',
  );
  static const EventChannel _eventChannel = EventChannel(
    'notification_voip_plugin/inapp_events',
  );
  static const EventChannel _voipEventsChannel = EventChannel(
    'notification_voip_plugin/voip_events',
  );

  static Stream<Map<String, dynamic>>? _tapStream;
  static Stream<Map<String, dynamic>>? _voipEventsStream;

  /// Get FCM token (Android & iOS)
  static Future<String?> getFCMToken() async {
    try {
      return await _channel.invokeMethod<String>('getFCMToken');
    } on PlatformException catch (e) {
      _logError('getFCMToken', e);
      return null;
    }
  }

  /// Get APNs token (iOS only)
  static Future<String?> getAPNsToken() async {
    try {
      return await _channel.invokeMethod<String>('getAPNsToken');
    } on PlatformException catch (e) {
      _logError('getAPNsToken', e);
      return null;
    }
  }

  /// Get VoIP token (iOS only)
  static Future<String?> getVoIPToken() async {
    try {
      return await _channel.invokeMethod<String>('getVoIPToken');
    } on PlatformException catch (e) {
      _logError('getVoIPToken', e);
      return null;
    }
  }

  /// Request notification permissions (Android & iOS)
  static Future<bool> requestNotificationPermissions() async {
    try {
      final bool? granted = await _channel.invokeMethod(
        'requestNotificationPermissions',
      );
      return granted ?? false;
    } on PlatformException catch (e) {
      _logError('requestNotificationPermissions', e);
      return false;
    }
  }

  /// Check if notifications are enabled (Android & iOS)
  static Future<bool> areNotificationsEnabled() async {
    try {
      final bool? enabled = await _channel.invokeMethod(
        'areNotificationsEnabled',
      );
      return enabled ?? false;
    } on PlatformException catch (e) {
      _logError('areNotificationsEnabled', e);
      return false;
    }
  }

  /// Open app notification settings (Android & iOS)
  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } on PlatformException catch (e) {
      _logError('openNotificationSettings', e);
    }
  }

  /// Show native in-app notification (visible for 5 seconds) (Android & iOS)
  static Future<bool> showInAppNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? sound,
  }) async {
    try {
      await _channel.invokeMethod('showInAppNotification', {
        'title': title,
        'body': body,
        'data': data ?? <String, dynamic>{},
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (sound != null) 'sound': sound,
      });
      return true;
    } on PlatformException catch (e) {
      _logError('showInAppNotification', e);
      return false;
    }
  }

  /// Show native system notification when app is in background/terminated (Android & iOS)
  /// [channelId] and [channelName] are used only on Android.
  static Future<void> showBackgroundNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? sound,
    String channelId = 'background_notifications',
    String channelName = 'Background Notifications',
  }) async {
    await _channel.invokeMethod('showBackgroundNotification', {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data ?? <String, dynamic>{},
      'sound': sound,
      'channelId': channelId,
      'channelName': channelName,
    });
  }

  /// Stream for notification tap events (Android & iOS)
  static Stream<Map<String, dynamic>> get onNotificationTap {
    _tapStream ??= _eventChannel
        .receiveBroadcastStream()
        .cast<Map<Object?, Object?>>()
        .map((event) => Map<String, dynamic>.from(event))
        .handleError((error) => _logStreamError('onNotificationTap', error));
    return _tapStream!;
  }

  /// Stream for call action events from notification banner (Android & iOS)
  static Stream<Map<String, dynamic>> get onCallActionEvents {
    return _eventChannel
        .receiveBroadcastStream()
        .cast<Map<Object?, Object?>>()
        .map((event) => Map<String, dynamic>.from(event));
  }

  /// Subscribe to notification tap events (Android & iOS)
  static StreamSubscription<Map<String, dynamic>> onNotificationTapListen(
    void Function(Map<String, dynamic> data) onTap, {
    Function? onError,
  }) {
    return onNotificationTap.listen(
      onTap,
      onError:
          onError ??
          (error) => _logStreamError('onNotificationTapListen', error),
    );
  }

  /// Check if phone account is enabled (Android only)
  static Future<bool> isPhoneAccountEnabled() async {
    final enabled = await _channel.invokeMethod('isPhoneAccountEnabled');
    return enabled == true;
  }

  /// Open phone account settings (Android only)
  static Future<void> openPhoneAccountSettings() async {
    await _channel.invokeMethod('openPhoneAccountSettings');
  }

  /// Register phone account for VoIP calls (Android only)
  static Future<void> registerPhoneAccount() async {
    await _channel.invokeMethod('registerPhoneAccount');
  }

  /// Launch app from background (Android & iOS)
  static Future<void> launchAppFromBackground() async {
    await _channel.invokeMethod('launchAppFromBackground');
  }

  /// Add incoming call to system (VoIP) (Android & iOS)
  static Future<void> addIncomingCall({
    required String callerId,
    required String callerName,
  }) async {
    await _channel.invokeMethod('addIncomingCall', {
      'callerId': callerId,
      'callerName': callerName,
    });
  }

  /// End current call (Android & iOS)
  static Future<void> endCall() async {
    await _channel.invokeMethod('endCall');
  }

  /// Request permission to answer phone calls (Android only)
  static Future<bool> requestAnswerPhoneCallsPermission() async {
    final result = await _channel.invokeMethod<bool>(
      'requestAnswerPhoneCallsPermission',
    );
    return result == true;
  }

  /// Set keys used for VoIP call data mapping (Android & iOS)
  static Future<void> setVoipCallKeys({
    required String nameKey,
    required String idKey,
    required String typeKey,
  }) async {
    await _channel.invokeMethod('setVoipCallKeys', {
      "nameKey": nameKey,
      "idKey": idKey,
      "typeKey": typeKey,
    });
  }

  /// Get the platform version string (e.g., Android 14, iOS 17.2) (Android & iOS)
  static Future<String?> getPlatformVersion() async {
    try {
      return await _channel.invokeMethod<String>('getPlatformVersion');
    } on PlatformException catch (e) {
      _logError('getPlatformVersion', e);
      return null;
    }
  }

  /// Handle VoIP call actions from plugin (Android & iOS)
  static Future<void> handleVoipFromPlugin(
    bool enabled,
    String nameKey,
    String idKey,
    String typeKey,
    String callAction,
  ) async {
    await _channel.invokeMethod('handleVoipFromPlugin', {
      "enabled": enabled,
      "nameKey": nameKey,
      "idKey": idKey,
      "typeKey": typeKey,
      "callAction": callAction,
    });
  }

  /// Stream of VoIP events (Android & iOS)
  static Stream<Map<String, dynamic>> get voipEventsStream {
    _voipEventsStream ??= _voipEventsChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event),
    );
    return _voipEventsStream!;
  }

  /// Dispose resources (Android & iOS)
  static void dispose() {
    _tapStream = null;
  }

  static void _logError(String method, PlatformException e) {
    // ignore: avoid_print
    print('Error in $method: ${e.message}');
  }

  static void _logStreamError(String stream, Object error) {
    // ignore: avoid_print
    print('Stream error in $stream: $error');
  }
}

/// Notification permission status (Android & iOS)
enum NotificationPermissionStatus {
  granted,
  denied,
  notDetermined, // iOS only
  restricted, // iOS only
}

/// Detailed permission result (Android & iOS)
class NotificationPermissionResult {
  final NotificationPermissionStatus status;
  final bool canShowAlert;
  final bool canPlaySound;
  final bool canSetBadge;

  const NotificationPermissionResult({
    required this.status,
    this.canShowAlert = false,
    this.canPlaySound = false,
    this.canSetBadge = false,
  });

  factory NotificationPermissionResult.fromMap(Map<String, dynamic> map) {
    return NotificationPermissionResult(
      status: NotificationPermissionStatus.values[map['status'] ?? 0],
      canShowAlert: map['canShowAlert'] ?? false,
      canPlaySound: map['canPlaySound'] ?? false,
      canSetBadge: map['canSetBadge'] ?? false,
    );
  }

  @override
  String toString() {
    return 'NotificationPermissionResult(status: $status, canShowAlert: $canShowAlert, canPlaySound: $canPlaySound, canSetBadge: $canSetBadge)';
  }
}
