import 'package:flutter/material.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';

import '../../shared/action_tile.dart';
import '../../shared/log_controller.dart';
import '../../shared/mini_log.dart';
import '../../shared/section_card.dart';

class BadgeSection extends StatelessWidget {
  final LogController logController;

  const BadgeSection({super.key, required this.logController});

  void _log(String msg, IconData icon, Color color) =>
      logController.add('badge', msg, icon, color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: 'Badge Count',
          icon: Icons.badge,
          children: [
            ActionTile(
              icon: Icons.edit,
              title: 'Set Custom Badge Count',
              subtitle: 'setBadgeCount(n) — enter any number',
              onTap: () => _showCustomBadgeDialog(context),
            ),
            ActionTile(
              icon: Icons.countertops,
              title: 'Get Badge Count',
              subtitle: 'getBadgeCount()',
              onTap: () async {
                final count = await NotificationVoipPlugin.getBadgeCount();
                _log('Badge count: $count', Icons.countertops, Colors.amber);
              },
            ),
            ActionTile(
              icon: Icons.clear,
              title: 'Clear Badge',
              subtitle: 'setBadgeCount(0)',
              onTap: () async {
                await NotificationVoipPlugin.setBadgeCount(0);
                _log('Badge cleared', Icons.clear, Colors.grey);
              },
            ),
          ],
        ),
        MiniLog(section: 'badge', logController: logController),
      ],
    );
  }

  Future<void> _showCustomBadgeDialog(BuildContext context) async {
    final controller = TextEditingController(text: '5');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.badge),
        title: const Text('Set Badge Count'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Badge Count',
            prefixIcon: Icon(Icons.numbers),
            hintText: 'Enter a number (0 to clear)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Set'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final count = int.tryParse(controller.text) ?? 0;
    await NotificationVoipPlugin.setBadgeCount(count);
    _log('Badge set to $count', Icons.badge, Colors.amber);
  }
}
