import SwiftUI
import SwiftData

struct AddIncomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var entry: IncomeEntry?
    var initialDate: Date

    @State private var amount: String
    @State private var source: String
    @State private var account: String
    @State private var date: Date
    @State private var notes: String

    private var isEditing: Bool { entry != nil }

    init(entry: IncomeEntry? = nil, initialDate: Date = Date()) {
        self.entry = entry
        self.initialDate = initialDate
        _amount  = State(initialValue: entry.map { String(format: "%.2f", $0.amount) } ?? "")
        _source  = State(initialValue: entry?.source  ?? IncomeEntry.sources[0])
        _account = State(initialValue: entry?.account ?? Expense.paymentSources[0])
        _date    = State(initialValue: entry?.date    ?? initialDate)
        _notes   = State(initialValue: entry?.notes   ?? "")
    }

    private var canSave: Bool {
        guard let v = Double(amount) else { return false }
        return v > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // Amount
                Section {
                    HStack {
                        Text("₹")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.text)
                    }
                    .padding(.vertical, 4)
                } header: { Text("Amount") }

                // Date
                Section("Date & Time") {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .tint(AppTheme.primary)
                }

                // Source
                Section("Source") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(IncomeEntry.sources, id: \.self) { src in
                                IncomeSourceChip(
                                    source: src,
                                    isSelected: source == src
                                ) {
                                    withAnimation(.spring(response: 0.25)) { source = src }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                // Account
                Section("Credited To") {
                    Picker("Account", selection: $account) {
                        ForEach(Expense.paymentSources, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }

                // Notes
                Section("Notes (optional)") {
                    TextField("Add a note…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Income" : "Log Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primary)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard let value = Double(amount), value > 0 else { return }
        if let existing = entry {
            existing.amount  = value
            existing.source  = source
            existing.account = account
            existing.date    = date
            existing.notes   = notes
        } else {
            modelContext.insert(IncomeEntry(
                amount: value, source: source, account: account, date: date, notes: notes
            ))
        }
        dismiss()
    }
}

// MARK: - IncomeSourceChip

struct IncomeSourceChip: View {
    let source: String
    let isSelected: Bool
    let action: () -> Void

    private var color: Color {
        let idx = IncomeEntry.sources.firstIndex(of: source) ?? 0
        return idx.isMultiple(of: 2) ? AppTheme.primary : AppTheme.secondary
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: IncomeEntry.sourceIcons[source] ?? "circle.fill")
                    .font(.caption)
                Text(source)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? color : color.opacity(0.12), in: Capsule())
            .foregroundStyle(isSelected ? AppTheme.background : color)
            .animation(.spring(response: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
