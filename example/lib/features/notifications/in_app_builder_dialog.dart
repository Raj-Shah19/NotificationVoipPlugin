import 'package:flutter/material.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';

typedef LogFn = void Function(String msg, IconData icon, Color color);

class InAppBuilderDialog {
  InAppBuilderDialog._();

  static Future<void> show(BuildContext context, LogFn log) async {
    final titleCtrl = TextEditingController(text: 'In-App Alert');
    final bodyCtrl =
        TextEditingController(text: 'This is a banner overlay');
    final senderCtrl = TextEditingController();
    final senderAvatarCtrl = TextEditingController();
    final tagCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.web_asset),
        title: const Text('In-App Notification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  prefixIcon: Icon(Icons.short_text),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: senderCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sender Name (optional)',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: senderAvatarCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sender Avatar URL (optional)',
                  prefixIcon: Icon(Icons.account_circle),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tagCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tag (optional)',
                  prefixIcon: Icon(Icons.label),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Show'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (result != true) return;

    final ok = await NotificationVoipPlugin.showInAppNotification(
      NvpNotification(
        title: titleCtrl.text,
        body: bodyCtrl.text,
        senderName:
            senderCtrl.text.isNotEmpty ? senderCtrl.text : null,
        senderAvatar:
            senderAvatarCtrl.text.isNotEmpty ? senderAvatarCtrl.text : null,
        tag: tagCtrl.text.isNotEmpty ? tagCtrl.text : null,
      ),
    );
    log('InApp: $ok', Icons.web_asset, Colors.cyan);
  }
}
