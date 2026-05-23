import Foundation
import SwiftData

/// Pure, stateless computation helpers.
/// All functions are static — pass in the queried arrays and get back a value.
enum BalanceEngine {

    // MARK: - Per-account balance

    /// opening balance + all income credited to account − all expenses charged to account
    static func balance(
        account: String,
        openings: [AccountOpening],
        income: [IncomeEntry],
        expenses: [Expense]
    ) -> Double {
        let opening  = openings.first  { $0.account == account }?.openingBalance ?? 0
        let totalIn  = income.filter   { $0.account == account }.reduce(0) { $0 + $1.amount }
        let totalOut = expenses.filter { $0.paymentSource == account }.reduce(0) { $0 + $1.amount }
        return opening + totalIn - totalOut
    }

    /// Sum of all account balances
    static func totalBalance(
        openings: [AccountOpening],
        income: [IncomeEntry],
        expenses: [Expense]
    ) -> Double {
        Expense.paymentSources.reduce(0) {
            $0 + balance(account: $1, openings: openings, income: income, expenses: expenses)
        }
    }

    // MARK: - Cashflow

    /// Income − expenses for a single calendar day
    static func dailyNetCashflow(
        date: Date,
        income: [IncomeEntry],
        expenses: [Expense]
    ) -> Double {
        let cal      = Calendar.current
        let dayIn    = income.filter   { cal.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.amount }
        let dayOut   = expenses.filter { cal.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.amount }
        return dayIn - dayOut
    }

    /// Total income for a single day
    static func dailyIncome(date: Date, income: [IncomeEntry]) -> Double {
        let cal = Calendar.current
        return income.filter { cal.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.amount }
    }

    /// Total expenses for a single day
    static func dailyExpenses(date: Date, expenses: [Expense]) -> Double {
        let cal = Calendar.current
        return expenses.filter { cal.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Weekly snapshot

    /// Returns true if no snapshot exists yet for this account in the current ISO week
    static func needsSnapshot(account: String, snapshots: [BalanceSnapshot]) -> Bool {
        let cal  = Calendar.current
        let week = cal.component(.weekOfYear, from: Date())
        let year = cal.component(.year,       from: Date())
        return !snapshots.contains { $0.account == account && $0.weekOfYear == week && $0.year == year }
    }

    /// Call on WalletView.onAppear — inserts missing snapshots into the model context
    @MainActor
    static func takeSnapshotsIfNeeded(
        context: ModelContext,
        openings: [AccountOpening],
        income: [IncomeEntry],
        expenses: [Expense],
        snapshots: [BalanceSnapshot]
    ) {
        for account in Expense.paymentSources {
            guard needsSnapshot(account: account, snapshots: snapshots) else { continue }
            let bal = balance(account: account, openings: openings, income: income, expenses: expenses)
            context.insert(BalanceSnapshot(account: account, balance: bal))
        }
    }

    // MARK: - Savings rate helpers

    /// Monthly salary income → savings rate against total expenses that month
    static func savingsRate(month: Date, income: [IncomeEntry], expenses: [Expense]) -> Double {
        let cal = Calendar.current
        let salary = income
            .filter { $0.source == "Salary" && cal.isDate($0.date, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
        let spent = expenses
            .filter { cal.isDate($0.date, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
        guard salary > 0 else { return 0 }
        let saved = salary - spent
        return max(0, (saved / salary) * 100)
    }
}
