import Flutter
import PushKit
import UIKit

class TokenHandler: NSObject, PKPushRegistryDelegate {
    var voipToken: String?
    var apnsToken: String?
    var tokenRefreshSink: FlutterEventSink?
    private var voipRegistry: PKPushRegistry?

    override init() {
        super.init()
    }

    func setup() {
        voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry?.delegate = self
        voipRegistry?.desiredPushTypes = [.voIP]
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func setAPNsToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        apnsToken = tokenString
        tokenRefreshSink?(tokenString)
    }

    func getAPNsToken(result: @escaping FlutterResult) {
        result(apnsToken)
    }

    func getVoIPToken(result: @escaping FlutterResult) {
        result(voipToken)
    }

    func getPushToken(result: @escaping FlutterResult) {
        result(apnsToken)
    }

    func getFCMToken(result: @escaping FlutterResult) {
        // Retrieve FCM token at runtime via Firebase Messaging,
        // without requiring Firebase as a hard dependency of this plugin.
        // Works when the host app has firebase_messaging / FirebaseMessaging configured.
        guard let messagingClass = NSClassFromString("FIRMessaging") else {
            result(nil)
            return
        }

        let messagingSel = NSSelectorFromString("messaging")
        guard let messagingType = messagingClass as? NSObjectProtocol,
              messagingType.responds(to: messagingSel),
              let messaging = messagingType.perform(messagingSel)?.takeUnretainedValue() else {
            result(nil)
            return
        }

        // Use the synchronous fcmToken property (available since Firebase Messaging 7+)
        let tokenSel = NSSelectorFromString("FCMToken")
        if messaging.responds(to: tokenSel),
           let token = messaging.perform(tokenSel)?.takeUnretainedValue() as? String,
           !token.isEmpty {
            result(token)
        } else {
            result(nil)
        }
    }

    // MARK: - PKPushRegistryDelegate
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if type == .voIP {
            let tokenString = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
            voipToken = tokenString
            tokenRefreshSink?(tokenString)
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        if type == .voIP { voipToken = nil }
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        if type == .voIP {
            // iOS 13+ REQUIRES reportNewIncomingCall() before this completion fires.
            // If we don't, iOS kills the app and may stop delivering VoIP pushes.
            NotificationVoipPlugin.shared?.handleVoIPPush(payload: payload, completion: completion)
        } else {
            completion()
        }
    }
}
