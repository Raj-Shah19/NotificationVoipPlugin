/// Action button for interactive notifications.
class NvpNotificationAction {
  final String id;
  final String title;
  final bool foreground;
  final bool isTextInput;
  final String? textInputPlaceholder;

  const NvpNotificationAction({
    required this.id,
    required this.title,
    this.foreground = true,
    this.isTextInput = false,
    this.textInputPlaceholder,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'foreground': foreground,
        'isTextInput': isTextInput,
        if (textInputPlaceholder != null)
          'textInputPlaceholder': textInputPlaceholder,
      };

  factory NvpNotificationAction.fromMap(Map<String, dynamic> map) {
    return NvpNotificationAction(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      foreground: map['foreground'] as bool? ?? true,
      isTextInput: map['isTextInput'] as bool? ?? false,
      textInputPlaceholder: map['textInputPlaceholder'] as String?,
    );
  }
}
