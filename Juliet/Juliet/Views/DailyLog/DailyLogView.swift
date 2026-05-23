import SwiftUI
import SwiftData

struct DailyLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date,     order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \IncomeEntry.date, order: .reverse) private var allIncome:   [IncomeEntry]

    // MARK: - State
    @State private var selectedDate     = Date()
    @State private var showDatePicker   = false
    @State private var logMode: LogMode = .expenses
    @State private var showingAddExpense = false
    @State private var showingAddIncome  = false
    @State private var expenseToEdit: Expense?
    @State private var incomeToEdit:  IncomeEntry?
    @State private var showingNotifications = false
    @State private var searchText  = ""
    @State private var filter      = ExpenseFilter()
    @State private var showingFilterSheet = false

    enum LogMode: String, CaseIterable {
        case expenses = "Expenses"
        case income   = "Income"
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty || !filter.isEmpty
    }

    // MARK: - Day-view data

    var dayExpenses: [Expense] {
        allExpenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    var dayIncome: [IncomeEntry] {
        allIncome.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    var dayTotal:       Double { dayExpenses.reduce(0) { $0 + $1.amount } }
    var dayIncomeTotal: Double { dayIncome.reduce(0) { $0 + $1.amount } }
    var dayTagBreakdown: [(String, Double)] {
        var dict: [String: Double] = [:]
        for e in dayExpenses { dict[e.tag, default: 0] += e.amount }
        return dict.sorted { $0.value > $1.value }
    }

    // Sets of start-of-day Dates used by CalendarGridView for dot indicators
    var expenseDaySet: Set<Date> {
        Set(allExpenses.map { Calendar.current.startOfDay(for: $0.date) })
    }
    var incomeDaySet: Set<Date> {
        Set(allIncome.map { Calendar.current.startOfDay(for: $0.date) })
    }

    // MARK: - Search/filter data (expenses only)

    var filteredExpenses: [Expense] {
        allExpenses.filter { expense in
            let kw = searchText.trimmingCharacters(in: .whitespaces).lowercased()
            if !kw.isEmpty {
                let hit = expense.notes.lowercased().contains(kw)
                    || expense.tag.lowercased().contains(kw)
                    || expense.paymentSource.lowercased().contains(kw)
                    || expense.formattedAmount.lowercased().contains(kw)
                if !hit { return false }
            }
            if !filter.tags.isEmpty     && !filter.tags.contains(expense.tag)             { return false }
            if !filter.accounts.isEmpty && !filter.accounts.contains(expense.paymentSource) { return false }
            if filter.dateRangeEnabled {
                let start = Calendar.current.startOfDay(for: filter.dateFrom)
                let end   = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: filter.dateTo) ?? filter.dateTo
                if expense.date < start || expense.date > end { return false }
            }
            return true
        }
    }
    var filteredTotal: Double { filteredExpenses.reduce(0) { $0 + $1.amount } }
    var groupedResults: [(Date, [Expense])] {
        var dict: [Date: [Expense]] = [:]
        for e in filteredExpenses {
            let day = Calendar.current.startOfDay(for: e.date)
            dict[day, default: []].append(e)
        }
        return dict.map { ($0.key, $0.value.sorted { $0.date > $1.date }) }.sorted { $0.0 > $1.0 }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isSearching {
                    searchResultsView
                } else {
                    dayBrowserView
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Juliet")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search expenses…"
            )
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingAddExpense) { AddEditExpenseView(initialDate: selectedDate) }
            .sheet(isPresented: $showingAddIncome)  { AddIncomeView(initialDate: selectedDate) }
            .sheet(item: $expenseToEdit) { AddEditExpenseView(expense: $0) }
            .sheet(item: $incomeToEdit)  { AddIncomeView(entry: $0) }
            .sheet(isPresented: $showingNotifications) { NotificationSettingsView() }
            .sheet(isPresented: $showingFilterSheet)   { SearchFilterSheet(filter: $filter) }
            .animation(.spring(response: 0.3), value: isSearching)
            .animation(.spring(response: 0.3), value: logMode)
        }
    }

    // MARK: - Day browser

    private var dayBrowserView: some View {
        VStack(spacing: 0) {
            dateSelectorBar
                .background(AppTheme.background)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(AppTheme.primaryLight).frame(height: 1)
                }

            if showDatePicker {
                CalendarGridView(
                    selectedDate: $selectedDate,
                    expenseDays: expenseDaySet,
                    incomeDays:  incomeDaySet
                )
                .background(AppTheme.background)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Expenses / Income segment
            Picker("Mode", selection: $logMode) {
                ForEach(LogMode.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 4)

            // Summary card — shows income+net when income exists that day
            if logMode == .expenses && !dayExpenses.isEmpty {
                DailySummaryCard(
                    total: dayTotal,
                    income: dayIncomeTotal,
                    breakdown: dayTagBreakdown
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            } else if logMode == .income && !dayIncome.isEmpty {
                DayIncomeSummaryCard(total: dayIncomeTotal, count: dayIncome.count)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }

            // List
            if logMode == .expenses {
                expenseListView(dayExpenses)
            } else {
                incomeListView(dayIncome)
            }
        }
        .animation(.spring(response: 0.35), value: showDatePicker)
    }

    // MARK: - Search results (expenses only)

    private var searchResultsView: some View {
        VStack(spacing: 0) {
            if !filter.isEmpty || !searchText.isEmpty {
                ActiveFilterBar(filter: $filter, searchText: $searchText)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if filteredExpenses.isEmpty {
                ContentUnavailableView.search(text: searchText.isEmpty ? "your filters" : searchText)
                    .frame(maxHeight: .infinity)
            } else {
                HStack {
                    Text("\(filteredExpenses.count) result\(filteredExpenses.count == 1 ? "" : "s")")
                        .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("₹\(String(format: "%.2f", filteredTotal))")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.text)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(AppTheme.background)
                .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.primaryLight).frame(height: 1) }

                List {
                    ForEach(groupedResults, id: \.0) { day, expenses in
                        Section {
                            ForEach(expenses) { expenseRowCell($0) }
                        } header: { dayHeaderLabel(for: day) }
                    }
                }
                .listStyle(.insetGrouped).scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Expense list

    @ViewBuilder
    private func expenseListView(_ expenses: [Expense]) -> some View {
        if expenses.isEmpty {
            ContentUnavailableView {
                Label("No Expenses", systemImage: "creditcard.fill")
            } description: {
                Text("Tap + to log an expense for this day")
            } actions: {
                Button("Add Expense") { showingAddExpense = true }
                    .buttonStyle(.borderedProminent).tint(AppTheme.primary)
            }
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(expenses) { expenseRowCell($0) }
                    .listRowBackground(Color(.secondarySystemGroupedBackground))
            }
            .listStyle(.insetGrouped).scrollContentBackground(.hidden)
        }
    }

    private func expenseRowCell(_ expense: Expense) -> some View {
        ExpenseRowView(expense: expense)
            .contentShape(Rectangle())
            .onTapGesture { expenseToEdit = expense }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    withAnimation { modelContext.delete(expense) }
                } label: { Label("Delete", systemImage: "trash.fill") }
            }
            .swipeActions(edge: .leading) {
                Button { expenseToEdit = expense } label: { Label("Edit", systemImage: "pencil") }
                    .tint(AppTheme.primary)
            }
    }

    // MARK: - Income list

    @ViewBuilder
    private func incomeListView(_ entries: [IncomeEntry]) -> some View {
        if entries.isEmpty {
            ContentUnavailableView {
                Label("No Income", systemImage: "arrow.down.circle.fill")
            } description: {
                Text("Tap + to log income for this day")
            } actions: {
                Button("Add Income") { showingAddIncome = true }
                    .buttonStyle(.borderedProminent).tint(AppTheme.primary)
            }
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(entries) { entry in
                    IncomeRowView(entry: entry)
                        .contentShape(Rectangle())
                        .onTapGesture { incomeToEdit = entry }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { modelContext.delete(entry) }
                            } label: { Label("Delete", systemImage: "trash.fill") }
                        }
                        .swipeActions(edge: .leading) {
                            Button { incomeToEdit = entry } label: { Label("Edit", systemImage: "pencil") }
                                .tint(AppTheme.primary)
                        }
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))
            }
            .listStyle(.insetGrouped).scrollContentBackground(.hidden)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { showingNotifications = true } label: {
                Image(systemName: "bell.fill").foregroundStyle(AppTheme.primary)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showingFilterSheet = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: filter.isEmpty
                          ? "line.3.horizontal.decrease.circle"
                          : "line.3.horizontal.decrease.circle.fill")
                        .font(.title3).foregroundStyle(AppTheme.primary)
                    if filter.activeCount > 0 {
                        Text("\(filter.activeCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.background)
                            .frame(width: 14, height: 14)
                            .background(AppTheme.secondary, in: Circle())
                            .offset(x: 5, y: -5)
                    }
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                if logMode == .expenses { showingAddExpense = true }
                else                    { showingAddIncome  = true }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3).foregroundStyle(AppTheme.primary)
            }
        }
    }

    // MARK: - Date selector bar

    private var dateSelectorBar: some View {
        HStack {
            Button { changeDate(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold)).foregroundStyle(AppTheme.primary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Button { withAnimation { showDatePicker.toggle() } } label: {
                VStack(spacing: 2) {
                    Text(selectedDate, style: .date).font(.headline).foregroundStyle(AppTheme.text)
                    Group {
                        if Calendar.current.isDateInToday(selectedDate)     { Text("Today") }
                        else if Calendar.current.isDateInYesterday(selectedDate) { Text("Yesterday") }
                    }
                    .font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            Button { changeDate(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold)).foregroundStyle(AppTheme.primary)
                    .frame(width: 44, height: 44)
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
            .opacity(Calendar.current.isDateInToday(selectedDate) ? 0.3 : 1)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func changeDate(by days: Int) {
        withAnimation(.spring(response: 0.3)) {
            if let d = Calendar.current.date(byAdding: .day, value: days, to: selectedDate), d <= Date() {
                selectedDate = d
            }
        }
    }

    private func dayHeaderLabel(for date: Date) -> some View {
        let cal = Calendar.current
        let label: String = {
            if cal.isDateInToday(date)     { return "Today" }
            if cal.isDateInYesterday(date) { return "Yesterday" }
            let fmt = DateFormatter(); fmt.dateStyle = .medium
            return fmt.string(from: date)
        }()
        return Text(label).font(.subheadline.weight(.semibold))
    }
}

// MARK: - DayIncomeSummaryCard

private struct DayIncomeSummaryCard: View {
    let total: Double
    let count: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Income Today")
                    .font(.caption).foregroundStyle(AppTheme.textSecondary)
                Text("₹\(String(format: "%.2f", total))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                Text("\(count) entr\(count == 1 ? "y" : "ies")")
                    .font(.caption2).foregroundStyle(AppTheme.textFaint)
            }
            Spacer()
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 36)).foregroundStyle(AppTheme.primary)
        }
        .padding(16)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.primaryLight, lineWidth: 1.5))
        .shadow(color: AppTheme.primary.opacity(0.10), radius: 8, y: 3)
    }
}
