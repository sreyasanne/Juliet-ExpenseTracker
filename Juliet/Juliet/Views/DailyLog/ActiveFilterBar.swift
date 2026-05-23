import SwiftUI

struct ActiveFilterBar: View {
    @Binding var filter: ExpenseFilter
    @Binding var searchText: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !searchText.isEmpty {
                    ActivePill(label: "\(searchText)", icon: "magnifyingglass", color: AppTheme.primary) {
                        withAnimation { searchText = "" }
                    }
                }
                ForEach(filter.tags.sorted(), id: \.self) { tag in
                    ActivePill(
                        label: tag,
                        icon: Expense.tagIcons[tag] ?? "tag.fill",
                        color: AppTheme.colorForTag(tag)
                    ) {
                        withAnimation { _ = filter.tags.remove(tag) }
                    }
                }
                ForEach(filter.accounts.sorted(), id: \.self) { account in
                    ActivePill(label: account, icon: accountIcon(account), color: AppTheme.primary) {
                        withAnimation { _ = filter.accounts.remove(account) }
                    }
                }
                if filter.dateRangeEnabled {
                    ActivePill(label: dateRangeLabel, icon: "calendar", color: AppTheme.secondary) {
                        withAnimation { filter.dateRangeEnabled = false }
                    }
                }
                if !filter.isEmpty || !searchText.isEmpty {
                    Button {
                        withAnimation { filter = ExpenseFilter(); searchText = "" }
                    } label: {
                        Text("Clear all")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.secondaryLight, in: Capsule())
                            .foregroundStyle(AppTheme.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(AppTheme.background.opacity(0.9) as Color)
    }

    private var dateRangeLabel: String {
        let fmt = DateFormatter(); fmt.dateFormat = "d MMM"
        return "\(fmt.string(from: filter.dateFrom)) – \(fmt.string(from: filter.dateTo))"
    }

    private func accountIcon(_ source: String) -> String {
        switch source {
        case "ICICI":  return "creditcard.fill"
        case "SBI":    return "building.columns.fill"
        case "Fampay": return "wallet.pass.fill"
        default:       return "creditcard.fill"
        }
    }
}

// MARK: - ActivePill

private struct ActivePill: View {
    let label: String
    let icon: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2.weight(.semibold))
            Text(label).font(.caption.weight(.semibold)).lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(color.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .padding(.vertical, 5)
        .background(color.opacity(0.14), in: Capsule())
        .foregroundStyle(color)
    }
}
