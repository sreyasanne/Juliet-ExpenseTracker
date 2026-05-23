import Foundation
import SwiftData

@Model
final class NotificationTime {
    var id: UUID
    var hour: Int
    var minute: Int
    var isEnabled: Bool

    init(hour: Int, minute: Int, isEnabled: Bool = true) {
        self.id = UUID()
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
    }
}

extension NotificationTime {
    var displayTime: String {
        let h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let period = hour >= 12 ? "PM" : "AM"
        return String(format: "%d:%02d %@", h, minute, period)
    }

    var notificationIdentifier: String {
        "juliet_notification_\(id.uuidString)"
    }
}
