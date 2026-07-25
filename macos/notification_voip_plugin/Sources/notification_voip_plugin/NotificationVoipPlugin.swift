import FlutterMacOS
import UserNotifications

public class NotificationVoipPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var inappEventChannel: FlutterEventChannel?

    private let notificationHandler = MacNotificationHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = NotificationVoipPlugin()

        let channel = FlutterMethodChannel(name: "notification_voip_plugin", binaryMessenger: registrar.messenger)
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)

        let inappEventChannel = FlutterEventChannel(name: "notification_voip_plugin/inapp_events", binaryMessenger: registrar.messenger)
        instance.inappEventChannel = inappEventChannel
        inappEventChannel.setStreamHandler(MacStreamHandler { sink in
            instance.notificationHandler.inappEventSink = sink
        })

        // Register empty stream handlers for voip/call_state/token_refresh (no-op on macOS)
        let voipChannel = FlutterEventChannel(name: "notification_voip_plugin/voip_events", binaryMessenger: registrar.messenger)
        voipChannel.setStreamHandler(MacStreamHandler { _ in })

        let callStateChannel = FlutterEventChannel(name: "notification_voip_plugin/call_state", binaryMessenger: registrar.messenger)
        callStateChannel.setStreamHandler(MacStreamHandler { _ in })

        let tokenChannel = FlutterEventChannel(name: "notification_voip_plugin/token_refresh", binaryMessenger: registrar.messenger)
        tokenChannel.setStreamHandler(MacStreamHandler { _ in })

        UNUserNotificationCenter.current().delegate = instance.notificationHandler
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            result(nil)
        case "getPushToken", "getFCMToken", "getAPNsToken", "getVoIPToken":
            result(nil)
        case "requestPermission":
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async { result(granted) }
            }
        case "isPermissionGranted":
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async { result(settings.authorizationStatus == .authorized) }
            }
        case "openSettings":
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                NSWorkspace.shared.open(url)
            }
            result(nil)
        case "showNotification":
            if let args = call.arguments as? [String: Any] {
                let notification = args["notification"] as? [String: Any] ?? [:]
                let template = args["template"] as? [String: Any]
                notificationHandler.showNotification(notification: notification, template: template, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
        case "showInAppNotification":
            // macOS in-app falls back to system notification
            if let args = call.arguments as? [String: Any] {
                let notification = args["notification"] as? [String: Any] ?? [:]
                let template = args["template"] as? [String: Any]
                notificationHandler.showNotification(notification: notification, template: template, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
        case "clearAll":
            notificationHandler.clearAll(result: result)
        case "setBadgeCount":
            let count = (call.arguments as? [String: Any])?["count"] as? Int ?? 0
            notificationHandler.setBadgeCount(count: count, result: result)
        case "getBadgeCount":
            notificationHandler.getBadgeCount(result: result)
        // VoIP — all no-ops on macOS
        case "showIncomingCall", "showOutgoingCall", "acceptCall", "rejectCall",
             "endCall", "toggleMute", "toggleSpeaker", "toggleCamera",
             "openPhoneAccountSettings":
            result(nil)
        case "isPhoneAccountEnabled":
            result(false)
        case "dispose":
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

private class MacStreamHandler: NSObject, FlutterStreamHandler {
    private let onSinkChanged: (FlutterEventSink?) -> Void
    init(_ onSinkChanged: @escaping (FlutterEventSink?) -> Void) {
        self.onSinkChanged = onSinkChanged
    }
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        onSinkChanged(events); return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        onSinkChanged(nil); return nil
    }
}
