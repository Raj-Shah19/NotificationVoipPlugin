/// Configurable payload key mapping for push notification data extraction.
class NvpPayloadKeys {
  final String detailsPath;
  final String titleKey;
  final String bodyKey;
  final String typeKey;
  final String senderNameKey;
  final String senderAvatarKey;
  final String senderIdKey;
  final String callActionKey;
  final String sessionIdKey;
  final String callTypeKey;
  final String badgeCountKey;
  final String conversationIdKey;
  final String tagKey;
  final String receiverAvatarKey;

  const NvpPayloadKeys({
    this.detailsPath = 'data.notificationDetails',
    this.titleKey = 'title',
    this.bodyKey = 'body',
    this.typeKey = 'type',
    this.senderNameKey = 'senderName',
    this.senderAvatarKey = 'senderAvatar',
    this.senderIdKey = 'sender',
    this.callActionKey = 'callAction',
    this.sessionIdKey = 'sessionId',
    this.callTypeKey = 'callType',
    this.badgeCountKey = 'unreadMessageCount',
    this.conversationIdKey = 'conversationId',
    this.tagKey = 'tag',
    this.receiverAvatarKey = 'receiverAvatar',
  });

  Map<String, dynamic> toMap() => {
        'detailsPath': detailsPath,
        'titleKey': titleKey,
        'bodyKey': bodyKey,
        'typeKey': typeKey,
        'senderNameKey': senderNameKey,
        'senderAvatarKey': senderAvatarKey,
        'senderIdKey': senderIdKey,
        'callActionKey': callActionKey,
        'sessionIdKey': sessionIdKey,
        'callTypeKey': callTypeKey,
        'badgeCountKey': badgeCountKey,
        'conversationIdKey': conversationIdKey,
        'tagKey': tagKey,
        'receiverAvatarKey': receiverAvatarKey,
      };
}
