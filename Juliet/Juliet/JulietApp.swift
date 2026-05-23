import SwiftUI
import SwiftData

@main
struct JulietApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    Expense.self,
                    IncomeEntry.self,
                    AccountOpening.self,
                    BalanceSnapshot.self,
                    RecurringPayment.self,
                    SavingsEntry.self,
                    CustomTag.self,
                    NotificationTime.self
                ])
                .onAppear {
                    NotificationManager.shared.requestPermission()
                }
        }
    }
}
