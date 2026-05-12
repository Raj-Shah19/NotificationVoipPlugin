## 2.0.1

### New

- None.

### Fixes

- Fixed dummy call dismissal on iOS using `reportCall(with:endedAt:reason:)` instead of `CXEndCallAction` to avoid any brief UI flash when suppressing cancelled/ended/busy VoIP pushes.
- Fixed call events (`performAnswerCall`, `performEndCall`) being lost when the Dart engine is not ready (background/terminated launch) — events are now buffered in `pendingCallEvents` and flushed once the event sink attaches.
- Fixed `isVideo` detection for payloads that send a `callType` (or `call_type`) string of `"video"` instead of a boolean flag.

### Deprecations

- None.

### Removals

- None.

---

## 2.0.0

### New

- Unified static API — all methods accessible via `NotificationVoipPlugin.*` with zero boilerplate.
- 8 notification templates: `normal`, `richText`, `bigText`, `bigPicture`, `bigBanner`, `progress`, `interactive`, `custom`.
- In-app banner overlays with native Android layout and iOS UIKit banner.
- Interactive notifications with action buttons and inline text input (`NvpNotificationAction`).
- Notification grouping with automatic summary via `groupKey`.
- Per-notification channel override (`channelId`, `channelName` on `NvpNotification`).
- Custom notification sounds (iOS bundle / Android raw resource).
- Native incoming call UI via CallKit (iOS) and ConnectionService (Android).
- Custom Flutter call screen widget (`NvpCallScreen`) with built-in accept, reject, mute, speaker, and camera controls.
- `NvpCallScreenController` with optimistic UI updates and automatic rollback on platform failure.
- Outgoing call support via `showOutgoingCall()`.
- Call timeout / auto-dismiss via `NvpCallConfig.duration`.
- Custom ringtone support via `NvpCallConfig.ringtone`.
- `endAllCalls()` for cleanup on logout or crash recovery.
- `setCallConnected()` for deferred connection flows (e.g., WebRTC negotiation).
- `getActiveCallIds()` for debugging and crash recovery.
- `cancelNotification()` to dismiss a specific notification by tag.
- `suppressNextForegroundNotification()` for iOS foreground push suppression.
- `NvpCallAction.timeoutEnded` event for unanswered call timeout.
- `onCallTimeoutEnded` callback in `NvpConfig`.
- `onPushReceived` stream and callback for iOS foreground push inspection.
- `onBannerDismiss` callback for in-app banner dismissal.
- `onChatPayload` and `onCallPayload` callbacks for payload routing.
- `NvpPayloadKeys` model for fully configurable push payload key mapping (SDK-agnostic).
- `NvpCallScreenConfig` for customizing the Flutter call screen (background color, avatar placeholder, custom builder, toggle callbacks).
- Cross-platform badge management with ShortcutBadger (Android) and native API (iOS).
- FCM, APNs, and VoIP push token retrieval with `onTokenRefresh` stream.
- Web platform support via browser Notification API.
- macOS, Windows, and Linux stub implementations for platform completeness.
- 5 EventChannels for real-time native → Dart communication.
- Event buffering for terminated-state launches — no events lost before Dart sink is ready.
- Federated plugin architecture with `NvpPlatformInterface` for custom platform implementations.
- `copyWith()` on `NvpNotification` and `NvpCallConfig` for immutable updates.
- `fromMap()` / `toMap()` serialization on all models.
- Comprehensive error handling — all public methods wrap platform calls in try/catch with `dart:developer` logging.
- Full example app demonstrating all features.

### Enhancements

- Replaced instance-based API with a cleaner static-only API surface.
- `NvpCallEvent.action` is now a typed `NvpCallAction` enum instead of a raw string, with both camelCase and snake_case parsing support.
- `NvpCallStatus` enum (`ringing`, `connected`, `onHold`, `ended`) for type-safe call state tracking.
- `NvpNotificationTemplateType` enum for type-safe template selection.
- Init is idempotent — calling `init()` multiple times cleanly tears down previous subscriptions.
- `dispose()` fully cleans up all streams, subscriptions, cached state, and native resources; plugin is re-initializable after dispose.
- iOS VoIP push handling complies with iOS 13+ PushKit ↔ CallKit requirement (reports dummy call and immediately ends for non-initiated pushes).
- Android phone account validation with `isPhoneAccountEnabled()` and `openPhoneAccountSettings()`.
- `showIncomingCall()` throws `PlatformException` with code `PHONE_ACCOUNT_NOT_ENABLED` on Android when the phone account is disabled.

### Fixes

- Fixed potential event loss when app is launched from terminated state via notification tap or VoIP push (event buffering on both iOS and Android).
- Fixed stream subscription leaks on repeated `init()` calls — previous subscriptions are now properly cancelled before re-wiring.

### Deprecations

- None.

### Removals

- None.

---

## 1.0.1

### Enhancements

- Updated README.md.
- Updated documentation.

---

## 1.0.0

### New

- Initial release.
