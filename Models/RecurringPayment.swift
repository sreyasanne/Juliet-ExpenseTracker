import Foundation
import SwiftData

@Model
final class RecurringPayment {
    var id: UUID
    var name: String
    var amount: Double
    var frequency: String       // "Weekly", "Monthly", "Yearly"
    var category: String
    var account: String
    var lastPaidDate: Date?
    var isActive: Bool
    var notes: String

    // MARK: - Subscription metadata
    var renewalDate: Date?       // Next billing / renewal date
    var loginEmail: String       // Email used to log in to this service
    var website: String          // Service URL (e.g. https://netflix.com)
    var passwordHint: String     // A hint — never store the real password

    init(
        name: String,
        amount: Double,
        frequency: String = "Monthly",
        category: String,
        account: String,
        notes: String = "",
        renewalDate: Date? = nil,
        loginEmail: String = "",
        website: String = "",
        passwordHint: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.frequency = frequency
        self.category = category
        self.account = account
        self.notes = notes
        self.isActive = true
        self.renewalDate = renewalDate
        self.loginEmail = loginEmail
        self.website = website
        self.passwordHint = passwordHint
    }
}

// MARK: - Computed helpers

extension RecurringPayment {
    static let frequencies = ["Weekly", "Monthly", "Yearly"]

    var isPaidThisMonth: Bool {
        guard let lastPaid = lastPaidDate else { return false }
        return Calendar.current.isDate(lastPaid, equalTo: Date(), toGranularity: .month)
    }

    var isPaidThisYear: Bool {
        guard let lastPaid = lastPaidDate else { return false }
        return Calendar.current.isDate(lastPaid, equalTo: Date(), toGranularity: .year)
    }

    var isPaidThisWeek: Bool {
        guard let lastPaid = lastPaidDate else { return false }
        return Calendar.current.isDate(lastPaid, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isDue: Bool {
        switch frequency {
        case "Weekly":  return !isPaidThisWeek
        case "Monthly": return !isPaidThisMonth
        case "Yearly":  return !isPaidThisYear
        default:        return !isPaidThisMonth
        }
    }

    var formattedAmount: String {
        "₹\(String(format: "%.2f", amount))"
    }

    var lastPaidText: String {
        guard let d = lastPaidDate else { return "Never paid" }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return "Paid \(fmt.string(from: d))"
    }

    /// Days until renewal, or nil if no renewal date set
    var daysUntilRenewal: Int? {
        guard let renewal = renewalDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: renewal).day ?? 0
        return days
    }

    var renewalStatusText: String? {
        guard let days = daysUntilRenewal else { return nil }
        if days < 0  { return "Renewed \(abs(days))d ago" }
        if days == 0 { return "Renews today" }
        if days == 1 { return "Renews tomorrow" }
        return "Renews in \(days)d"
    }

    var renewalStatusColor: String {
        guard let days = daysUntilRenewal else { return "secondary" }
        if days <= 3  { return "red" }
        if days <= 7  { return "orange" }
        return "green"
    }

    var hasSubscriptionDetails: Bool {
        !loginEmail.isEmpty || !website.isEmpty || !passwordHint.isEmpty || renewalDate != nil
    }
}
