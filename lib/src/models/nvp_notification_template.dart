import 'nvp_notification_action.dart';

/// Notification template types.
enum NvpNotificationTemplateType {
  normal,
  richText,
  bigText,
  bigPicture,
  bigBanner,
  progress,
  interactive,
  custom,
}

/// Notification template configuration.
class NvpNotificationTemplate {
  final NvpNotificationTemplateType type;
  final String? expandedText;
  final String? imageUrl;
  final String? summaryText;
  final int? progressValue;
  final int progressMax;
  final bool progressIndeterminate;
  final List<NvpNotificationAction>? actions;
  final String? customLayoutName;
  final Map<String, dynamic>? customLayoutData;
  final String? iosCategoryIdentifier;

  static const normal =
      NvpNotificationTemplate(type: NvpNotificationTemplateType.normal);

  const NvpNotificationTemplate({
    required this.type,
    this.expandedText,
    this.imageUrl,
    this.summaryText,
    this.progressValue,
    this.progressMax = 100,
    this.progressIndeterminate = false,
    this.actions,
    this.customLayoutName,
    this.customLayoutData,
    this.iosCategoryIdentifier,
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        if (expandedText != null) 'expandedText': expandedText,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (summaryText != null) 'summaryText': summaryText,
        if (progressValue != null) 'progressValue': progressValue,
        'progressMax': progressMax,
        'progressIndeterminate': progressIndeterminate,
        if (actions != null)
          'actions': actions!.map((a) => a.toMap()).toList(),
        if (customLayoutName != null) 'customLayoutName': customLayoutName,
        if (customLayoutData != null) 'customLayoutData': customLayoutData,
        if (iosCategoryIdentifier != null)
          'iosCategoryIdentifier': iosCategoryIdentifier,
      };
}
