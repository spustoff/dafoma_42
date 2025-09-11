//
//  FinanceDataService.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import Foundation
import SwiftUI

// MARK: - Finance Data Service
class FinanceDataService: ObservableObject {
    
    // MARK: - File URLs
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    private var expensesURL: URL {
        documentsDirectory.appendingPathComponent("expenses.json")
    }
    
    private var budgetsURL: URL {
        documentsDirectory.appendingPathComponent("budgets.json")
    }
    
    private var portfolioURL: URL {
        documentsDirectory.appendingPathComponent("portfolio.json")
    }
    
    // MARK: - JSON Encoder/Decoder
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // MARK: - Expense Management
    func loadExpenses() async throws -> [FinanceItem] {
        if FileManager.default.fileExists(atPath: expensesURL.path) {
            let data = try Data(contentsOf: expensesURL)
            return try decoder.decode([FinanceItem].self, from: data)
        } else {
            // Return sample data for first launch
            return FinanceItem.sampleExpenses
        }
    }
    
    func saveExpenses(_ expenses: [FinanceItem]) async throws {
        let data = try encoder.encode(expenses)
        try data.write(to: expensesURL)
    }
    
    func addExpense(_ expense: FinanceItem) async throws {
        var expenses = try await loadExpenses()
        expenses.append(expense)
        try await saveExpenses(expenses)
    }
    
    func deleteExpense(withId id: UUID) async throws {
        var expenses = try await loadExpenses()
        expenses.removeAll { $0.id == id }
        try await saveExpenses(expenses)
    }
    
    func updateExpense(_ expense: FinanceItem) async throws {
        var expenses = try await loadExpenses()
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            try await saveExpenses(expenses)
        }
    }
    
    // MARK: - Budget Management
    func loadBudgets() async throws -> [BudgetItem] {
        if FileManager.default.fileExists(atPath: budgetsURL.path) {
            let data = try Data(contentsOf: budgetsURL)
            return try decoder.decode([BudgetItem].self, from: data)
        } else {
            // Return sample data for first launch
            return BudgetItem.sampleBudgets
        }
    }
    
    func saveBudgets(_ budgets: [BudgetItem]) async throws {
        let data = try encoder.encode(budgets)
        try data.write(to: budgetsURL)
    }
    
    func addBudget(_ budget: BudgetItem) async throws {
        var budgets = try await loadBudgets()
        budgets.append(budget)
        try await saveBudgets(budgets)
    }
    
    func deleteBudget(withId id: UUID) async throws {
        var budgets = try await loadBudgets()
        budgets.removeAll { $0.id == id }
        try await saveBudgets(budgets)
    }
    
    func updateBudget(_ budget: BudgetItem) async throws {
        var budgets = try await loadBudgets()
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
            try await saveBudgets(budgets)
        }
    }
    
    // MARK: - Portfolio Management
    func loadPortfolio() async throws -> InvestmentPortfolio? {
        if FileManager.default.fileExists(atPath: portfolioURL.path) {
            let data = try Data(contentsOf: portfolioURL)
            return try decoder.decode(InvestmentPortfolio.self, from: data)
        } else {
            // Return sample portfolio for first launch
            return InvestmentPortfolio.samplePortfolio
        }
    }
    
    func savePortfolio(_ portfolio: InvestmentPortfolio) async throws {
        let data = try encoder.encode(portfolio)
        try data.write(to: portfolioURL)
    }
    
    func addInvestment(_ investment: InvestmentItem, to portfolio: InvestmentPortfolio) async throws {
        var updatedPortfolio = portfolio
        updatedPortfolio.investments.append(investment)
        try await savePortfolio(updatedPortfolio)
    }
    
    func deleteInvestment(withId id: UUID, from portfolio: InvestmentPortfolio) async throws {
        var updatedPortfolio = portfolio
        updatedPortfolio.investments.removeAll { $0.id == id }
        try await savePortfolio(updatedPortfolio)
    }
    
    func updateInvestment(_ investment: InvestmentItem, in portfolio: InvestmentPortfolio) async throws {
        var updatedPortfolio = portfolio
        if let index = updatedPortfolio.investments.firstIndex(where: { $0.id == investment.id }) {
            updatedPortfolio.investments[index] = investment
            try await savePortfolio(updatedPortfolio)
        }
    }
    
    // MARK: - Data Analytics
    func getExpensesSummary(for period: DateInterval) async throws -> ExpensesSummary {
        let expenses = try await loadExpenses()
        let filteredExpenses = expenses.filter { expense in
            expense.date >= period.start && expense.date <= period.end
        }
        
        let totalAmount = filteredExpenses.reduce(0) { $0 + $1.amount }
        let expenseCount = filteredExpenses.count
        
        var categoryTotals: [ExpenseCategory: Double] = [:]
        for expense in filteredExpenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        
        let topCategory = categoryTotals.max { $0.value < $1.value }
        
        return ExpensesSummary(
            totalAmount: totalAmount,
            expenseCount: expenseCount,
            categoryBreakdown: categoryTotals,
            topSpendingCategory: topCategory?.key,
            period: period
        )
    }
    
    func getBudgetPerformance(for month: Int, year: Int) async throws -> BudgetPerformance {
        let budgets = try await loadBudgets()
        let expenses = try await loadExpenses()
        
        let monthBudgets = budgets.filter { $0.month == month && $0.year == year }
        let monthExpenses = expenses.filter { expense in
            let calendar = Calendar.current
            return calendar.component(.month, from: expense.date) == month &&
                   calendar.component(.year, from: expense.date) == year
        }
        
        var categoryPerformance: [ExpenseCategory: CategoryBudgetPerformance] = [:]
        
        for budget in monthBudgets {
            let categoryExpenses = monthExpenses.filter { $0.category == budget.category }
            let actualSpent = categoryExpenses.reduce(0) { $0 + $1.amount }
            
            categoryPerformance[budget.category] = CategoryBudgetPerformance(
                budgetAmount: budget.budgetAmount,
                actualSpent: actualSpent,
                isOverBudget: actualSpent > budget.budgetAmount,
                percentageUsed: budget.budgetAmount > 0 ? (actualSpent / budget.budgetAmount) * 100 : 0
            )
        }
        
        let totalBudget = monthBudgets.reduce(0) { $0 + $1.budgetAmount }
        let totalSpent = monthExpenses.reduce(0) { $0 + $1.amount }
        
        return BudgetPerformance(
            month: month,
            year: year,
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            categoryPerformance: categoryPerformance,
            overBudgetCategories: categoryPerformance.filter { $0.value.isOverBudget }.count
        )
    }
    
    // MARK: - Data Export/Import
    func exportAllData() async throws -> FinanceDataExport {
        let expenses = try await loadExpenses()
        let budgets = try await loadBudgets()
        let portfolio = try await loadPortfolio()
        
        return FinanceDataExport(
            expenses: expenses,
            budgets: budgets,
            portfolio: portfolio,
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
    }
    
    func importData(_ data: FinanceDataExport) async throws {
        try await saveExpenses(data.expenses)
        try await saveBudgets(data.budgets)
        if let portfolio = data.portfolio {
            try await savePortfolio(portfolio)
        }
    }
    
    func exportToCSV() async throws -> String {
        let expenses = try await loadExpenses()
        var csv = "Date,Title,Amount,Category,Notes,Recurring\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        for expense in expenses {
            let row = [
                formatter.string(from: expense.date),
                expense.title.replacingOccurrences(of: ",", with: ";"),
                String(expense.amount),
                expense.category.rawValue,
                expense.notes.replacingOccurrences(of: ",", with: ";"),
                String(expense.isRecurring)
            ].joined(separator: ",")
            csv += row + "\n"
        }
        
        return csv
    }
    
    // MARK: - Data Cleanup
    func cleanupOldData(olderThan days: Int) async throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        var expenses = try await loadExpenses()
        expenses.removeAll { $0.date < cutoffDate }
        try await saveExpenses(expenses)
        
        // Don't clean up budgets as they're monthly and users might want historical data
        // Don't clean up portfolio as it's current holdings
    }
    
    func resetAllData() async throws {
        try? FileManager.default.removeItem(at: expensesURL)
        try? FileManager.default.removeItem(at: budgetsURL)
        try? FileManager.default.removeItem(at: portfolioURL)
    }
    
    // MARK: - File Management
    func getDataSize() -> String {
        let urls = [expensesURL, budgetsURL, portfolioURL]
        var totalSize: Int64 = 0
        
        for url in urls {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attributes[.size] as? Int64 {
                totalSize += size
            }
        }
        
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    func backupData() async throws -> URL {
        let backupDirectory = documentsDirectory.appendingPathComponent("Backups")
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        
        let timestamp = DateFormatter().string(from: Date())
        let backupURL = backupDirectory.appendingPathComponent("FinFocus_Backup_\(timestamp).json")
        
        let exportData = try await exportAllData()
        let data = try encoder.encode(exportData)
        try data.write(to: backupURL)
        
        return backupURL
    }
    
    func restoreFromBackup(at url: URL) async throws {
        let data = try Data(contentsOf: url)
        let backupData = try decoder.decode(FinanceDataExport.self, from: data)
        try await importData(backupData)
    }
}

// MARK: - Supporting Data Structures
struct ExpensesSummary {
    let totalAmount: Double
    let expenseCount: Int
    let categoryBreakdown: [ExpenseCategory: Double]
    let topSpendingCategory: ExpenseCategory?
    let period: DateInterval
    
    var formattedTotalAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "$0.00"
    }
    
    var averageExpenseAmount: Double {
        guard expenseCount > 0 else { return 0 }
        return totalAmount / Double(expenseCount)
    }
    
    var formattedAverageAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: averageExpenseAmount)) ?? "$0.00"
    }
}

struct CategoryBudgetPerformance {
    let budgetAmount: Double
    let actualSpent: Double
    let isOverBudget: Bool
    let percentageUsed: Double
    
    var remainingAmount: Double {
        return budgetAmount - actualSpent
    }
    
    var formattedBudgetAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: budgetAmount)) ?? "$0.00"
    }
    
    var formattedActualSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: actualSpent)) ?? "$0.00"
    }
    
    var formattedRemainingAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: remainingAmount)) ?? "$0.00"
    }
}

struct BudgetPerformance {
    let month: Int
    let year: Int
    let totalBudget: Double
    let totalSpent: Double
    let categoryPerformance: [ExpenseCategory: CategoryBudgetPerformance]
    let overBudgetCategories: Int
    
    var remainingBudget: Double {
        return totalBudget - totalSpent
    }
    
    var budgetUtilization: Double {
        guard totalBudget > 0 else { return 0 }
        return (totalSpent / totalBudget) * 100
    }
    
    var isOverBudget: Bool {
        return totalSpent > totalBudget
    }
    
    var formattedTotalBudget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalBudget)) ?? "$0.00"
    }
    
    var formattedTotalSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalSpent)) ?? "$0.00"
    }
    
    var formattedRemainingBudget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: remainingBudget)) ?? "$0.00"
    }
}

struct FinanceDataExport: Codable {
    let expenses: [FinanceItem]
    let budgets: [BudgetItem]
    let portfolio: InvestmentPortfolio?
    let exportDate: Date
    let appVersion: String
}

