import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';

typedef LogFn = void Function(String msg, IconData icon, Color color);

class CallBuilderDialog {
  CallBuilderDialog._();

  static Future<void> show({
    required BuildContext context,
    required LogFn log,
    required bool isNative,
    required bool isIncoming,
    required ValueChanged<String> onCallIdChanged,
  }) async {
    final callerCtrl = TextEditingController(text: 'John Doe');
    final callIdCtrl = TextEditingController(
      text: 'session-${DateTime.now().millisecondsSinceEpoch}',
    );
    final avatarCtrl = TextEditingController();
    final extraKeyCtrl = TextEditingController(text: 'roomId');
    final extraValCtrl = TextEditingController(text: 'room-42');
    bool isVideo = false;
    bool useAvatar = false;
    bool useExtra = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          icon: Icon(isIncoming ? Icons.call_received : Icons.call_made),
          title: Text(
            isIncoming
                ? (isNative ? 'Incoming (Native)' : 'Incoming (Custom)')
                : 'Outgoing (Custom)',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: callerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Caller Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: callIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Call ID',
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    title: const Text('Video Call'),
                    secondary: const Icon(Icons.videocam),
                    value: isVideo,
                    onChanged: (v) => set(() => isVideo = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Caller Avatar'),
                    secondary: const Icon(Icons.account_circle),
                    value: useAvatar,
                    onChanged: (v) => set(() => useAvatar = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (useAvatar)
                    TextField(
                      controller: avatarCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Avatar URL',
                        prefixIcon: Icon(Icons.link),
                        hintText: 'https://...',
                      ),
                    ),
                  SwitchListTile(
                    title: const Text('Extra Data'),
                    secondary: const Icon(Icons.data_object),
                    value: useExtra,
                    onChanged: (v) => set(() => useExtra = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (useExtra)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: extraKeyCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Key',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: extraValCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Value',
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: Icon(isIncoming ? Icons.call : Icons.call_made),
              label: Text(isIncoming ? 'Show Call' : 'Start Call'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    onCallIdChanged(callIdCtrl.text);

    final callConfig = NvpCallConfig(
      callId: callIdCtrl.text,
      callerName: callerCtrl.text,
      callerAvatar:
          useAvatar && avatarCtrl.text.isNotEmpty ? avatarCtrl.text : null,
      isVideo: isVideo,
      isOutgoing: !isIncoming,
      extra: useExtra
          ? {extraKeyCtrl.text: extraValCtrl.text}
          : const {},
    );

    if (!context.mounted) return;

    if (isNative) {
      await _handleNativeCall(context, callConfig, isIncoming, log);
    } else {
      await _handleCustomScreenCall(
        context,
        callConfig,
        isIncoming,
        log,
      );
    }
  }

  static Future<void> _handleNativeCall(
    BuildContext context,
    NvpCallConfig config,
    bool isIncoming,
    LogFn log,
  ) async {
    try {
      if (isIncoming) {
        await NotificationVoipPlugin.showIncomingCall(config);
        log(
          'Native incoming: ${config.callId}',
          Icons.call_received,
          Colors.green,
        );
      } else {
        await NotificationVoipPlugin.showOutgoingCall(config);
        log(
          'Native outgoing: ${config.callId}',
          Icons.call_made,
          Colors.green,
        );
      }
    } on PlatformException catch (e) {
      if (e.code == 'PHONE_ACCOUNT_NOT_ENABLED') {
        log('Phone account not enabled', Icons.error, Colors.red);
        if (!context.mounted) return;
        _showPhoneAccountDialog(context);
      } else {
        log('Error: ${e.message}', Icons.error, Colors.red);
      }
    }
  }

  static Future<void> _handleCustomScreenCall(
    BuildContext context,
    NvpCallConfig config,
    bool isIncoming,
    LogFn log,
  ) async {
    log(
      'Custom screen: ${config.callId}',
      Icons.phone_android,
      Colors.green,
    );

    try {
      if (isIncoming) {
        await NotificationVoipPlugin.showIncomingCall(
          config.copyWith(useNativeScreen: false),
        );
      } else {
        await NotificationVoipPlugin.showOutgoingCall(config);
      }
    } on PlatformException catch (e) {
      if (e.code == 'PHONE_ACCOUNT_NOT_ENABLED') {
        log('Phone account not enabled', Icons.error, Colors.red);
        if (!context.mounted) return;
        _showPhoneAccountDialog(context);
        return;
      }
    }

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NvpCallScreen(
          event: NvpCallEvent(
            action: isIncoming ? NvpCallAction.incoming : null,
            callId: config.callId,
            callerName: config.callerName,
            isVideo: config.isVideo,
          ),
          controller: NvpCallScreenController(callId: config.callId),
        ),
      ),
    );
  }

  static void _showPhoneAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.phonelink_setup, color: Colors.orange),
        title: const Text('Phone Account Required'),
        content: const Text(
          'The VoIP calling account needs to be enabled to show native '
          'call screens.\n\nPlease enable it in your phone\'s Calling '
          'Accounts settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
            onPressed: () {
              Navigator.pop(ctx);
              NotificationVoipPlugin.openPhoneAccountSettings();
            },
          ),
        ],
      ),
    );
  }
}
