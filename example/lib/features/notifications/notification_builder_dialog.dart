import 'package:flutter/material.dart';
import 'package:notification_voip_plugin/notification_voip_plugin.dart';

typedef LogFn = void Function(String msg, IconData icon, Color color);

class NotificationBuilderDialog {
  NotificationBuilderDialog._();

  static Future<void> show(BuildContext context, LogFn log) async {
    final titleCtrl = TextEditingController(text: 'Hello');
    final bodyCtrl =
        TextEditingController(text: 'This is a test notification');
    final imageCtrl =
        TextEditingController(text: 'https://picsum.photos/400/200');
    final expandedCtrl = TextEditingController(
      text: 'Expanded text shown when notification is pulled down.',
    );
    final groupCtrl = TextEditingController(text: 'demo-group');
    final progressCtrl = TextEditingController(text: '65');
    final senderCtrl = TextEditingController(text: 'Alice');
    final tagCtrl = TextEditingController();
    final channelIdCtrl = TextEditingController();
    final channelNameCtrl = TextEditingController();
    final senderIdCtrl = TextEditingController();
    final senderAvatarCtrl = TextEditingController();
    final conversationIdCtrl = TextEditingController();

    var selectedType = NvpNotificationTemplateType.normal;
    bool useGroup = false;
    bool useActions = false;
    bool showAdvanced = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          icon: const Icon(Icons.notifications_active),
          title: const Text('Build Notification'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
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
                    controller: tagCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tag (optional)',
                      prefixIcon: Icon(Icons.label),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Template type selector
                  DropdownButtonFormField<NvpNotificationTemplateType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Template Type',
                      prefixIcon: Icon(Icons.style),
                    ),
                    items: NvpNotificationTemplateType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => set(() => selectedType = v!),
                  ),
                  const SizedBox(height: 8),

                  // Template-specific fields
                  if ([
                    NvpNotificationTemplateType.bigText,
                    NvpNotificationTemplateType.bigBanner,
                    NvpNotificationTemplateType.richText,
                  ].contains(selectedType))
                    TextField(
                      controller: expandedCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Expanded Text',
                        prefixIcon: Icon(Icons.expand),
                      ),
                      maxLines: 3,
                    ),
                  if ([
                    NvpNotificationTemplateType.bigPicture,
                    NvpNotificationTemplateType.bigBanner,
                  ].contains(selectedType)) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: imageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        prefixIcon: Icon(Icons.image),
                      ),
                    ),
                  ],
                  if (selectedType ==
                      NvpNotificationTemplateType.progress) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: progressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Progress (0-100)',
                        prefixIcon: Icon(Icons.hourglass_bottom),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 4),

                  // Group toggle
                  SwitchListTile(
                    title: const Text('Group notifications'),
                    secondary: const Icon(Icons.group_work),
                    value: useGroup,
                    onChanged: (v) => set(() => useGroup = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (useGroup)
                    TextField(
                      controller: groupCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Group Key',
                        prefixIcon: Icon(Icons.folder),
                      ),
                    ),

                  // Interactive actions toggle
                  if (selectedType ==
                      NvpNotificationTemplateType.interactive)
                    SwitchListTile(
                      title: const Text('Add reply action'),
                      secondary: const Icon(Icons.reply),
                      value: useActions,
                      onChanged: (v) => set(() => useActions = v),
                      contentPadding: EdgeInsets.zero,
                    ),

                  // Advanced fields toggle
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => set(() => showAdvanced = !showAdvanced),
                    child: Row(
                      children: [
                        Icon(
                          showAdvanced
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          showAdvanced
                              ? 'Hide advanced fields'
                              : 'Show advanced fields',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showAdvanced) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: channelIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Channel ID (optional)',
                        prefixIcon: Icon(Icons.tv),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: channelNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Channel Name (optional)',
                        prefixIcon: Icon(Icons.tv),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: senderIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sender ID (optional)',
                        prefixIcon: Icon(Icons.fingerprint),
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
                      controller: conversationIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Conversation ID (optional)',
                        prefixIcon: Icon(Icons.chat),
                      ),
                    ),
                  ],
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
              icon: const Icon(Icons.send),
              label: const Text('Send'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final notification = NvpNotification(
      title: titleCtrl.text,
      body: bodyCtrl.text,
      groupKey: useGroup ? groupCtrl.text : null,
      senderName:
          senderCtrl.text.isNotEmpty ? senderCtrl.text : null,
      tag: tagCtrl.text.isNotEmpty ? tagCtrl.text : null,
      channelId:
          channelIdCtrl.text.isNotEmpty ? channelIdCtrl.text : null,
      channelName:
          channelNameCtrl.text.isNotEmpty ? channelNameCtrl.text : null,
      senderId:
          senderIdCtrl.text.isNotEmpty ? senderIdCtrl.text : null,
      senderAvatar:
          senderAvatarCtrl.text.isNotEmpty ? senderAvatarCtrl.text : null,
      conversationId: conversationIdCtrl.text.isNotEmpty
          ? conversationIdCtrl.text
          : null,
    );

    final template = _buildTemplate(
      selectedType,
      expandedCtrl.text,
      imageCtrl.text,
      progressCtrl.text,
      useActions,
    );

    final ok = await NotificationVoipPlugin.showNotification(
      notification,
      template: template,
    );
    log('${selectedType.name}: $ok', Icons.notifications, Colors.blue);
  }

  static NvpNotificationTemplate? _buildTemplate(
    NvpNotificationTemplateType type,
    String expandedText,
    String imageUrl,
    String progressText,
    bool useActions,
  ) {
    switch (type) {
      case NvpNotificationTemplateType.normal:
        return null;
      case NvpNotificationTemplateType.bigText:
        return NvpNotificationTemplate(
          type: type,
          expandedText: expandedText,
        );
      case NvpNotificationTemplateType.bigPicture:
        return NvpNotificationTemplate(type: type, imageUrl: imageUrl);
      case NvpNotificationTemplateType.bigBanner:
        return NvpNotificationTemplate(
          type: type,
          imageUrl: imageUrl,
          expandedText: expandedText,
        );
      case NvpNotificationTemplateType.richText:
        return NvpNotificationTemplate(
          type: type,
          expandedText: expandedText,
        );
      case NvpNotificationTemplateType.progress:
        return NvpNotificationTemplate(
          type: type,
          progressValue: int.tryParse(progressText) ?? 65,
        );
      case NvpNotificationTemplateType.interactive:
        return NvpNotificationTemplate(
          type: type,
          actions: useActions
              ? const [
                  NvpNotificationAction(
                    id: 'reply',
                    title: 'Reply',
                    isTextInput: true,
                    textInputPlaceholder: 'Type a reply...',
                  ),
                  NvpNotificationAction(id: 'mark_read', title: 'Mark Read'),
                ]
              : const [NvpNotificationAction(id: 'ok', title: 'OK')],
        );
      case NvpNotificationTemplateType.custom:
        return NvpNotificationTemplate(
          type: type,
          customLayoutName: 'custom_layout',
        );
    }
  }
}
