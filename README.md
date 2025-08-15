
```markdown
# notification_voip_plugin

A Flutter plugin for handling notifications and VoIP events on **Android** and **iOS**.

## Features

- Retrieve FCM, APNs, and VoIP tokens
- Request and check notification permissions
- Show in-app and background notifications
- Listen for notification tap and VoIP events
- Manage phone account and VoIP call actions (Android/iOS)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  notification_voip_plugin: ^<latest_version>
```

Then run:

```sh
flutter pub get
```

## Platform Support

| Method                                 | Android | iOS   |
|-----------------------------------------|:-------:|:-----:|
| getFCMToken                            |   ✅    |  ✅   |
| getAPNsToken                           |         |  ✅   |
| getVoIPToken                           |         |  ✅   |
| requestNotificationPermissions          |   ✅    |  ✅   |
| areNotificationsEnabled                |   ✅    |  ✅   |
| openNotificationSettings               |   ✅    |  ✅   |
| showInAppNotification                  |   ✅    |  ✅   |
| showBackgroundNotification             |   ✅    |  ✅   |
| onNotificationTap                      |   ✅    |  ✅   |
| onCallActionEvents                     |   ✅    |  ✅   |
| isPhoneAccountEnabled                  |   ✅    |       |
| openPhoneAccountSettings               |   ✅    |       |
| registerPhoneAccount                   |   ✅    |       |
| launchAppFromBackground                |   ✅    |  ✅   |
| addIncomingCall                        |   ✅    |  ✅   |
| endCall                                |   ✅    |  ✅   |
| requestAnswerPhoneCallsPermission      |   ✅    |       |
| setVoipCallKeys                        |   ✅    |  ✅   |
| getPlatformVersion                     |   ✅    |  ✅   |
| handleVoipFromPlugin                   |   ✅    |  ✅   |
| voipEventsStream                       |   ✅    |  ✅   |
| dispose                                |   ✅    |  ✅   |

## Usage

Import the package:

```dart
import 'package:notification_voip_plugin/notification_voip_plugin.dart';
```

### Get FCM Token (Android & iOS)
```dart
final fcmToken = await NotificationVoipPlugin.getFCMToken();
```

### Get APNs Token (iOS only)
```dart
final apnsToken = await NotificationVoipPlugin.getAPNsToken();
```

### Get VoIP Token (iOS only)
```dart
final voipToken = await NotificationVoipPlugin.getVoIPToken();
```

### Request Notification Permissions (Android & iOS)
```dart
final granted = await NotificationVoipPlugin.requestNotificationPermissions();
```

### Check if Notifications are Enabled (Android & iOS)
```dart
final enabled = await NotificationVoipPlugin.areNotificationsEnabled();
```

### Open Notification Settings (Android & iOS)
```dart
await NotificationVoipPlugin.openNotificationSettings();
```

### Show In-App Notification (Android & iOS)
```dart
await NotificationVoipPlugin.showInAppNotification(
  title: 'Hello',
  body: 'This is an in-app notification',
  data: {'key': 'value'},
  imageUrl: 'https://example.com/image.png',
  sound: 'default',
);
```

### Show Background Notification (Android & iOS)
```dart
await NotificationVoipPlugin.showBackgroundNotification(
  title: 'Background',
  body: 'This is a background notification',
  data: {'key': 'value'},
  imageUrl: 'https://example.com/image.png',
  sound: 'default',
  channelId: 'custom_channel', // Android only
  channelName: 'Custom Channel', // Android only
);
```

### Listen for Notification Taps (Android & iOS)
```dart
NotificationVoipPlugin.onNotificationTapListen((data) {
  print('Notification tapped: $data');
});
```

### Listen for VoIP Events (Android & iOS)
```dart
NotificationVoipPlugin.voipEventsStream.listen((event) {
  print('VoIP event: $event');
});
```

### Add Incoming Call (VoIP) (Android & iOS)
```dart
await NotificationVoipPlugin.addIncomingCall(
  callerId: '123',
  callerName: 'John Doe',
);
```

### End Call (Android & iOS)
```dart
await NotificationVoipPlugin.endCall();
```

### Set VoIP Call Keys (Android & iOS)
```dart
await NotificationVoipPlugin.setVoipCallKeys(
  nameKey: 'name',
  idKey: 'id',
  typeKey: 'type',
);
```

### Get Platform Version (Android & iOS)
```dart
final version = await NotificationVoipPlugin.getPlatformVersion();
```

### Dispose Resources (Android & iOS)
```dart
NotificationVoipPlugin.dispose();
```

### Android-only Methods

- `isPhoneAccountEnabled()`
- `openPhoneAccountSettings()`
- `registerPhoneAccount()`
- `requestAnswerPhoneCallsPermission()`

## API Reference

See the Dart documentation in `lib/notification_voip_plugin.dart` for all available methods and details.