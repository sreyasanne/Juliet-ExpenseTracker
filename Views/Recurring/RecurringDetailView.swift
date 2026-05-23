import SwiftUI

struct RecurringDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let payment: RecurringPayment
    let onEdit: () -> Void
    let onMarkPaid: () -> Void

    @State private var showPasswordHint = false
    @State private var copiedField: String? = nil

    var body: some View {
        NavigationStack {
            List {
                Section {
                    heroCard
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section("Billing") {
                    detailRow(icon: "indianrupeesign.circle.fill", label: "Amount",    value: payment.formattedAmount,  color: AppTheme.primary)
                    detailRow(icon: "arrow.clockwise",             label: "Frequency", value: payment.frequency,        color: AppTheme.primary)
                    detailRow(icon: "creditcard.fill",             label: "Account",   value: payment.account,          color: AppTheme.primary)
                    detailRow(icon: "checkmark.circle.fill",       label: "Last Paid", value: payment.lastPaidText,
                              color: payment.isDue ? AppTheme.secondary : AppTheme.primary)

                    if let renewal = payment.renewalDate {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(renewalColor.opacity(0.15)).frame(width: 34, height: 34)
                                Image(systemName: "calendar.badge.clock").font(.subheadline).foregroundStyle(renewalColor)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Renewal Date").font(.caption).foregroundStyle(AppTheme.textSecondary)
                                Text(renewal, style: .date).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.text)
                            }
                            Spacer()
                            if let status = payment.renewalStatusText {
                                Text(status)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(renewalColor.opacity(0.14), in: Capsule())
                                    .foregroundStyle(renewalColor)
                            }
                        }
                    }
                }

                if payment.hasSubscriptionDetails {
                    Section("Login Details") {
                        if !payment.loginEmail.isEmpty {
                            copyableRow(icon: "envelope.fill", label: "Email",
                                        value: payment.loginEmail, fieldId: "email", color: AppTheme.primary)
                        }
                        if !payment.website.isEmpty {
                            let clean = payment.website.hasPrefix("http") ? payment.website : "https://\(payment.website)"
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(AppTheme.primaryLight).frame(width: 34, height: 34)
                                    Image(systemName: "globe").font(.subheadline).foregroundStyle(AppTheme.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Website").font(.caption).foregroundStyle(AppTheme.textSecondary)
                                    Text(payment.website).font(.subheadline).foregroundStyle(AppTheme.primary)
                                }
                                Spacer()
                                Link(destination: URL(string: clean) ?? URL(string: "https://")!) {
                                    Image(systemName: "arrow.up.right.square.fill").foregroundStyle(AppTheme.primary)
                                }
                            }
                        }
                        if !payment.passwordHint.isEmpty {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(AppTheme.secondaryLight).frame(width: 34, height: 34)
                                    Image(systemName: "key.fill").font(.subheadline).foregroundStyle(AppTheme.secondary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Password Hint").font(.caption).foregroundStyle(AppTheme.textSecondary)
                                    if showPasswordHint {
                                        Text(payment.passwordHint).font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.text)
                                            .transition(.blurReplace)
                                    } else {
                                        Text(String(repeating: "•", count: min(payment.passwordHint.count, 12)))
                                            .font(.subheadline).foregroundStyle(AppTheme.textFaint)
                                            .transition(.blurReplace)
                                    }
                                }
                                Spacer()
                                Button {
                                    withAnimation(.spring(response: 0.2)) { showPasswordHint.toggle() }
                                } label: {
                                    Image(systemName: showPasswordHint ? "eye.slash.fill" : "eye.fill")
                                        .foregroundStyle(AppTheme.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if !payment.notes.isEmpty {
                    Section("Notes") {
                        Text(payment.notes).font(.body).foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Section {
                    if payment.isDue {
                        Button {
                            onMarkPaid(); dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.primary)
                                Text("Mark as Paid").foregroundStyle(AppTheme.primary).fontWeight(.semibold)
                            }
                        }
                    }
                    Button {
                        onEdit(); dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "pencil.circle.fill").foregroundStyle(AppTheme.secondary)
                            Text("Edit Payment").foregroundStyle(AppTheme.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(payment.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primary)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if copiedField != nil {
                copyToast.transition(.move(edge: .bottom).combined(with: .opacity)).padding(.bottom, 32)
            }
        }
        .animation(.spring(response: 0.3), value: copiedField)
    }

    // MARK: - Hero card

    private var heroCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: Expense.tagIcons[payment.category] ?? "arrow.clockwise")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(statusColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.name).font(.title3.weight(.bold)).foregroundStyle(AppTheme.text)
                HStack(spacing: 6) {
                    Text(payment.formattedAmount).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textSecondary)
                    Text("·").foregroundStyle(AppTheme.textFaint)
                    Text(payment.frequency).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(statusColor).frame(width: 6, height: 6)
                    Text(payment.isDue ? "Due" : "Paid")
                        .font(.caption.weight(.semibold)).foregroundStyle(statusColor)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1.5))
        .padding(.horizontal, 16).padding(.top, 4)
    }

    // MARK: - Row helpers

    private func detailRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.subheadline).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(AppTheme.textSecondary)
                Text(value).font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.text)
            }
            Spacer()
        }
    }

    private func copyableRow(icon: String, label: String, value: String, fieldId: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.subheadline).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(AppTheme.textSecondary)
                Text(value).font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.text)
            }
            Spacer()
            Button {
                UIPasteboard.general.string = value
                withAnimation { copiedField = fieldId }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { copiedField = nil }
                }
            } label: {
                Image(systemName: copiedField == fieldId ? "checkmark.circle.fill" : "doc.on.doc")
                    .foregroundStyle(copiedField == fieldId ? AppTheme.primary : color.opacity(0.55))
                    .animation(.spring(response: 0.2), value: copiedField)
            }
            .buttonStyle(.plain)
        }
    }

    private var copyToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.primary)
            Text("Copied to clipboard").font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.text)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(AppTheme.background, in: Capsule())
        .overlay(Capsule().stroke(AppTheme.primaryLight, lineWidth: 1))
        .shadow(color: AppTheme.primary.opacity(0.12), radius: 8, y: 4)
    }

    private var statusColor: Color { payment.isDue ? AppTheme.secondary : AppTheme.primary }
    private var renewalColor: Color {
        guard let days = payment.daysUntilRenewal else { return AppTheme.primary }
        return days <= 7 ? AppTheme.secondary : AppTheme.primary
    }
}
