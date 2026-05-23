import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("juliet.onboardingComplete") private var onboardingComplete = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DailyLogView()
                .tabItem { Label("Log",       systemImage: "list.bullet.rectangle.portrait.fill") }
                .tag(0)

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.pie.fill") }
                .tag(1)

            RecurringView()
                .tabItem { Label("Recurring", systemImage: "arrow.clockwise.circle.fill") }
                .tag(2)

            WalletView()
                .tabItem { Label("Wallet",    systemImage: "wallet.pass.fill") }
                .tag(3)
        }
        .tint(AppTheme.primary)
        // Show onboarding as a full-screen cover on first launch
        .fullScreenCover(isPresented: Binding(
            get: { !onboardingComplete },
            set: { _ in }
        )) {
            OpeningBalanceSetupView()
        }
    }
}

#Preview {
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
        ], inMemory: true)
}
