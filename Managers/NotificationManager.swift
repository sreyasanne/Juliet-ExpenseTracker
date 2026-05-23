import Foundation
import UserNotifications
import SwiftUI

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[Notifications] Permission error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Schedule from NotificationTime models

    /// Call this whenever notification times change.
    func rescheduleAll(times: [NotificationTime]) {
        // Remove all existing Juliet notifications
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            let ids = requests
                .filter { $0.identifier.hasPrefix("juliet_notification_") }
                .map(\.identifier)
            self.center.removePendingNotificationRequests(withIdentifiers: ids)

            // Schedule new ones
            for time in times where time.isEnabled {
                self.schedule(time: time)
            }
        }
    }

    private func schedule(time: NotificationTime) {
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
        dateComponents.hour = time.hour
        dateComponents.minute = time.minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: time.notificationIdentifier,
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
