import Foundation
import SwiftUI
import SwiftData

@Model
final class IncomeEntry {
    var id: UUID
    var amount: Double
    var source: String   // "Salary", "Freelance", "Cashback", "Gift", "Refund", "Other"
    var account: String  // "ICICI", "SBI", "Fampay"
    var date: Date
    var notes: String

    init(
        amount: Double,
        source: String,
        account: String,
        date: Date = Date(),
        notes: String = ""
    ) {
        self.id = UUID()
        self.amount = amount
        self.source = source
        self.account = account
        self.date = date
        self.notes = notes
    }
}

// MARK: - Static helpers

extension IncomeEntry {
    static let sources = ["Salary", "Freelance", "Cashback", "Gift", "Refund", "Other"]

    static let sourceIcons: [String: String] = [
        "Salary":    "briefcase.fill",
        "Freelance": "laptopcomputer",
        "Cashback":  "arrow.uturn.left.circle.fill",
        "Gift":      "gift.fill",
        "Refund":    "arrow.left.circle.fill",
        "Other":     "ellipsis.circle.fill"
    ]

    var formattedAmount: String { "₹\(String(format: "%.2f", amount))" }

    var icon: String { IncomeEntry.sourceIcons[source] ?? "indianrupeesign.circle.fill" }

    /// Alternates primary/secondary by source index so items look distinct
    var themeColor: Color {
        let idx = IncomeEntry.sources.firstIndex(of: source) ?? 0
        return idx.isMultiple(of: 2) ? AppTheme.primary : AppTheme.secondary
    }
}
