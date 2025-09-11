//
//  ExpenseTrackerView.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import SwiftUI

struct ExpenseTrackerView: View {
    @EnvironmentObject private var viewModel: ExpenseTrackerViewModel
    @EnvironmentObject private var appStorage: AppStorageHelper
    @State private var showingAddExpense = false
    @State private var selectedExpense: FinanceItem?
    @State private var showingExpenseDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Summary Cards
                    summarySection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Spending Chart
                    if !viewModel.filteredExpenses.isEmpty {
                        spendingChartSection
                    }
                    
                    // Budget Overview
                    if !viewModel.currentMonthBudgets.isEmpty {
                        budgetOverviewSection
                    }
                    
                    // Recent Expenses
                    recentExpensesSection
                }
                .padding(.horizontal)
            }
            .refreshable {
                viewModel.refreshData()
            }
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Menu {
                    Picker("Time Period", selection: $viewModel.selectedPeriod) {
                        ForEach(ExpenseTrackerViewModel.TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                } label: {
                    Image(systemName: "calendar")
                        .foregroundColor(Color("FinFocusOrange"))
                },
                trailing: Button {
                    showingAddExpense = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color("FinFocusOrange"))
                }
            )
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
                    .environmentObject(viewModel)
                    .environmentObject(appStorage)
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
                    .environmentObject(viewModel)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Summary")
                    .font(.headline)
                    .foregroundColor(Color("FinFocusBlue"))
                Spacer()
                Text(viewModel.selectedPeriod.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 16) {
                SummaryCard(
                    title: "Total Spent",
                    value: viewModel.formattedTotalExpenses,
                    icon: "creditcard.fill",
                    color: Color("FinFocusOrange")
                )
                
                SummaryCard(
                    title: "Transactions",
                    value: "\(viewModel.filteredExpenses.count)",
                    icon: "list.bullet",
                    color: Color("FinFocusBlue")
                )
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(Color("FinFocusBlue"))
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Add Expense",
                    icon: "plus.circle",
                    color: Color("FinFocusOrange")
                ) {
                    showingAddExpense = true
                }
                
                QuickActionButton(
                    title: "Set Budget",
                    icon: "target",
                    color: Color("FinFocusBlue")
                ) {
                    viewModel.showingBudgetSetup = true
                }
                
                QuickActionButton(
                    title: "View Report",
                    icon: "chart.bar.fill",
                    color: .green
                ) {
                    // Navigate to reports
                }
            }
        }
        .sheet(isPresented: $viewModel.showingBudgetSetup) {
            BudgetSetupView()
                .environmentObject(viewModel)
                .environmentObject(appStorage)
        }
    }
    
    private var spendingChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundColor(Color("FinFocusBlue"))
            
            // Simple bar chart using rectangles (iOS 15.6 compatible)
            VStack(spacing: 8) {
                ForEach(viewModel.topSpendingCategories.prefix(5), id: \.category) { item in
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: item.category.icon)
                                .foregroundColor(item.category.color)
                                .font(.caption)
                            
                            Text(item.category.rawValue)
                                .font(.caption)
                                .foregroundColor(Color("FinFocusBlue"))
                                .frame(width: 80, alignment: .leading)
                        }
                        
                        // Bar representation
                        GeometryReader { geometry in
                            let maxAmount = viewModel.topSpendingCategories.first?.amount ?? 1
                            let percentage = item.amount / maxAmount
                            
                            HStack {
                                Rectangle()
                                    .fill(item.category.color.opacity(0.7))
                                    .frame(width: geometry.size.width * percentage)
                                    .cornerRadius(4)
                                
                                Spacer()
                            }
                        }
                        .frame(height: 20)
                        
                        Text(String(format: "$%.0f", item.amount))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var budgetOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Budget Overview")
                    .font(.headline)
                    .foregroundColor(Color("FinFocusBlue"))
                
                Spacer()
                
                Text("\(Int(viewModel.budgetUtilizationPercentage * 100))% Used")
                    .font(.caption)
                    .foregroundColor(viewModel.budgetUtilizationPercentage > 0.8 ? .red : .gray)
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.currentMonthBudgets.prefix(3)) { budget in
                    BudgetProgressView(budget: budget)
                }
                
                if viewModel.currentMonthBudgets.count > 3 {
                    Button("View All Budgets") {
                        // Navigate to budget view
                    }
                    .font(.caption)
                    .foregroundColor(Color("FinFocusOrange"))
                }
            }
        }
    }
    
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Expenses")
                    .font(.headline)
                    .foregroundColor(Color("FinFocusBlue"))
                
                Spacer()
                
                if !viewModel.filteredExpenses.isEmpty {
                    Button("View All") {
                        // Navigate to all expenses
                    }
                    .font(.caption)
                    .foregroundColor(Color("FinFocusOrange"))
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.filteredExpenses.isEmpty {
                EmptyStateView(
                    title: "No Expenses Yet",
                    description: "Start tracking your expenses by adding your first transaction.",
                    buttonTitle: "Add Expense",
                    buttonAction: { showingAddExpense = true }
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.filteredExpenses.prefix(10)) { expense in
                        ExpenseRowView(expense: expense) {
                            selectedExpense = expense
                            showingExpenseDetail = true
                        }
                    }
                }
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("FinFocusBlue"))
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("FinFocusWhite"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color("FinFocusBlue"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BudgetProgressView: View {
    let budget: BudgetItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: budget.category.icon)
                        .foregroundColor(budget.category.color)
                        .font(.caption)
                    
                    Text(budget.category.rawValue)
                        .font(.caption)
                        .foregroundColor(Color("FinFocusBlue"))
                }
                
                Spacer()
                
                Text("\(budget.formattedSpentAmount) / \(budget.formattedBudgetAmount)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: budget.percentageUsed, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: budget.isOverBudget ? .red : Color("FinFocusOrange")))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct ExpenseRowView: View {
    let expense: FinanceItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category Icon
                Image(systemName: expense.category.icon)
                    .foregroundColor(expense.category.color)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(expense.category.color.opacity(0.1))
                    .cornerRadius(8)
                
                // Expense Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.title)
                        .font(.headline)
                        .foregroundColor(Color("FinFocusBlue"))
                        .lineLimit(1)
                    
                    HStack {
                        Text(expense.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if expense.isRecurring {
                            Image(systemName: "repeat")
                                .font(.caption2)
                                .foregroundColor(Color("FinFocusOrange"))
                        }
                    }
                }
                
                Spacer()
                
                // Amount and Date
                VStack(alignment: .trailing, spacing: 4) {
                    Text(expense.formattedAmount)
                        .font(.headline)
                        .foregroundColor(Color("FinFocusBlue"))
                    
                    Text(expense.formattedDate)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color("FinFocusWhite"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    let title: String
    let description: String
    let buttonTitle: String
    let buttonAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("FinFocusBlue"))
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button(buttonTitle, action: buttonAction)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color("FinFocusOrange"))
                .cornerRadius(25)
        }
        .padding(40)
    }
}

// Placeholder views for sheets
struct AddExpenseView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewModel: ExpenseTrackerViewModel
    @EnvironmentObject private var appStorage: AppStorageHelper
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory = ExpenseCategory.other
    @State private var notes = ""
    @State private var date = Date()
    @State private var isRecurring = false
    @State private var recurringFrequency = RecurringFrequency.monthly
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Details")) {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Notes (Optional)", text: $notes)
                        .lineLimit(3)
                }
                
                Section(header: Text("Recurring")) {
                    Toggle("Recurring Expense", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Frequency", selection: $recurringFrequency) {
                            ForEach(RecurringFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.rawValue).tag(frequency)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveExpense()
                }
                .disabled(!isValidExpense)
            )
        }
    }
    
    private var isValidExpense: Bool {
        !title.isEmpty && !amount.isEmpty && Double(amount) != nil
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }
        
        let expense = FinanceItem(
            title: title,
            amount: amountValue,
            category: selectedCategory,
            date: date,
            notes: notes,
            isRecurring: isRecurring,
            recurringFrequency: isRecurring ? recurringFrequency : nil
        )
        
        viewModel.addExpense(expense)
        presentationMode.wrappedValue.dismiss()
    }
}

struct ExpenseDetailView: View {
    let expense: FinanceItem
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewModel: ExpenseTrackerViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Amount Display
                    VStack(spacing: 8) {
                        Text(expense.formattedAmount)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        Text(expense.title)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    
                    // Details
                    VStack(spacing: 16) {
                        DetailRow(title: "Category", value: expense.category.rawValue, icon: expense.category.icon)
                        DetailRow(title: "Date", value: expense.formattedDate, icon: "calendar")
                        
                        if expense.isRecurring {
                            DetailRow(title: "Frequency", value: expense.recurringFrequency?.rawValue ?? "", icon: "repeat")
                        }
                        
                        if !expense.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.headline)
                                    .foregroundColor(Color("FinFocusBlue"))
                                
                                Text(expense.notes)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Expense Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("FinFocusOrange"))
                .frame(width: 20)
            
            Text(title)
                .font(.headline)
                .foregroundColor(Color("FinFocusBlue"))
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.gray)
        }
    }
}

struct BudgetSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewModel: ExpenseTrackerViewModel
    
    var body: some View {
        NavigationView {
            Text("Budget Setup View")
                .navigationTitle("Set Budget")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
        }
    }
}

#Preview {
    ExpenseTrackerView()
        .environmentObject(ExpenseTrackerViewModel())
        .environmentObject(AppStorageHelper())
}
