import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Cache the stream to avoid creating multiple instances
  static Stream<Map<String, dynamic>>? _tapStream;

  static Stream<Map<String, dynamic>>? _voipEventsStream;

  /// Get FCM token (Android & iOS)
  static Future<String?> getFCMToken() async {
    try {
      final String? token = await _channel.invokeMethod('getFCMToken');
      return token;
    } on PlatformException catch (e) {
      debugPrint('Error getting FCM token: ${e.message}');
      return null;
    }
  }

  /// Get APNs token (iOS only)
  static Future<String?> getAPNsToken() async {
    try {
      final String? token = await _channel.invokeMethod('getAPNsToken');
      return token;
    } on PlatformException catch (e) {
      debugPrint('Error getting APNs token: ${e.message}');
      return null;
    }
  }

  /// Get VoIP token (iOS only)
  static Future<String?> getVoIPToken() async {
    try {
      final String? token = await _channel.invokeMethod('getVoIPToken');
      return token;
    } on PlatformException catch (e) {
      debugPrint('Error getting VoIP token: ${e.message}');
      return null;
    }
  }

  /// Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    try {
      final bool? granted = await _channel.invokeMethod(
        'requestNotificationPermissions',
      );
      return granted ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error requesting notification permissions: ${e.message}');
      return false;
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      final bool? enabled = await _channel.invokeMethod(
        'areNotificationsEnabled',
      );
      return enabled ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking notification status: ${e.message}');
      return false;
    }
  }

  /// Open app notification settings
  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } on PlatformException catch (e) {
      debugPrint('Error opening notification settings: ${e.message}');
    }
  }

  /// Show native in-app notification (visible for 5 seconds)
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
      debugPrint('Error showing in-app notification: ${e.message}');
      return false;
    }
  }

  /// Show native system notification when app is in background/terminated
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

  /// Listen for taps on the notification banner
  static Stream<Map<String, dynamic>> get onNotificationTap {
    _tapStream ??= _eventChannel
        .receiveBroadcastStream()
        .cast<Map<Object?, Object?>>()
        .map((event) => Map<String, dynamic>.from(event))
        .handleError((error) {
          debugPrint('Error in notification tap stream: $error');
        });
    return _tapStream!;
  }

  static Stream<Map<String, dynamic>> get onCallActionEvents {
    return _eventChannel
        .receiveBroadcastStream()
        .cast<Map<Object?, Object?>>()
        .map((event) => Map<String, dynamic>.from(event));
  }

  /// Subscribe to notification tap events with a callback
  static StreamSubscription<Map<String, dynamic>> onNotificationTapListen(
    void Function(Map<String, dynamic> data) onTap, {
    Function? onError,
  }) {
    return onNotificationTap.listen(
      onTap,
      onError:
          onError ?? (error) => debugPrint('Notification tap error: $error'),
    );
  }

  static Future<bool> isPhoneAccountEnabled() async {
    final enabled = await _channel.invokeMethod('isPhoneAccountEnabled');
    return enabled == true;
  }

  static Future<void> openPhoneAccountSettings() async {
    await _channel.invokeMethod('openPhoneAccountSettings');
  }

  static Future<void> registerPhoneAccount() async =>
      await _channel.invokeMethod('registerPhoneAccount');

  static Future<void> launchAppFromBackground() async {
    await _channel.invokeMethod('launchAppFromBackground');
  }

  static Future<void> addIncomingCall({
    required String callerId,
    required String callerName,
  }) async {
    await _channel.invokeMethod('addIncomingCall', {
      'callerId': callerId,
      'callerName': callerName,
    });
  }

  static Future<void> endCall() async {
    await _channel.invokeMethod('endCall');
  }

  static Future<bool> requestAnswerPhoneCallsPermission() async {
    final result = await _channel.invokeMethod<bool>(
      'requestAnswerPhoneCallsPermission',
    );
    return result == true;
  }

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

  /// Get the platform version string (e.g., Android 14, iOS 17.2)
  static Future<String?> getPlatformVersion() async {
    try {
      final String? version = await _channel.invokeMethod('getPlatformVersion');
      return version;
    } on PlatformException catch (e) {
      debugPrint('Error getting platform version: ${e.message}');
      return null;
    }
  }

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

  static Stream<Map<String, dynamic>> get voipEventsStream {
    _voipEventsStream ??= _voipEventsChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event),
    );
    return _voipEventsStream!;
  }

  /// Dispose resources (call this when you no longer need the plugin)
  static void dispose() {
    _tapStream = null;
  }
}

/// Notification permission status
enum NotificationPermissionStatus {
  granted,
  denied,
  notDetermined, // iOS only
  restricted, // iOS only
}

/// Detailed permission result (for future use)
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

//------------------------------------------------------------------------------

// import 'package:flutter/services.dart';
// import 'dart:async';
//
// class NotificationVoipPlugin {
//   static const EventChannel _eventChannel = EventChannel(
//     'notification_voip_plugin/inapp_events',
//   );
//   static const MethodChannel _channel = MethodChannel(
//     'notification_voip_plugin',
//   );
//
//   static Stream<Map<String, dynamic>>? _tapStream;
//
//   // Get FCM token (Android)
//   static Future<String?> getFCMToken() async {
//     final String? token = await _channel.invokeMethod('getFCMToken');
//     return token;
//   }
//
//   // Get APNs token (iOS)
//   static Future<String?> getAPNsToken() async {
//     final String? token = await _channel.invokeMethod('getAPNsToken');
//     return token;
//   }
//
//   // Get VoIP token (iOS)
//   static Future<String?> getVoIPToken() async {
//     final String? token = await _channel.invokeMethod('getVoIPToken');
//     return token;
//   }
//
//   /// Request notification permissions
//   static Future<bool> requestNotificationPermissions() async {
//     final bool? granted = await _channel.invokeMethod(
//       'requestNotificationPermissions',
//     );
//     return granted ?? false;
//   }
//
//   /// Check if notifications are enabled
//   static Future<bool> areNotificationsEnabled() async {
//     final bool? enabled = await _channel.invokeMethod(
//       'areNotificationsEnabled',
//     );
//     return enabled ?? false;
//   }
//
//   /// Open app notification settings
//   static Future<void> openNotificationSettings() async {
//     await _channel.invokeMethod('openNotificationSettings');
//   }
//
//   /// Show native in-app notification (visible for 5 seconds)
//   static Future<void> showInAppNotification({
//     required String title,
//     required String body,
//     Map<String, dynamic>? data,
//   }) async {
//     await _channel.invokeMethod('showInAppNotification', {
//       'title': title,
//       'body': body,
//       'data': data ?? {},
//     });
//   }
//
//   /// Listen for taps on the banner
//   static Stream<Map<String, dynamic>> get onNotificationTap {
//     _tapStream ??= _eventChannel
//         .receiveBroadcastStream()
//         .map((event) => Map<String, dynamic>.from(event));
//     return _tapStream!;
//   }
// }
//
// /// Notification permission status
// enum NotificationPermissionStatus {
//   granted,
//   denied,
//   notDetermined, // iOS only
//   restricted, // iOS only
// }
//
// /// Detailed permission result
// class NotificationPermissionResult {
//   final NotificationPermissionStatus status;
//   final bool canShowAlert;
//   final bool canPlaySound;
//   final bool canSetBadge;
//
//   NotificationPermissionResult({
//     required this.status,
//     this.canShowAlert = false,
//     this.canPlaySound = false,
//     this.canSetBadge = false,
//   });
//
//   factory NotificationPermissionResult.fromMap(Map<String, dynamic> map) {
//     return NotificationPermissionResult(
//       status: NotificationPermissionStatus.values[map['status'] ?? 0],
//       canShowAlert: map['canShowAlert'] ?? false,
//       canPlaySound: map['canPlaySound'] ?? false,
//       canSetBadge: map['canSetBadge'] ?? false,
//     );
//   }
// }
