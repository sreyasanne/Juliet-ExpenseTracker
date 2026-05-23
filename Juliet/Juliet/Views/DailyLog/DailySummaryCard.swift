import SwiftUI

struct DailySummaryCard: View {
    let total: Double            // expenses
    let income: Double           // income (0 if none that day)
    let breakdown: [(String, Double)]

    init(total: Double, income: Double = 0, breakdown: [(String, Double)]) {
        self.total = total
        self.income = income
        self.breakdown = breakdown
    }

    private var net: Double { income - total }
    private var hasIncome: Bool { income > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row — always show expenses; expand when income exists
            if hasIncome {
                // Three-stat layout: income / spent / net
                HStack(spacing: 0) {
                    statBlock(
                        label: "Income",
                        value: income,
                        icon: "arrow.down.circle.fill",
                        color: AppTheme.primary,
                        prefix: "+"
                    )
                    Divider().frame(height: 40).overlay(AppTheme.primaryLight)
                    statBlock(
                        label: "Spent",
                        value: total,
                        icon: "arrow.up.circle.fill",
                        color: AppTheme.secondary,
                        prefix: "-"
                    )
                    Divider().frame(height: 40).overlay(AppTheme.primaryLight)
                    statBlock(
                        label: "Net",
                        value: net,
                        icon: net >= 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                        color: net >= 0 ? AppTheme.primary : AppTheme.secondary,
                        prefix: net >= 0 ? "+" : ""
                    )
                }
            } else {
                // Original single-stat layout
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Total")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("₹\(String(format: "%.2f", total))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.text)
                    }
                    Spacer()
                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AppTheme.primary)
                }
            }

            // Tag breakdown chips
            if !breakdown.isEmpty {
                Divider().overlay(AppTheme.primaryLight)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(breakdown, id: \.0) { tag, amount in
                            TagChip(tag: tag, amount: amount)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.primaryLight, lineWidth: 1.5)
        )
        .shadow(color: AppTheme.primary.opacity(0.10), radius: 8, y: 3)
    }

    // MARK: - Stat block (income mode)

    private func statBlock(label: String, value: Double, icon: String, color: Color, prefix: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.body).foregroundStyle(color)
            Text("\(prefix)₹\(String(format: "%.0f", abs(value)))")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textFaint)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - TagChip

private struct TagChip: View {
    let tag: String
    let amount: Double
    private var color: Color { AppTheme.colorForTag(tag) }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: Expense.tagIcons[tag] ?? "tag.fill").font(.caption2)
            Text(tag).font(.caption.weight(.medium))
            Text("₹\(String(format: "%.0f", amount))")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(color.opacity(0.15), in: Capsule())
        .foregroundStyle(color)
    }
}
