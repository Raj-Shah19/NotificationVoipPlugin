import Flutter
import UIKit
import PushKit
import CallKit
import UserNotifications

private var bannerDataKey: UInt8 = 0

private class SimpleStreamHandler: NSObject, FlutterStreamHandler {
    private weak var plugin: NotificationVoipPlugin?
    private let which: Int  // 0 = tap, 1 = call

    init(plugin: NotificationVoipPlugin, which: Int) {
        self.plugin = plugin
        self.which = which
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
        -> FlutterError?
    {
        if which == 0 {
            plugin?.notificationTapSink = events
        } else {
            plugin?.callEventSink = events
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if which == 0 { plugin?.notificationTapSink = nil } else { plugin?.callEventSink = nil }
        return nil
    }
}

public class NotificationVoipPlugin: NSObject, FlutterPlugin, PKPushRegistryDelegate,
    UNUserNotificationCenterDelegate
{
    // Channels & sinks
    private var channel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var callEventChannel: FlutterEventChannel?
    var notificationTapSink: FlutterEventSink?
    var callEventSink: FlutterEventSink?

    // Tokens and state
    private var voipRegistry: PKPushRegistry?
    private var voipToken: String?
    private var apnsToken: String?
    private var currentBanner: UIView?
    public static var shared: NotificationVoipPlugin?

    // CallKit
    private var callProvider: CXProvider?
    private var callController = CXCallController()
    private var activeCalls: [String: UUID] = [:]
    private var latestVoipPayload: [String: Any]? = nil

    // Dart-defined keys for payload mapping
    private var voipNameKey: String = "receiverName"
    private var voipIdKey: String = "sessionId"
    private var voipTypeKey: String = "callType"

    // ---- Plugin Registration ----
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = NotificationVoipPlugin()
        NotificationVoipPlugin.shared = instance

        // Main MethodChannel
        let channel = FlutterMethodChannel(
            name: "notification_voip_plugin",
            binaryMessenger: registrar.messenger()
        )
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)

        // In-app banner tap events channel
        let eventChannel = FlutterEventChannel(
            name: "notification_voip_plugin/inapp_events",
            binaryMessenger: registrar.messenger()
        )
        instance.eventChannel = eventChannel
        eventChannel.setStreamHandler(SimpleStreamHandler(plugin: instance, which: 0))
        //        eventChannel.setStreamHandler(
        //            SimpleStreamHandler(
        //                onListen: { sink in instance.notificationTapSink = sink },
        //                onCancel: { instance.notificationTapSink = nil }
        //            ))
        // VoIP events (CallKit UI) channel
        let callEventChannel = FlutterEventChannel(
            name: "notification_voip_plugin/voip_events",
            binaryMessenger: registrar.messenger()
        )
        instance.callEventChannel = callEventChannel
        callEventChannel.setStreamHandler(SimpleStreamHandler(plugin: instance, which: 1))
        //        callEventChannel.setStreamHandler(
        //            SimpleStreamHandler(
        //                onListen: { sink in instance.callEventSink = sink },
        //                onCancel: { instance.callEventSink = nil }
        //            ))
        // VoIP, APNs, and notification center delegate
        instance.setupVoIP()
        instance.setupAPNs()
        UNUserNotificationCenter.current().delegate = instance
    }

    // ----- Separate StreamHandlers for two EventChannels -----
    private lazy var notificationTapStreamHandler: FlutterStreamHandler = {
        return StreamHandler { sink in self.notificationTapSink = sink }
    }()
    private lazy var callEventStreamHandler: FlutterStreamHandler = {
        return StreamHandler { sink in self.callEventSink = sink }
    }()

    // ----- VoIP & APNs Setup -----
    private func setupVoIP() {
        voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry?.delegate = self
        voipRegistry?.desiredPushTypes = [PKPushType.voIP]
    }
    private func setupAPNs() {
        DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
    }
    public func setAPNsToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        apnsToken = tokenString
        print("🔔 APNs token updated: \(tokenString)")
    }

    // ----- Flutter Method Channel -----
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "getPlatformVersion":
            let version = "iOS " + UIDevice.current.systemVersion
            result(version)
        case "getAPNsToken":
            result(apnsToken)
        case "getVoIPToken":
            result(voipToken)
        case "requestNotificationPermissions":
            requestNotificationPermissions(result: result)
        case "showInAppNotification":
            if let args = call.arguments as? [String: Any] {
                showInAppBannerNotification(args: args)
                result(nil)
            } else {
                result(
                    FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
        case "clearAllNotifications":
            clearAllNotifications(); result(nil)
        case "setVoipCallKeys":
            guard let args = call.arguments as? [String: Any],
                let nameKey = args["nameKey"] as? String,
                let idKey = args["idKey"] as? String,
                let typeKey = args["typeKey"] as? String
            else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing keys", details: nil));
                return
            }
            voipNameKey = nameKey; voipIdKey = idKey; voipTypeKey = typeKey; result(nil)
        case "handleVoipFromPlugin":
            guard let args = call.arguments as? [String: Any],
                let enabled = args["enabled"] as? Bool,
                let nameKey = args["nameKey"] as? String,
                let idKey = args["idKey"] as? String,
                let typeKey = args["typeKey"] as? String,
                let callAction = args["callAction"] as? String
            else {
                result(
                    FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil));
                return
            }
            handleVoipFromPlugin(
                enabled: enabled, nameKey: nameKey, idKey: idKey, typeKey: typeKey,
                callAction: callAction)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ----- PushKit VoIP Delegate -----
    public func pushRegistry(
        _ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        if type == .voIP {
            let tokenString = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
            voipToken = tokenString
            print("🔔 VoIP token updated: \(tokenString)")
        }
    }
    public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType)
    {
        if type == .voIP { voipToken = nil }
    }
    public func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        if type == .voIP {
            let dict: [String: Any]
            if let cast = payload.dictionaryPayload as? [String: Any] {
                dict = cast
            } else {
                dict = Dictionary(
                    uniqueKeysWithValues: payload.dictionaryPayload.compactMap {
                        guard let key = $0.key as? String else { return nil }
                        return (key, $0.value)
                    })
            }
            self.latestVoipPayload = dict
            let callAction = dict["callAction"] as? String ?? ""
            handleVoipFromPlugin(
                enabled: true,
                nameKey: voipNameKey,
                idKey: voipIdKey,
                typeKey: voipTypeKey,
                callAction: callAction
            )
        }
        completion()
    }

    // ----- Dynamic VoIP CallKit handler -----
    public func handleVoipFromPlugin(
        enabled: Bool,
        nameKey: String,
        idKey: String,
        typeKey: String,
        callAction: String
    ) {
        guard enabled else { return }
        guard let payload = latestVoipPayload else {
            print("No stored VoIP payload available")
            return
        }
        guard let callerName = payload[nameKey] as? String,
            let callId = payload[idKey] as? String,
            let callType = payload[typeKey] as? String
        else {
            print("handleVoipFromPlugin: missing required value(s) in payload")
            return
        }
        let actionLower = callAction.lowercased()
        setupCallKitIfNeeded()
        if actionLower == "initiated" {
            showNativeIncomingCall(callerName: callerName, callId: callId, type: callType)
        } else if ["unanswered", "rejected", "cancelled", "busy", "ended"].contains(actionLower) {
            endCall(callId: callId, reason: actionLower)
        }
    }

    private func requestNotificationPermissions(result: @escaping FlutterResult) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(
                        FlutterError(
                            code: "PERMISSION_ERROR",
                            message: "Failed to request permissions",
                            details: error.localizedDescription
                        )
                    )
                } else {
                    result(granted)
                }
            }
        }
    }

    private func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        currentBanner?.removeFromSuperview()
        currentBanner = nil
    }

    private func setupCallKitIfNeeded() {
        if callProvider != nil { return }
        let config = CXProviderConfiguration(localizedName: "YourAppName")
        config.supportsVideo = true
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.generic]
        callProvider = CXProvider(configuration: config)
        callProvider?.setDelegate(self, queue: nil)
    }

    private func showNativeIncomingCall(callerName: String, callId: String, type: String) {
        let uuid = UUID()
        activeCalls[callId] = uuid
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerName)
        update.hasVideo = (type.lowercased() == "video")
        callProvider?.reportNewIncomingCall(
            with: uuid, update: update,
            completion: { error in
                if let error = error {
                    print("CallKit error: \(error)")
                } else {
                    print("✅ Incoming system call UI shown!")
                }
            })
    }

    // MARK: - In-App Banner Notification
    private func showInAppBannerNotification(args: [String: Any]) {
        let title = args["title"] as? String ?? "Notification"
        let body = args["body"] as? String ?? ""
        let data = args["data"] as? [String: Any] ?? [:]
        let imageUrl = args["imageUrl"] as? String

        DispatchQueue.main.async {
            // Remove any existing banner
            self.currentBanner?.removeFromSuperview()

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first(where: { $0.isKeyWindow })
            else {
                print("❌ Could not find key window")
                return
            }

            let safeAreaTop = window.safeAreaInsets.top
            let bannerHeight: CGFloat = 80
            let screenWidth = window.frame.width

            // Create main banner container
            let banner = UIView()
            banner.frame = CGRect(
                x: 8, y: -bannerHeight, width: screenWidth - 16, height: bannerHeight)
            banner.backgroundColor = UIColor.systemBlue
            banner.layer.cornerRadius = 12
            banner.clipsToBounds = true

            // Add shadow
            banner.layer.shadowColor = UIColor.black.cgColor
            banner.layer.shadowOffset = CGSize(width: 0, height: 2)
            banner.layer.shadowOpacity = 0.2
            banner.layer.shadowRadius = 4
            banner.layer.masksToBounds = false

            // Avatar (left side)
            let avatarView = UIImageView()
            avatarView.frame = CGRect(x: 12, y: 16, width: 48, height: 48)
            avatarView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            avatarView.layer.cornerRadius = 24
            avatarView.clipsToBounds = true
            avatarView.contentMode = .scaleAspectFill

            // Set default avatar
            avatarView.image = UIImage(systemName: "person.circle.fill")
            avatarView.tintColor = .white
            banner.addSubview(avatarView)

            // Load image if provided
            if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                self.loadImageAsync(from: url) { image in
                    DispatchQueue.main.async {
                        avatarView.image = image
                    }
                }
            }

            // Text container (middle)
            let textContainer = UIView()
            textContainer.frame = CGRect(x: 72, y: 12, width: screenWidth - 128, height: 56)
            banner.addSubview(textContainer)

            // Title label
            let titleLabel = UILabel()
            titleLabel.frame = CGRect(x: 0, y: 4, width: textContainer.frame.width, height: 20)
            titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
            titleLabel.textColor = .white
            titleLabel.text = title
            titleLabel.numberOfLines = 1
            textContainer.addSubview(titleLabel)

            // Body label
            let bodyLabel = UILabel()
            bodyLabel.frame = CGRect(x: 0, y: 26, width: textContainer.frame.width, height: 32)
            bodyLabel.font = UIFont.systemFont(ofSize: 14)
            bodyLabel.textColor = UIColor.white.withAlphaComponent(0.9)
            bodyLabel.text = body
            bodyLabel.numberOfLines = 2
            textContainer.addSubview(bodyLabel)

            // Close button (right side)
            let closeButton = UIButton(type: .system)
            closeButton.frame = CGRect(x: screenWidth - 48, y: 16, width: 32, height: 32)
            closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            closeButton.tintColor = UIColor.white.withAlphaComponent(0.8)
            closeButton.addTarget(
                self, action: #selector(self.closeBannerTapped), for: .touchUpInside)
            banner.addSubview(closeButton)

            // Store data for tap handling
            objc_setAssociatedObject(
                banner, &bannerDataKey, data as AnyObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            // Add tap gesture
            let tapGesture = UITapGestureRecognizer(
                target: self, action: #selector(self.bannerTapped(_:)))
            banner.addGestureRecognizer(tapGesture)

            // Add to window
            window.addSubview(banner)
            self.currentBanner = banner

            // Calculate final position (below safe area)
            let finalY = safeAreaTop + 8

            // Animate slide in
            UIView.animate(
                withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0,
                options: .curveEaseOut
            ) {
                banner.frame.origin.y = finalY
            }

            // Auto dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.dismissBanner(banner)
            }
        }
    }

    @objc private func bannerTapped(_ sender: UITapGestureRecognizer) {
        guard let banner = sender.view else { return }
        if let data = objc_getAssociatedObject(banner, &bannerDataKey) as? [String: Any] {
            notificationTapSink?(data)  // <-- fixed!
        }
        dismissBanner(banner)
    }

    @objc private func closeBannerTapped() {
        if let banner = currentBanner {
            dismissBanner(banner)
        }
    }

    private func dismissBanner(_ banner: UIView) {
        UIView.animate(
            withDuration: 0.3,
            animations: {
                banner.frame.origin.y = -banner.frame.height - 20
            }
        ) { _ in
            banner.removeFromSuperview()
            if self.currentBanner == banner {
                self.currentBanner = nil
            }
        }
    }

    private func loadImageAsync(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                let image = UIImage(data: data)
            else {
                completion(nil)
                return
            }
            completion(image)
        }.resume()
    }

    private func endCall(callId: String, reason: String) {
        guard let uuid = activeCalls[callId] else { return }
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        callController.request(transaction) { error in
            if let error = error {
                print("End call error: \(error)")
            } else {
                print("Call ended with reason: \(reason)")
            }
        }
        let endedReason: CXCallEndedReason
        switch reason.lowercased() {
        case "unanswered":
            endedReason = .unanswered
        case "rejected", "declined":
            endedReason = .remoteEnded
        case "cancelled":
            endedReason = .remoteEnded
        case "busy":
            endedReason = .failed
        case "ended":
            endedReason = .remoteEnded
        default:
            endedReason = .remoteEnded
        }
        callProvider?.reportCall(with: uuid, endedAt: Date(), reason: endedReason)
        activeCalls.removeValue(forKey: callId)
    }

    // MARK: - In-App Banner Notification, Permissions, Cleanup methods (unchanged)
    // ... Add your in-app banner code here, using notificationTapSink? on tap ...

    private class StreamHandler: NSObject, FlutterStreamHandler {
        private let didListen: (_ sink: @escaping FlutterEventSink) -> Void
        init(_ didListen: @escaping (_ sink: @escaping FlutterEventSink) -> Void) {
            self.didListen = didListen
        }
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
            -> FlutterError?
        {
            didListen(events); return nil
        }
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            didListen({ _ in }); return nil
        }
    }
}

// ----- CallKit Delegate: Only sends to callEventSink! -----
extension NotificationVoipPlugin: CXProviderDelegate {
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        if let callId = activeCalls.first(where: { $0.value == action.callUUID })?.key {
            callEventSink?([
                "action": "accept",
                "callId": callId,
                "payload": latestVoipPayload ?? [:],
            ])
        }
        action.fulfill()
    }
    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        if let callId = activeCalls.first(where: { $0.value == action.callUUID })?.key {
            callEventSink?([
                "action": "decline",
                "callId": callId,
                "payload": latestVoipPayload ?? [:],
            ])
            activeCalls.removeValue(forKey: callId)
        }
        action.fulfill()
    }
    public func providerDidReset(_ provider: CXProvider) {
        activeCalls.removeAll()
        latestVoipPayload = nil
    }
}

// ----- StreamHandler for notification taps -----
extension NotificationVoipPlugin: FlutterStreamHandler {
    public func onListen(
        withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.notificationTapSink = events
        return nil
    }
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.notificationTapSink = nil
        return nil
    }
}

/*
//-----------------------------------------------------------------------

import UIKit
import Flutter
import PushKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// Create a key for associated object
private var bannerDataKey: UInt8 = 0

public class NotificationVoipPlugin: NSObject, FlutterPlugin, PKPushRegistryDelegate,
    UNUserNotificationCenterDelegate, FlutterStreamHandler
{

    private var channel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var voipRegistry: PKPushRegistry?
    private var voipToken: String?
    private var eventSink: FlutterEventSink?
    private var currentBanner: UIView?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "notification_voip_plugin",
            binaryMessenger: registrar.messenger()
        )

        let eventChannel = FlutterEventChannel(
            name: "notification_voip_plugin/inapp_events",
            binaryMessenger: registrar.messenger()
        )

        let instance = NotificationVoipPlugin()
        instance.channel = channel
        instance.eventChannel = eventChannel

        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)

        // Setup VoIP registry
        instance.setupVoIP()

        // Setup notification center delegate
        UNUserNotificationCenter.current().delegate = instance
    }

    private func setupVoIP() {
        voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry?.delegate = self
        voipRegistry?.desiredPushTypes = [PKPushType.voIP]
    }

    // MARK: - FlutterStreamHandler
    public func onListen(
        withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "getFCMToken":
            Messaging.messaging().token { token, error in
                if let error = error {
                    result(
                        FlutterError(
                            code: "UNAVAILABLE",
                            message: "FCM token not available",
                            details: error.localizedDescription
                        )
                    )
                } else if let token = token {
                    result(token)
                } else {
                    result(nil)
                }
            }

        case "getAPNsToken":
            if let apnsToken = Messaging.messaging().apnsToken {
                let tokenString = apnsToken.map { String(format: "%02.2hhx", $0) }.joined()
                result(tokenString)
            } else {
                result(nil)
            }

        case "getVoIPToken":
            result(voipToken)

        case "requestNotificationPermissions":
            requestNotificationPermissions(result: result)

        case "areNotificationsEnabled":
            areNotificationsEnabled(result: result)

        case "openNotificationSettings":
            openNotificationSettings()
            result(nil)

        case "showForegroundNotification":
            if let args = call.arguments as? [String: Any] {
                showForegroundNotification(args: args, result: result)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Invalid arguments",
                        details: nil
                    )
                )
            }

        // NEW: In-App Notification Banner
        case "showInAppNotification":
            if let args = call.arguments as? [String: Any] {
                showInAppBannerNotification(args: args)
                result(nil)
            } else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Invalid arguments",
                        details: nil
                    )
                )
            }

         case "showBackgroundNotification":
                if let args = call.arguments as? [String: Any] {
                    showBackgroundNotification(args: args, result: result)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                }

        case "clearAllNotifications":
            clearAllNotifications()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - In-App Banner Notification
    private func showInAppBannerNotification(args: [String: Any]) {
        let title = args["title"] as? String ?? "Notification"
        let body = args["body"] as? String ?? ""
        let data = args["data"] as? [String: Any] ?? [:]
        let imageUrl = args["imageUrl"] as? String

        DispatchQueue.main.async
 {
            // Remove any existing banner
            self.currentBanner?.removeFromSuperview()

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                print("❌ Could not find key window")
                return
            }

            let safeAreaTop = window.safeAreaInsets.top
            let bannerHeight: CGFloat = 80
            let screenWidth = window.frame.width

            // Create main banner container
            let banner = UIView()
            banner.frame = CGRect(x: 8, y: -bannerHeight, width: screenWidth - 16, height: bannerHeight)
            banner.backgroundColor = UIColor.systemBlue
            banner.layer.cornerRadius = 12
            banner.clipsToBounds = true

            // Add shadow
            banner.layer.shadowColor = UIColor.black.cgColor
            banner.layer.shadowOffset = CGSize(width: 0, height: 2)
            banner.layer.shadowOpacity = 0.2
            banner.layer.shadowRadius = 4
            banner.layer.masksToBounds = false

            // Avatar (left side)
            let avatarView = UIImageView()
            avatarView.frame = CGRect(x: 12, y: 16, width: 48, height: 48)
            avatarView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            avatarView.layer.cornerRadius = 24
            avatarView.clipsToBounds = true
            avatarView.contentMode = .scaleAspectFill

            // Set default avatar
            avatarView.image = UIImage(systemName: "person.circle.fill")
            avatarView.tintColor = .white
            banner.addSubview(avatarView)

            // Load image if provided
            if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                self.loadImageAsync(from: url) { image in
                    DispatchQueue.main.async {
                        avatarView.image = image
                    }
                }
            }

            // Text container (middle)
            let textContainer = UIView()
            textContainer.frame = CGRect(x: 72, y: 12, width: screenWidth - 128, height: 56)
            banner.addSubview(textContainer)

            // Title label
            let titleLabel = UILabel()
            titleLabel.frame = CGRect(x: 0, y: 4, width: textContainer.frame.width, height: 20)
            titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
            titleLabel.textColor = .white
            titleLabel.text = title
            titleLabel.numberOfLines = 1
            textContainer.addSubview(titleLabel)

            // Body label
            let bodyLabel = UILabel()
            bodyLabel.frame = CGRect(x: 0, y: 26, width: textContainer.frame.width, height: 32)
            bodyLabel.font = UIFont.systemFont(ofSize: 14)
            bodyLabel.textColor = UIColor.white.withAlphaComponent(0.9)
            bodyLabel.text = body
            bodyLabel.numberOfLines = 2
            textContainer.addSubview(bodyLabel)

            // Close button (right side)
            let closeButton = UIButton(type: .system)
            closeButton.frame = CGRect(x: screenWidth - 48, y: 16, width: 32, height: 32)
            closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            closeButton.tintColor = UIColor.white.withAlphaComponent(0.8)
            closeButton.addTarget(self, action: #selector(self.closeBannerTapped), for: .touchUpInside)
            banner.addSubview(closeButton)

            // Store data for tap handling
            objc_setAssociatedObject(banner, &bannerDataKey, data as AnyObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            // Add tap gesture
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.bannerTapped(_:)))
            banner.addGestureRecognizer(tapGesture)

            // Add to window
            window.addSubview(banner)
            self.currentBanner = banner

            // Calculate final position (below safe area)
            let finalY = safeAreaTop + 8

            // Animate slide in
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
                banner.frame.origin.y = finalY
            }

            // Auto dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.dismissBanner(banner)
            }
        }
    }

    private func showBackgroundNotification(args: [String: Any], result: @escaping FlutterResult) {
        let title = args["title"] as? String ?? "Notification"
        let body = args["body"] as? String ?? ""
        let imageUrl = args["imageUrl"] as? String
        let data = args["data"] as? [String: Any]
        let sound = args["sound"] as? String

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound != nil ?
            UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(sound!).wav")) :
            UNNotificationSound.default
        content.badge = NSNumber(value: 1)

        // Add user info data for tap handling
        if let data = data {
            content.userInfo = data
        }

        // Load image attachment if provided
        if let imageUrlString = imageUrl, let imageURL = URL(string: imageUrlString) {
            loadImageAttachment(url: imageURL) { attachment in
                if let attachment = attachment {
                    content.attachments = [attachment]
                }
                self.scheduleBackgroundNotification(content: content, result: result)
            }
        } else {
            scheduleBackgroundNotification(content: content, result: result)
        }
    }

    private func scheduleBackgroundNotification(content: UNMutableNotificationContent, result: @escaping FlutterResult) {
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "NOTIFICATION_ERROR", message: "Failed to show notification", details: error.localizedDescription))
                } else {
                    result(nil)
                }
            }
        }
    }


    @objc private func bannerTapped(_ sender: UITapGestureRecognizer) {
        guard let banner = sender.view else { return }

        // Get stored data - Fixed this line too
        if let data = objc_getAssociatedObject(banner, &bannerDataKey) as? [String: Any] {
            // Send tap event to Flutter
            eventSink?(data)
        }

        // Dismiss banner
        dismissBanner(banner)
    }


    @objc private func closeBannerTapped() {
        if let banner = currentBanner {
            dismissBanner(banner)
        }
    }

    private func dismissBanner(_ banner: UIView) {
        UIView.animate(withDuration: 0.3, animations: {
            banner.frame.origin.y = -banner.frame.height - 20
        }) { _ in
            banner.removeFromSuperview()
            if self.currentBanner == banner {
                self.currentBanner = nil
            }
        }
    }


    private func loadImageAsync(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                let image = UIImage(data: data)
            else {
                completion(nil)
                return
            }
            completion(image)
        }.resume()
    }

    // MARK: - Foreground Notification (System notifications)
    private func showForegroundNotification(args: [String: Any], result: @escaping FlutterResult) {
        let title = args["title"] as? String ?? "New Message"
        let body = args["body"] as? String ?? ""
        let imageUrl = args["imageUrl"] as? String
        let data = args["data"] as? [String: Any]
        let sound = args["sound"] as? String
        let badgeCount = args["badgeCount"] as? Int

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound =
            sound != nil
            ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(sound!).wav"))
            : UNNotificationSound.default

        if let badgeCount = badgeCount {
            content.badge = NSNumber(value: badgeCount)
        }

        // Add user info data
        if let data = data {
            content.userInfo = data
        }

        // Load image attachment if provided
        if let imageUrlString = imageUrl, let imageURL = URL(string: imageUrlString) {
            loadImageAttachment(url: imageURL) { attachment in
                if let attachment = attachment {
                    content.attachments = [attachment]
                }
                self.scheduleNotification(content: content, result: result)
            }
        } else {
            scheduleNotification(content: content, result: result)
        }
    }

    private func loadImageAttachment(
        url: URL, completion: @escaping (UNNotificationAttachment?) -> Void
    ) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            let tempDirectory = NSTemporaryDirectory()
            let fileName = url.lastPathComponent
            let tempFileURL = URL(fileURLWithPath: tempDirectory).appendingPathComponent(fileName)

            do {
                try data.write(to: tempFileURL)
                let attachment = try UNNotificationAttachment(
                    identifier: fileName, url: tempFileURL, options: nil)
                completion(attachment)
            } catch {
                completion(nil)
            }
        }.resume()
    }

    private func scheduleNotification(
        content: UNMutableNotificationContent, result: @escaping FlutterResult
    ) {
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    result(
                        FlutterError(
                            code: "NOTIFICATION_ERROR", message: "Failed to show notification",
                            details: error.localizedDescription))
                } else {
                    result(nil)
                }
            }
        }
    }

    private func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // Also clear in-app banner
        currentBanner?.removeFromSuperview()
        currentBanner = nil
    }

    // MARK: - Permission Methods
    private func requestNotificationPermissions(result: @escaping FlutterResult) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(
                        FlutterError(
                            code: "PERMISSION_ERROR",
                            message: "Failed to request permissions",
                            details: error.localizedDescription
                        )
                    )
                } else {
                    result(granted)
                }
            }
        }
    }

    private func areNotificationsEnabled(result: @escaping FlutterResult) {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                let enabled = settings.authorizationStatus == .authorized
                result(enabled)
            }
        }
    }

    private func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
//    public func userNotificationCenter(
//        _ center: UNUserNotificationCenter,
//        willPresent notification: UNNotification,
//        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
//            Void
//    ) {
////        // Show notification even when app is in foreground
////        if #available(iOS 14.0, *) {
////            completionHandler([.banner, .sound, .badge])
////        } else {
////            completionHandler([.alert, .sound, .badge])
////        }
//    }

public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
        Void
) {
    let userInfo = notification.request.content.userInfo

    // ✅ Check if this is a Firebase notification with custom data
    if let customTitle = userInfo["title"] as? String,
       let customBody = userInfo["body"] as? String,
       (customTitle != notification.request.content.title || customBody != notification.request.content.body) {

        // ✅ Don't show the original FCM notification
        completionHandler([])

        // ✅ Show custom notification instead using existing method
        let args: [String: Any] = [
            "title": customTitle,
            "body": customBody,
            "data": userInfo,
            "imageUrl": userInfo["imageUrl"] as? String ?? ""
        ]

        // Use your existing showBackgroundNotification method
        showBackgroundNotification(args: args) { _ in
            // Notification shown successfully
        }
    } else {
        // ✅ For non-Firebase notifications or when no custom data, don't show anything
        // (Your foreground in-app banner will handle Firebase messages)
        completionHandler([])
    }
}

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        eventSink?(userInfo)
        completionHandler()
    }

    // MARK: - PKPushRegistryDelegate
    public func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        if type == .voIP {
            let tokenString = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
            voipToken = tokenString
        }
    }

    public func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        if type == .voIP {
            voipToken = nil
        }
    }

    public func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        // Handle incoming VoIP push notification
        if type == .voIP {
            print("Received VoIP push: \(payload.dictionaryPayload)")
            eventSink?(payload.dictionaryPayload)
        }
        completion()
    }
}*/
