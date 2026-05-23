import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var amount: Double
    var date: Date
    var notes: String
    var tag: String
    var paymentSource: String

    init(
        amount: Double,
        date: Date = Date(),
        notes: String = "",
        tag: String,
        paymentSource: String
    ) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.notes = notes
        self.tag = tag
        self.paymentSource = paymentSource
    }
}

// MARK: - Static helpers

extension Expense {
    static let predefinedTags = ["Food", "Friends", "Drinks", "Office", "Home", "Travel"]
    static let paymentSources = ["ICICI", "SBI", "Fampay"]

    static let tagIcons: [String: String] = [
        "Food":    "fork.knife",
        "Friends": "person.2.fill",
        "Drinks":  "cup.and.saucer.fill",
        "Office":  "briefcase.fill",
        "Home":    "house.fill",
        "Travel":  "airplane"
    ]

    // Strict palette: only AppTheme.primaryHex or AppTheme.secondaryHex
    // Even-indexed tags → Sky Blue, odd-indexed → Baby Pink
    static let tagColors: [String: String] = [
        "Food":    AppTheme.primaryHex,    // Sky Blue
        "Friends": AppTheme.secondaryHex,  // Baby Pink
        "Drinks":  AppTheme.primaryHex,
        "Office":  AppTheme.secondaryHex,
        "Home":    AppTheme.primaryHex,
        "Travel":  AppTheme.secondaryHex
    ]

    var formattedAmount: String {
        "₹\(String(format: "%.2f", amount))"
    }

    var icon: String {
        Expense.tagIcons[tag] ?? "tag.fill"
    }
}
