import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    private var tagColor: Color { AppTheme.colorForTag(expense.tag) }

    var body: some View {
        HStack(spacing: 14) {
            // Tag icon bubble
            ZStack {
                Circle()
                    .fill(tagColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: expense.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tagColor)
            }

            // Details
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.tag)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                if !expense.notes.isEmpty {
                    Text(expense.notes)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    Image(systemName: paymentIcon(expense.paymentSource))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textFaint)
                    Text(expense.paymentSource)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textFaint)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textFaint)
                    Text(expense.date, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textFaint)
                }
            }

            Spacer()

            Text(expense.formattedAmount)
                .font(.body.weight(.bold))
                .foregroundStyle(AppTheme.text)
        }
        .padding(.vertical, 6)
    }

    private func paymentIcon(_ source: String) -> String {
        switch source {
        case "ICICI":  return "creditcard.fill"
        case "SBI":    return "building.columns.fill"
        case "Fampay": return "wallet.pass.fill"
        default:       return "creditcard.fill"
        }
    }
}
