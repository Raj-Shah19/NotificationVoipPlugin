import 'package:flutter/material.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';

import '../../shared/action_tile.dart';
import '../../shared/log_controller.dart';
import '../../shared/mini_log.dart';
import '../../shared/section_card.dart';
import 'call_builder_dialog.dart';

class CallsSection extends StatelessWidget {
  final LogController logController;
  final String lastCallId;
  final ValueChanged<String> onCallIdChanged;

  const CallsSection({
    super.key,
    required this.logController,
    required this.lastCallId,
    required this.onCallIdChanged,
  });

  void _log(String msg, IconData icon, Color color) =>
      logController.add('calls', msg, icon, color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: 'VoIP Calls',
          icon: Icons.call,
          children: [
            ActionTile(
              icon: Icons.call_received,
              title: 'Incoming Call (Native)',
              subtitle: 'showIncomingCall() — ConnectionService / CallKit',
              onTap: () => CallBuilderDialog.show(
                context: context,
                log: _log,
                isNative: true,
                isIncoming: true,
                onCallIdChanged: onCallIdChanged,
              ),
            ),
            ActionTile(
              icon: Icons.phone_android,
              title: 'Incoming Call (Custom Screen)',
              subtitle: 'showIncomingCall() + NvpCallScreen',
              onTap: () => CallBuilderDialog.show(
                context: context,
                log: _log,
                isNative: false,
                isIncoming: true,
                onCallIdChanged: onCallIdChanged,
              ),
            ),
            ActionTile(
              icon: Icons.call_made,
              title: 'Outgoing Call (Custom Screen)',
              subtitle: 'showOutgoingCall() + NvpCallScreen',
              onTap: () => CallBuilderDialog.show(
                context: context,
                log: _log,
                isNative: false,
                isIncoming: false,
                onCallIdChanged: onCallIdChanged,
              ),
            ),
            const Divider(),
            ActionTile(
              icon: Icons.call_end,
              title: 'End Active Call',
              subtitle: 'endCall()',
              onTap: () async {
                if (lastCallId.isEmpty) {
                  _log(
                    'No active call to end',
                    Icons.call_end,
                    Colors.grey,
                  );
                  return;
                }
                await NotificationVoipPlugin.endCall(lastCallId);
                _log('Ended: $lastCallId', Icons.call_end, Colors.red);
              },
            ),
            ActionTile(
              icon: Icons.mic_off,
              title: 'Toggle Mute',
              subtitle: 'toggleMute()',
              onTap: () async {
                if (lastCallId.isEmpty) return;
                await NotificationVoipPlugin.toggleMute(lastCallId);
                _log(
                  'Toggled mute: $lastCallId',
                  Icons.mic_off,
                  Colors.orange,
                );
              },
            ),
            ActionTile(
              icon: Icons.volume_up,
              title: 'Toggle Speaker',
              subtitle: 'toggleSpeaker()',
              onTap: () async {
                if (lastCallId.isEmpty) return;
                await NotificationVoipPlugin.toggleSpeaker(lastCallId);
                _log(
                  'Toggled speaker: $lastCallId',
                  Icons.volume_up,
                  Colors.orange,
                );
              },
            ),
            ActionTile(
              icon: Icons.videocam,
              title: 'Toggle Camera',
              subtitle: 'toggleCamera()',
              onTap: () async {
                if (lastCallId.isEmpty) return;
                await NotificationVoipPlugin.toggleCamera(lastCallId);
                _log(
                  'Toggled camera: $lastCallId',
                  Icons.videocam,
                  Colors.orange,
                );
              },
            ),
            const Divider(),
            ActionTile(
              icon: Icons.delete_forever,
              title: 'Dispose Plugin',
              subtitle: 'dispose() — clean up all resources',
              onTap: () async {
                await NotificationVoipPlugin.dispose();
                _log('Plugin disposed', Icons.delete_forever, Colors.red);
              },
            ),
          ],
        ),
        MiniLog(section: 'calls', logController: logController),
      ],
    );
  }
}
