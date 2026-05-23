import Foundation
import SwiftData

/// Auto-saved weekly balance snapshot for one account.
/// Created automatically (never manually) by BalanceEngine on each week's first open.
@Model
final class BalanceSnapshot {
    var id: UUID
    var account: String
    var balance: Double
    var date: Date
    var weekOfYear: Int
    var year: Int

    init(account: String, balance: Double, date: Date = Date()) {
        self.id = UUID()
        self.account = account
        self.balance = balance
        self.date = date
        let cal = Calendar.current
        self.weekOfYear = cal.component(.weekOfYear, from: date)
        self.year       = cal.component(.year,       from: date)
    }
}

extension BalanceSnapshot {
    var formattedBalance: String { "₹\(String(format: "%.2f", balance))" }

    var weekLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        return fmt.string(from: date)
    }
}
