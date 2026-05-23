import SwiftUI

/// A custom monthly calendar grid that shows activity dots per day.
/// - Green  = income only
/// - Red    = expense only
/// - Yellow = both
struct CalendarGridView: View {
    @Binding var selectedDate: Date
    let expenseDays: Set<Date>   // start-of-day Dates that have expenses
    let incomeDays:  Set<Date>   // start-of-day Dates that have income

    @State private var displayMonth: Date

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    init(selectedDate: Binding<Date>, expenseDays: Set<Date>, incomeDays: Set<Date>) {
        _selectedDate = selectedDate
        self.expenseDays = expenseDays
        self.incomeDays  = incomeDays
        _displayMonth = State(initialValue: Calendar.current.startOfMonth(for: selectedDate.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 8) {
            // Month header
            HStack {
                Button { shiftMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 36, height: 36)
                }
                Spacer()
                Button { withAnimation(.spring(response: 0.3)) { displayMonth = cal.startOfMonth(for: Date()) } } label: {
                    Text(displayMonth, format: .dateTime.month(.wide).year())
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.text)
                }
                Spacer()
                Button { shiftMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 36, height: 36)
                }
                .disabled(isCurrentMonth)
                .opacity(isCurrentMonth ? 0.3 : 1)
            }
            .padding(.horizontal, 12)

            // Weekday labels
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(height: 28)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 4) {
                // Leading empty cells
                ForEach(0..<leadingEmptyCells, id: \.self) { _ in
                    Color.clear.frame(height: 50)
                }
                // Day numbers
                ForEach(daysInMonth, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                        isToday: cal.isDateInToday(date),
                        isFuture: date > Date(),
                        dot: dotColor(for: date)
                    )
                    .onTapGesture {
                        if date <= Date() {
                            withAnimation(.spring(response: 0.25)) { selectedDate = date }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        // Sync display month when selected date changes externally
        .onChange(of: selectedDate) { _, newVal in
            let newMonth = cal.startOfMonth(for: newVal)
            if newMonth != displayMonth { withAnimation(.spring(response: 0.3)) { displayMonth = newMonth } }
        }
    }

    // MARK: - Helpers

    private var isCurrentMonth: Bool {
        cal.isDate(displayMonth, equalTo: cal.startOfMonth(for: Date()), toGranularity: .month)
    }

    private var daysInMonth: [Date] {
        guard let range = cal.range(of: .day, in: .month, for: displayMonth) else { return [] }
        return range.compactMap { day -> Date? in
            cal.date(bySetting: .day, value: day, of: displayMonth)
        }
    }

    private var leadingEmptyCells: Int {
        let weekday = cal.component(.weekday, from: displayMonth)
        return weekday - 1   // Sunday = 1, so offset = 0..6
    }

    private func shiftMonth(by value: Int) {
        guard let newMonth = cal.date(byAdding: .month, value: value, to: displayMonth) else { return }
        let cap = cal.startOfMonth(for: Date())
        withAnimation(.spring(response: 0.3)) { displayMonth = min(newMonth, cap) }
    }

    private func dotColor(for date: Date) -> Color? {
        let day = cal.startOfDay(for: date)
        let hasExp = expenseDays.contains(day)
        let hasInc = incomeDays.contains(day)
        if hasExp && hasInc { return .yellow }
        if hasExp            { return .red }
        if hasInc            { return .green }
        return nil
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isFuture: Bool
    let dot: Color?

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if isSelected {
                    Circle().fill(AppTheme.primary).frame(width: 34, height: 34)
                } else if isToday {
                    Circle().fill(AppTheme.primaryLight).frame(width: 34, height: 34)
                }
                Text(date, format: .dateTime.day())
                    .font(.system(size: 16, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundStyle(
                        isFuture ? AppTheme.textFaint :
                        isSelected ? AppTheme.background :
                        AppTheme.text
                    )
            }
            // Activity dot
            if let dot {
                Circle()
                    .fill(dot)
                    .frame(width: 5, height: 5)
            } else {
                Circle().fill(Color.clear).frame(width: 5, height: 5)
            }
        }
        .frame(height: 50)
        .opacity(isFuture ? 0.35 : 1)
    }
}

// MARK: - Calendar extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
