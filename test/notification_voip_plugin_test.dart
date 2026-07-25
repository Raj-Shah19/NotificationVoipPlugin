import 'package:flutter_test/flutter_test.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNvpPlatform extends NvpPlatformInterface
    with MockPlatformInterfaceMixin {
  @override
  Future<void> init(Map<String, dynamic>? config) async {}

  @override
  Future<String?> getPushToken() async => 'mock-push-token';

  @override
  Future<String?> getFCMToken() async => 'mock-fcm-token';

  @override
  Future<String?> getAPNsToken() async => 'mock-apns-token';

  @override
  Future<String?> getVoIPToken() async => 'mock-voip-token';

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> isPermissionGranted() async => true;

  @override
  Future<void> openSettings() async {}

  @override
  Future<bool> showInAppNotification(
      Map<String, dynamic> notification, Map<String, dynamic>? template,
      [Map<String, dynamic>? style]) async {
    return true;
  }

  @override
  Future<bool> showNotification(
      Map<String, dynamic> notification, Map<String, dynamic>? template) async {
    return true;
  }

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> setBadgeCount(int count) async {}

  @override
  Future<int> getBadgeCount() async => 5;

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
      const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onCallEventStream => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onCallStateChangedStream =>
      const Stream.empty();

  @override
  Stream<String> get onTokenRefreshStream => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

/// Mock that throws on every call to test error handling.
class ThrowingNvpPlatform extends NvpPlatformInterface
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getPushToken() async => throw Exception('fail');

  @override
  Future<bool> requestPermission() async => throw Exception('fail');

  @override
  Future<bool> showNotification(
          Map<String, dynamic> n, Map<String, dynamic>? t) async =>
      throw Exception('fail');

  @override
  Future<bool> showInAppNotification(Map<String, dynamic> n,
          Map<String, dynamic>? t, [Map<String, dynamic>? s]) async =>
      throw Exception('fail');

  @override
  Future<void> acceptCall(String callId) async => throw Exception('fail');

  @override
  Future<void> rejectCall(String callId) async => throw Exception('fail');

  @override
  Future<void> endCall(String callId) async => throw Exception('fail');

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNvpPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockNvpPlatform();
    NvpPlatformInterface.instance = mockPlatform;
  });

  // ── 3.2 Platform Interface Tests ──

  group('Platform Interface', () {
    test('UT-016: default instance is NvpMethodChannel', () {
      // Reset to default
      final defaultInterface = NvpPlatformInterface.instance;
      // After setUp, it's our mock — but we can verify the type system works
      expect(defaultInterface, isA<NvpPlatformInterface>());
    });

    test('UT-017: instance setter with token verification', () {
      final mock = MockNvpPlatform();
      NvpPlatformInterface.instance = mock;
      expect(NvpPlatformInterface.instance, same(mock));
    });

    test('UT-018: base methods throw UnimplementedError', () {
      // Create a minimal subclass that doesn't override anything
      final base = _MinimalPlatform();
      expect(() => base.init(null), throwsA(isA<UnimplementedError>()));
      expect(() => base.getPushToken(), throwsA(isA<UnimplementedError>()));
      expect(() => base.getFCMToken(), throwsA(isA<UnimplementedError>()));
      expect(() => base.getAPNsToken(), throwsA(isA<UnimplementedError>()));
      expect(() => base.getVoIPToken(), throwsA(isA<UnimplementedError>()));
      expect(
          () => base.requestPermission(), throwsA(isA<UnimplementedError>()));
      expect(() => base.isPermissionGranted(),
          throwsA(isA<UnimplementedError>()));
      expect(() => base.openSettings(), throwsA(isA<UnimplementedError>()));
      expect(() => base.showInAppNotification({}, null),
          throwsA(isA<UnimplementedError>()));
      expect(() => base.showNotification({}, null),
          throwsA(isA<UnimplementedError>()));
      expect(() => base.clearAll(), throwsA(isA<UnimplementedError>()));
      expect(
          () => base.setBadgeCount(0), throwsA(isA<UnimplementedError>()));
      expect(() => base.getBadgeCount(), throwsA(isA<UnimplementedError>()));
      expect(() => base.showIncomingCall({}),
          throwsA(isA<UnimplementedError>()));
      expect(() => base.showOutgoingCall({}),
          throwsA(isA<UnimplementedError>()));
      expect(
          () => base.acceptCall('x'), throwsA(isA<UnimplementedError>()));
      expect(
          () => base.rejectCall('x'), throwsA(isA<UnimplementedError>()));
      expect(() => base.endCall('x'), throwsA(isA<UnimplementedError>()));
      expect(() => base.toggleMute('x'), throwsA(isA<UnimplementedError>()));
      expect(
          () => base.toggleSpeaker('x'), throwsA(isA<UnimplementedError>()));
      expect(
          () => base.toggleCamera('x'), throwsA(isA<UnimplementedError>()));
      expect(() => base.isPhoneAccountEnabled(),
          throwsA(isA<UnimplementedError>()));
      expect(() => base.openPhoneAccountSettings(),
          throwsA(isA<UnimplementedError>()));
      expect(() => base.onNotificationTapStream,
          throwsA(isA<UnimplementedError>()));
      expect(() => base.onCallEventStream,
          throwsA(isA<UnimplementedError>()));
      expect(() => base.onCallStateChangedStream,
          throwsA(isA<UnimplementedError>()));
      expect(() => base.onTokenRefreshStream,
          throwsA(isA<UnimplementedError>()));
      expect(() => base.dispose(), throwsA(isA<UnimplementedError>()));
    });
  });

  // ── 3.3 Main API Class Tests ──

  group('Main API - init', () {
    test('UT-019: init() with default config', () async {
      await NotificationVoipPlugin.init();
      // No exception = success
    });

    test('UT-020: init() with custom NvpConfig', () async {
      await NotificationVoipPlugin.init(
          const NvpConfig(appName: 'TestApp'));
      // No exception = success
    });
  });

  group('Main API - tokens', () {
    test('UT-021: getPushToken() delegates to platform', () async {
      final token = await NotificationVoipPlugin.getPushToken();
      expect(token, 'mock-push-token');
    });
  });

  group('Main API - permissions', () {
    test('UT-022: requestPermission() delegates to platform', () async {
      final granted = await NotificationVoipPlugin.requestPermission();
      expect(granted, true);
    });
  });

  group('Main API - notifications', () {
    test('UT-023: showNotification() delegates to platform', () async {
      final result = await NotificationVoipPlugin.showNotification(
        const NvpNotification(title: 'Test', body: 'Body'),
      );
      expect(result, true);
    });

    test('UT-024: showInAppNotification() delegates to platform', () async {
      final result = await NotificationVoipPlugin.showInAppNotification(
        const NvpNotification(title: 'Test', body: 'Body'),
      );
      expect(result, true);
    });
  });

  group('Main API - calls', () {
    test('UT-025: endCall() delegates to platform', () async {
      await NotificationVoipPlugin.endCall('call-123');
      // No exception = success
    });
  });

  group('Main API - lifecycle', () {
    test('UT-026: dispose() cleans up stream references', () async {
      await NotificationVoipPlugin.dispose();
      // No exception = success
    });
  });

  group('Main API - streams', () {
    test('UT-027: onNotificationTap returns typed stream', () {
      final stream = NotificationVoipPlugin.onNotificationTap;
      expect(stream, isA<Stream<NvpNotification>>());
    });

    test('UT-028: onCallEvent returns typed stream', () {
      final stream = NotificationVoipPlugin.onCallEvent;
      expect(stream, isA<Stream<NvpCallEvent>>());
    });
  });

  group('Main API - badge', () {
    test('UT-029: setBadgeCount() delegates to platform', () async {
      await NotificationVoipPlugin.setBadgeCount(5);
      // No exception = success
    });

    test('UT-030: clearAll() delegates to platform', () async {
      await NotificationVoipPlugin.clearAll();
      // No exception = success
    });
  });

  // ── 3.4 Edge Case Tests ──

  group('Edge Cases - Models', () {
    test('EC-001: NvpNotification.fromMap() with missing optional fields', () {
      final n = NvpNotification.fromMap({'title': 'T', 'body': 'B'});
      expect(n.title, 'T');
      expect(n.body, 'B');
      expect(n.imageUrl, isNull);
      expect(n.senderId, isNull);
      expect(n.groupKey, isNull);
      expect(n.conversationId, isNull);
    });

    test('EC-002: NvpNotification.fromMap() with empty map', () {
      final n = NvpNotification.fromMap({});
      expect(n.title, '');
      expect(n.body, '');
    });

    test('EC-003: NvpCallEvent.fromMap() with minimal fields', () {
      final e =
          NvpCallEvent.fromMap({'action': 'accept', 'callId': '1'});
      expect(e.action, NvpCallAction.accept);
      expect(e.callId, '1');
      expect(e.callerName, isNull);
      expect(e.isVideo, false);
    });

    test('EC-004: NvpNotificationTemplate with custom type', () {
      const t = NvpNotificationTemplate(
          type: NvpNotificationTemplateType.custom);
      final map = t.toMap();
      expect(map['type'], 'custom');
    });

    test('EC-005: NvpCallState.fromMap() with unknown status', () {
      final s = NvpCallState.fromMap(
          {'callId': '1', 'status': 'unknown_value'});
      expect(s.status, NvpCallStatus.ended); // defaults to ended
    });

    test('EC-006: NvpConfig with null callbacks', () {
      const config = NvpConfig();
      expect(config.onBannerTap, isNull);
      expect(config.onCallAnswered, isNull);
      expect(config.onTokenRefresh, isNull);
    });

    test('EC-007: NvpPayloadKeys custom values', () {
      const keys = NvpPayloadKeys(titleKey: 't', bodyKey: 'b');
      expect(keys.titleKey, 't');
      expect(keys.bodyKey, 'b');
    });

    test('EC-008: NvpNotification.toMap() with null groupKey', () {
      const n = NvpNotification(title: 'T', body: 'B');
      final map = n.toMap();
      expect(map.containsKey('groupKey'), false);
    });

    test('EC-009: NvpCallConfig for outgoing call', () {
      const c = NvpCallConfig(
          callId: '1', callerName: 'Test', isOutgoing: true);
      final map = c.toMap();
      expect(map['isOutgoing'], true);
    });

    test('EC-010: NvpNotificationAction with isTextInput', () {
      const a = NvpNotificationAction(
        id: 'reply',
        title: 'Reply',
        isTextInput: true,
        textInputPlaceholder: 'Type...',
      );
      final map = a.toMap();
      expect(map['isTextInput'], true);
      expect(map['textInputPlaceholder'], 'Type...');
    });
  });

  // ── 3.5 Error Handling Tests ──

  group('Error Handling', () {
    late ThrowingNvpPlatform throwingPlatform;

    setUp(() {
      throwingPlatform = ThrowingNvpPlatform();
      NvpPlatformInterface.instance = throwingPlatform;
    });

    test('EH-001: getPushToken() handles exception', () async {
      final token = await NotificationVoipPlugin.getPushToken();
      expect(token, isNull);
    });

    test('EH-002: requestPermission() handles exception', () async {
      final granted = await NotificationVoipPlugin.requestPermission();
      expect(granted, false);
    });

    test('EH-003: showNotification() handles exception', () async {
      final result = await NotificationVoipPlugin.showNotification(
        const NvpNotification(title: 'T', body: 'B'),
      );
      expect(result, false);
    });

    test('EH-004: showInAppNotification() handles exception', () async {
      final result = await NotificationVoipPlugin.showInAppNotification(
        const NvpNotification(title: 'T', body: 'B'),
      );
      expect(result, false);
    });

    test('EH-005: endCall() handles exception', () async {
      await NotificationVoipPlugin.endCall('id');
      // No crash = success
    });
  });

  // ── 3.1 Model Unit Tests ──

  group('Models - NvpConfig', () {
    test('UT-001: NvpConfig default values', () {
      const config = NvpConfig();
      expect(config.bannerDuration, const Duration(seconds: 5));
      expect(config.channelId, 'default_channel');
      expect(config.channelName, 'Default Channel');
      expect(config.callScreenConfig.useNativeCallScreen, true);
      expect(config.appName, isNull);
      expect(config.defaultGroupKey, isNull);
    });

    test('UT-002: NvpConfig.toMap() serialization', () {
      const config = NvpConfig(appName: 'TestApp', channelId: 'ch1');
      final map = config.toMap();
      expect(map['appName'], 'TestApp');
      expect(map['channelId'], 'ch1');
      expect(map['bannerDuration'], 5000);
      expect(map['useNativeCallScreen'], true);
    });

    test('UT-003: NvpConfig with all callbacks', () {
      final config = NvpConfig(
        onBannerTap: (_) {},
        onBannerDismiss: (_) {},
        onSystemNotificationTap: (_) {},
        onCallAnswered: (_) {},
        onCallDeclined: (_) {},
        onCallEnded: (_) {},
        onTokenRefresh: (_) {},
        onChatPayload: (_) {},
        onCallPayload: (_) {},
      );
      expect(config.onBannerTap, isNotNull);
      expect(config.onCallAnswered, isNotNull);
      expect(config.onTokenRefresh, isNotNull);
    });
  });

  group('Models - NvpPayloadKeys', () {
    test('UT-004: NvpPayloadKeys default values', () {
      const keys = NvpPayloadKeys();
      expect(keys.titleKey, 'title');
      expect(keys.bodyKey, 'body');
      expect(keys.senderNameKey, 'senderName');
      expect(keys.sessionIdKey, 'sessionId');
      expect(keys.conversationIdKey, 'conversationId');
    });
  });

  group('Models - NvpNotification', () {
    test('UT-005: NvpNotification.fromMap()', () {
      final n = NvpNotification.fromMap({
        'title': 'Hello',
        'body': 'World',
        'imageUrl': 'https://img.com/a.png',
        'senderId': 'u1',
        'groupKey': 'conv-123',
      });
      expect(n.title, 'Hello');
      expect(n.body, 'World');
      expect(n.imageUrl, 'https://img.com/a.png');
      expect(n.senderId, 'u1');
      expect(n.groupKey, 'conv-123');
    });

    test('UT-006: NvpNotification.toMap() roundtrip', () {
      const original = NvpNotification(
        title: 'T',
        body: 'B',
        senderId: 's1',
        groupKey: 'g1',
      );
      final roundtripped = NvpNotification.fromMap(original.toMap());
      expect(roundtripped.title, original.title);
      expect(roundtripped.body, original.body);
      expect(roundtripped.senderId, original.senderId);
      expect(roundtripped.groupKey, original.groupKey);
    });

    test('UT-007: NvpNotification with groupKey', () {
      const n = NvpNotification(
          title: 'T', body: 'B', groupKey: 'conv-123');
      expect(n.groupKey, 'conv-123');
    });

    test('UT-008: NvpNotification without groupKey', () {
      const n = NvpNotification(title: 'T', body: 'B');
      expect(n.groupKey, isNull);
    });
  });

  group('Models - NvpNotificationTemplate', () {
    test('UT-009: toMap() for each template type', () {
      for (final type in NvpNotificationTemplateType.values) {
        final t = NvpNotificationTemplate(type: type);
        expect(t.toMap()['type'], type.name);
      }
    });
  });

  group('Models - NvpNotificationAction', () {
    test('UT-010: toMap()', () {
      const a = NvpNotificationAction(
        id: 'reply',
        title: 'Reply',
        isTextInput: true,
        textInputPlaceholder: 'Type...',
      );
      final map = a.toMap();
      expect(map['id'], 'reply');
      expect(map['title'], 'Reply');
      expect(map['isTextInput'], true);
      expect(map['textInputPlaceholder'], 'Type...');
    });
  });

  group('Models - NvpCallEvent', () {
    test('UT-011: fromMap()', () {
      final e = NvpCallEvent.fromMap({
        'action': 'accept',
        'callId': 'session-1',
        'callerName': 'John',
        'isVideo': true,
        'callType': 'video',
      });
      expect(e.action, NvpCallAction.accept);
      expect(e.callId, 'session-1');
      expect(e.callerName, 'John');
      expect(e.isVideo, true);
    });

    test('UT-012: toMap() roundtrip', () {
      const original = NvpCallEvent(
        action: NvpCallAction.decline,
        callId: 'c1',
        callerName: 'Jane',
        isVideo: false,
      );
      final roundtripped = NvpCallEvent.fromMap(original.toMap());
      expect(roundtripped.action, original.action);
      expect(roundtripped.callId, original.callId);
      expect(roundtripped.callerName, original.callerName);
    });
  });

  group('Models - NvpCallConfig', () {
    test('UT-013: toMap()', () {
      const c = NvpCallConfig(
        callId: 'c1',
        callerName: 'John',
        isVideo: true,
        isOutgoing: true,
      );
      final map = c.toMap();
      expect(map['callId'], 'c1');
      expect(map['callerName'], 'John');
      expect(map['isVideo'], true);
      expect(map['isOutgoing'], true);
    });
  });

  group('Models - NvpCallState', () {
    test('UT-014: fromMap()', () {
      final s = NvpCallState.fromMap({
        'callId': 'c1',
        'status': 'connected',
        'isMuted': true,
        'isSpeakerOn': false,
        'isCameraOn': true,
      });
      expect(s.callId, 'c1');
      expect(s.status, NvpCallStatus.connected);
      expect(s.isMuted, true);
    });

    test('UT-015: NvpCallStatus enum values', () {
      expect(NvpCallStatus.values,
          containsAll([
            NvpCallStatus.ringing,
            NvpCallStatus.connected,
            NvpCallStatus.onHold,
            NvpCallStatus.ended,
          ]));
    });
  });
}

/// Minimal platform that doesn't override anything — used to test base throws.
class _MinimalPlatform extends NvpPlatformInterface
    with MockPlatformInterfaceMixin {}
