import SwiftUI
import SwiftData
import Charts

struct WalletView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var openings:   [AccountOpening]
    @Query(sort: \IncomeEntry.date,      order: .reverse) private var allIncome:    [IncomeEntry]
    @Query(sort: \Expense.date,          order: .reverse) private var allExpenses:  [Expense]
    @Query(sort: \BalanceSnapshot.date,  order: .ascending) private var snapshots: [BalanceSnapshot]

    @State private var showingEditOpenings = false
    @State private var showingAddIncome    = false
    @State private var incomeToEdit: IncomeEntry?
    @State private var selectedSnapshotAccount = "All"

    // MARK: - Computed

    private var totalBalance: Double {
        BalanceEngine.totalBalance(openings: openings, income: allIncome, expenses: allExpenses)
    }

    private func accountBalance(_ account: String) -> Double {
        BalanceEngine.balance(account: account, openings: openings, income: allIncome, expenses: allExpenses)
    }

    private var todayNet: Double {
        BalanceEngine.dailyNetCashflow(date: Date(), income: allIncome, expenses: allExpenses)
    }
    private var todayIncome: Double   { BalanceEngine.dailyIncome(date: Date(), income: allIncome) }
    private var todayExpenses: Double { BalanceEngine.dailyExpenses(date: Date(), expenses: allExpenses) }

    private var recentIncome: [IncomeEntry] { Array(allIncome.prefix(20)) }

    /// Snapshots for the trend chart — total or per-account
    private var trendData: [(date: Date, balance: Double)] {
        if selectedSnapshotAccount == "All" {
            // Group snapshots by week, sum all accounts
            var dict: [Int: (Date, Double)] = [:]
            for snap in snapshots {
                let key = snap.year * 100 + snap.weekOfYear
                dict[key] = (snap.date, (dict[key]?.1 ?? 0) + snap.balance)
            }
            return dict.values.sorted { $0.0 < $1.0 }
        } else {
            return snapshots
                .filter { $0.account == selectedSnapshotAccount }
                .map { (date: $0.date, balance: $0.balance) }
        }
    }

    private var thisMonthSavingsRate: Double {
        BalanceEngine.savingsRate(month: Date(), income: allIncome, expenses: allExpenses)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    totalBalanceCard
                    accountCardsRow
                    todayCashflowCard
                    if trendData.count > 1 { trendChartCard }
                    incomeLogSection
                }
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingEditOpenings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(AppTheme.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddIncome = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddIncome) { AddIncomeView() }
            .sheet(item: $incomeToEdit) { AddIncomeView(entry: $0) }
            .sheet(isPresented: $showingEditOpenings) { EditOpeningBalancesView() }
            .onAppear {
                BalanceEngine.takeSnapshotsIfNeeded(
                    context: modelContext,
                    openings: openings,
                    income: allIncome,
                    expenses: allExpenses,
                    snapshots: snapshots
                )
            }
        }
    }

    // MARK: - Total balance card

    private var totalBalanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Balance")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("₹\(String(format: "%.2f", totalBalance))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Savings Rate")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textFaint)
                    Text(String(format: "%.1f%%", thisMonthSavingsRate))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(thisMonthSavingsRate >= 20 ? AppTheme.primary : AppTheme.secondary)
                    Text("this month")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textFaint)
                }
            }
        }
        .padding(18)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1.5))
        .shadow(color: AppTheme.primary.opacity(0.08), radius: 10, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Account cards row

    private var accountCardsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Expense.paymentSources, id: \.self) { account in
                    AccountBalanceCard(
                        account: account,
                        balance: accountBalance(account)
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Today cashflow card

    private var todayCashflowCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's Cashflow")
                .font(.headline)
                .foregroundStyle(AppTheme.text)

            HStack(spacing: 0) {
                cashflowStat(
                    label: "Income",
                    value: todayIncome,
                    icon: "arrow.down.circle.fill",
                    color: AppTheme.primary
                )
                Divider().frame(height: 40).overlay(AppTheme.primaryLight)
                cashflowStat(
                    label: "Spent",
                    value: todayExpenses,
                    icon: "arrow.up.circle.fill",
                    color: AppTheme.secondary
                )
                Divider().frame(height: 40).overlay(AppTheme.primaryLight)
                cashflowStat(
                    label: "Net",
                    value: todayNet,
                    icon: todayNet >= 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                    color: todayNet >= 0 ? AppTheme.primary : AppTheme.secondary,
                    showSign: true
                )
            }
        }
        .padding(18)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1.5))
        .shadow(color: AppTheme.primary.opacity(0.08), radius: 10, y: 4)
        .padding(.horizontal)
    }

    private func cashflowStat(label: String, value: Double, icon: String, color: Color, showSign: Bool = false) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(showSign
                 ? "\(value >= 0 ? "+" : "")₹\(String(format: "%.0f", value))"
                 : "₹\(String(format: "%.0f", value))")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textFaint)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Trend chart

    private var trendChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Balance Trend")
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Picker("Account", selection: $selectedSnapshotAccount) {
                    Text("All").tag("All")
                    ForEach(Expense.paymentSources, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.primary)
                .font(.caption)
            }

            Chart(trendData, id: \.date) { item in
                LineMark(
                    x: .value("Week", item.date, unit: .weekOfYear),
                    y: .value("Balance", item.balance)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(AppTheme.primary)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                AreaMark(
                    x: .value("Week", item.date, unit: .weekOfYear),
                    y: .value("Balance", item.balance)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.primary.opacity(0.28), AppTheme.secondary.opacity(0.04)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                PointMark(
                    x: .value("Week", item.date, unit: .weekOfYear),
                    y: .value("Balance", item.balance)
                )
                .foregroundStyle(AppTheme.secondary)
                .symbolSize(36)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { val in
                    if let d = val.as(Date.self) {
                        AxisValueLabel {
                            Text(d, format: .dateTime.day().month(.abbreviated))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textFaint)
                        }
                    }
                }
            }
            .frame(height: 180)

            Text("Weekly auto-saved snapshots")
                .font(.caption2)
                .foregroundStyle(AppTheme.textFaint)
        }
        .padding(18)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1.5))
        .shadow(color: AppTheme.primary.opacity(0.08), radius: 10, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Income log section

    @ViewBuilder
    private var incomeLogSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Income")
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Button {
                    showingAddIncome = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.caption.weight(.bold))
                        Text("Add").font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.primaryLight, in: Capsule())
                    .foregroundStyle(AppTheme.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            if recentIncome.isEmpty {
                ContentUnavailableView {
                    Label("No Income Logged", systemImage: "arrow.down.circle")
                } description: {
                    Text("Tap + to log salary, cashback, or any other income")
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(recentIncome) { entry in
                        IncomeRowView(entry: entry)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                            .onTapGesture { incomeToEdit = entry }
                        if entry.id != recentIncome.last?.id {
                            Divider().padding(.leading, 72).padding(.horizontal, 16)
                        }
                    }
                }
                .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1))
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - AccountBalanceCard

struct AccountBalanceCard: View {
    let account: String
    let balance: Double

    private var icon: String {
        switch account {
        case "ICICI":  return "creditcard.fill"
        case "SBI":    return "building.columns.fill"
        case "Fampay": return "wallet.pass.fill"
        default:       return "creditcard.fill"
        }
    }

    private var color: Color {
        let idx = Expense.paymentSources.firstIndex(of: account) ?? 0
        return idx.isMultiple(of: 2) ? AppTheme.primary : AppTheme.secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.body.weight(.semibold)).foregroundStyle(color)
                }
                Spacer()
                Text(balance >= 0 ? "Active" : "Overdrawn")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(color.opacity(0.12), in: Capsule())
                    .foregroundStyle(color)
            }
            Spacer()
            Text(account)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            Text("₹\(String(format: "%.2f", balance))")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(balance >= 0 ? AppTheme.text : AppTheme.secondary)
        }
        .padding(14)
        .frame(width: 150, height: 120)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(color.opacity(0.25), lineWidth: 1.5))
        .shadow(color: color.opacity(0.10), radius: 8, y: 3)
    }
}

// MARK: - EditOpeningBalancesView

struct EditOpeningBalancesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var openings: [AccountOpening]

    @State private var balances: [String: String] = [:]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("These are the starting balances Juliet uses to compute your real-time account totals.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Section("Opening Balances") {
                    ForEach(Expense.paymentSources, id: \.self) { account in
                        HStack {
                            Text(account).foregroundStyle(AppTheme.text)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("₹").foregroundStyle(AppTheme.textFaint)
                                TextField("0", text: Binding(
                                    get: { balances[account] ?? "" },
                                    set: { balances[account] = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Opening Balances")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold).foregroundStyle(AppTheme.primary)
                }
            }
            .onAppear { loadCurrentValues() }
        }
    }

    private func loadCurrentValues() {
        for account in Expense.paymentSources {
            let existing = openings.first { $0.account == account }
            balances[account] = existing.map { String(format: "%.2f", $0.openingBalance) } ?? "0"
        }
    }

    private func save() {
        for account in Expense.paymentSources {
            let val = Double(balances[account] ?? "") ?? 0
            if let existing = openings.first(where: { $0.account == account }) {
                existing.openingBalance = val
                existing.setDate = Date()
            } else {
                modelContext.insert(AccountOpening(account: account, openingBalance: val))
            }
        }
        dismiss()
    }
}
