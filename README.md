# notification_voip_plugin

A Flutter plugin for notifications and VoIP calls across Android, iOS, Web, macOS, Windows, and Linux.

[![pub package](https://img.shields.io/pub/v/notification_voip_plugin.svg)](https://pub.dev/packages/notification_voip_plugin)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## What It Does

This plugin gives you a single Dart API to handle:

- **System notifications** with 8 visual templates (big text, big picture, progress bar, action buttons, and more)
- **In-app banner overlays** that slide in from the top
- **VoIP calls** with native call UI (CallKit on iOS, ConnectionService on Android) or a custom Flutter call screen
- **Push tokens** (FCM, APNs, VoIP via PushKit)
- **Badge count** management
- **Live Activities** on iOS (Dynamic Island / Lock Screen) — experimental

Everything is accessed through `NotificationVoipPlugin.*` — no instances, no singletons, no boilerplate.

---

## Platform Support

| Feature | Android | iOS | macOS | Windows | Linux | Web |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| System Notifications | ✅ | ✅ | ✅ | stub | stub | ✅ |
| In-App Banners | ✅ | ✅ | — | — | — | — |
| Notification Templates | ✅ | ✅ | — | — | — | — |
| VoIP Calls (Native UI) | ✅ | ✅ | — | — | — | — |
| Custom Call Screen | ✅ | ✅ | — | — | — | — |
| Badge Count | ✅ | ✅ | ✅ | — | — | — |
| FCM Token | ✅ | — | — | — | — | — |
| APNs Token | — | ✅ | — | — | — | — |
| VoIP Token | — | ✅ | — | — | — | — |
| Live Activities ⚠️ | — | ✅ (16.2+) | — | — | — | — |
| Phone Account Check | ✅ | — | — | — | — | — |

---

## Quick Start

### 1. Install

```yaml
dependencies:
  notification_voip_plugin: ^2.0.0
```

```bash
flutter pub get
```

### 2. Initialize

```dart
import 'package:notification_voip_plugin/notification_voip_plugin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationVoipPlugin.init(
    const NvpConfig(
      appName: 'My App',
      channelId: 'my_channel',
      channelName: 'My Channel',
    ),
  );
  runApp(const MyApp());
}
```

`NvpConfig` is optional — `init()` works with sensible defaults.

### 3. Request Permission

```dart
final granted = await NotificationVoipPlugin.requestPermission();
```

### 4. Show a Notification

```dart
await NotificationVoipPlugin.showNotification(
  const NvpNotification(title: 'Hello', body: 'World'),
);
```

That's it. You're up and running.

---

## Setup

### Android

**Minimum SDK** — set `minSdk 24` in `android/app/build.gradle`:

```groovy
android {
    defaultConfig {
        minSdk = 24
    }
}
```

**Firebase (for FCM tokens)** — add Google Services plugin to `android/build.gradle`:

```groovy
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

Apply it in `android/app/build.gradle`:

```groovy
apply plugin: 'com.google.gms.google-services'
```

Place your `google-services.json` in `android/app/`.

**Permissions** — the plugin's manifest already declares all required permissions (merged automatically):

```
POST_NOTIFICATIONS, MANAGE_OWN_CALLS, FOREGROUND_SERVICE,
RECORD_AUDIO, BLUETOOTH, BLUETOOTH_ADMIN, READ_PHONE_STATE,
READ_PHONE_NUMBERS, ANSWER_PHONE_CALLS
```

No additional manifest entries needed.

**Phone Account (VoIP)** — on Android, the user must enable the VoIP phone account in system settings before incoming calls work:

```dart
final enabled = await NotificationVoipPlugin.isPhoneAccountEnabled();
if (!enabled) {
  await NotificationVoipPlugin.openPhoneAccountSettings();
}
```

### iOS

**Deployment Target** — iOS 14.0+ in your `ios/Podfile`:

```ruby
platform :ios, '14.0'
```

**Xcode Capabilities** — enable on your Runner target:
- Push Notifications
- Background Modes → check "Voice over IP" and "Remote notifications"

**Info.plist** — add:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>voip</string>
    <string>remote-notification</string>
</array>
```

**APNs Token Forwarding** — in `AppDelegate.swift`:

```swift
import notification_voip_plugin

override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    NotificationVoipPlugin.shared?.setAPNsToken(deviceToken)
}
```

---

## Usage

### Notifications

**Simple notification:**

```dart
await NotificationVoipPlugin.showNotification(
  const NvpNotification(title: 'Hello', body: 'World'),
);
```

**With a template:**

```dart
// Big text (expandable)
await NotificationVoipPlugin.showNotification(
  const NvpNotification(title: 'Article', body: 'Preview...'),
  template: const NvpNotificationTemplate(
    type: NvpNotificationTemplateType.bigText,
    expandedText: 'Full article text that expands when pulled down.',
  ),
);

// Big picture
await NotificationVoipPlugin.showNotification(
  const NvpNotification(title: 'Photo', body: 'New photo shared'),
  template: const NvpNotificationTemplate(
    type: NvpNotificationTemplateType.bigPicture,
    imageUrl: 'https://example.com/photo.jpg',
  ),
);

// Progress bar
await NotificationVoipPlugin.showNotification(
  const NvpNotification(title: 'Download', body: 'Downloading...', tag: 'dl-1'),
  template: const NvpNotificationTemplate(
    type: NvpNotificationTemplateType.progress,
    progressValue: 65,
    progressMax: 100,
  ),
);
```

**Interactive (action buttons + text input):**

```dart
await NotificationVoipPlugin.showNotification(
  const NvpNotification(title: 'New Message', body: 'Hey!'),
  template: const NvpNotificationTemplate(
    type: NvpNotificationTemplateType.interactive,
    actions: [
      NvpNotificationAction(id: 'reply', title: 'Reply', isTextInput: true, textInputPlaceholder: 'Type a reply...'),
      NvpNotificationAction(id: 'mark_read', title: 'Mark Read'),
    ],
  ),
);
```

**Grouped notifications:**

```dart
await NotificationVoipPlugin.showNotification(
  const NvpNotification(title: 'Chat', body: 'New message', groupKey: 'chat-group'),
);
```

**In-app banner overlay:**

```dart
await NotificationVoipPlugin.showInAppNotification(
  const NvpNotification(title: 'Alert', body: 'This is a banner overlay'),
);
```

**Available template types:** `normal`, `richText`, `bigText`, `bigPicture`, `bigBanner`, `progress`, `interactive`, `custom`

### Badge Count

```dart
await NotificationVoipPlugin.setBadgeCount(5);
final count = await NotificationVoipPlugin.getBadgeCount();
await NotificationVoipPlugin.setBadgeCount(0); // clear
```

### Push Tokens

```dart
final pushToken = await NotificationVoipPlugin.getPushToken();   // FCM on Android, APNs on iOS
final fcmToken  = await NotificationVoipPlugin.getFCMToken();    // Android only
final apnsToken = await NotificationVoipPlugin.getAPNsToken();   // iOS only
final voipToken = await NotificationVoipPlugin.getVoIPToken();   // iOS only
```

### VoIP Calls

**Incoming call (native UI):**

```dart
try {
  await NotificationVoipPlugin.showIncomingCall(
    const NvpCallConfig(
      callId: 'session-123',
      callerName: 'John Doe',
      isVideo: true,
    ),
  );
} on PlatformException catch (e) {
  if (e.code == 'PHONE_ACCOUNT_NOT_ENABLED') {
    await NotificationVoipPlugin.openPhoneAccountSettings();
  }
}
```

**Incoming call (custom Flutter screen):**

```dart
await NotificationVoipPlugin.showIncomingCall(
  const NvpCallConfig(
    callId: 'session-123',
    callerName: 'John Doe',
    isVideo: false,
    useNativeScreen: false,
  ),
);
```

**Outgoing call:**

```dart
await NotificationVoipPlugin.showOutgoingCall(
  const NvpCallConfig(
    callId: 'session-456',
    callerName: 'Jane Doe',
    isOutgoing: true,
  ),
);
```

**Call controls:**

```dart
await NotificationVoipPlugin.toggleMute('session-123');
await NotificationVoipPlugin.toggleSpeaker('session-123');
await NotificationVoipPlugin.toggleCamera('session-123');
await NotificationVoipPlugin.endCall('session-123');
await NotificationVoipPlugin.endAllCalls(); // cleanup on logout
```

**Deferred connection (e.g., after WebRTC setup):**

```dart
await NotificationVoipPlugin.setCallConnected('session-123');
```

### Custom Call Screen Widget

The plugin includes a ready-to-use `NvpCallScreen` widget:

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => NvpCallScreen(
    event: NvpCallEvent(action: NvpCallAction.incoming, callId: 'session-123', callerName: 'John'),
    controller: NvpCallScreenController(callId: 'session-123'),
  ),
));
```

`NvpCallScreenController` methods:

| Method | Returns | Description |
|---|---|---|
| `accept()` | `Future<void>` | Accept incoming call |
| `reject()` | `Future<void>` | Reject incoming call |
| `end()` | `Future<void>` | End current call |
| `toggleMute()` | `Future<bool>` | Toggle mute, returns new state |
| `toggleSpeaker()` | `Future<bool>` | Toggle speaker, returns new state |
| `toggleCamera()` | `Future<bool>` | Toggle camera, returns new state |

State getters: `isMuted`, `isSpeakerOn`, `isCameraOn`

If a platform call fails, the controller automatically rolls back the local state.

### Event Streams

```dart
// Notification tapped (system or in-app banner)
NotificationVoipPlugin.onNotificationTap.listen((NvpNotification n) {
  print('Tapped: ${n.title}');
});

// VoIP call events (accept, decline, ended, incoming, timeoutEnded)
NotificationVoipPlugin.onCallEvent.listen((NvpCallEvent e) {
  print('Call: ${e.action} (${e.callId})');
});

// Real-time call state changes (mute, speaker, status)
NotificationVoipPlugin.onCallStateChanged.listen((NvpCallState s) {
  print('State: ${s.status.name} muted=${s.isMuted}');
});

// Push token refreshed
NotificationVoipPlugin.onTokenRefresh.listen((String token) {
  print('New token: $token');
});

// Push received in foreground (iOS) — inspect and optionally suppress
NotificationVoipPlugin.onPushReceived.listen((Map<String, dynamic> payload) {
  if (payload['conversationId'] == activeConversationId) {
    NotificationVoipPlugin.suppressNextForegroundNotification();
  }
});
```

### Callbacks via NvpConfig

As an alternative to streams, register callbacks directly in `NvpConfig`:

```dart
await NotificationVoipPlugin.init(
  NvpConfig(
    appName: 'My App',
    onBannerTap: (notification) => print('Banner: ${notification.title}'),
    onSystemNotificationTap: (notification) => print('Tapped: ${notification.title}'),
    onCallAnswered: (event) => print('Answered: ${event.callId}'),
    onCallDeclined: (event) => print('Declined: ${event.callId}'),
    onCallEnded: (event) => print('Ended: ${event.callId}'),
    onCallIncoming: (event) => print('Incoming: ${event.callId}'),
    onCallTimeoutEnded: (event) => print('Timeout: ${event.callId}'),
    onCallStateChanged: (state) => print('State: ${state.status.name}'),
    onTokenRefresh: (token) => print('Token: $token'),
    onPushReceived: (payload) => print('Push: $payload'),
  ),
);
```

### Live Activities (iOS 16.1+) — ⚠️ Experimental

> This feature is experimental. The API may change in future releases.

**Setup:**
1. In Xcode: File → New → Target → Widget Extension
2. Add `NSSupportsLiveActivities = YES` to `Runner/Info.plist`
3. Copy the example widget from `ios/WidgetExtensionExample/NvpLiveActivityWidget.swift`
4. Set Widget Extension deployment target to iOS 16.1+

**Usage:**

```dart
// Check support
final enabled = await NotificationVoipPlugin.areLiveActivitiesEnabled();

// Start
await NotificationVoipPlugin.startLiveActivity(
  const NvpLiveActivity(tag: 'download-1', title: 'Downloading...', progress: 0.0),
);

// Update
await NotificationVoipPlugin.updateLiveActivity(
  const NvpLiveActivity(tag: 'download-1', title: 'Downloading...', body: '25/50 MB', progress: 0.5),
);

// End
await NotificationVoipPlugin.endLiveActivity('download-1');
await NotificationVoipPlugin.endAllLiveActivities();
```

### Cleanup

```dart
await NotificationVoipPlugin.dispose();
```

This cancels all stream subscriptions, clears cached streams, and releases native resources. The plugin can be re-initialized after dispose.

---

## API Reference

### Initialization & Lifecycle

| Method | Description |
|---|---|
| `init([NvpConfig? config])` | Initialize the plugin. Call once at app start. |
| `dispose()` | Clean up all resources and cancel subscriptions. |
| `config` | Current plugin configuration (getter). |

### Permissions

| Method | Description |
|---|---|
| `requestPermission()` → `Future<bool>` | Request notification permission. Returns `true` if granted. |
| `isPermissionGranted()` → `Future<bool>` | Check if notifications are enabled. |
| `openSettings()` | Open OS notification settings for this app. |

### Tokens

| Method | Description |
|---|---|
| `getPushToken()` → `Future<String?>` | Platform push token (FCM on Android, APNs on iOS). |
| `getFCMToken()` → `Future<String?>` | Firebase Cloud Messaging token (Android). |
| `getAPNsToken()` → `Future<String?>` | APNs device token (iOS). |
| `getVoIPToken()` → `Future<String?>` | VoIP push token via PushKit (iOS). |

### Notifications

| Method | Description |
|---|---|
| `showNotification(NvpNotification, {NvpNotificationTemplate?})` → `Future<bool>` | Show a system notification. |
| `showInAppNotification(NvpNotification, {NvpNotificationTemplate?})` → `Future<bool>` | Show an in-app banner overlay. |
| `cancelNotification(String tag)` | Cancel a specific notification by tag. |
| `clearAll()` | Clear all notifications and dismiss banners. |
| `suppressNextForegroundNotification()` | Suppress the next foreground notification (iOS). |

### Badge

| Method | Description |
|---|---|
| `setBadgeCount(int count)` | Set app badge count. Pass `0` to clear. |
| `getBadgeCount()` → `Future<int>` | Get current badge count. |

### VoIP / Calls

| Method | Description |
|---|---|
| `showIncomingCall(NvpCallConfig)` | Show incoming call UI. Throws `PHONE_ACCOUNT_NOT_ENABLED` on Android if needed. |
| `showOutgoingCall(NvpCallConfig)` | Show outgoing call UI. |
| `endCall(String callId)` | End a call by session ID. |
| `endAllCalls()` | End all active calls. |
| `setCallConnected(String callId)` | Mark a call as connected (for deferred connection flows). |
| `getActiveCallIds()` → `Future<List<String>>` | Get list of active call IDs. |
| `toggleMute(String callId)` | Toggle mute. |
| `toggleSpeaker(String callId)` | Toggle speaker. |
| `toggleCamera(String callId)` | Toggle camera. |

### Android-Only

| Method | Description |
|---|---|
| `isPhoneAccountEnabled()` → `Future<bool>` | Check if VoIP phone account is enabled. |
| `openPhoneAccountSettings()` | Open phone account settings. |

### Live Activities (iOS) — ⚠️ Experimental

| Method | Description |
|---|---|
| `areLiveActivitiesEnabled()` → `Future<bool>` | Check if Live Activities are supported. |
| `startLiveActivity(NvpLiveActivity)` → `Future<Map?>` | Start a Live Activity. |
| `updateLiveActivity(NvpLiveActivity)` → `Future<bool>` | Update by tag. |
| `endLiveActivity(String tag)` → `Future<bool>` | End by tag. |
| `endAllLiveActivities()` → `Future<bool>` | End all. |

### Event Streams

| Stream | Type | Description |
|---|---|---|
| `onNotificationTap` | `Stream<NvpNotification>` | User tapped a notification. |
| `onCallEvent` | `Stream<NvpCallEvent>` | Call lifecycle events (accept, decline, ended, incoming, timeoutEnded). |
| `onCallStateChanged` | `Stream<NvpCallState>` | Real-time call state changes. |
| `onTokenRefresh` | `Stream<String>` | Push token refreshed. |
| `onPushReceived` | `Stream<Map<String, dynamic>>` | Foreground push received (iOS). |

---

## Models

### NvpConfig

Plugin configuration passed to `init()`.

| Field | Type | Default | Description |
|---|---|---|---|
| `appName` | `String?` | `null` | App name for CallKit / ConnectionService display. |
| `bannerDuration` | `Duration` | `5 seconds` | How long in-app banners stay visible. |
| `payloadKeys` | `NvpPayloadKeys` | defaults | Key mapping for push payload extraction. |
| `channelId` | `String` | `'default_channel'` | Android notification channel ID. |
| `channelName` | `String` | `'Default Channel'` | Android notification channel name. |
| `defaultTemplate` | `NvpNotificationTemplate` | `normal` | Default notification template. |
| `callScreenConfig` | `NvpCallScreenConfig` | defaults | Call screen customization. |
| `defaultGroupKey` | `String?` | `null` | Default group key for notifications. |

Plus 13 optional callbacks: `onBannerTap`, `onBannerDismiss`, `onSystemNotificationTap`, `onCallAnswered`, `onCallDeclined`, `onCallEnded`, `onCallIncoming`, `onCallTimeoutEnded`, `onCallStateChanged`, `onTokenRefresh`, `onPushReceived`, `onChatPayload`, `onCallPayload`.

### NvpNotification

| Field | Type | Description |
|---|---|---|
| `title` | `String` | Notification title (required). |
| `body` | `String` | Notification body (required). |
| `imageUrl` | `String?` | Image / avatar URL. |
| `data` | `Map<String, dynamic>` | Custom data payload. |
| `senderId` | `String?` | Sender identifier. |
| `senderName` | `String?` | Sender display name. |
| `senderAvatar` | `String?` | Sender avatar URL. |
| `receiverId` | `String?` | Receiver identifier. |
| `receiverName` | `String?` | Receiver display name. |
| `receiverType` | `String?` | Receiver type (user, group, etc.). |
| `conversationId` | `String?` | Conversation / thread identifier. |
| `tag` | `String?` | Unique tag for in-place updates and cancellation. |
| `unreadMessageCount` | `int?` | Badge number on the notification. |
| `channelId` | `String?` | Android channel ID override. |
| `channelName` | `String?` | Android channel name override. |
| `groupKey` | `String?` | Group key for notification bundling. |
| `sound` | `String?` | Custom sound (iOS: bundle file name, Android: raw resource name). |

Includes `fromMap()`, `toMap()`, and `copyWith()`.

### NvpNotificationTemplate

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | `NvpNotificationTemplateType` | — | Template type (required). |
| `expandedText` | `String?` | `null` | Expanded text for `bigText` / `richText`. |
| `imageUrl` | `String?` | `null` | Image URL for `bigPicture` / `bigBanner`. |
| `summaryText` | `String?` | `null` | Summary text for `bigBanner`. |
| `progressValue` | `int?` | `null` | Current progress value. |
| `progressMax` | `int` | `100` | Maximum progress value. |
| `progressIndeterminate` | `bool` | `false` | Show indeterminate progress bar. |
| `actions` | `List<NvpNotificationAction>?` | `null` | Action buttons for `interactive`. |
| `customLayoutName` | `String?` | `null` | Android custom XML layout name. |
| `customLayoutData` | `Map?` | `null` | Data for custom layout. |
| `iosCategoryIdentifier` | `String?` | `null` | iOS notification category identifier. |

**Template types:** `normal`, `richText`, `bigText`, `bigPicture`, `bigBanner`, `progress`, `interactive`, `custom`

### NvpNotificationAction

| Field | Type | Default | Description |
|---|---|---|---|
| `id` | `String` | — | Unique action identifier. |
| `title` | `String` | — | Button label. |
| `foreground` | `bool` | `true` | Bring app to foreground on tap. |
| `isTextInput` | `bool` | `false` | Show text input field. |
| `textInputPlaceholder` | `String?` | `null` | Placeholder for text input. |

### NvpCallConfig

| Field | Type | Default | Description |
|---|---|---|---|
| `callId` | `String` | — | Unique call session ID (required). |
| `callerName` | `String` | — | Caller display name (required). |
| `callerAvatar` | `String?` | `null` | Caller avatar URL. |
| `isVideo` | `bool` | `false` | Video call. |
| `isOutgoing` | `bool` | `false` | Outgoing call. |
| `useNativeScreen` | `bool` | `true` | Use native UI vs custom Flutter screen. |
| `duration` | `int?` | `null` | Auto-dismiss timeout in seconds. |
| `ringtone` | `String?` | `null` | Custom ringtone (iOS: bundle file, Android: raw resource). |
| `extra` | `Map<String, dynamic>` | `{}` | Extra data. |

Includes `fromMap()`, `toMap()`, and `copyWith()`.

### NvpCallEvent

| Field | Type | Description |
|---|---|---|
| `action` | `NvpCallAction?` | `accept`, `decline`, `ended`, `incoming`, `timeoutEnded` |
| `callId` | `String` | Call session ID. |
| `callerName` | `String?` | Caller display name. |
| `callerAvatar` | `String?` | Caller avatar URL. |
| `isVideo` | `bool` | Video call. |
| `callType` | `String?` | Call type identifier. |
| `conversationId` | `String?` | Associated conversation ID. |
| `payload` | `Map<String, dynamic>` | Extra event data. |

### NvpCallState

| Field | Type | Description |
|---|---|---|
| `callId` | `String` | Call session ID. |
| `status` | `NvpCallStatus` | `ringing`, `connected`, `onHold`, `ended` |
| `isMuted` | `bool` | Microphone muted. |
| `isSpeakerOn` | `bool` | Speaker on. |
| `isCameraOn` | `bool` | Camera on. |
| `connectedAt` | `DateTime?` | When the call was connected. |
| `extra` | `Map<String, dynamic>` | Extra state data. |

### NvpCallScreenConfig

| Field | Type | Default | Description |
|---|---|---|---|
| `useNativeCallScreen` | `bool` | `true` | Native UI vs custom Flutter screen. |
| `callScreenBuilder` | `Widget Function(NvpCallEvent, NvpCallScreenController)?` | `null` | Custom call screen builder. |
| `backgroundColor` | `Color?` | `null` | Call screen background color. |
| `avatarPlaceholder` | `Widget?` | `null` | Placeholder for caller avatar. |
| `onCallInitiated` | `Function?` | `null` | Called when a call is initiated. |
| `onMuteToggled` | `Function?` | `null` | Called when mute is toggled. |
| `onSpeakerToggled` | `Function?` | `null` | Called when speaker is toggled. |
| `onCameraToggled` | `Function?` | `null` | Called when camera is toggled. |

### NvpPayloadKeys

Configurable key mapping so the plugin works with any backend push payload format.

| Field | Default | Description |
|---|---|---|
| `detailsPath` | `'data.notificationDetails'` | Dot-path to notification details in payload. |
| `titleKey` | `'title'` | Key for notification title. |
| `bodyKey` | `'body'` | Key for notification body. |
| `typeKey` | `'type'` | Key for notification type. |
| `senderNameKey` | `'senderName'` | Key for sender name. |
| `senderAvatarKey` | `'senderAvatar'` | Key for sender avatar URL. |
| `senderIdKey` | `'sender'` | Key for sender ID. |
| `callActionKey` | `'callAction'` | Key for call action. |
| `sessionIdKey` | `'sessionId'` | Key for call session ID. |
| `callTypeKey` | `'callType'` | Key for call type. |
| `badgeCountKey` | `'unreadMessageCount'` | Key for badge count. |
| `conversationIdKey` | `'conversationId'` | Key for conversation ID. |
| `tagKey` | `'tag'` | Key for notification tag. |
| `receiverAvatarKey` | `'receiverAvatar'` | Key for receiver avatar URL. |

### NvpLiveActivity — ⚠️ Experimental

| Field | Type | Default | Description |
|---|---|---|---|
| `tag` | `String` | — | Unique identifier (required). |
| `title` | `String` | `''` | Title for Dynamic Island / Lock Screen. |
| `body` | `String` | `''` | Body text. |
| `progress` | `double` | `0.0` | Progress (0.0 – 1.0). |
| `icon` | `String?` | `null` | SF Symbol name. |
| `data` | `Map<String, String>` | `{}` | Extra data for Widget Extension. |

---

## Callback Types

```dart
typedef NvpBannerTapCallback = void Function(NvpNotification notification);
typedef NvpBannerDismissCallback = void Function(NvpNotification notification);
typedef NvpSystemNotificationTapCallback = void Function(NvpNotification notification);
typedef NvpCallAnsweredCallback = void Function(NvpCallEvent event);
typedef NvpCallDeclinedCallback = void Function(NvpCallEvent event);
typedef NvpCallEndedCallback = void Function(NvpCallEvent event);
typedef NvpCallIncomingCallback = void Function(NvpCallEvent event);
typedef NvpCallTimeoutEndedCallback = void Function(NvpCallEvent event);
typedef NvpCallStateChangedCallback = void Function(NvpCallState state);
typedef NvpTokenRefreshCallback = void Function(String token);
typedef NvpPushReceivedCallback = void Function(Map<String, dynamic> payload);
typedef NvpChatPayloadCallback = void Function(NvpNotification notification);
typedef NvpCallPayloadCallback = void Function(NvpCallEvent event);
```

---

## Example App

A full example app is included in the `example/` directory:

```bash
cd example
flutter run
```

---

## Contributing

Contributions are welcome. Please open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

## License

MIT — see [LICENSE](LICENSE) for details.
