import Flutter
import UserNotifications
import UIKit

private var bannerDataKey: UInt8 = 0

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    var inappEventSink: FlutterEventSink?
    var pushReceivedSink: FlutterEventSink?
    private var currentBanner: UIView?
    private var bannerDuration: TimeInterval = 5.0
    private var appName: String?

    /// Whether foreground push notifications should be suppressed.
    /// Set to `true` from Dart after receiving an `onPushReceived` event
    /// to prevent the notification from being displayed.
    var suppressNextForegroundNotification: Bool = false

    func configure(config: [String: Any]?) {
        if let duration = config?["bannerDuration"] as? Int {
            bannerDuration = Double(duration) / 1000.0
        }
        appName = config?["appName"] as? String
    }

    func showNotification(notification: [String: Any], template: [String: Any]?, result: @escaping FlutterResult) {
        let title = notification["title"] as? String ?? "Notification"
        let body = notification["body"] as? String ?? ""
        let imageUrl = notification["imageUrl"] as? String ?? template?["imageUrl"] as? String
        let groupKey = notification["groupKey"] as? String
        let tag = notification["tag"] as? String
        let templateType = template?["type"] as? String ?? "normal"

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        // Custom sound support
        if let soundName = notification["sound"] as? String, !soundName.isEmpty {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        } else {
            content.sound = .default
        }

        if let groupKey = groupKey {
            content.threadIdentifier = groupKey
        }

        // Badge
        if let unreadCount = notification["unreadMessageCount"] as? Int {
            content.badge = NSNumber(value: unreadCount)
        }

        // Template handling
        switch templateType {
        case "bigText":
            let expandedText = template?["expandedText"] as? String ?? body
            content.body = expandedText
        case "bigPicture", "bigBanner":
            if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                downloadImage(from: url) { localUrl in
                    if let localUrl = localUrl,
                       let attachment = try? UNNotificationAttachment(identifier: "image", url: localUrl, options: nil) {
                        content.attachments = [attachment]
                    }
                    if templateType == "bigBanner", let expandedText = template?["expandedText"] as? String {
                        content.subtitle = expandedText
                    }
                    self.scheduleNotification(content: content, tag: tag, result: result)
                }
                return
            }
        case "progress":
            let progressValue = template?["progressValue"] as? Int ?? 0
            let progressMax = template?["progressMax"] as? Int ?? 100
            content.body = "\(body) (\(progressValue)/\(progressMax))"
            // Suppress sound for progress updates
            content.sound = nil
        case "interactive":
            if let actions = template?["actions"] as? [[String: Any]] {
                var notificationActions: [UNNotificationAction] = []
                let categoryId = "nvp_interactive_\(UUID().uuidString)"

                for action in actions {
                    guard let actionId = action["id"] as? String,
                          let actionTitle = action["title"] as? String else { continue }
                    let isTextInput = action["isTextInput"] as? Bool ?? false
                    let placeholder = action["textInputPlaceholder"] as? String ?? "Type..."

                    if isTextInput {
                        let textAction = UNTextInputNotificationAction(
                            identifier: actionId, title: actionTitle,
                            options: [.foreground],
                            textInputButtonTitle: actionTitle,
                            textInputPlaceholder: placeholder
                        )
                        notificationActions.append(textAction)
                    } else {
                        let foreground = action["foreground"] as? Bool ?? true
                        let options: UNNotificationActionOptions = foreground ? [.foreground] : []
                        let notifAction = UNNotificationAction(identifier: actionId, title: actionTitle, options: options)
                        notificationActions.append(notifAction)
                    }
                }

                let category = UNNotificationCategory(
                    identifier: categoryId,
                    actions: notificationActions,
                    intentIdentifiers: [],
                    options: []
                )
                // Merge with existing categories instead of replacing them
                UNUserNotificationCenter.current().getNotificationCategories { existingCategories in
                    var updatedCategories = existingCategories
                    updatedCategories.insert(category)
                    UNUserNotificationCenter.current().setNotificationCategories(updatedCategories)
                }
                content.categoryIdentifier = categoryId
            }
        default:
            break // normal template — no extra processing
        }

        scheduleNotification(content: content, tag: tag, result: result)
    }

    private func scheduleNotification(content: UNMutableNotificationContent, tag: String? = nil, result: @escaping FlutterResult) {
        let identifier = tag ?? UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "NOTIFICATION_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    result(true)
                }
            }
        }
    }

    func showInAppNotification(notification: [String: Any], result: @escaping FlutterResult) {
        let title = notification["title"] as? String ?? "Notification"
        let body = notification["body"] as? String ?? ""
        let data = notification["data"] as? [String: Any] ?? [:]
        let imageUrl = notification["imageUrl"] as? String

        DispatchQueue.main.async {
            self.showBanner(title: title, body: body, data: data, imageUrl: imageUrl)
            result(true)
        }
    }

    func clearAll(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        DispatchQueue.main.async {
            self.currentBanner?.removeFromSuperview()
            self.currentBanner = nil
        }
        result(nil)
    }

    func cancelNotification(tag: String, result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [tag])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [tag])
        result(nil)
    }

    func setBadgeCount(count: Int, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            if #available(iOS 16.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(count) { _ in }
            } else {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
            result(nil)
        }
    }

    func getBadgeCount(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            result(UIApplication.shared.applicationIconBadgeNumber)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        var eventData: [String: Any] = [
            "title": response.notification.request.content.title,
            "body": response.notification.request.content.body
        ]
        for (key, value) in userInfo {
            if let key = key as? String {
                eventData[key] = value
            }
        }
        if let textResponse = response as? UNTextInputNotificationResponse {
            eventData["actionId"] = response.actionIdentifier
            eventData["replyText"] = textResponse.userText
        } else if response.actionIdentifier != UNNotificationDefaultActionIdentifier {
            eventData["actionId"] = response.actionIdentifier
        }

        // Buffer the event if the Dart sink isn't ready yet (terminated state)
        if let sink = inappEventSink {
            sink(eventData)
        } else {
            NotificationVoipPlugin.shared?.pendingNotificationTapEvents.append(eventData)
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Fire the push received stream so Dart can inspect the payload
        let userInfo = notification.request.content.userInfo
        var payload: [String: Any] = [
            "title": notification.request.content.title,
            "body": notification.request.content.body
        ]
        for (key, value) in userInfo {
            if let key = key as? String {
                payload[key] = value
            }
        }
        pushReceivedSink?(payload)

        // Give Dart a brief window to call suppressNextForegroundNotification()
        // before we decide whether to show the notification.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.suppressNextForegroundNotification {
                self.suppressNextForegroundNotification = false
                completionHandler([])
            } else {
                completionHandler([.banner, .sound, .badge])
            }
        }
    }

    // MARK: - Banner
    private func showBanner(title: String, body: String, data: [String: Any], imageUrl: String?) {
        currentBanner?.removeFromSuperview()

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }

        let safeAreaTop = window.safeAreaInsets.top
        let bannerHeight: CGFloat = 80
        let screenWidth = window.frame.width

        let banner = UIView()
        banner.frame = CGRect(x: 8, y: -bannerHeight, width: screenWidth - 16, height: bannerHeight)
        banner.backgroundColor = UIColor.systemBlue
        banner.layer.cornerRadius = 12
        banner.clipsToBounds = true

        // Avatar
        let avatarView = UIImageView()
        avatarView.frame = CGRect(x: 12, y: 16, width: 48, height: 48)
        avatarView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        avatarView.layer.cornerRadius = 24
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .white
        banner.addSubview(avatarView)

        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            loadImageAsync(from: url) { image in
                DispatchQueue.main.async { avatarView.image = image }
            }
        }

        // Text
        let textContainer = UIView()
        textContainer.frame = CGRect(x: 72, y: 12, width: screenWidth - 128, height: 56)
        banner.addSubview(textContainer)

        let titleLabel = UILabel()
        titleLabel.frame = CGRect(x: 0, y: 4, width: textContainer.frame.width, height: 20)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .white
        titleLabel.text = title
        textContainer.addSubview(titleLabel)

        let bodyLabel = UILabel()
        bodyLabel.frame = CGRect(x: 0, y: 26, width: textContainer.frame.width, height: 32)
        bodyLabel.font = UIFont.systemFont(ofSize: 14)
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        bodyLabel.text = body
        bodyLabel.numberOfLines = 2
        textContainer.addSubview(bodyLabel)

        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.frame = CGRect(x: screenWidth - 48, y: 16, width: 32, height: 32)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = UIColor.white.withAlphaComponent(0.8)
        closeButton.addTarget(self, action: #selector(closeBannerTapped), for: .touchUpInside)
        banner.addSubview(closeButton)

        objc_setAssociatedObject(banner, &bannerDataKey, data as AnyObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(bannerTapped(_:)))
        banner.addGestureRecognizer(tapGesture)

        window.addSubview(banner)
        currentBanner = banner

        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            banner.frame.origin.y = safeAreaTop + 8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + bannerDuration) {
            self.dismissBanner(banner)
        }
    }

    @objc private func bannerTapped(_ sender: UITapGestureRecognizer) {
        guard let banner = sender.view else { return }
        if let data = objc_getAssociatedObject(banner, &bannerDataKey) as? [String: Any] {
            inappEventSink?(data)
        }
        dismissBanner(banner)
    }

    @objc private func closeBannerTapped() {
        if let banner = currentBanner { dismissBanner(banner) }
    }

    private func dismissBanner(_ banner: UIView) {
        UIView.animate(withDuration: 0.3, animations: {
            banner.frame.origin.y = -banner.frame.height - 20
        }) { _ in
            banner.removeFromSuperview()
            if self.currentBanner == banner { self.currentBanner = nil }
        }
    }

    private func loadImageAsync(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                completion(nil); return
            }
            completion(image)
        }.resume()
    }

    private func downloadImage(from url: URL, completion: @escaping (URL?) -> Void) {
        URLSession.shared.downloadTask(with: url) { localUrl, _, error in
            guard let localUrl = localUrl, error == nil else {
                completion(nil); return
            }
            let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
            try? FileManager.default.moveItem(at: localUrl, to: tmpUrl)
            completion(tmpUrl)
        }.resume()
    }
}
