import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var times: [NotificationTime]

    @State private var showingAddTime = false
    @State private var newDate: Date = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    ) ?? Date()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    infoCard
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    if times.isEmpty {
                        Text("No reminders set")
                            .foregroundStyle(AppTheme.textFaint)
                            .italic()
                    } else {
                        ForEach(times) { time in
                            NotificationTimeRow(time: time) { toggle(time) }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { delete(time) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(AppTheme.secondary)
                                }
                        }
                    }
                    if times.count < 6 {
                        Button { showingAddTime = true } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill").foregroundStyle(AppTheme.primary)
                                Text("Add Reminder Time").foregroundStyle(AppTheme.primary)
                            }
                        }
                    }
                } header: {
                    Text("Daily Reminders (\(times.count)/6)")
                } footer: {
                    Text("Juliet sends a notification at each enabled time every day.")
                }
            }
            .listStyle(.insetGrouped)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .sheet(isPresented: $showingAddTime) { addTimeSheet }
            .onAppear { seedDefaultTimesIfNeeded() }
        }
    }

    // MARK: - Info card

    private var infoCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 28))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text("Expense Reminders")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                Text("Set 3–6 daily times and Juliet will nudge you to log expenses.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(14)
        .background(AppTheme.primaryXLight, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1))
        .padding(.horizontal, 16).padding(.bottom, 4)
    }

    // MARK: - Add sheet

    private var addTimeSheet: some View {
        NavigationStack {
            Form {
                Section("Pick a time") {
                    DatePicker("Time", selection: $newDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .tint(AppTheme.primary)
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddTime = false }.foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addTime(); showingAddTime = false }
                        .fontWeight(.semibold).foregroundStyle(AppTheme.primary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func addTime() {
        let cal = Calendar.current
        let h = cal.component(.hour, from: newDate)
        let m = cal.component(.minute, from: newDate)
        modelContext.insert(NotificationTime(hour: h, minute: m))
        reschedule()
    }
    private func toggle(_ time: NotificationTime) { time.isEnabled.toggle(); reschedule() }
    private func delete(_ time: NotificationTime) {
        NotificationManager.shared.remove(time: time); modelContext.delete(time); reschedule()
    }
    private func reschedule() {
        Task { @MainActor in NotificationManager.shared.rescheduleAll(times: times) }
    }
    private func seedDefaultTimesIfNeeded() {
        guard times.isEmpty else { return }
        [(9, 0), (13, 30), (21, 0)].forEach { modelContext.insert(NotificationTime(hour: $0.0, minute: $0.1)) }
        reschedule()
    }
}

// MARK: - Row

private struct NotificationTimeRow: View {
    let time: NotificationTime
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundStyle(AppTheme.primary)
                .frame(width: 24)
            Text(time.displayTime).font(.body).foregroundStyle(AppTheme.text)
            Spacer()
            Toggle("", isOn: Binding(
                get: { time.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(AppTheme.primary)
        }
    }
}
