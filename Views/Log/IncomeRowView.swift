import SwiftUI

struct IncomeRowView: View {
    let entry: IncomeEntry

    var body: some View {
        HStack(spacing: 14) {
            // Source icon bubble
            ZStack {
                Circle()
                    .fill(entry.themeColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: entry.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(entry.themeColor)
            }

            // Details
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.source)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    Image(systemName: accountIcon(entry.account))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textFaint)
                    Text(entry.account)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textFaint)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textFaint)
                    Text(entry.date, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textFaint)
                }
            }

            Spacer()

            // Amount — green tint using primary colour
            HStack(spacing: 2) {
                Text("+")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
                Text(entry.formattedAmount)
                    .font(.body.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
            }
        }
        .padding(.vertical, 6)
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
