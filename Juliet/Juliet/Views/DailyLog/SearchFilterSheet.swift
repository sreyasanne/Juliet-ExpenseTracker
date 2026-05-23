import SwiftUI
import SwiftData

// MARK: - Filter state

struct ExpenseFilter: Equatable {
    var tags: Set<String> = []
    var accounts: Set<String> = []
    var dateRangeEnabled: Bool = false
    var dateFrom: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    var dateTo: Date = Date()

    var isEmpty: Bool {
        tags.isEmpty && accounts.isEmpty && !dateRangeEnabled
    }
    var activeCount: Int {
        (tags.isEmpty ? 0 : 1) + (accounts.isEmpty ? 0 : 1) + (dateRangeEnabled ? 1 : 0)
    }
}

// MARK: - Sheet

struct SearchFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var customTags: [CustomTag]

    @Binding var filter: ExpenseFilter
    @State private var draft: ExpenseFilter

    init(filter: Binding<ExpenseFilter>) {
        _filter = filter
        _draft = State(initialValue: filter.wrappedValue)
    }

    private var allTags: [String] {
        Expense.predefinedTags + customTags.map(\.name)
    }

    var body: some View {
        NavigationStack {
            List {
                // Tags
                Section {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 8
                    ) {
                        ForEach(allTags, id: \.self) { tag in
                            FilterChipButton(
                                label: tag,
                                icon: Expense.tagIcons[tag] ?? "tag.fill",
                                color: AppTheme.colorForTag(tag),
                                isSelected: draft.tags.contains(tag)
                            ) {
                                withAnimation(.spring(response: 0.25)) {
                                    if draft.tags.contains(tag) {
                                        _ = draft.tags.remove(tag)
                                    } else {
                                        _ = draft.tags.insert(tag)
                                    }
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
                } header: {
                    sectionHeader("Category", count: draft.tags.count) { draft.tags.removeAll() }
                }

                // Accounts
                Section {
                    HStack(spacing: 10) {
                        ForEach(Expense.paymentSources, id: \.self) { source in
                            FilterChipButton(
                                label: source,
                                icon: accountIcon(source),
                                color: AppTheme.primary,
                                isSelected: draft.accounts.contains(source)
                            ) {
                                withAnimation(.spring(response: 0.25)) {
                                    if draft.accounts.contains(source) {
                                        _ = draft.accounts.remove(source)
                                    } else {
                                        _ = draft.accounts.insert(source)
                                    }
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
                } header: {
                    sectionHeader("Account", count: draft.accounts.count) { draft.accounts.removeAll() }
                }

                // Date range
                Section {
                    Toggle("Enable Date Range", isOn: $draft.dateRangeEnabled.animation())
                        .tint(AppTheme.primary)
                    if draft.dateRangeEnabled {
                        DatePicker("From", selection: $draft.dateFrom, in: ...draft.dateTo, displayedComponents: .date)
                        DatePicker("To",   selection: $draft.dateTo,   in: draft.dateFrom...Date(), displayedComponents: .date)
                    }
                } header: {
                    sectionHeader("Date Range", count: draft.dateRangeEnabled ? 1 : 0) {
                        draft.dateRangeEnabled = false
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !draft.isEmpty {
                        Button("Clear All") {
                            withAnimation { draft = ExpenseFilter() }
                        }
                        .foregroundStyle(AppTheme.secondary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { filter = draft; dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func sectionHeader(_ title: String, count: Int, onClear: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            if count > 0 {
                Text("(\(count))").foregroundStyle(AppTheme.primary)
                Spacer()
                Button("Clear") { onClear() }
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
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

// MARK: - FilterChipButton

struct FilterChipButton: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.body)
                Text(label).font(.caption.weight(.semibold)).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? color : color.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(isSelected ? AppTheme.background : color)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
            .animation(.spring(response: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
