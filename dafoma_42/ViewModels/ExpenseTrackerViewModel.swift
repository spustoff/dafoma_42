//
//  ExpenseTrackerViewModel.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ExpenseTrackerViewModel: ObservableObject {
    @Published var expenses: [FinanceItem] = []
    @Published var budgets: [BudgetItem] = []
    @Published var selectedPeriod: TimePeriod = .thisMonth
    @Published var selectedCategory: ExpenseCategory? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingAddExpense: Bool = false
    @Published var showingBudgetSetup: Bool = false
    
    private let financeDataService: FinanceDataService
    private var cancellables = Set<AnyCancellable>()
    
    enum TimePeriod: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisYear = "This Year"
        case all = "All Time"
        
        var dateRange: (start: Date, end: Date) {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .thisWeek:
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
                return (startOfWeek, endOfWeek)
            case .thisMonth:
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
                return (startOfMonth, endOfMonth)
            case .thisYear:
                let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
                let endOfYear = calendar.dateInterval(of: .year, for: now)?.end ?? now
                return (startOfYear, endOfYear)
            case .all:
                return (Date.distantPast, Date.distantFuture)
            }
        }
    }
    
    init(financeDataService: FinanceDataService = FinanceDataService()) {
        self.financeDataService = financeDataService
        loadData()
    }
    
    // MARK: - Data Loading
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let expensesResult = financeDataService.loadExpenses()
                async let budgetsResult = financeDataService.loadBudgets()
                
                let (loadedExpenses, loadedBudgets) = try await (expensesResult, budgetsResult)
                
                await MainActor.run {
                    self.expenses = loadedExpenses
                    self.budgets = loadedBudgets
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Expense Management
    func addExpense(_ expense: FinanceItem) {
        expenses.append(expense)
        updateBudgetSpending(for: expense)
        saveExpenses()
    }
    
    func updateExpense(_ expense: FinanceItem) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            recalculateBudgets()
            saveExpenses()
        }
    }
    
    func deleteExpense(_ expense: FinanceItem) {
        expenses.removeAll { $0.id == expense.id }
        recalculateBudgets()
        saveExpenses()
    }
    
    func deleteExpenses(at offsets: IndexSet) {
        let expensesToDelete = offsets.map { filteredExpenses[$0] }
        for expense in expensesToDelete {
            deleteExpense(expense)
        }
    }
    
    // MARK: - Budget Management
    func addBudget(_ budget: BudgetItem) {
        budgets.append(budget)
        saveBudgets()
    }
    
    func updateBudget(_ budget: BudgetItem) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
            saveBudgets()
        }
    }
    
    func deleteBudget(_ budget: BudgetItem) {
        budgets.removeAll { $0.id == budget.id }
        saveBudgets()
    }
    
    private func updateBudgetSpending(for expense: FinanceItem) {
        let currentMonth = Calendar.current.component(.month, from: expense.date)
        let currentYear = Calendar.current.component(.year, from: expense.date)
        
        if let budgetIndex = budgets.firstIndex(where: { 
            $0.category == expense.category && 
            $0.month == currentMonth && 
            $0.year == currentYear 
        }) {
            budgets[budgetIndex].spentAmount += expense.amount
        }
    }
    
    private func recalculateBudgets() {
        for budgetIndex in budgets.indices {
            let budget = budgets[budgetIndex]
            let categoryExpenses = expenses.filter { expense in
                expense.category == budget.category &&
                Calendar.current.component(.month, from: expense.date) == budget.month &&
                Calendar.current.component(.year, from: expense.date) == budget.year
            }
            budgets[budgetIndex].spentAmount = categoryExpenses.reduce(0) { $0 + $1.amount }
        }
    }
    
    // MARK: - Computed Properties
    var filteredExpenses: [FinanceItem] {
        let dateRange = selectedPeriod.dateRange
        var filtered = expenses.filter { expense in
            expense.date >= dateRange.start && expense.date <= dateRange.end
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    
    var totalExpenses: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var formattedTotalExpenses: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalExpenses)) ?? "$0.00"
    }
    
    var expensesByCategory: [ExpenseCategory: Double] {
        var categoryTotals: [ExpenseCategory: Double] = [:]
        for expense in filteredExpenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        return categoryTotals
    }
    
    var topSpendingCategories: [(category: ExpenseCategory, amount: Double)] {
        expensesByCategory.sorted { $0.value > $1.value }
            .prefix(5)
            .map { (category: $0.key, amount: $0.value) }
    }
    
    var currentMonthBudgets: [BudgetItem] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return budgets.filter { $0.month == currentMonth && $0.year == currentYear }
    }
    
    var overBudgetCategories: [BudgetItem] {
        currentMonthBudgets.filter { $0.isOverBudget }
    }
    
    var totalBudgetAmount: Double {
        currentMonthBudgets.reduce(0) { $0 + $1.budgetAmount }
    }
    
    var totalSpentAmount: Double {
        currentMonthBudgets.reduce(0) { $0 + $1.spentAmount }
    }
    
    var budgetUtilizationPercentage: Double {
        guard totalBudgetAmount > 0 else { return 0 }
        return min(totalSpentAmount / totalBudgetAmount, 1.0)
    }
    
    // MARK: - Analytics
    func getSpendingTrend(for category: ExpenseCategory? = nil, days: Int = 30) -> [DailySpending] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        var dailySpending: [Date: Double] = [:]
        
        let relevantExpenses = expenses.filter { expense in
            expense.date >= startDate && expense.date <= endDate
        }.filter { expense in
            category == nil || expense.category == category
        }
        
        for expense in relevantExpenses {
            let day = calendar.startOfDay(for: expense.date)
            dailySpending[day, default: 0] += expense.amount
        }
        
        var result: [DailySpending] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let day = calendar.startOfDay(for: currentDate)
            let amount = dailySpending[day] ?? 0
            result.append(DailySpending(date: day, amount: amount))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return result
    }
    
    func getMonthlySpending(for year: Int = Calendar.current.component(.year, from: Date())) -> [MonthlySpending] {
        var monthlyTotals: [Int: Double] = [:]
        
        let yearExpenses = expenses.filter { 
            Calendar.current.component(.year, from: $0.date) == year 
        }
        
        for expense in yearExpenses {
            let month = Calendar.current.component(.month, from: expense.date)
            monthlyTotals[month, default: 0] += expense.amount
        }
        
        return (1...12).map { month in
            MonthlySpending(
                month: month,
                year: year,
                amount: monthlyTotals[month] ?? 0,
                monthName: DateFormatter().monthSymbols[month - 1]
            )
        }
    }
    
    // MARK: - Data Persistence
    private func saveExpenses() {
        Task {
            do {
                try await financeDataService.saveExpenses(expenses)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save expenses: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveBudgets() {
        Task {
            do {
                try await financeDataService.saveBudgets(budgets)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save budgets: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    func clearErrorMessage() {
        errorMessage = nil
    }
    
    func refreshData() {
        loadData()
    }
    
    func resetAllData() {
        expenses.removeAll()
        budgets.removeAll()
        saveExpenses()
        saveBudgets()
    }
}

// MARK: - Supporting Data Structures
struct DailySpending: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct MonthlySpending: Identifiable {
    let id = UUID()
    let month: Int
    let year: Int
    let amount: Double
    let monthName: String
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

