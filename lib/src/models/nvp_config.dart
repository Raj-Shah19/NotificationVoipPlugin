import 'nvp_payload_keys.dart';
import 'nvp_notification_template.dart';
import 'nvp_call_screen_config.dart';
import '../nvp_callbacks.dart';

/// Plugin configuration. Pass to `NotificationVoipPlugin.init()`.
class NvpConfig {
  final String? appName;
  final Duration bannerDuration;
  final NvpPayloadKeys payloadKeys;
  final String channelId;
  final String channelName;
  final NvpNotificationTemplate defaultTemplate;
  final NvpCallScreenConfig callScreenConfig;
  final String? defaultGroupKey;

  // Overrideable callbacks
  final NvpBannerTapCallback? onBannerTap;
  final NvpBannerDismissCallback? onBannerDismiss;
  final NvpSystemNotificationTapCallback? onSystemNotificationTap;
  final NvpCallAnsweredCallback? onCallAnswered;
  final NvpCallDeclinedCallback? onCallDeclined;
  final NvpCallEndedCallback? onCallEnded;
  final NvpCallIncomingCallback? onCallIncoming;
  final NvpCallTimeoutEndedCallback? onCallTimeoutEnded;
  final NvpCallStateChangedCallback? onCallStateChanged;
  final NvpTokenRefreshCallback? onTokenRefresh;
  final NvpPushReceivedCallback? onPushReceived;
  final NvpChatPayloadCallback? onChatPayload;
  final NvpCallPayloadCallback? onCallPayload;

  const NvpConfig({
    this.appName,
    this.bannerDuration = const Duration(seconds: 5),
    this.payloadKeys = const NvpPayloadKeys(),
    this.channelId = 'default_channel',
    this.channelName = 'Default Channel',
    this.defaultTemplate = NvpNotificationTemplate.normal,
    this.callScreenConfig = const NvpCallScreenConfig(),
    this.defaultGroupKey,
    this.onBannerTap,
    this.onBannerDismiss,
    this.onSystemNotificationTap,
    this.onCallAnswered,
    this.onCallDeclined,
    this.onCallEnded,
    this.onCallIncoming,
    this.onCallTimeoutEnded,
    this.onCallStateChanged,
    this.onTokenRefresh,
    this.onPushReceived,
    this.onChatPayload,
    this.onCallPayload,
  });

  Map<String, dynamic> toMap() => {
        if (appName != null) 'appName': appName,
        'bannerDuration': bannerDuration.inMilliseconds,
        'payloadKeys': payloadKeys.toMap(),
        'channelId': channelId,
        'channelName': channelName,
        'defaultTemplate': defaultTemplate.toMap(),
        'useNativeCallScreen': callScreenConfig.useNativeCallScreen,
        if (defaultGroupKey != null) 'defaultGroupKey': defaultGroupKey,
      };
}
