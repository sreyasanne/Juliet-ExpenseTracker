import Foundation
import UserNotifications
import SwiftUI

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error = error {
                print("[Notifications] Permission error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Schedule from NotificationTime models

    /// Call this whenever notification times change.
    /// Extracts primitive values first so no SwiftData objects cross into the callback closure.
    func rescheduleAll(times: [NotificationTime]) {
        struct TimeInfo: Sendable {
            let hour: Int
            let minute: Int
            let identifier: String
        }
        let infos = times
            .filter(\.isEnabled)
            .map { TimeInfo(hour: $0.hour, minute: $0.minute, identifier: $0.notificationIdentifier) }

        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            let ids = requests
                .filter { $0.identifier.hasPrefix("juliet_notification_") }
                .map(\.identifier)
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
            for info in infos {
                self.scheduleWith(hour: info.hour, minute: info.minute, identifier: info.identifier)
            }
        }
    }

    private func scheduleWith(hour: Int, minute: Int, identifier: String) {
        let messages = [
            "Time to log your expenses! Don't forget that coffee ☕",
            "Quick check-in: anything to log today?",
            "Juliet is waiting — keep your spending in check 💸",
            "Log your expenses now, thank yourself later.",
            "A few seconds of logging = clear finances 📊",
            "Did you spend anything today? Let's track it!"
        ]

        let content = UNMutableNotificationContent()
        content.title = "Juliet"
        content.body = messages.randomElement() ?? "Time to log your expenses!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("[Notifications] Schedule error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Remove a single time

    func remove(time: NotificationTime) {
        center.removePendingNotificationRequests(
            withIdentifiers: [time.notificationIdentifier]
        )
    }
}
