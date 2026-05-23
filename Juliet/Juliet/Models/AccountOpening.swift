import Foundation
import SwiftData

/// Stores the user-entered opening balance for one account.
/// Created once per account during first-launch onboarding.
/// Can be edited later from the Wallet tab.
@Model
final class AccountOpening {
    var id: UUID
    var account: String        // "ICICI", "SBI", "Fampay"
    var openingBalance: Double
    var setDate: Date

    init(account: String, openingBalance: Double, setDate: Date = Date()) {
        self.id = UUID()
        self.account = account
        self.openingBalance = openingBalance
        self.setDate = setDate
    }
}

extension AccountOpening {
    var formattedBalance: String {
        "₹\(String(format: "%.2f", openingBalance))"
    }
}
