import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]

    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedChartType: ChartType = .byTag
    @State private var customStart = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var customEnd = Date()

    enum TimePeriod: String, CaseIterable { case week = "Week"; case month = "Month"; case custom = "Custom" }
    enum ChartType: String, CaseIterable { case byTag = "By Category"; case byAccount = "By Account"; case daily = "Daily Trend" }

    // MARK: - Filtered data

    var filteredExpenses: [Expense] {
        let cal = Calendar.current
        switch selectedPeriod {
        case .week:   return allExpenses.filter { $0.date >= cal.date(byAdding: .day, value: -6, to: Date())! }
        case .month:  return allExpenses.filter { $0.date >= cal.date(byAdding: .month, value: -1, to: Date())! }
        case .custom: return allExpenses.filter { $0.date >= customStart && $0.date <= customEnd }
        }
    }
    var totalSpend: Double { filteredExpenses.reduce(0) { $0 + $1.amount } }

    var tagData: [(tag: String, amount: Double)] {
        var dict: [String: Double] = [:]
        for e in filteredExpenses { dict[e.tag, default: 0] += e.amount }
        return dict.map { (tag: $0.key, amount: $0.value) }.sorted { $0.amount > $1.amount }
    }
    var accountData: [(account: String, amount: Double)] {
        var dict: [String: Double] = [:]
        for e in filteredExpenses { dict[e.paymentSource, default: 0] += e.amount }
        return dict.map { (account: $0.key, amount: $0.value) }.sorted { $0.amount > $1.amount }
    }
    var dailyData: [(date: Date, amount: Double)] {
        var dict: [Date: Double] = [:]
        for e in filteredExpenses {
            let day = Calendar.current.startOfDay(for: e.date)
            dict[day, default: 0] += e.amount
        }
        return dict.map { (date: $0.key, amount: $0.value) }.sorted { $0.date < $1.date }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period picker
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedPeriod == .custom { customDateRange }

                    totalCard

                    Picker("Chart", selection: $selectedChartType) {
                        ForEach(ChartType.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if filteredExpenses.isEmpty {
                        ContentUnavailableView("No Data", systemImage: "chart.pie",
                                              description: Text("No expenses in this period"))
                            .padding(.top, 40)
                    } else {
                        chartSection
                        if selectedChartType != .daily { legendSection }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Cards

    private var totalCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Spent")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Text("₹\(String(format: "%.2f", totalSpend))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                Text("\(filteredExpenses.count) transactions")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textFaint)
            }
            Spacer()
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.primaryMedium)
        }
        .padding(18)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1.5))
        .shadow(color: AppTheme.primary.opacity(0.08), radius: 8, y: 3)
        .padding(.horizontal)
    }

    // MARK: - Chart section

    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedChartType.rawValue)
                .font(.headline)
                .foregroundStyle(AppTheme.text)
                .padding(.horizontal)

            switch selectedChartType {
            case .byTag:     pieChart(data: tagData.map { ($0.tag, $0.amount) }).padding(.horizontal)
            case .byAccount: barChart(data: accountData.map { ($0.account, $0.amount) }).padding(.horizontal)
            case .daily:     dailyLineChart.padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1.5))
        .shadow(color: AppTheme.primary.opacity(0.08), radius: 8, y: 3)
        .padding(.horizontal)
    }

    private func pieChart(data: [(String, Double)]) -> some View {
        Chart(Array(data.enumerated()), id: \.offset) { idx, item in
            SectorMark(
                angle: .value("Amount", item.1),
                innerRadius: .ratio(0.52),
                angularInset: 2
            )
            .cornerRadius(5)
            .foregroundStyle(AppTheme.chartPalette[idx % AppTheme.chartPalette.count])
        }
        .chartLegend(.hidden)
        .frame(height: 240)
    }

    private func barChart(data: [(String, Double)]) -> some View {
        Chart(Array(data.enumerated()), id: \.offset) { idx, item in
            BarMark(
                x: .value("Label", item.0),
                y: .value("Amount", item.1)
            )
            .cornerRadius(6)
            .foregroundStyle(AppTheme.chartPalette[idx % AppTheme.chartPalette.count])
            .annotation(position: .top) {
                Text("₹\(String(format: "%.0f", item.1))")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .chartLegend(.hidden)
        .frame(height: 220)
    }

    private var dailyLineChart: some View {
        Chart(dailyData, id: \.date) { item in
            LineMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Amount", item.amount)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(AppTheme.primary)
            .lineStyle(StrokeStyle(lineWidth: 2.5))

            AreaMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Amount", item.amount)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [AppTheme.primary.opacity(0.35), AppTheme.secondary.opacity(0.05)],
                    startPoint: .top, endPoint: .bottom
                )
            )

            PointMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Amount", item.amount)
            )
            .foregroundStyle(AppTheme.secondary)
            .symbolSize(40)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { val in
                if let d = val.as(Date.self) {
                    AxisValueLabel {
                        Text(d, format: .dateTime.day())
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textFaint)
                    }
                }
            }
        }
        .frame(height: 200)
    }

    // MARK: - Legend

    @ViewBuilder
    private var legendSection: some View {
        let data: [(String, Double)] = selectedChartType == .byAccount
            ? accountData.map { ($0.account, $0.amount) }
            : tagData.map { ($0.tag, $0.amount) }

        VStack(spacing: 10) {
            ForEach(Array(data.enumerated()), id: \.offset) { idx, item in
                HStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.chartPalette[idx % AppTheme.chartPalette.count])
                        .frame(width: 12, height: 12)
                    Text(item.0)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Text("₹\(String(format: "%.2f", item.1))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.text)
                    Text(percentage(item.1))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 46, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1.5))
        .shadow(color: AppTheme.primary.opacity(0.08), radius: 8, y: 3)
        .padding(.horizontal)
    }

    private var customDateRange: some View {
        VStack(spacing: 12) {
            DatePicker("From", selection: $customStart, in: ...customEnd, displayedComponents: .date)
                .tint(AppTheme.primary)
            DatePicker("To",   selection: $customEnd,   in: customStart...Date(), displayedComponents: .date)
                .tint(AppTheme.primary)
        }
        .padding(.horizontal)
    }

    private func percentage(_ amount: Double) -> String {
        guard totalSpend > 0 else { return "0%" }
        return String(format: "%.1f%%", (amount / totalSpend) * 100)
    }
}
