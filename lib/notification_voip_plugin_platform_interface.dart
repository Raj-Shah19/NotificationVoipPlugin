import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'notification_voip_plugin_method_channel.dart';

abstract class NotificationVoipPluginPlatform extends PlatformInterface {
  /// Constructs a NotificationVoipPluginPlatform.
  NotificationVoipPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static NotificationVoipPluginPlatform _instance =
      MethodChannelNotificationVoipPlugin();

  /// The default instance of [NotificationVoipPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelNotificationVoipPlugin].
  static NotificationVoipPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NotificationVoipPluginPlatform] when
  /// they register themselves.
  static set instance(NotificationVoipPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
