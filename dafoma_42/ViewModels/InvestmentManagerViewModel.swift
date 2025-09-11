//
//  InvestmentManagerViewModel.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import Foundation
import SwiftUI
import Combine

@MainActor
class InvestmentManagerViewModel: ObservableObject {
    @Published var portfolio: InvestmentPortfolio = InvestmentPortfolio(name: "My Portfolio")
    @Published var newsArticles: [NewsArticle] = []
    @Published var selectedNewsCategory: NewsCategory? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingAddInvestment: Bool = false
    @Published var showingNewsDetail: Bool = false
    @Published var selectedNewsArticle: NewsArticle?
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .alphabetical
    
    private let financeDataService: FinanceDataService
    private let newsService: NewsService
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    enum SortOption: String, CaseIterable {
        case alphabetical = "Alphabetical"
        case value = "Value"
        case gainLoss = "Gain/Loss"
        case gainLossPercent = "Gain/Loss %"
        case purchaseDate = "Purchase Date"
        
        var icon: String {
            switch self {
            case .alphabetical: return "textformat.abc"
            case .value: return "dollarsign.circle"
            case .gainLoss: return "chart.line.uptrend.xyaxis"
            case .gainLossPercent: return "percent"
            case .purchaseDate: return "calendar"
            }
        }
    }
    
    init(financeDataService: FinanceDataService = FinanceDataService(), newsService: NewsService = NewsService()) {
        self.financeDataService = financeDataService
        self.newsService = newsService
        loadData()
        setupPeriodicRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Data Loading
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let portfolioResult = financeDataService.loadPortfolio()
                async let newsResult = newsService.loadNews()
                
                let (loadedPortfolio, loadedNews) = try await (portfolioResult, newsResult)
                
                await MainActor.run {
                    if let portfolio = loadedPortfolio {
                        self.portfolio = portfolio
                    }
                    self.newsArticles = loadedNews
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
    
    private func setupPeriodicRefresh() {
        // Refresh market data every 5 minutes during market hours
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshMarketData()
            }
        }
    }
    
    func refreshMarketData() async {
        // In a real app, this would fetch current prices from a financial API
        // For now, we'll simulate price updates
        await simulatePriceUpdates()
    }
    
    private func simulatePriceUpdates() async {
        // Simulate realistic price movements (±2%)
        for index in portfolio.investments.indices {
            let currentPrice = portfolio.investments[index].currentPrice
            let change = Double.random(in: -0.02...0.02)
            let newPrice = currentPrice * (1 + change)
            portfolio.investments[index].currentPrice = max(newPrice, 0.01) // Prevent negative prices
        }
        savePortfolio()
    }
    
    // MARK: - Investment Management
    func addInvestment(_ investment: InvestmentItem) {
        portfolio.investments.append(investment)
        savePortfolio()
    }
    
    func updateInvestment(_ investment: InvestmentItem) {
        if let index = portfolio.investments.firstIndex(where: { $0.id == investment.id }) {
            portfolio.investments[index] = investment
            savePortfolio()
        }
    }
    
    func deleteInvestment(_ investment: InvestmentItem) {
        portfolio.investments.removeAll { $0.id == investment.id }
        savePortfolio()
    }
    
    func deleteInvestments(at offsets: IndexSet) {
        let investmentsToDelete = offsets.map { sortedInvestments[$0] }
        for investment in investmentsToDelete {
            deleteInvestment(investment)
        }
    }
    
    // MARK: - Portfolio Analysis
    var sortedInvestments: [InvestmentItem] {
        let filtered = searchText.isEmpty ? portfolio.investments : 
            portfolio.investments.filter { investment in
                investment.name.localizedCaseInsensitiveContains(searchText) ||
                investment.symbol.localizedCaseInsensitiveContains(searchText)
            }
        
        switch sortOption {
        case .alphabetical:
            return filtered.sorted { $0.name < $1.name }
        case .value:
            return filtered.sorted { $0.totalValue > $1.totalValue }
        case .gainLoss:
            return filtered.sorted { $0.gainLoss > $1.gainLoss }
        case .gainLossPercent:
            return filtered.sorted { $0.gainLossPercentage > $1.gainLossPercentage }
        case .purchaseDate:
            return filtered.sorted { $0.purchaseDate > $1.purchaseDate }
        }
    }
    
    var diversificationScore: Double {
        let typeCount = Set(portfolio.investments.map { $0.type }).count
        let maxTypes = InvestmentType.allCases.count
        return Double(typeCount) / Double(maxTypes) * 100
    }
    
    var riskScore: Double {
        guard !portfolio.investments.isEmpty else { return 0 }
        
        let riskValues: [RiskLevel: Double] = [
            .low: 1.0,
            .moderate: 2.0,
            .high: 3.0,
            .veryHigh: 4.0
        ]
        
        let totalValue = portfolio.totalValue
        guard totalValue > 0 else { return 0 }
        
        let weightedRisk = portfolio.investments.reduce(0) { result, investment in
            let weight = investment.totalValue / totalValue
            let riskValue = riskValues[investment.riskLevel] ?? 2.0
            return result + (weight * riskValue)
        }
        
        return (weightedRisk / 4.0) * 100 // Convert to percentage
    }
    
    var portfolioMetrics: PortfolioMetrics {
        PortfolioMetrics(
            totalValue: portfolio.totalValue,
            totalGainLoss: portfolio.totalGainLoss,
            totalGainLossPercentage: portfolio.totalGainLossPercentage,
            diversificationScore: diversificationScore,
            riskScore: riskScore,
            investmentCount: portfolio.investments.count
        )
    }
    
    func getAllocationData() -> [AllocationData] {
        let allocation = portfolio.actualAllocation
        return InvestmentType.allCases.compactMap { type in
            let percentage = allocation[type] ?? 0
            guard percentage > 0 else { return nil }
            return AllocationData(type: type, percentage: percentage)
        }.sorted { $0.percentage > $1.percentage }
    }
    
    func getPerformanceHistory(days: Int = 30) -> [PerformancePoint] {
        // In a real app, this would fetch historical data
        // For now, we'll generate sample data
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        var points: [PerformancePoint] = []
        let currentValue = portfolio.totalValue
        
        for i in 0...days {
            let date = calendar.date(byAdding: .day, value: -i, to: endDate) ?? endDate
            // Simulate historical values with some randomness
            let randomFactor = 1.0 + Double.random(in: -0.05...0.05)
            let value = currentValue * randomFactor
            points.append(PerformancePoint(date: date, value: value))
        }
        
        return points.reversed()
    }
    
    // MARK: - News Management
    var filteredNews: [NewsArticle] {
        var filtered = newsArticles
        
        if let category = selectedNewsCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.summary.localizedCaseInsensitiveContains(searchText) ||
                article.source.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.publishedDate > $1.publishedDate }
    }
    
    var bookmarkedNews: [NewsArticle] {
        newsArticles.filter { $0.isBookmarked }
    }
    
    func toggleBookmark(for article: NewsArticle) {
        if let index = newsArticles.firstIndex(where: { $0.id == article.id }) {
            newsArticles[index].isBookmarked.toggle()
            saveNews()
        }
    }
    
    func refreshNews() {
        Task {
            do {
                let freshNews = try await newsService.fetchLatestNews()
                await MainActor.run {
                    self.newsArticles = freshNews
                    self.saveNews()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to refresh news: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Data Persistence
    private func savePortfolio() {
        Task {
            do {
                try await financeDataService.savePortfolio(portfolio)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save portfolio: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveNews() {
        Task {
            do {
                try await newsService.saveNews(newsArticles)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save news: \(error.localizedDescription)"
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
    
    func resetPortfolio() {
        portfolio = InvestmentPortfolio(name: "My Portfolio")
        savePortfolio()
    }
    
    func exportPortfolioData() -> String {
        // Create CSV export of portfolio data
        var csv = "Symbol,Name,Type,Shares,Purchase Price,Current Price,Total Value,Gain/Loss,Gain/Loss %,Purchase Date\n"
        
        for investment in portfolio.investments {
            let row = [
                investment.symbol,
                investment.name,
                investment.type.rawValue,
                investment.formattedShares,
                String(investment.purchasePrice),
                String(investment.currentPrice),
                String(investment.totalValue),
                String(investment.gainLoss),
                String(format: "%.2f", investment.gainLossPercentage),
                investment.purchaseDate.description
            ].joined(separator: ",")
            csv += row + "\n"
        }
        
        return csv
    }
}

// MARK: - Supporting Data Structures
struct PortfolioMetrics {
    let totalValue: Double
    let totalGainLoss: Double
    let totalGainLossPercentage: Double
    let diversificationScore: Double
    let riskScore: Double
    let investmentCount: Int
    
    var formattedTotalValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalValue)) ?? "$0.00"
    }
    
    var formattedGainLoss: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let sign = totalGainLoss >= 0 ? "+" : ""
        return sign + (formatter.string(from: NSNumber(value: totalGainLoss)) ?? "$0.00")
    }
    
    var formattedGainLossPercentage: String {
        let sign = totalGainLossPercentage >= 0 ? "+" : ""
        return sign + String(format: "%.2f", totalGainLossPercentage) + "%"
    }
    
    var riskLevel: String {
        switch riskScore {
        case 0..<25: return "Conservative"
        case 25..<50: return "Moderate"
        case 50..<75: return "Aggressive"
        default: return "Very Aggressive"
        }
    }
    
    var diversificationLevel: String {
        switch diversificationScore {
        case 0..<30: return "Poor"
        case 30..<60: return "Fair"
        case 60..<80: return "Good"
        default: return "Excellent"
        }
    }
}

struct AllocationData: Identifiable {
    let id = UUID()
    let type: InvestmentType
    let percentage: Double
    
    var formattedPercentage: String {
        return String(format: "%.1f%%", percentage)
    }
}

struct PerformancePoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    
    var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

