import 'package:flutter_test/flutter_test.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';
import 'package:notification_voip_plugin/notification_voip_plugin_platform_interface.dart';
import 'package:notification_voip_plugin/notification_voip_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNotificationVoipPluginPlatform
    with MockPlatformInterfaceMixin
    implements NotificationVoipPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NotificationVoipPluginPlatform initialPlatform = NotificationVoipPluginPlatform.instance;

  test('$MethodChannelNotificationVoipPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNotificationVoipPlugin>());
  });

  test('getPlatformVersion', () async {
    MockNotificationVoipPluginPlatform fakePlatform = MockNotificationVoipPluginPlatform();
    NotificationVoipPluginPlatform.instance = fakePlatform;

    expect(await NotificationVoipPlugin.getPlatformVersion(), '42');
  });
}
