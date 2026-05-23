import SwiftUI
import SwiftData

struct AddSavingsEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var entry: SavingsEntry?

    @State private var date: Date
    @State private var salary: String = ""
    @State private var amountSetAside: String = ""
    @State private var balance: String = ""
    @State private var notes: String = ""

    private var isEditing: Bool { entry != nil }

    init(entry: SavingsEntry? = nil) {
        self.entry = entry
        _date           = State(initialValue: entry?.date ?? Date())
        _salary         = State(initialValue: entry.map { String(format: "%.2f", $0.salary) } ?? "")
        _amountSetAside = State(initialValue: entry.map { String(format: "%.2f", $0.amountSetAside) } ?? "")
        _balance        = State(initialValue: entry.map { String(format: "%.2f", $0.balance) } ?? "")
        _notes          = State(initialValue: entry?.notes ?? "")
    }

    private var canSave: Bool {
        Double(salary) != nil && Double(salary)! > 0 &&
        Double(amountSetAside) != nil && Double(amountSetAside)! >= 0 &&
        Double(balance) != nil && Double(balance)! >= 0
    }
    private var inferredRate: Double {
        guard let s = Double(salary), s > 0, let a = Double(amountSetAside) else { return 0 }
        return (a / s) * 100
    }
    private var rateColor: Color { inferredRate >= 15 ? AppTheme.primary : AppTheme.secondary }

    var body: some View {
        NavigationStack {
            Form {
                Section("Month") {
                    DatePicker("Month", selection: $date, in: ...Date(), displayedComponents: .date)
                        .tint(AppTheme.primary)
                }

                Section("Income") {
                    labeledField("Salary Received",  placeholder: "0.00", binding: $salary)
                    labeledField("Amount Set Aside", placeholder: "0.00", binding: $amountSetAside)
                    if let s = Double(salary), s > 0, let a = Double(amountSetAside) {
                        HStack {
                            Text("Savings Rate").foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Text(String(format: "%.1f%%", (a / s) * 100))
                                .fontWeight(.semibold)
                                .foregroundStyle(rateColor)
                        }
                        .font(.subheadline)
                    }
                }

                Section {
                    labeledField("Current Balance", placeholder: "0.00", binding: $balance)
                    Text("SBI savings account — balance snapshot only, no transactions tracked here.")
                        .font(.caption).foregroundStyle(AppTheme.textFaint)
                } header: { Text("SBI Balance") }

                Section("Notes") {
                    TextField("Optional notes…", text: $notes, axis: .vertical).lineLimit(2...4)
                }
            }
            .navigationTitle(isEditing ? "Edit Entry" : "Log Savings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Log") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primary)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func labeledField(_ label: String, placeholder: String, binding: Binding<String>) -> some View {
        HStack {
            Text(label).foregroundStyle(AppTheme.textSecondary)
            Spacer()
            HStack(spacing: 2) {
                Text("₹").foregroundStyle(AppTheme.textFaint)
                TextField(placeholder, text: binding)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
        }
    }

    private func save() {
        guard let s = Double(salary), s > 0,
              let a = Double(amountSetAside), a >= 0,
              let b = Double(balance), b >= 0 else { return }
        if let existing = entry {
            existing.date = date; existing.salary = s
            existing.amountSetAside = a; existing.balance = b; existing.notes = notes
        } else {
            modelContext.insert(SavingsEntry(date: date, salary: s, amountSetAside: a, balance: b, notes: notes))
        }
        dismiss()
    }
}
