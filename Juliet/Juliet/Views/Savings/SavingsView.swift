import SwiftUI
import SwiftData
import Charts

struct SavingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsEntry.date, order: .reverse) private var entries: [SavingsEntry]

    @State private var showingAdd = false
    @State private var entryToEdit: SavingsEntry?

    var latestEntry: SavingsEntry? { entries.first }
    var averageSavingsRate: Double {
        guard !entries.isEmpty else { return 0 }
        return entries.map(\.savingsRate).reduce(0, +) / Double(entries.count)
    }
    var totalSetAside: Double { entries.reduce(0) { $0 + $1.amountSetAside } }
    var chartData: [SavingsEntry] { Array(entries.prefix(12).reversed()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if entries.isEmpty {
                        ContentUnavailableView {
                            Label("No Savings Data", systemImage: "banknote")
                        } description: {
                            Text("Log your monthly salary and savings to get started")
                        } actions: {
                            Button("Add Entry") { showingAdd = true }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.primary)
                        }
                        .padding(.top, 60)
                    } else {
                        balanceCard
                        savingsRateCard
                        if chartData.count > 1 { savingsChart }
                        historyList
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Savings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) { AddSavingsEntryView() }
            .sheet(item: $entryToEdit) { AddSavingsEntryView(entry: $0) }
        }
    }

    // MARK: - Balance card

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SBI Savings Balance")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(latestEntry?.formattedBalance ?? "₹0.00")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                }
                Spacer()
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(AppTheme.primaryMedium)
            }
            Divider().overlay(AppTheme.primaryLight)
            HStack(spacing: 0) {
                statBlock(title: "Last Salary",  value: latestEntry?.formattedSalary   ?? "—")
                Divider().frame(height: 36).overlay(AppTheme.primaryLight)
                statBlock(title: "Set Aside",    value: latestEntry?.formattedSetAside ?? "—")
                Divider().frame(height: 36).overlay(AppTheme.primaryLight)
                statBlock(title: "Total Saved",  value: "₹\(String(format: "%.0f", totalSetAside))")
            }
        }
        .padding(18)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1.5))
        .shadow(color: AppTheme.primary.opacity(0.08), radius: 10, y: 4)
        .padding(.horizontal)
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title).font(.caption2).foregroundStyle(AppTheme.textFaint)
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.text)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Savings rate card

    private var savingsRateCard: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().stroke(AppTheme.primaryLight, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: min((latestEntry?.savingsRate ?? 0) / 100, 1))
                    .stroke(
                        rateColor(latestEntry?.savingsRate ?? 0),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: latestEntry?.savingsRate)
                VStack(spacing: 0) {
                    Text(latestEntry?.formattedSavingsRate ?? "0%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                    Text("rate").font(.caption2).foregroundStyle(AppTheme.textFaint)
                }
            }
            .frame(width: 84, height: 84)

            VStack(alignment: .leading, spacing: 8) {
                Text("Savings Rate").font(.headline).foregroundStyle(AppTheme.text)
                Text("This month: \(latestEntry?.formattedSavingsRate ?? "0%")")
                    .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                Text("Average: \(String(format: "%.1f%%", averageSavingsRate))")
                    .font(.caption).foregroundStyle(AppTheme.textFaint)
                Text(rateMessage(latestEntry?.savingsRate ?? 0))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(rateColor(latestEntry?.savingsRate ?? 0))
            }
            Spacer()
        }
        .padding(18)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1.5))
        .shadow(color: AppTheme.primary.opacity(0.08), radius: 10, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Chart

    private var savingsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings History").font(.headline).foregroundStyle(AppTheme.text).padding(.horizontal)
            Chart(chartData) { entry in
                LineMark(
                    x: .value("Month", entry.date, unit: .month),
                    y: .value("Balance", entry.balance)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(AppTheme.primary)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                AreaMark(
                    x: .value("Month", entry.date, unit: .month),
                    y: .value("Balance", entry.balance)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.primary.opacity(0.30), AppTheme.secondary.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                PointMark(
                    x: .value("Month", entry.date, unit: .month),
                    y: .value("Balance", entry.balance)
                )
                .foregroundStyle(AppTheme.secondary)
                .symbolSize(40)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { val in
                    if let d = val.as(Date.self) {
                        AxisValueLabel {
                            Text(d, format: .dateTime.month(.abbreviated))
                                .font(.caption2).foregroundStyle(AppTheme.textFaint)
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1.5))
        .shadow(color: AppTheme.primary.opacity(0.08), radius: 10, y: 4)
        .padding(.horizontal)
    }

    // MARK: - History list

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Log").font(.headline).foregroundStyle(AppTheme.text).padding(.horizontal)
            ForEach(entries) { entry in
                SavingsEntryRow(entry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture { entryToEdit = entry }
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Helpers

    private func rateColor(_ rate: Double) -> Color {
        if rate >= 30 { return AppTheme.primary }
        return AppTheme.secondary
    }
    private func rateMessage(_ rate: Double) -> String {
        if rate >= 30 { return "Excellent saving!" }
        if rate >= 15 { return "Good progress" }
        if rate > 0   { return "Try to save more" }
        return "Start saving today"
    }
}

// MARK: - SavingsEntryRow

struct SavingsEntryRow: View {
    let entry: SavingsEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.monthYear)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                HStack(spacing: 4) {
                    Text("Salary: \(entry.formattedSalary)")
                    Text("·")
                    Text("Set aside: \(entry.formattedSetAside)")
                }
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.formattedBalance)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                Text(entry.formattedSavingsRate)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(entry.savingsRate >= 15 ? AppTheme.primary : AppTheme.secondary)
            }
        }
        .padding(14)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1))
    }
}
