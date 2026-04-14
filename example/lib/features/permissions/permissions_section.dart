import 'dart:io';

import 'package:flutter/material.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';

import '../../shared/action_tile.dart';
import '../../shared/log_controller.dart';
import '../../shared/mini_log.dart';
import '../../shared/section_card.dart';

class PermissionsSection extends StatelessWidget {
  final LogController logController;

  const PermissionsSection({super.key, required this.logController});

  void _log(String msg, IconData icon, Color color) =>
      logController.add('permissions', msg, icon, color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: 'Permissions & Settings',
          icon: Icons.security,
          children: [
            ActionTile(
              icon: Icons.check_circle_outline,
              title: 'Request Permission',
              subtitle: 'requestPermission()',
              onTap: () async {
                final granted =
                    await NotificationVoipPlugin.requestPermission();
                _log(
                  'Permission: ${granted ? "granted" : "denied"}',
                  Icons.security,
                  granted ? Colors.green : Colors.red,
                );
              },
            ),
            ActionTile(
              icon: Icons.verified_user,
              title: 'Check Permission',
              subtitle: 'isPermissionGranted()',
              onTap: () async {
                final granted =
                    await NotificationVoipPlugin.isPermissionGranted();
                _log(
                  'Permission granted: $granted',
                  Icons.verified_user,
                  granted ? Colors.green : Colors.red,
                );
              },
            ),
            ActionTile(
              icon: Icons.settings,
              title: 'Open App Settings',
              subtitle: 'openSettings()',
              onTap: () async {
                await NotificationVoipPlugin.openSettings();
                _log('Opened app settings', Icons.settings, Colors.grey);
              },
            ),
            if (Platform.isAndroid) ...[
              const Divider(),
              ActionTile(
                icon: Icons.phone_android,
                title: 'Check Phone Account',
                subtitle: 'isPhoneAccountEnabled()',
                onTap: () async {
                  final enabled =
                      await NotificationVoipPlugin.isPhoneAccountEnabled();
                  _log(
                    'Phone account: ${enabled ? "enabled" : "disabled"}',
                    Icons.phone_android,
                    enabled ? Colors.green : Colors.red,
                  );
                },
              ),
              ActionTile(
                icon: Icons.phonelink_setup,
                title: 'Open Phone Account Settings',
                subtitle: 'openPhoneAccountSettings()',
                onTap: () async {
                  await NotificationVoipPlugin.openPhoneAccountSettings();
                  _log(
                    'Opened phone account settings',
                    Icons.phonelink_setup,
                    Colors.grey,
                  );
                },
              ),
            ],
          ],
        ),
        MiniLog(section: 'permissions', logController: logController),
      ],
    );
  }
}
