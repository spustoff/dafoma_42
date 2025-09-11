//
//  InvestmentView.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import SwiftUI

struct InvestmentView: View {
    @EnvironmentObject private var viewModel: InvestmentManagerViewModel
    @EnvironmentObject private var appStorage: AppStorageHelper
    @State private var showingAddInvestment = false
    @State private var selectedInvestment: InvestmentItem?
    @State private var showingInvestmentDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Portfolio Summary
                    portfolioSummarySection
                    
                    // Performance Chart
                    if !viewModel.portfolio.investments.isEmpty {
                        performanceChartSection
                    }
                    
                    // Asset Allocation
                    if !viewModel.portfolio.investments.isEmpty {
                        assetAllocationSection
                    }
                    
                    // Top Performers
                    if !viewModel.portfolio.topPerformers.isEmpty {
                        topPerformersSection
                    }
                    
                    // Holdings List
                    holdingsSection
                }
                .padding(.horizontal)
            }
            .refreshable {
                viewModel.refreshData()
                await viewModel.refreshMarketData()
            }
            .navigationTitle("Investments")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Menu {
                    Picker("Sort By", selection: $viewModel.sortOption) {
                        ForEach(InvestmentManagerViewModel.SortOption.allCases, id: \.self) { option in
                            Label(option.rawValue, systemImage: option.icon).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(Color("FinFocusOrange"))
                },
                trailing: Button {
                    showingAddInvestment = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color("FinFocusOrange"))
                }
            )
            .sheet(isPresented: $showingAddInvestment) {
                AddInvestmentView()
                    .environmentObject(viewModel)
                    .environmentObject(appStorage)
            }
            .sheet(item: $selectedInvestment) { investment in
                InvestmentDetailView(investment: investment)
                    .environmentObject(viewModel)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var portfolioSummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Portfolio Summary")
                    .font(.headline)
                    .foregroundColor(Color("FinFocusBlue"))
                Spacer()
                
                Button("View Metrics") {
                    // Show detailed metrics
                }
                .font(.caption)
                .foregroundColor(Color("FinFocusOrange"))
            }
            
            VStack(spacing: 12) {
                // Total Value
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Portfolio Value")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(viewModel.portfolio.formattedTotalValue)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color("FinFocusBlue"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.portfolio.isPortfolioProfit ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                            Text(viewModel.portfolio.formattedTotalGainLoss)
                                .font(.headline)
                        }
                        .foregroundColor(viewModel.portfolio.isPortfolioProfit ? .green : .red)
                        
                        Text(viewModel.portfolio.formattedTotalGainLossPercentage)
                            .font(.caption)
                            .foregroundColor(viewModel.portfolio.isPortfolioProfit ? .green : .red)
                    }
                }
                
                // Quick Stats
                HStack(spacing: 16) {
                    StatCard(
                        title: "Holdings",
                        value: "\(viewModel.portfolio.investments.count)",
                        icon: "chart.pie.fill",
                        color: Color("FinFocusBlue")
                    )
                    
                    StatCard(
                        title: "Diversification",
                        value: "\(Int(viewModel.diversificationScore))%",
                        icon: "scatter.fill",
                        color: Color("FinFocusOrange")
                    )
                    
                    StatCard(
                        title: "Risk Level",
                        value: viewModel.portfolioMetrics.riskLevel,
                        icon: "exclamationmark.triangle.fill",
                        color: riskLevelColor
                    )
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
    }
    
    private var riskLevelColor: Color {
        switch viewModel.riskScore {
        case 0..<25: return .green
        case 25..<50: return .yellow
        case 50..<75: return .orange
        default: return .red
        }
    }
    
    private var performanceChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio Performance")
                .font(.headline)
                .foregroundColor(Color("FinFocusBlue"))
            
            // Simple performance display (iOS 15.6 compatible)
            VStack(spacing: 12) {
                HStack {
                    Text("30-Day Trend")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.portfolio.isPortfolioProfit ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(viewModel.portfolio.formattedTotalGainLossPercentage)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewModel.portfolio.isPortfolioProfit ? .green : .red)
                }
                
                // Simple line representation using rectangles
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<30, id: \.self) { index in
                        let height = CGFloat.random(in: 20...60)
                        Rectangle()
                            .fill(Color("FinFocusOrange").opacity(0.7))
                            .frame(width: 8, height: height)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 80)
                
                HStack {
                    Text("Current Value: \(viewModel.portfolio.formattedTotalValue)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var assetAllocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Asset Allocation")
                .font(.headline)
                .foregroundColor(Color("FinFocusBlue"))
            
            // Simple pie chart representation using progress bars
            VStack(spacing: 8) {
                ForEach(viewModel.getAllocationData()) { data in
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(data.type.color)
                                .frame(width: 12, height: 12)
                            
                            Text(data.type.rawValue)
                                .font(.caption)
                                .foregroundColor(Color("FinFocusBlue"))
                                .frame(width: 80, alignment: .leading)
                        }
                        
                        // Progress bar representation
                        GeometryReader { geometry in
                            HStack {
                                Rectangle()
                                    .fill(data.type.color.opacity(0.7))
                                    .frame(width: geometry.size.width * (data.percentage / 100))
                                    .cornerRadius(4)
                                
                                Spacer()
                            }
                        }
                        .frame(height: 16)
                        
                        Text(data.formattedPercentage)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performers")
                .font(.headline)
                .foregroundColor(Color("FinFocusBlue"))
            
            VStack(spacing: 8) {
                ForEach(viewModel.portfolio.topPerformers.prefix(3)) { investment in
                    PerformanceRowView(investment: investment) {
                        selectedInvestment = investment
                        showingInvestmentDetail = true
                    }
                }
            }
        }
    }
    
    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Holdings")
                    .font(.headline)
                    .foregroundColor(Color("FinFocusBlue"))
                
                Spacer()
                
                if !viewModel.searchText.isEmpty {
                    Button("Clear") {
                        viewModel.searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(Color("FinFocusOrange"))
                }
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search investments...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.sortedInvestments.isEmpty {
                EmptyInvestmentView {
                    showingAddInvestment = true
                }
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.sortedInvestments) { investment in
                        InvestmentRowView(investment: investment) {
                            selectedInvestment = investment
                            showingInvestmentDetail = true
                        }
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color("FinFocusBlue"))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct PerformanceRowView: View {
    let investment: InvestmentItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Type Icon
                Image(systemName: investment.type.icon)
                    .foregroundColor(investment.type.color)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(investment.type.color.opacity(0.1))
                    .cornerRadius(8)
                
                // Investment Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(investment.symbol)
                        .font(.headline)
                        .foregroundColor(Color("FinFocusBlue"))
                    
                    Text(investment.name)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Performance
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: investment.isProfit ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(investment.formattedGainLossPercentage)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(investment.isProfit ? .green : .red)
                    
                    Text(investment.formattedTotalValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color("FinFocusWhite"))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InvestmentRowView: View {
    let investment: InvestmentItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Type Icon
                Image(systemName: investment.type.icon)
                    .foregroundColor(investment.type.color)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(investment.type.color.opacity(0.1))
                    .cornerRadius(8)
                
                // Investment Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(investment.symbol)
                            .font(.headline)
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        Spacer()
                        
                        Text(investment.formattedTotalValue)
                            .font(.headline)
                            .foregroundColor(Color("FinFocusBlue"))
                    }
                    
                    HStack {
                        Text(investment.name)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: investment.isProfit ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2)
                            Text(investment.formattedGainLoss)
                                .font(.caption)
                            Text("(\(investment.formattedGainLossPercentage))")
                                .font(.caption)
                        }
                        .foregroundColor(investment.isProfit ? .green : .red)
                    }
                    
                    HStack {
                        Text("\(investment.formattedShares) shares @ \(investment.formattedCurrentPrice)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: investment.riskLevel.icon)
                                .font(.caption2)
                            Text(investment.riskLevel.rawValue)
                                .font(.caption2)
                        }
                        .foregroundColor(investment.riskLevel.color)
                    }
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

struct EmptyInvestmentView: View {
    let onAddInvestment: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Investments Yet")
                    .font(.headline)
                    .foregroundColor(Color("FinFocusBlue"))
                
                Text("Start building your investment portfolio by adding your first investment.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Investment", action: onAddInvestment)
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
struct AddInvestmentView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewModel: InvestmentManagerViewModel
    @EnvironmentObject private var appStorage: AppStorageHelper
    
    @State private var symbol = ""
    @State private var name = ""
    @State private var selectedType = InvestmentType.stocks
    @State private var shares = ""
    @State private var purchasePrice = ""
    @State private var currentPrice = ""
    @State private var selectedRiskLevel = RiskLevel.moderate
    @State private var notes = ""
    @State private var purchaseDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Investment Details")) {
                    TextField("Symbol (e.g., AAPL)", text: $symbol)
                        .autocapitalization(.allCharacters)
                    
                    TextField("Company Name", text: $name)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(InvestmentType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    
                    TextField("Number of Shares", text: $shares)
                        .keyboardType(.decimalPad)
                    
                    TextField("Purchase Price", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                    
                    TextField("Current Price", text: $currentPrice)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }
                
                Section(header: Text("Risk Assessment")) {
                    Picker("Risk Level", selection: $selectedRiskLevel) {
                        ForEach(RiskLevel.allCases, id: \.self) { level in
                            HStack {
                                Image(systemName: level.icon)
                                    .foregroundColor(level.color)
                                Text(level.rawValue)
                            }
                            .tag(level)
                        }
                    }
                    
                    TextField("Notes (Optional)", text: $notes)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Add Investment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveInvestment()
                }
                .disabled(!isValidInvestment)
            )
        }
    }
    
    private var isValidInvestment: Bool {
        !symbol.isEmpty && !name.isEmpty && !shares.isEmpty && 
        !purchasePrice.isEmpty && !currentPrice.isEmpty &&
        Double(shares) != nil && Double(purchasePrice) != nil && Double(currentPrice) != nil
    }
    
    private func saveInvestment() {
        guard let sharesValue = Double(shares),
              let purchasePriceValue = Double(purchasePrice),
              let currentPriceValue = Double(currentPrice) else { return }
        
        let investment = InvestmentItem(
            symbol: symbol.uppercased(),
            name: name,
            type: selectedType,
            shares: sharesValue,
            purchasePrice: purchasePriceValue,
            currentPrice: currentPriceValue,
            purchaseDate: purchaseDate,
            riskLevel: selectedRiskLevel,
            notes: notes
        )
        
        viewModel.addInvestment(investment)
        presentationMode.wrappedValue.dismiss()
    }
}

struct InvestmentDetailView: View {
    let investment: InvestmentItem
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewModel: InvestmentManagerViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(investment.symbol)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        Text(investment.name)
                            .font(.headline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Performance Summary
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text("Current Value")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(investment.formattedTotalValue)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("FinFocusBlue"))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Gain/Loss")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                HStack(spacing: 4) {
                                    Image(systemName: investment.isProfit ? "arrow.up.right" : "arrow.down.right")
                                        .font(.caption)
                                    Text(investment.formattedGainLoss)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(investment.isProfit ? .green : .red)
                            }
                        }
                        
                        HStack {
                            Text("Return: \(investment.formattedGainLossPercentage)")
                                .font(.headline)
                                .foregroundColor(investment.isProfit ? .green : .red)
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Investment Details
                    VStack(spacing: 16) {
                        InvestmentDetailRow(title: "Type", value: investment.type.rawValue, icon: investment.type.icon)
                        InvestmentDetailRow(title: "Shares", value: investment.formattedShares, icon: "number")
                        InvestmentDetailRow(title: "Purchase Price", value: String(format: "%.2f", investment.purchasePrice), icon: "dollarsign.circle")
                        InvestmentDetailRow(title: "Current Price", value: investment.formattedCurrentPrice, icon: "chart.line.uptrend.xyaxis")
                        InvestmentDetailRow(title: "Purchase Date", value: investment.purchaseDate.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                        InvestmentDetailRow(title: "Risk Level", value: investment.riskLevel.rawValue, icon: investment.riskLevel.icon)
                        
                        if !investment.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.headline)
                                    .foregroundColor(Color("FinFocusBlue"))
                                
                                Text(investment.notes)
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
            .navigationTitle("Investment Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct InvestmentDetailRow: View {
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

#Preview {
    InvestmentView()
        .environmentObject(InvestmentManagerViewModel())
        .environmentObject(AppStorageHelper())
}
