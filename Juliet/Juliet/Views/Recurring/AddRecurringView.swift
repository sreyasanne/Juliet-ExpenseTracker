import SwiftUI
import SwiftData

struct AddRecurringView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var payment: RecurringPayment?

    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var frequency: String = "Monthly"
    @State private var category: String = Expense.predefinedTags[0]
    @State private var account: String = Expense.paymentSources[0]
    @State private var notes: String = ""
    @State private var isActive: Bool = true
    @State private var hasRenewalDate: Bool = false
    @State private var renewalDate: Date = Date()
    @State private var loginEmail: String = ""
    @State private var website: String = ""
    @State private var passwordHint: String = ""
    @State private var showPasswordHint: Bool = false

    private var isEditing: Bool { payment != nil }

    init(payment: RecurringPayment? = nil) {
        self.payment = payment
        _name           = State(initialValue: payment?.name ?? "")
        _amount         = State(initialValue: payment.map { String(format: "%.2f", $0.amount) } ?? "")
        _frequency      = State(initialValue: payment?.frequency ?? "Monthly")
        _category       = State(initialValue: payment?.category ?? Expense.predefinedTags[0])
        _account        = State(initialValue: payment?.account ?? Expense.paymentSources[0])
        _notes          = State(initialValue: payment?.notes ?? "")
        _isActive       = State(initialValue: payment?.isActive ?? true)
        _hasRenewalDate = State(initialValue: payment?.renewalDate != nil)
        _renewalDate    = State(initialValue: payment?.renewalDate ?? Date())
        _loginEmail     = State(initialValue: payment?.loginEmail ?? "")
        _website        = State(initialValue: payment?.website ?? "")
        _passwordHint   = State(initialValue: payment?.passwordHint ?? "")
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(amount) != nil && Double(amount)! > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name (e.g. Netflix, SIP, Rent)", text: $name).autocorrectionDisabled()
                    HStack {
                        Text("₹").foregroundStyle(AppTheme.textSecondary)
                        TextField("Amount", text: $amount).keyboardType(.decimalPad)
                    }
                }

                Section("Frequency") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurringPayment.frequencies, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(Expense.predefinedTags, id: \.self) { tag in
                            Label(tag, systemImage: Expense.tagIcons[tag] ?? "tag").tag(tag)
                        }
                    }
                    .tint(AppTheme.primary)
                }

                Section("Account") {
                    Picker("Account", selection: $account) {
                        ForEach(Expense.paymentSources, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }

                Section {
                    Toggle("Set Renewal Date", isOn: $hasRenewalDate.animation())
                        .tint(AppTheme.primary)
                    if hasRenewalDate {
                        DatePicker("Renewal Date", selection: $renewalDate, displayedComponents: .date)
                            .tint(AppTheme.primary)
                    }
                } header: {
                    Text("Renewal")
                } footer: {
                    Text("Juliet will show a countdown to renewal on the row.")
                }

                Section {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(AppTheme.primary)
                            .frame(width: 20)
                        TextField("Login email", text: $loginEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(AppTheme.primary)
                            .frame(width: 20)
                        TextField("Website (e.g. netflix.com)", text: $website)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundStyle(AppTheme.secondary)
                            .frame(width: 20)
                        if showPasswordHint {
                            TextField("Password hint", text: $passwordHint).autocorrectionDisabled()
                        } else {
                            SecureField("Password hint", text: $passwordHint)
                        }
                        Spacer()
                        Button { showPasswordHint.toggle() } label: {
                            Image(systemName: showPasswordHint ? "eye.slash" : "eye")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Login Details")
                } footer: {
                    Text("Store a hint — not your actual password.")
                        .foregroundStyle(AppTheme.secondary)
                }

                Section("Notes") {
                    TextField("Any additional notes…", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                if isEditing {
                    Section {
                        Toggle("Active", isOn: $isActive).tint(AppTheme.primary)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Payment" : "New Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(AppTheme.textSecondary)
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
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        if let existing = payment {
            existing.name = n; existing.amount = value; existing.frequency = frequency
            existing.category = category; existing.account = account; existing.notes = notes
            existing.isActive = isActive; existing.renewalDate = hasRenewalDate ? renewalDate : nil
            existing.loginEmail = loginEmail.trimmingCharacters(in: .whitespaces)
            existing.website = website.trimmingCharacters(in: .whitespaces)
            existing.passwordHint = passwordHint
        } else {
            modelContext.insert(RecurringPayment(
                name: n, amount: value, frequency: frequency, category: category, account: account,
                notes: notes, renewalDate: hasRenewalDate ? renewalDate : nil,
                loginEmail: loginEmail.trimmingCharacters(in: .whitespaces),
                website: website.trimmingCharacters(in: .whitespaces), passwordHint: passwordHint
            ))
        }
        dismiss()
    }
}
