import SwiftUI
import SwiftData

struct RecurringView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringPayment.name) private var payments: [RecurringPayment]

    @State private var showingAdd = false
    @State private var paymentToEdit: RecurringPayment?
    @State private var paymentToView: RecurringPayment?

    var duePayments: [RecurringPayment]      { payments.filter { $0.isActive && $0.isDue } }
    var paidPayments: [RecurringPayment]     { payments.filter { $0.isActive && !$0.isDue } }
    var inactivePayments: [RecurringPayment] { payments.filter { !$0.isActive } }

    var totalMonthly: Double {
        payments.filter(\.isActive).reduce(0) { acc, p in
            switch p.frequency {
            case "Weekly": return acc + p.amount * 4
            case "Yearly": return acc + p.amount / 12
            default:       return acc + p.amount
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if payments.isEmpty {
                    ContentUnavailableView {
                        Label("No Recurring Payments", systemImage: "arrow.clockwise.circle")
                    } description: {
                        Text("Add subscriptions, SIPs, rent, and more")
                    } actions: {
                        Button("Add Payment") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.primary)
                    }
                } else {
                    List {
                        Section {
                            monthlyCostCard
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                        }

                        if !duePayments.isEmpty {
                            Section {
                                ForEach(duePayments) { payment in
                                    RecurringRow(payment: payment, onMarkPaid: { markPaid(payment) })
                                        .contentShape(Rectangle())
                                        .onTapGesture { paymentToView = payment }
                                        .swipeActions(edge: .trailing) { deleteButton(for: payment) }
                                        .swipeActions(edge: .leading) {
                                            Button { markPaid(payment) } label: {
                                                Label("Mark Paid", systemImage: "checkmark.circle.fill")
                                            }.tint(AppTheme.primary)
                                            Button { paymentToEdit = payment } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }.tint(AppTheme.secondary)
                                        }
                                }
                            } header: {
                                Label("Due", systemImage: "exclamationmark.circle.fill")
                                    .foregroundStyle(AppTheme.secondary)
                            }
                        }

                        if !paidPayments.isEmpty {
                            Section {
                                ForEach(paidPayments) { payment in
                                    RecurringRow(payment: payment, onMarkPaid: nil)
                                        .contentShape(Rectangle())
                                        .onTapGesture { paymentToView = payment }
                                        .swipeActions(edge: .trailing) { deleteButton(for: payment) }
                                        .swipeActions(edge: .leading) {
                                            Button { paymentToEdit = payment } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }.tint(AppTheme.primary)
                                        }
                                }
                            } header: {
                                Label("Paid", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primary)
                            }
                        }

                        if !inactivePayments.isEmpty {
                            Section("Inactive") {
                                ForEach(inactivePayments) { payment in
                                    RecurringRow(payment: payment, onMarkPaid: nil)
                                        .opacity(0.45)
                                        .contentShape(Rectangle())
                                        .onTapGesture { paymentToView = payment }
                                        .swipeActions(edge: .trailing) { deleteButton(for: payment) }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Recurring")
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
            .sheet(isPresented: $showingAdd) { AddRecurringView() }
            .sheet(item: $paymentToEdit) { AddRecurringView(payment: $0) }
            .sheet(item: $paymentToView) { payment in
                RecurringDetailView(
                    payment: payment,
                    onEdit: { paymentToEdit = payment },
                    onMarkPaid: { markPaid(payment) }
                )
            }
        }
    }

    private var monthlyCostCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Monthly Commitment")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text("₹\(String(format: "%.2f", totalMonthly))")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(duePayments.count) due")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(duePayments.isEmpty ? AppTheme.textFaint : AppTheme.secondary)
                Text("\(paidPayments.count) paid")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textFaint)
            }
        }
        .padding(16)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1.5))
        .shadow(color: AppTheme.primary.opacity(0.08), radius: 6, y: 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func markPaid(_ payment: RecurringPayment) {
        withAnimation { payment.lastPaidDate = Date() }
    }

    @ViewBuilder
    private func deleteButton(for payment: RecurringPayment) -> some View {
        Button(role: .destructive) {
            withAnimation { modelContext.delete(payment) }
        } label: {
            Label("Delete", systemImage: "trash.fill")
        }
        .tint(AppTheme.secondary)
    }
}

// MARK: - RecurringRow

struct RecurringRow: View {
    let payment: RecurringPayment
    let onMarkPaid: (() -> Void)?

    private var statusColor: Color { payment.isDue ? AppTheme.secondary : AppTheme.primary }
    private var renewalColor: Color {
        guard let days = payment.daysUntilRenewal else { return AppTheme.primary }
        if days <= 3  { return AppTheme.secondary }
        if days <= 7  { return AppTheme.secondary.opacity(0.7) }
        return AppTheme.primary
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: Expense.tagIcons[payment.category] ?? "arrow.clockwise")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(payment.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                HStack(spacing: 4) {
                    Text(payment.frequency)
                    Text("·"); Text(payment.category)
                    Text("·"); Text(payment.account)
                }
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

                if !payment.loginEmail.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "envelope.fill").font(.system(size: 9))
                        Text(payment.loginEmail).lineLimit(1)
                    }
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textFaint)
                }

                if let status = payment.renewalStatusText {
                    Text(status)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(renewalColor)
                } else {
                    Text(payment.lastPaidText)
                        .font(.caption2)
                        .foregroundStyle(payment.isDue ? AppTheme.secondary : AppTheme.primary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(payment.formattedAmount)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                if payment.isDue, let markPaid = onMarkPaid {
                    Button(action: markPaid) {
                        Text("Pay")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.primaryLight, in: Capsule())
                            .foregroundStyle(AppTheme.primary)
                    }
                    .buttonStyle(.plain)
                } else if !payment.isDue {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.primary)
                        .font(.body)
                }
            }
        }
        .padding(.vertical, 4)
        .overlay(alignment: .topTrailing) {
            if payment.hasSubscriptionDetails {
                Image(systemName: "info.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.primaryMedium)
                    .offset(x: 0, y: -2)
            }
        }
    }
}
