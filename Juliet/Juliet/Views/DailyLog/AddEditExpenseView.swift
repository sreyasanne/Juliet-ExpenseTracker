import SwiftUI
import SwiftData

struct AddEditExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var customTags: [CustomTag]
    @Query private var openings:   [AccountOpening]
    @Query private var allIncome:  [IncomeEntry]
    @Query private var allExpenses: [Expense]

    var expense: Expense?
    var initialDate: Date

    @State private var amount: String = ""
    @State private var date: Date
    @State private var notes: String = ""
    @State private var selectedTag: String = Expense.predefinedTags[0]
    @State private var selectedSource: String = Expense.paymentSources[0]
    @State private var showingNewTagSheet = false
    @State private var newTagName: String = ""

    private var isEditing: Bool { expense != nil }
    private var allTags: [String] { Expense.predefinedTags + customTags.map(\.name) }

    /// Current balance for the selected account
    private var availableBalance: Double {
        BalanceEngine.balance(
            account: selectedSource,
            openings: openings,
            income: allIncome,
            expenses: allExpenses
        )
    }

    /// When editing, the original amount is already "spent" — add it back so we compare the delta
    private var effectiveAvailable: Double {
        availableBalance + (expense?.amount ?? 0)
    }

    private var enteredAmount: Double { Double(amount) ?? 0 }
    private var isInsufficientFunds: Bool {
        enteredAmount > 0 && enteredAmount > effectiveAvailable
    }

    init(expense: Expense? = nil, initialDate: Date = Date()) {
        self.expense = expense
        self.initialDate = initialDate
        _date          = State(initialValue: expense?.date ?? initialDate)
        _amount        = State(initialValue: expense.map { String(format: "%.2f", $0.amount) } ?? "")
        _notes         = State(initialValue: expense?.notes ?? "")
        _selectedTag   = State(initialValue: expense?.tag ?? Expense.predefinedTags[0])
        _selectedSource = State(initialValue: expense?.paymentSource ?? Expense.paymentSources[0])
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
                            .foregroundStyle(isInsufficientFunds ? Color.orange : AppTheme.text)
                    }
                    .padding(.vertical, 4)

                    // Balance indicator
                    HStack(spacing: 6) {
                        Image(systemName: isInsufficientFunds ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.caption)
                        if isInsufficientFunds {
                            Text("Insufficient funds — \(selectedSource) has ₹\(String(format: "%.2f", effectiveAvailable)) available")
                                .font(.caption)
                        } else {
                            Text("\(selectedSource) available: ₹\(String(format: "%.2f", effectiveAvailable))")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(isInsufficientFunds ? Color.orange : AppTheme.textSecondary)
                    .animation(.spring(response: 0.25), value: isInsufficientFunds)
                } header: { Text("Amount") }

                // Date & Time
                Section("Date & Time") {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .tint(AppTheme.primary)
                }

                // Tag
                Section("Category") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allTags, id: \.self) { tag in
                                TagSelectionChip(
                                    tag: tag,
                                    isSelected: selectedTag == tag
                                ) {
                                    withAnimation(.spring(response: 0.25)) { selectedTag = tag }
                                }
                            }
                            Button {
                                showingNewTagSheet = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus").font(.caption.weight(.bold))
                                    Text("New").font(.caption.weight(.semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(AppTheme.primaryLight, in: Capsule())
                                .foregroundStyle(AppTheme.primary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                // Payment source
                Section("Payment Source") {
                    Picker("Source", selection: $selectedSource) {
                        ForEach(Expense.paymentSources, id: \.self) { source in
                            Label(source, systemImage: paymentIcon(source)).tag(source)
                        }
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
            .navigationTitle(isEditing ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(amount.isEmpty || Double(amount) == nil || Double(amount)! <= 0 || isInsufficientFunds)
                        .fontWeight(.semibold)
                        .foregroundStyle(isInsufficientFunds ? Color.orange : AppTheme.primary)
                }
            }
            .sheet(isPresented: $showingNewTagSheet) { newTagSheet }
        }
    }

    // MARK: - New tag sheet

    private var newTagSheet: some View {
        NavigationStack {
            Form {
                Section("Tag Name") {
                    TextField("e.g. Gym, Entertainment", text: $newTagName)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingNewTagSheet = false }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        modelContext.insert(CustomTag(name: trimmed))
                        selectedTag = trimmed
                        newTagName = ""
                        showingNewTagSheet = false
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Save

    private func save() {
        guard let value = Double(amount), value > 0 else { return }
        if let existing = expense {
            existing.amount = value; existing.date = date
            existing.notes = notes; existing.tag = selectedTag
            existing.paymentSource = selectedSource
        } else {
            modelContext.insert(Expense(amount: value, date: date, notes: notes,
                                        tag: selectedTag, paymentSource: selectedSource))
        }
        dismiss()
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

// MARK: - TagSelectionChip

private struct TagSelectionChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void

    private var color: Color { AppTheme.colorForTag(tag) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: Expense.tagIcons[tag] ?? "tag.fill").font(.caption)
                Text(tag).font(.caption.weight(.semibold))
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
