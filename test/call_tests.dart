import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ── Tracking Mock ──
// Records all call-related method invocations so we can assert arguments.
class TrackingNvpPlatform extends NvpPlatformInterface
    with MockPlatformInterfaceMixin {
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<void> init(Map<String, dynamic>? config) async {
    calls.add({'method': 'init', 'config': config});
  }

  @override
  Future<void> showIncomingCall(Map<String, dynamic> call) async {
    calls.add({'method': 'showIncomingCall', ...call});
  }

  @override
  Future<void> showOutgoingCall(Map<String, dynamic> call) async {
    calls.add({'method': 'showOutgoingCall', ...call});
  }

  @override
  Future<void> acceptCall(String callId) async {
    calls.add({'method': 'acceptCall', 'callId': callId});
  }

  @override
  Future<void> rejectCall(String callId) async {
    calls.add({'method': 'rejectCall', 'callId': callId});
  }

  @override
  Future<void> endCall(String callId) async {
    calls.add({'method': 'endCall', 'callId': callId});
  }

  @override
  Future<void> toggleMute(String callId) async {
    calls.add({'method': 'toggleMute', 'callId': callId});
  }

  @override
  Future<void> toggleSpeaker(String callId) async {
    calls.add({'method': 'toggleSpeaker', 'callId': callId});
  }

  @override
  Future<void> toggleCamera(String callId) async {
    calls.add({'method': 'toggleCamera', 'callId': callId});
  }

  @override
  Future<bool> isPhoneAccountEnabled() async {
    calls.add({'method': 'isPhoneAccountEnabled'});
    return true;
  }

  @override
  Future<void> openPhoneAccountSettings() async {
    calls.add({'method': 'openPhoneAccountSettings'});
  }

  @override
  Stream<Map<String, dynamic>> get onCallEventStream => _callEventController.stream;
  final _callEventController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onCallStateChangedStream => _callStateController.stream;
  final _callStateController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onNotificationTapStream => const Stream.empty();

  @override
  Stream<String> get onTokenRefreshStream => const Stream.empty();

  @override
  Future<void> dispose() async {
    calls.add({'method': 'dispose'});
  }
}

// ── Mock that throws PlatformException for showIncomingCall ──
class PhoneAccountDisabledPlatform extends NvpPlatformInterface
    with MockPlatformInterfaceMixin {
  @override
  Future<void> init(Map<String, dynamic>? config) async {}

  @override
  Future<void> showIncomingCall(Map<String, dynamic> call) async {
    throw PlatformException(
      code: 'PHONE_ACCOUNT_NOT_ENABLED',
      message: 'The VoIP phone account is not enabled.',
    );
  }

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
  Stream<Map<String, dynamic>> get onCallEventStream => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onCallStateChangedStream => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onNotificationTapStream => const Stream.empty();

  @override
  Stream<String> get onTokenRefreshStream => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

// ── Tests ──

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TrackingNvpPlatform platform;

  setUp(() async {
    platform = TrackingNvpPlatform();
    NvpPlatformInterface.instance = platform;
    // Reset cached streams by disposing
    await NotificationVoipPlugin.dispose();
    platform.calls.clear();
  });

  // ═══════════════════════════════════════════
  // 1. NvpCallConfig model tests
  // ═══════════════════════════════════════════

  group('NvpCallConfig', () {
    test('toMap() includes all fields for incoming audio call', () {
      const config = NvpCallConfig(
        callId: 'call-001',
        callerName: 'Alice',
        isVideo: false,
        isOutgoing: false,
      );
      final map = config.toMap();
      expect(map['callId'], 'call-001');
      expect(map['callerName'], 'Alice');
      expect(map['isVideo'], false);
      expect(map['isOutgoing'], false);
      expect(map['extra'], isEmpty);
    });

    test('toMap() includes all fields for outgoing video call', () {
      const config = NvpCallConfig(
        callId: 'call-002',
        callerName: 'Bob',
        callerAvatar: 'https://example.com/bob.png',
        isVideo: true,
        isOutgoing: true,
        extra: {'roomId': 'room-42'},
      );
      final map = config.toMap();
      expect(map['callId'], 'call-002');
      expect(map['callerName'], 'Bob');
      expect(map['callerAvatar'], 'https://example.com/bob.png');
      expect(map['isVideo'], true);
      expect(map['isOutgoing'], true);
      expect(map['extra'], {'roomId': 'room-42'});
    });

    test('fromMap() reconstructs correctly', () {
      final config = NvpCallConfig.fromMap({
        'callId': 'c1',
        'callerName': 'Jane',
        'callerAvatar': 'avatar.png',
        'isVideo': true,
        'isOutgoing': true,
        'extra': {'key': 'val'},
      });
      expect(config.callId, 'c1');
      expect(config.callerName, 'Jane');
      expect(config.callerAvatar, 'avatar.png');
      expect(config.isVideo, true);
      expect(config.isOutgoing, true);
      expect(config.extra['key'], 'val');
    });

    test('fromMap() handles missing fields with defaults', () {
      final config = NvpCallConfig.fromMap({});
      expect(config.callId, '');
      expect(config.callerName, '');
      expect(config.callerAvatar, isNull);
      expect(config.isVideo, false);
      expect(config.isOutgoing, false);
      expect(config.extra, isEmpty);
    });

    test('toMap() omits callerAvatar when null', () {
      const config = NvpCallConfig(callId: 'c1', callerName: 'X');
      final map = config.toMap();
      expect(map.containsKey('callerAvatar'), false);
    });

    test('roundtrip fromMap(toMap()) preserves data', () {
      const original = NvpCallConfig(
        callId: 'rt-1',
        callerName: 'Roundtrip',
        callerAvatar: 'av.png',
        isVideo: true,
        isOutgoing: false,
        extra: {'a': 1},
      );
      final restored = NvpCallConfig.fromMap(original.toMap());
      expect(restored.callId, original.callId);
      expect(restored.callerName, original.callerName);
      expect(restored.callerAvatar, original.callerAvatar);
      expect(restored.isVideo, original.isVideo);
      expect(restored.isOutgoing, original.isOutgoing);
      expect(restored.extra['a'], 1);
    });
  });

  // ═══════════════════════════════════════════
  // 2. NvpCallEvent model tests
  // ═══════════════════════════════════════════

  group('NvpCallEvent', () {
    test('fromMap() with all fields', () {
      final event = NvpCallEvent.fromMap({
        'action': 'accept',
        'callId': 'session-1',
        'callerName': 'John',
        'callerAvatar': 'john.png',
        'isVideo': true,
        'callType': 'video',
        'conversationId': 'conv-1',
        'payload': {'custom': 'data'},
      });
      expect(event.action, NvpCallAction.accept);
      expect(event.callId, 'session-1');
      expect(event.callerName, 'John');
      expect(event.callerAvatar, 'john.png');
      expect(event.isVideo, true);
      expect(event.callType, 'video');
      expect(event.conversationId, 'conv-1');
      expect(event.payload['custom'], 'data');
    });

    test('fromMap() with empty map defaults', () {
      final event = NvpCallEvent.fromMap({});
      expect(event.action, null);
      expect(event.callId, '');
      expect(event.callerName, isNull);
      expect(event.isVideo, false);
      expect(event.payload, isEmpty);
    });

    test('toMap() omits null optional fields', () {
      const event = NvpCallEvent(action: NvpCallAction.decline, callId: 'c1');
      final map = event.toMap();
      expect(map.containsKey('callerName'), false);
      expect(map.containsKey('callerAvatar'), false);
      expect(map.containsKey('callType'), false);
      expect(map.containsKey('conversationId'), false);
      expect(map['action'], 'decline');
      expect(map['callId'], 'c1');
    });
  });

  // ═══════════════════════════════════════════
  // 3. NvpCallState model tests
  // ═══════════════════════════════════════════

  group('NvpCallState', () {
    test('fromMap() parses all statuses', () {
      for (final status in NvpCallStatus.values) {
        final state = NvpCallState.fromMap({
          'callId': 'c1',
          'status': status.name,
        });
        expect(state.status, status);
      }
    });

    test('fromMap() with connectedAt timestamp', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final state = NvpCallState.fromMap({
        'callId': 'c1',
        'status': 'connected',
        'connectedAt': now,
      });
      expect(state.connectedAt, isNotNull);
      expect(state.connectedAt!.millisecondsSinceEpoch, now);
    });

    test('fromMap() without connectedAt', () {
      final state = NvpCallState.fromMap({
        'callId': 'c1',
        'status': 'ringing',
      });
      expect(state.connectedAt, isNull);
    });

    test('toMap() includes connectedAt when present', () {
      final dt = DateTime(2025, 1, 1);
      final state = NvpCallState(
        callId: 'c1',
        status: NvpCallStatus.connected,
        connectedAt: dt,
      );
      final map = state.toMap();
      expect(map['connectedAt'], dt.millisecondsSinceEpoch);
    });

    test('toMap() omits connectedAt when null', () {
      const state = NvpCallState(
        callId: 'c1',
        status: NvpCallStatus.ringing,
      );
      final map = state.toMap();
      expect(map.containsKey('connectedAt'), false);
    });

    test('defaults: isMuted=false, isSpeakerOn=false, isCameraOn=true', () {
      const state = NvpCallState(
        callId: 'c1',
        status: NvpCallStatus.ringing,
      );
      expect(state.isMuted, false);
      expect(state.isSpeakerOn, false);
      expect(state.isCameraOn, true);
    });

    test('fromMap() with all toggle states', () {
      final state = NvpCallState.fromMap({
        'callId': 'c1',
        'status': 'connected',
        'isMuted': true,
        'isSpeakerOn': true,
        'isCameraOn': false,
      });
      expect(state.isMuted, true);
      expect(state.isSpeakerOn, true);
      expect(state.isCameraOn, false);
    });
  });

  // ═══════════════════════════════════════════
  // 4. Plugin API — showIncomingCall
  // ═══════════════════════════════════════════

  group('showIncomingCall', () {
    test('delegates to platform with correct arguments', () async {
      const config = NvpCallConfig(
        callId: 'incoming-1',
        callerName: 'Alice',
        isVideo: false,
      );
      await NotificationVoipPlugin.showIncomingCall(config);

      final call = platform.calls.firstWhere((c) => c['method'] == 'showIncomingCall');
      expect(call['callId'], 'incoming-1');
      expect(call['callerName'], 'Alice');
      expect(call['isVideo'], false);
      expect(call['isOutgoing'], false);
    });

    test('passes video flag correctly', () async {
      const config = NvpCallConfig(
        callId: 'vid-1',
        callerName: 'Bob',
        isVideo: true,
      );
      await NotificationVoipPlugin.showIncomingCall(config);

      final call = platform.calls.firstWhere((c) => c['method'] == 'showIncomingCall');
      expect(call['isVideo'], true);
    });

    test('passes callerAvatar when provided', () async {
      const config = NvpCallConfig(
        callId: 'av-1',
        callerName: 'Carol',
        callerAvatar: 'https://example.com/carol.png',
      );
      await NotificationVoipPlugin.showIncomingCall(config);

      final call = platform.calls.firstWhere((c) => c['method'] == 'showIncomingCall');
      expect(call['callerAvatar'], 'https://example.com/carol.png');
    });

    test('passes extra data', () async {
      const config = NvpCallConfig(
        callId: 'ex-1',
        callerName: 'Dave',
        extra: {'roomId': 'r1', 'token': 'abc'},
      );
      await NotificationVoipPlugin.showIncomingCall(config);

      final call = platform.calls.firstWhere((c) => c['method'] == 'showIncomingCall');
      expect(call['extra'], {'roomId': 'r1', 'token': 'abc'});
    });

    test('throws PlatformException when phone account not enabled', () async {
      NvpPlatformInterface.instance = PhoneAccountDisabledPlatform();

      const config = NvpCallConfig(callId: 'fail-1', callerName: 'X');
      expect(
        () => NotificationVoipPlugin.showIncomingCall(config),
        throwsA(isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'PHONE_ACCOUNT_NOT_ENABLED',
        )),
      );
    });
  });

  // ═══════════════════════════════════════════
  // 5. Plugin API — showOutgoingCall
  // ═══════════════════════════════════════════

  group('showOutgoingCall', () {
    test('delegates to platform with correct arguments', () async {
      const config = NvpCallConfig(
        callId: 'out-1',
        callerName: 'Eve',
        isVideo: false,
        isOutgoing: true,
      );
      await NotificationVoipPlugin.showOutgoingCall(config);

      final call = platform.calls.firstWhere((c) => c['method'] == 'showOutgoingCall');
      expect(call['callId'], 'out-1');
      expect(call['callerName'], 'Eve');
      expect(call['isOutgoing'], true);
    });

    test('passes video flag for outgoing video call', () async {
      const config = NvpCallConfig(
        callId: 'out-vid-1',
        callerName: 'Frank',
        isVideo: true,
        isOutgoing: true,
      );
      await NotificationVoipPlugin.showOutgoingCall(config);

      final call = platform.calls.firstWhere((c) => c['method'] == 'showOutgoingCall');
      expect(call['isVideo'], true);
    });
  });

  // ═══════════════════════════════════════════
  // 6. Plugin API — endCall
  // ═══════════════════════════════════════════

  group('endCall', () {
    test('delegates callId to platform', () async {
      await NotificationVoipPlugin.endCall('session-42');

      final call = platform.calls.firstWhere((c) => c['method'] == 'endCall');
      expect(call['callId'], 'session-42');
    });

    test('handles empty callId', () async {
      await NotificationVoipPlugin.endCall('');

      final call = platform.calls.firstWhere((c) => c['method'] == 'endCall');
      expect(call['callId'], '');
    });
  });

  // ═══════════════════════════════════════════
  // 7. Plugin API — toggleMute / toggleSpeaker / toggleCamera
  // ═══════════════════════════════════════════

  group('toggleMute', () {
    test('delegates callId to platform', () async {
      await NotificationVoipPlugin.toggleMute('m-1');

      final call = platform.calls.firstWhere((c) => c['method'] == 'toggleMute');
      expect(call['callId'], 'm-1');
    });
  });

  group('toggleSpeaker', () {
    test('delegates callId to platform', () async {
      await NotificationVoipPlugin.toggleSpeaker('s-1');

      final call = platform.calls.firstWhere((c) => c['method'] == 'toggleSpeaker');
      expect(call['callId'], 's-1');
    });
  });

  group('toggleCamera', () {
    test('delegates callId to platform', () async {
      await NotificationVoipPlugin.toggleCamera('cam-1');

      final call = platform.calls.firstWhere((c) => c['method'] == 'toggleCamera');
      expect(call['callId'], 'cam-1');
    });
  });

  // ═══════════════════════════════════════════
  // 8. Plugin API — isPhoneAccountEnabled / openPhoneAccountSettings
  // ═══════════════════════════════════════════

  group('isPhoneAccountEnabled', () {
    test('returns true from mock', () async {
      final result = await NotificationVoipPlugin.isPhoneAccountEnabled();
      expect(result, true);
    });

    test('returns false when platform returns false', () async {
      NvpPlatformInterface.instance = PhoneAccountDisabledPlatform();
      final result = await NotificationVoipPlugin.isPhoneAccountEnabled();
      expect(result, false);
    });
  });

  group('openPhoneAccountSettings', () {
    test('delegates to platform', () async {
      await NotificationVoipPlugin.openPhoneAccountSettings();

      final call = platform.calls.firstWhere((c) => c['method'] == 'openPhoneAccountSettings');
      expect(call, isNotNull);
    });
  });

  // ═══════════════════════════════════════════
  // 9. Streams — onCallEvent
  // ═══════════════════════════════════════════

  group('onCallEvent stream', () {
    test('emits NvpCallEvent from raw map', () async {
      final events = <NvpCallEvent>[];
      final sub = NotificationVoipPlugin.onCallEvent.listen(events.add);

      platform._callEventController.add({
        'action': 'accept',
        'callId': 'stream-1',
        'callerName': 'StreamUser',
        'isVideo': false,
      });

      await Future.delayed(Duration.zero);
      expect(events, hasLength(1));
      expect(events.first.action, NvpCallAction.accept);
      expect(events.first.callId, 'stream-1');
      expect(events.first.callerName, 'StreamUser');

      await sub.cancel();
    });

    test('emits multiple events in order', () async {
      final actions = <NvpCallAction?>[];
      final sub = NotificationVoipPlugin.onCallEvent.listen((e) => actions.add(e.action));

      platform._callEventController.add({'action': 'incoming', 'callId': 'c1'});
      platform._callEventController.add({'action': 'accept', 'callId': 'c1'});
      platform._callEventController.add({'action': 'ended', 'callId': 'c1'});

      await Future.delayed(Duration.zero);
      expect(actions, [NvpCallAction.incoming, NvpCallAction.accept, NvpCallAction.ended]);

      await sub.cancel();
    });
  });

  // ═══════════════════════════════════════════
  // 10. Streams — onCallStateChanged
  // ═══════════════════════════════════════════

  group('onCallStateChanged stream', () {
    test('emits NvpCallState from raw map', () async {
      final states = <NvpCallState>[];
      final sub = NotificationVoipPlugin.onCallStateChanged.listen(states.add);

      platform._callStateController.add({
        'callId': 'state-1',
        'status': 'ringing',
        'isMuted': false,
        'isSpeakerOn': false,
        'isCameraOn': true,
      });

      await Future.delayed(Duration.zero);
      expect(states, hasLength(1));
      expect(states.first.callId, 'state-1');
      expect(states.first.status, NvpCallStatus.ringing);

      await sub.cancel();
    });

    test('tracks state transitions ringing -> connected -> ended', () async {
      final statuses = <NvpCallStatus>[];
      final sub = NotificationVoipPlugin.onCallStateChanged.listen(
        (s) => statuses.add(s.status),
      );

      platform._callStateController.add({'callId': 'c1', 'status': 'ringing'});
      platform._callStateController.add({'callId': 'c1', 'status': 'connected'});
      platform._callStateController.add({'callId': 'c1', 'status': 'ended'});

      await Future.delayed(Duration.zero);
      expect(statuses, [NvpCallStatus.ringing, NvpCallStatus.connected, NvpCallStatus.ended]);

      await sub.cancel();
    });

    test('tracks mute toggle in state changes', () async {
      final muteStates = <bool>[];
      final sub = NotificationVoipPlugin.onCallStateChanged.listen(
        (s) => muteStates.add(s.isMuted),
      );

      platform._callStateController.add({'callId': 'c1', 'status': 'connected', 'isMuted': false});
      platform._callStateController.add({'callId': 'c1', 'status': 'connected', 'isMuted': true});
      platform._callStateController.add({'callId': 'c1', 'status': 'connected', 'isMuted': false});

      await Future.delayed(Duration.zero);
      expect(muteStates, [false, true, false]);

      await sub.cancel();
    });
  });

  // ═══════════════════════════════════════════
  // 11. NvpCallScreenController
  // ═══════════════════════════════════════════

  group('NvpCallScreenController', () {
    test('toggleMute flips isMuted state', () async {
      final controller = NvpCallScreenController(callId: 'ctrl-1');
      expect(controller.isMuted, false);

      await controller.toggleMute();
      expect(controller.isMuted, true);

      await controller.toggleMute();
      expect(controller.isMuted, false);
    });

    test('toggleSpeaker flips isSpeakerOn state', () async {
      final controller = NvpCallScreenController(callId: 'ctrl-1');
      expect(controller.isSpeakerOn, false);

      await controller.toggleSpeaker();
      expect(controller.isSpeakerOn, true);
    });

    test('toggleCamera flips isCameraOn state', () async {
      final controller = NvpCallScreenController(callId: 'ctrl-1');
      expect(controller.isCameraOn, true); // default is true

      await controller.toggleCamera();
      expect(controller.isCameraOn, false);
    });

    test('initial state is correct', () {
      final controller = NvpCallScreenController(callId: 'init-test');
      expect(controller.callId, 'init-test');
      expect(controller.isMuted, false);
      expect(controller.isSpeakerOn, false);
      expect(controller.isCameraOn, true);
    });
  });

  // ═══════════════════════════════════════════
  // 12. Full call lifecycle
  // ═══════════════════════════════════════════

  group('Full call lifecycle', () {
    test('incoming call: show -> toggle controls -> end', () async {
      const config = NvpCallConfig(
        callId: 'lifecycle-1',
        callerName: 'Lifecycle Test',
        isVideo: true,
      );

      await NotificationVoipPlugin.showIncomingCall(config);
      await NotificationVoipPlugin.toggleMute('lifecycle-1');
      await NotificationVoipPlugin.toggleSpeaker('lifecycle-1');
      await NotificationVoipPlugin.toggleCamera('lifecycle-1');
      await NotificationVoipPlugin.endCall('lifecycle-1');

      final methods = platform.calls.map((c) => c['method']).toList();
      expect(methods, [
        'showIncomingCall',
        'toggleMute',
        'toggleSpeaker',
        'toggleCamera',
        'endCall',
      ]);

      // Verify all used the same callId
      final callIds = platform.calls
          .where((c) => c.containsKey('callId'))
          .map((c) => c['callId'])
          .toSet();
      expect(callIds, {'lifecycle-1'});
    });

    test('outgoing call: show -> end', () async {
      const config = NvpCallConfig(
        callId: 'out-lifecycle',
        callerName: 'Outgoing Test',
        isOutgoing: true,
      );

      await NotificationVoipPlugin.showOutgoingCall(config);
      await NotificationVoipPlugin.endCall('out-lifecycle');

      final methods = platform.calls.map((c) => c['method']).toList();
      expect(methods, ['showOutgoingCall', 'endCall']);
    });
  });

  // ═══════════════════════════════════════════
  // 13. dispose clears streams
  // ═══════════════════════════════════════════

  group('dispose', () {
    test('dispose delegates to platform', () async {
      await NotificationVoipPlugin.dispose();

      final call = platform.calls.firstWhere((c) => c['method'] == 'dispose');
      expect(call, isNotNull);
    });
  });
}
