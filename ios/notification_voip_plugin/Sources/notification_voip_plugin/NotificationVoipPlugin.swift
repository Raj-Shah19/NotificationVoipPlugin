import Flutter
import UIKit
import UserNotifications

public class NotificationVoipPlugin: NSObject, FlutterPlugin {
    public static var shared: NotificationVoipPlugin?

    private var channel: FlutterMethodChannel?
    private var inappEventChannel: FlutterEventChannel?
    private var voipEventChannel: FlutterEventChannel?
    private var callStateChannel: FlutterEventChannel?
    private var tokenRefreshChannel: FlutterEventChannel?
    private var pushReceivedChannel: FlutterEventChannel?

    let tokenHandler = TokenHandler()
    let permissionHandler = PermissionHandler()
    let notificationHandler = NotificationHandler()
    public let callHandler = CallHandler()

    /// Pending events buffered before the Dart EventChannel sinks are ready.
    var pendingNotificationTapEvents: [[String: Any]] = []
    var pendingCallEvents: [[String: Any]] = []

    /// When true, foreground VoIP pushes skip the full CallKit UI and only
    /// relay the event to Dart. Set via `init` config from Dart.
    var suppressForegroundVoIP: Bool = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = NotificationVoipPlugin()
        NotificationVoipPlugin.shared = instance

        // MethodChannel
        let channel = FlutterMethodChannel(
            name: "notification_voip_plugin",
            binaryMessenger: registrar.messenger()
        )
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)

        // 4 EventChannels with dedicated sinks
        let inappEventChannel = FlutterEventChannel(
            name: "notification_voip_plugin/inapp_events",
            binaryMessenger: registrar.messenger()
        )
        instance.inappEventChannel = inappEventChannel
        inappEventChannel.setStreamHandler(NvpStreamHandler { sink in
            instance.notificationHandler.inappEventSink = sink
            // Drain any events buffered before the sink was ready
            if let sink = sink {
                for event in instance.pendingNotificationTapEvents {
                    sink(event)
                }
                instance.pendingNotificationTapEvents.removeAll()
            }
        })

        let voipEventChannel = FlutterEventChannel(
            name: "notification_voip_plugin/voip_events",
            binaryMessenger: registrar.messenger()
        )
        instance.voipEventChannel = voipEventChannel
        voipEventChannel.setStreamHandler(NvpStreamHandler { sink in
            instance.callHandler.voipEventSink = sink
            // Drain any events buffered before the sink was ready
            if let sink = sink {
                for event in instance.pendingCallEvents {
                    sink(event)
                }
                instance.pendingCallEvents.removeAll()
            }
        })

        let callStateChannel = FlutterEventChannel(
            name: "notification_voip_plugin/call_state",
            binaryMessenger: registrar.messenger()
        )
        instance.callStateChannel = callStateChannel
        callStateChannel.setStreamHandler(NvpStreamHandler { sink in
            instance.callHandler.callStateSink = sink
        })

        let tokenRefreshChannel = FlutterEventChannel(
            name: "notification_voip_plugin/token_refresh",
            binaryMessenger: registrar.messenger()
        )
        instance.tokenRefreshChannel = tokenRefreshChannel
        tokenRefreshChannel.setStreamHandler(NvpStreamHandler { sink in
            instance.tokenHandler.tokenRefreshSink = sink
        })

        let pushReceivedChannel = FlutterEventChannel(
            name: "notification_voip_plugin/push_received",
            binaryMessenger: registrar.messenger()
        )
        instance.pushReceivedChannel = pushReceivedChannel
        pushReceivedChannel.setStreamHandler(NvpStreamHandler { sink in
            instance.notificationHandler.pushReceivedSink = sink
        })

        // Setup VoIP, APNs, and notification delegate
        instance.tokenHandler.setup()
        UNUserNotificationCenter.current().delegate = instance.notificationHandler
    }

    /// Called from AppDelegate to set APNs token
    public func setAPNsToken(_ deviceToken: Data) {
        tokenHandler.setAPNsToken(deviceToken)
    }

    /// Called from TokenHandler when VoIP push arrives.
    /// MUST report to CallKit before the PushKit completion handler fires (iOS 13+ requirement).
    func handleVoIPPush(payload: Any, completion: @escaping () -> Void) {
        var callerName = "Unknown"
        var callId = UUID().uuidString
        var isVideo = false
        var callAction: String? = nil

        if let pushPayload = payload as? NSObject,
           let dict = pushPayload.value(forKey: "dictionaryPayload") as? [String: Any] {
            callerName = dict["callerName"] as? String
                ?? dict["caller_name"] as? String
                ?? dict["displayName"] as? String
                ?? dict["display_name"] as? String
                ?? dict["senderName"] as? String
                ?? "Unknown"
            callId = dict["callId"] as? String
                ?? dict["call_id"] as? String
                ?? dict["sessionId"] as? String
                ?? dict["uuid"] as? String
                ?? UUID().uuidString
            isVideo = dict["isVideo"] as? Bool
                ?? dict["is_video"] as? Bool
                ?? (dict["video"] as? Bool ?? false)
            if !isVideo, let callType = dict["callType"] as? String ?? dict["call_type"] as? String {
                isVideo = (callType == "video")
            }
            callAction = dict["callAction"] as? String
                ?? dict["call_action"] as? String
        }

        // Only show the incoming call screen when the call is being initiated.
        // For other actions (cancelled, ended, rejected, busy, etc.) we still
        // must report *something* to CallKit (iOS 13+ PushKit requirement),
        // then immediately end it so no UI is shown to the user.
        if callAction == "initiated" {
            let isForeground = UIApplication.shared.applicationState == .active
            if isForeground && suppressForegroundVoIP {
                // Foreground + suppression: satisfy the PushKit ↔ CallKit
                // requirement without showing the native call UI, and relay the
                // event to Dart so the host app shows its own in-app UI.
                callHandler.reportAndImmediatelyEndCall(
                    callId: callId,
                    completion: completion
                )
            } else {
                callHandler.reportIncomingCallFromPush(
                    callId: callId,
                    callerName: callerName,
                    isVideo: isVideo,
                    completion: completion
                )
            }
        } else {
            // If there's already an active call with this ID (e.g. a "cancelled"
            // push for a ringing call), end it through CallKit.
            if callHandler.hasActiveCall(callId: callId) {
                callHandler.endCallFromPush(callId: callId, completion: completion)
            } else {
                // No active call — report a dummy call and immediately end it
                // to satisfy the PushKit ↔ CallKit requirement.
                callHandler.reportAndImmediatelyEndCall(
                    callId: callId,
                    completion: completion
                )
            }
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            let config = call.arguments as? [String: Any]
            notificationHandler.configure(config: config)
            callHandler.configure(config: config)
            suppressForegroundVoIP = config?["suppressForegroundVoIP"] as? Bool ?? false
            result(nil)

        // Tokens
        case "getPushToken":
            tokenHandler.getPushToken(result: result)
        case "getFCMToken":
            tokenHandler.getFCMToken(result: result)
        case "getAPNsToken":
            tokenHandler.getAPNsToken(result: result)
        case "getVoIPToken":
            tokenHandler.getVoIPToken(result: result)

        // Permissions
        case "requestPermission":
            permissionHandler.requestPermission(result: result)
        case "isPermissionGranted":
            permissionHandler.isPermissionGranted(result: result)
        case "openSettings":
            permissionHandler.openSettings(result: result)

        // Notifications
        case "showNotification":
            if let args = call.arguments as? [String: Any] {
                let notification = args["notification"] as? [String: Any] ?? [:]
                let template = args["template"] as? [String: Any]
                notificationHandler.showNotification(notification: notification, template: template, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
        case "showInAppNotification":
            if let args = call.arguments as? [String: Any] {
                let notification = args["notification"] as? [String: Any] ?? [:]
                let style = args["style"] as? [String: Any]
                notificationHandler.showInAppNotification(notification: notification, style: style, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
        case "clearAll":
            notificationHandler.clearAll(result: result)
        case "cancelNotification":
            let tag = (call.arguments as? [String: Any])?["tag"] as? String ?? ""
            notificationHandler.cancelNotification(tag: tag, result: result)
        case "suppressNextForegroundNotification":
            notificationHandler.suppressNextForegroundNotification = true
            result(nil)
        case "setBadgeCount":
            let count = (call.arguments as? [String: Any])?["count"] as? Int ?? 0
            notificationHandler.setBadgeCount(count: count, result: result)
        case "getBadgeCount":
            notificationHandler.getBadgeCount(result: result)

        // Calls
        case "showIncomingCall":
            if let args = call.arguments as? [String: Any] {
                callHandler.showIncomingCall(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
        case "showOutgoingCall":
            if let args = call.arguments as? [String: Any] {
                callHandler.showOutgoingCall(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
        case "acceptCall":
            let acceptCallId = (call.arguments as? [String: Any])?["callId"] as? String ?? ""
            callHandler.acceptCall(callId: acceptCallId, result: result)
        case "rejectCall":
            let rejectCallId = (call.arguments as? [String: Any])?["callId"] as? String ?? ""
            callHandler.rejectCall(callId: rejectCallId, result: result)
        case "endCall":
            let callId = (call.arguments as? [String: Any])?["callId"] as? String ?? ""
            callHandler.endCall(callId: callId, result: result)
        case "endAllCalls":
            callHandler.endAllCalls(result: result)
        case "setCallConnected":
            let connCallId = (call.arguments as? [String: Any])?["callId"] as? String ?? ""
            callHandler.setCallConnected(callId: connCallId, result: result)
        case "getActiveCallIds":
            callHandler.getActiveCallIds(result: result)
        case "toggleMute":
            let callId = (call.arguments as? [String: Any])?["callId"] as? String ?? ""
            callHandler.toggleMute(callId: callId, result: result)
        case "toggleSpeaker":
            let callId = (call.arguments as? [String: Any])?["callId"] as? String ?? ""
            callHandler.toggleSpeaker(callId: callId, result: result)
        case "toggleCamera":
            let callId = (call.arguments as? [String: Any])?["callId"] as? String ?? ""
            callHandler.toggleCamera(callId: callId, result: result)

        // Android-only (no-op on iOS)
        case "isPhoneAccountEnabled":
            result(false)
        case "openPhoneAccountSettings":
            result(nil)

        // Lifecycle
        case "dispose":
            callHandler.dispose()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
