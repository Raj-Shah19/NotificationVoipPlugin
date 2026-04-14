import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';

import '../../shared/action_tile.dart';
import '../../shared/log_controller.dart';
import '../../shared/mini_log.dart';
import '../../shared/section_card.dart';

class TokensSection extends StatelessWidget {
  final LogController logController;

  const TokensSection({super.key, required this.logController});

  void _log(String msg, IconData icon, Color color) =>
      logController.add('tokens', msg, icon, color);

  Future<void> _fetchAndLog(
    BuildContext context,
    String label,
    Future<String?> Function() fetcher,
  ) async {
    final token = await fetcher();
    _log('$label: ${token ?? "null"}', Icons.key, Colors.teal);
    if (!context.mounted) return;
    if (token != null) {
      await Clipboard.setData(ClipboardData(text: token));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: 'Push Tokens',
          icon: Icons.vpn_key,
          children: [
            ActionTile(
              icon: Icons.key,
              title: 'Get Push Token',
              subtitle: 'getPushToken() — FCM on Android, APNs on iOS',
              onTap: () => _fetchAndLog(
                context,
                'Push',
                NotificationVoipPlugin.getPushToken,
              ),
            ),
            ActionTile(
              icon: Icons.cloud,
              title: 'Get FCM Token',
              subtitle: 'getFCMToken()',
              onTap: () => _fetchAndLog(
                context,
                'FCM',
                NotificationVoipPlugin.getFCMToken,
              ),
            ),
            ActionTile(
              icon: Icons.apple,
              title: 'Get APNs Token',
              subtitle: 'getAPNsToken() — iOS only',
              onTap: () => _fetchAndLog(
                context,
                'APNs',
                NotificationVoipPlugin.getAPNsToken,
              ),
            ),
            ActionTile(
              icon: Icons.phone_in_talk,
              title: 'Get VoIP Token',
              subtitle: 'getVoIPToken() — iOS only',
              onTap: () => _fetchAndLog(
                context,
                'VoIP',
                NotificationVoipPlugin.getVoIPToken,
              ),
            ),
          ],
        ),
        MiniLog(section: 'tokens', logController: logController),
      ],
    );
  }
}
