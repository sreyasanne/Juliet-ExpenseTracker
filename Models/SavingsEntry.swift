import Foundation
import SwiftData

@Model
final class SavingsEntry {
    var id: UUID
    var date: Date
    var salary: Double
    var amountSetAside: Double
    var balance: Double
    var notes: String

    init(
        date: Date = Date(),
        salary: Double,
        amountSetAside: Double,
        balance: Double,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.salary = salary
        self.amountSetAside = amountSetAside
        self.balance = balance
        self.notes = notes
    }
}

// MARK: - Computed helpers

extension SavingsEntry {
    var savingsRate: Double {
        guard salary > 0 else { return 0 }
        return (amountSetAside / salary) * 100
    }

    var formattedBalance: String {
        "₹\(String(format: "%.2f", balance))"
    }

    var formattedSalary: String {
        "₹\(String(format: "%.2f", salary))"
    }

    var formattedSetAside: String {
        "₹\(String(format: "%.2f", amountSetAside))"
    }

    var formattedSavingsRate: String {
        String(format: "%.1f%%", savingsRate)
    }

    var monthYear: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date)
    }
}
