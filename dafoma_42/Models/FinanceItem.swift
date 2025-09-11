//
//  FinanceItem.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import Foundation
import SwiftUI

// MARK: - Expense Category
enum ExpenseCategory: String, CaseIterable, Codable {
    case food = "Food & Dining"
    case transport = "Transportation"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case utilities = "Utilities"
    case healthcare = "Healthcare"
    case education = "Education"
    case savings = "Savings"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "gamecontroller.fill"
        case .utilities: return "house.fill"
        case .healthcare: return "cross.case.fill"
        case .education: return "book.fill"
        case .savings: return "banknote.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .shopping: return .purple
        case .entertainment: return .pink
        case .utilities: return .green
        case .healthcare: return .red
        case .education: return .indigo
        case .savings: return .mint
        case .other: return .gray
        }
    }
}

// MARK: - Finance Item
struct FinanceItem: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    var notes: String
    var isRecurring: Bool
    var recurringFrequency: RecurringFrequency?
    
    init(title: String, amount: Double, category: ExpenseCategory, date: Date = Date(), notes: String = "", isRecurring: Bool = false, recurringFrequency: RecurringFrequency? = nil) {
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        self.isRecurring = isRecurring
        self.recurringFrequency = recurringFrequency
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Recurring Frequency
enum RecurringFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .yearly: return "calendar.badge.plus"
        }
    }
}

// MARK: - Budget Item
struct BudgetItem: Identifiable, Codable {
    let id = UUID()
    var category: ExpenseCategory
    var budgetAmount: Double
    var spentAmount: Double
    var month: Int
    var year: Int
    
    init(category: ExpenseCategory, budgetAmount: Double, spentAmount: Double = 0, month: Int = Calendar.current.component(.month, from: Date()), year: Int = Calendar.current.component(.year, from: Date())) {
        self.category = category
        self.budgetAmount = budgetAmount
        self.spentAmount = spentAmount
        self.month = month
        self.year = year
    }
    
    var remainingAmount: Double {
        return budgetAmount - spentAmount
    }
    
    var percentageUsed: Double {
        guard budgetAmount > 0 else { return 0 }
        return min(spentAmount / budgetAmount, 1.0)
    }
    
    var isOverBudget: Bool {
        return spentAmount > budgetAmount
    }
    
    var formattedBudgetAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: budgetAmount)) ?? "$0.00"
    }
    
    var formattedSpentAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: spentAmount)) ?? "$0.00"
    }
    
    var formattedRemainingAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: remainingAmount)) ?? "$0.00"
    }
}

// MARK: - Sample Data
extension FinanceItem {
    static let sampleExpenses: [FinanceItem] = [
        FinanceItem(title: "Grocery Shopping", amount: 85.50, category: .food, date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), notes: "Weekly grocery run"),
        FinanceItem(title: "Gas Station", amount: 45.00, category: .transport, date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()),
        FinanceItem(title: "Netflix Subscription", amount: 15.99, category: .entertainment, date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(), isRecurring: true, recurringFrequency: .monthly),
        FinanceItem(title: "Coffee Shop", amount: 12.75, category: .food, date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
        FinanceItem(title: "Electricity Bill", amount: 120.00, category: .utilities, date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(), isRecurring: true, recurringFrequency: .monthly),
        FinanceItem(title: "Book Purchase", amount: 25.99, category: .education, date: Date()),
        FinanceItem(title: "Emergency Fund", amount: 500.00, category: .savings, date: Date(), notes: "Monthly savings contribution")
    ]
}

extension BudgetItem {
    static let sampleBudgets: [BudgetItem] = [
        BudgetItem(category: .food, budgetAmount: 400.00, spentAmount: 285.50),
        BudgetItem(category: .transport, budgetAmount: 200.00, spentAmount: 145.00),
        BudgetItem(category: .entertainment, budgetAmount: 100.00, spentAmount: 65.99),
        BudgetItem(category: .utilities, budgetAmount: 300.00, spentAmount: 275.00),
        BudgetItem(category: .shopping, budgetAmount: 250.00, spentAmount: 180.00),
        BudgetItem(category: .healthcare, budgetAmount: 150.00, spentAmount: 75.00),
        BudgetItem(category: .education, budgetAmount: 100.00, spentAmount: 25.99),
        BudgetItem(category: .savings, budgetAmount: 1000.00, spentAmount: 500.00)
    ]
}

