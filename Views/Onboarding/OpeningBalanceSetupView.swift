import SwiftUI
import SwiftData

/// Shown exactly once on first launch.
/// Asks for the current real-world balance of each account so the engine
/// has a correct starting point.
struct OpeningBalanceSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("juliet.onboardingComplete") private var onboardingComplete = false

    // One text field per account
    @State private var balances: [String: String] = [
        "ICICI": "", "SBI": "", "Fampay": ""
    ]
    @State private var currentPage = 0

    private let accounts = Expense.paymentSources
    private let accountIcons = [
        "ICICI":  "creditcard.fill",
        "SBI":    "building.columns.fill",
        "Fampay": "wallet.pass.fill"
    ]
    private let accountDescriptions = [
        "ICICI":  "Your ICICI bank account",
        "SBI":    "Your SBI savings account",
        "Fampay": "Your Fampay prepaid balance"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.top, 48)

                Text("Welcome to Juliet")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)

                Text("Enter your current account balances to get started.\nJuliet will track everything from here.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 36)

            // Balance cards
            VStack(spacing: 14) {
                ForEach(accounts, id: \.self) { account in
                    AccountBalanceInputCard(
                        account: account,
                        icon: accountIcons[account] ?? "creditcard.fill",
                        description: accountDescriptions[account] ?? "",
                        balance: Binding(
                            get: { balances[account] ?? "" },
                            set: { balances[account] = $0 }
                        )
                    )
                }
            }
            .padding(.horizontal, 20)

            Text("You can always update these later from the Wallet tab.")
                .font(.caption)
                .foregroundStyle(AppTheme.textFaint)
                .padding(.top, 16)
                .padding(.horizontal, 32)
                .multilineTextAlignment(.center)

            Spacer()

            // CTA
            Button(action: save) {
                HStack(spacing: 8) {
                    Text("Set Up Juliet")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(AppTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    // MARK: - Save

    private func save() {
        for account in accounts {
            let raw = balances[account] ?? ""
            let amount = Double(raw) ?? 0
            // Remove any existing opening for this account before inserting
            modelContext.insert(AccountOpening(account: account, openingBalance: amount))
        }
        onboardingComplete = true
    }
}

// MARK: - AccountBalanceInputCard

private struct AccountBalanceInputCard: View {
    let account: String
    let icon: String
    let description: String
    @Binding var balance: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryLight)
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(account)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textFaint)
            }

            Spacer()

            HStack(spacing: 4) {
                Text("₹")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("0", text: $balance)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 96)
            }
        }
        .padding(16)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.primaryLight, lineWidth: 1.5)
        )
        .shadow(color: AppTheme.primary.opacity(0.07), radius: 6, y: 2)
    }
}

#Preview {
    OpeningBalanceSetupView()
        .modelContainer(for: [AccountOpening.self], inMemory: true)
}
