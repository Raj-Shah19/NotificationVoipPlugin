import FlutterMacOS
import UserNotifications
import AppKit

class MacNotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    var inappEventSink: FlutterEventSink?

    func showNotification(notification: [String: Any], template: [String: Any]?, result: @escaping FlutterResult) {
        let title = notification["title"] as? String ?? "Notification"
        let body = notification["body"] as? String ?? ""
        let groupKey = notification["groupKey"] as? String
        let tag = notification["tag"] as? String
        let templateType = template?["type"] as? String ?? "normal"

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let groupKey = groupKey {
            content.threadIdentifier = groupKey
        }

        if let unreadCount = notification["unreadMessageCount"] as? Int {
            content.badge = NSNumber(value: unreadCount)
        }

        switch templateType {
        case "bigText":
            content.body = template?["expandedText"] as? String ?? body
        case "bigPicture":
            if let imageUrl = template?["imageUrl"] as? String, let url = URL(string: imageUrl) {
                downloadImage(from: url) { localUrl in
                    if let localUrl = localUrl,
                       let attachment = try? UNNotificationAttachment(identifier: "image", url: localUrl, options: nil) {
                        content.attachments = [attachment]
                    }
                    self.scheduleNotification(content: content, tag: tag, result: result)
                }
                return
            }
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
                        notificationActions.append(UNTextInputNotificationAction(
                            identifier: actionId, title: actionTitle, options: [.foreground],
                            textInputButtonTitle: actionTitle, textInputPlaceholder: placeholder
                        ))
                    } else {
                        let foreground = action["foreground"] as? Bool ?? true
                        notificationActions.append(UNNotificationAction(
                            identifier: actionId, title: actionTitle,
                            options: foreground ? [.foreground] : []
                        ))
                    }
                }
                let category = UNNotificationCategory(identifier: categoryId, actions: notificationActions, intentIdentifiers: [], options: [])
                UNUserNotificationCenter.current().setNotificationCategories([category])
                content.categoryIdentifier = categoryId
            }
        default:
            break
        }

        scheduleNotification(content: content, tag: tag, result: result)
    }

    private func scheduleNotification(content: UNMutableNotificationContent, tag: String? = nil, result: @escaping FlutterResult) {
        let identifier = tag ?? UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                result(error == nil ? true : FlutterError(code: "NOTIFICATION_ERROR", message: error?.localizedDescription, details: nil))
            }
        }
    }

    func clearAll(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        result(nil)
    }

    func setBadgeCount(count: Int, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            NSApplication.shared.dockTile.badgeLabel = count > 0 ? "\(count)" : nil
            result(nil)
        }
    }

    func getBadgeCount(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            let badge = NSApplication.shared.dockTile.badgeLabel
            result(Int(badge ?? "0") ?? 0)
        }
    }

    // UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        var eventData: [String: Any] = [
            "title": response.notification.request.content.title,
            "body": response.notification.request.content.body
        ]
        for (key, value) in response.notification.request.content.userInfo {
            if let key = key as? String { eventData[key] = value }
        }
        inappEventSink?(eventData)
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    private func downloadImage(from url: URL, completion: @escaping (URL?) -> Void) {
        URLSession.shared.downloadTask(with: url) { localUrl, _, error in
            guard let localUrl = localUrl, error == nil else { completion(nil); return }
            let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
            try? FileManager.default.moveItem(at: localUrl, to: tmpUrl)
            completion(tmpUrl)
        }.resume()
    }
}
