/// Notification data model.
class NvpNotification {
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final String? senderId;
  final String? senderName;
  final String? senderAvatar;
  final String? receiverId;
  final String? receiverName;
  final String? receiverType;
  final String? conversationId;
  final String? tag;
  final int? unreadMessageCount;
  final String? channelId;
  final String? channelName;
  final String? groupKey;

  /// Custom notification sound. Platform-specific:
  /// - iOS: name of a sound file in the app bundle (e.g. `'alert'`)
  /// - Android: name of a raw resource (e.g. `'notification_sound'`)
  /// Pass `null` for the system default sound.
  final String? sound;

  const NvpNotification({
    required this.title,
    required this.body,
    this.imageUrl,
    this.data = const {},
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.receiverId,
    this.receiverName,
    this.receiverType,
    this.conversationId,
    this.tag,
    this.unreadMessageCount,
    this.channelId,
    this.channelName,
    this.groupKey,
    this.sound,
  });

  factory NvpNotification.fromMap(Map<String, dynamic> map) {
    return NvpNotification(
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      data: map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : const {},
      senderId: map['senderId'] as String?,
      senderName: map['senderName'] as String?,
      senderAvatar: map['senderAvatar'] as String?,
      receiverId: map['receiverId'] as String?,
      receiverName: map['receiverName'] as String?,
      receiverType: map['receiverType'] as String?,
      conversationId: map['conversationId'] as String?,
      tag: map['tag'] as String?,
      unreadMessageCount: map['unreadMessageCount'] as int?,
      channelId: map['channelId'] as String?,
      channelName: map['channelName'] as String?,
      groupKey: map['groupKey'] as String?,
      sound: map['sound'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'data': data,
        if (senderId != null) 'senderId': senderId,
        if (senderName != null) 'senderName': senderName,
        if (senderAvatar != null) 'senderAvatar': senderAvatar,
        if (receiverId != null) 'receiverId': receiverId,
        if (receiverName != null) 'receiverName': receiverName,
        if (receiverType != null) 'receiverType': receiverType,
        if (conversationId != null) 'conversationId': conversationId,
        if (tag != null) 'tag': tag,
        if (unreadMessageCount != null)
          'unreadMessageCount': unreadMessageCount,
        if (channelId != null) 'channelId': channelId,
        if (channelName != null) 'channelName': channelName,
        if (groupKey != null) 'groupKey': groupKey,
        if (sound != null) 'sound': sound,
      };

  /// Returns a copy with the given fields replaced.
  NvpNotification copyWith({
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? receiverId,
    String? receiverName,
    String? receiverType,
    String? conversationId,
    String? tag,
    int? unreadMessageCount,
    String? channelId,
    String? channelName,
    String? groupKey,
    String? sound,
  }) {
    return NvpNotification(
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverType: receiverType ?? this.receiverType,
      conversationId: conversationId ?? this.conversationId,
      tag: tag ?? this.tag,
      unreadMessageCount: unreadMessageCount ?? this.unreadMessageCount,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      groupKey: groupKey ?? this.groupKey,
      sound: sound ?? this.sound,
    );
  }
}
