import 'package:flutter/material.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';

import '../../shared/action_tile.dart';
import '../../shared/log_controller.dart';
import '../../shared/mini_log.dart';
import '../../shared/section_card.dart';
import 'notification_builder_dialog.dart';
import 'in_app_builder_dialog.dart';

class NotificationsSection extends StatelessWidget {
  final LogController logController;

  const NotificationsSection({super.key, required this.logController});

  void _log(String msg, IconData icon, Color color) =>
      logController.add('notifications', msg, icon, color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: 'Notifications',
          icon: Icons.notifications,
          children: [
            ActionTile(
              icon: Icons.tune,
              title: 'Custom Notification',
              subtitle:
                  'Customize title, body, template, group, image & more',
              onTap: () => NotificationBuilderDialog.show(context, _log),
            ),
            ActionTile(
              icon: Icons.web_asset,
              title: 'Custom In-App Notification',
              subtitle: 'showInAppNotification() with custom content',
              onTap: () => InAppBuilderDialog.show(context, _log),
            ),
            const Divider(),
            ActionTile(
              icon: Icons.cleaning_services,
              title: 'Clear All Notifications',
              subtitle: 'clearAll()',
              onTap: () async {
                await NotificationVoipPlugin.clearAll();
                _log(
                  'All notifications cleared',
                  Icons.cleaning_services,
                  Colors.grey,
                );
              },
            ),
          ],
        ),
        MiniLog(section: 'notifications', logController: logController),
      ],
    );
  }
}
