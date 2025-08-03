import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_voip_plugin_platform_interface.dart';

/// An implementation of [NotificationVoipPluginPlatform] that uses method channels.
class MethodChannelNotificationVoipPlugin extends NotificationVoipPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('notification_voip_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
