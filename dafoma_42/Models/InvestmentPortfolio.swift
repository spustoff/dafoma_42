//
//  InvestmentPortfolio.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import Foundation
import SwiftUI

// MARK: - Investment Type
enum InvestmentType: String, CaseIterable, Codable {
    case stocks = "Stocks"
    case bonds = "Bonds"
    case etf = "ETF"
    case mutualFunds = "Mutual Funds"
    case crypto = "Cryptocurrency"
    case realEstate = "Real Estate"
    case commodities = "Commodities"
    case cash = "Cash"
    
    var icon: String {
        switch self {
        case .stocks: return "chart.line.uptrend.xyaxis"
        case .bonds: return "doc.text.fill"
        case .etf: return "chart.pie.fill"
        case .mutualFunds: return "building.columns.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .realEstate: return "house.fill"
        case .commodities: return "leaf.fill"
        case .cash: return "dollarsign.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .stocks: return .green
        case .bonds: return .blue
        case .etf: return .purple
        case .mutualFunds: return .orange
        case .crypto: return .yellow
        case .realEstate: return .brown
        case .commodities: return .mint
        case .cash: return .gray
        }
    }
}

// MARK: - Investment Risk Level
enum RiskLevel: String, CaseIterable, Codable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "shield.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high: return "flame.fill"
        case .veryHigh: return "bolt.fill"
        }
    }
}

// MARK: - Investment Item
struct InvestmentItem: Identifiable, Codable, Hashable {
    let id = UUID()
    var symbol: String
    var name: String
    var type: InvestmentType
    var shares: Double
    var purchasePrice: Double
    var currentPrice: Double
    var purchaseDate: Date
    var riskLevel: RiskLevel
    var notes: String
    
    init(symbol: String, name: String, type: InvestmentType, shares: Double, purchasePrice: Double, currentPrice: Double, purchaseDate: Date = Date(), riskLevel: RiskLevel = .moderate, notes: String = "") {
        self.symbol = symbol
        self.name = name
        self.type = type
        self.shares = shares
        self.purchasePrice = purchasePrice
        self.currentPrice = currentPrice
        self.purchaseDate = purchaseDate
        self.riskLevel = riskLevel
        self.notes = notes
    }
    
    var totalValue: Double {
        return shares * currentPrice
    }
    
    var totalCost: Double {
        return shares * purchasePrice
    }
    
    var gainLoss: Double {
        return totalValue - totalCost
    }
    
    var gainLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (gainLoss / totalCost) * 100
    }
    
    var isProfit: Bool {
        return gainLoss > 0
    }
    
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
        let sign = gainLoss >= 0 ? "+" : ""
        return sign + (formatter.string(from: NSNumber(value: gainLoss)) ?? "$0.00")
    }
    
    var formattedGainLossPercentage: String {
        let sign = gainLossPercentage >= 0 ? "+" : ""
        return sign + String(format: "%.2f", gainLossPercentage) + "%"
    }
    
    var formattedCurrentPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: currentPrice)) ?? "$0.00"
    }
    
    var formattedShares: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        return formatter.string(from: NSNumber(value: shares)) ?? "0"
    }
}

// MARK: - Investment Portfolio
struct InvestmentPortfolio: Identifiable, Codable {
    let id = UUID()
    var name: String
    var investments: [InvestmentItem]
    var createdDate: Date
    var targetAllocation: [InvestmentType: Double] // Percentage allocation
    
    init(name: String, investments: [InvestmentItem] = [], createdDate: Date = Date(), targetAllocation: [InvestmentType: Double] = [:]) {
        self.name = name
        self.investments = investments
        self.createdDate = createdDate
        self.targetAllocation = targetAllocation
    }
    
    var totalValue: Double {
        return investments.reduce(0) { $0 + $1.totalValue }
    }
    
    var totalCost: Double {
        return investments.reduce(0) { $0 + $1.totalCost }
    }
    
    var totalGainLoss: Double {
        return totalValue - totalCost
    }
    
    var totalGainLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (totalGainLoss / totalCost) * 100
    }
    
    var isPortfolioProfit: Bool {
        return totalGainLoss > 0
    }
    
    var formattedTotalValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalValue)) ?? "$0.00"
    }
    
    var formattedTotalGainLoss: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let sign = totalGainLoss >= 0 ? "+" : ""
        return sign + (formatter.string(from: NSNumber(value: totalGainLoss)) ?? "$0.00")
    }
    
    var formattedTotalGainLossPercentage: String {
        let sign = totalGainLossPercentage >= 0 ? "+" : ""
        return sign + String(format: "%.2f", totalGainLossPercentage) + "%"
    }
    
    // Calculate actual allocation by type
    var actualAllocation: [InvestmentType: Double] {
        guard totalValue > 0 else { return [:] }
        
        var allocation: [InvestmentType: Double] = [:]
        for type in InvestmentType.allCases {
            let typeValue = investments
                .filter { $0.type == type }
                .reduce(0) { $0 + $1.totalValue }
            allocation[type] = (typeValue / totalValue) * 100
        }
        return allocation
    }
    
    // Get top performing investments
    var topPerformers: [InvestmentItem] {
        return investments
            .filter { $0.isProfit }
            .sorted { $0.gainLossPercentage > $1.gainLossPercentage }
            .prefix(3)
            .map { $0 }
    }
    
    // Get worst performing investments
    var worstPerformers: [InvestmentItem] {
        return investments
            .filter { !$0.isProfit }
            .sorted { $0.gainLossPercentage < $1.gainLossPercentage }
            .prefix(3)
            .map { $0 }
    }
}

// MARK: - News Article
struct NewsArticle: Identifiable, Codable {
    let id = UUID()
    var title: String
    var summary: String
    var source: String
    var publishedDate: Date
    var category: NewsCategory
    var imageURL: String?
    var articleURL: String?
    var isBookmarked: Bool
    
    init(title: String, summary: String, source: String, publishedDate: Date = Date(), category: NewsCategory, imageURL: String? = nil, articleURL: String? = nil, isBookmarked: Bool = false) {
        self.title = title
        self.summary = summary
        self.source = source
        self.publishedDate = publishedDate
        self.category = category
        self.imageURL = imageURL
        self.articleURL = articleURL
        self.isBookmarked = isBookmarked
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: publishedDate)
    }
    
    var timeAgo: String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(publishedDate)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 { // Less than 1 day
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else { // 1 day or more
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - News Category
enum NewsCategory: String, CaseIterable, Codable {
    case markets = "Markets"
    case economy = "Economy"
    case crypto = "Cryptocurrency"
    case personal = "Personal Finance"
    case investing = "Investing"
    case business = "Business"
    case technology = "Technology"
    case global = "Global"
    
    var icon: String {
        switch self {
        case .markets: return "chart.line.uptrend.xyaxis"
        case .economy: return "building.columns.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .personal: return "person.crop.circle.fill"
        case .investing: return "chart.pie.fill"
        case .business: return "briefcase.fill"
        case .technology: return "laptopcomputer"
        case .global: return "globe"
        }
    }
    
    var color: Color {
        switch self {
        case .markets: return .green
        case .economy: return .blue
        case .crypto: return .yellow
        case .personal: return .purple
        case .investing: return .orange
        case .business: return .red
        case .technology: return .mint
        case .global: return .indigo
        }
    }
}

// MARK: - Sample Data
extension InvestmentItem {
    static let sampleInvestments: [InvestmentItem] = [
        InvestmentItem(symbol: "AAPL", name: "Apple Inc.", type: .stocks, shares: 10.0, purchasePrice: 150.00, currentPrice: 175.50, purchaseDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(), riskLevel: .moderate, notes: "Tech giant with strong fundamentals"),
        InvestmentItem(symbol: "MSFT", name: "Microsoft Corporation", type: .stocks, shares: 5.0, purchasePrice: 300.00, currentPrice: 285.75, purchaseDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(), riskLevel: .moderate),
        InvestmentItem(symbol: "SPY", name: "SPDR S&P 500 ETF", type: .etf, shares: 20.0, purchasePrice: 400.00, currentPrice: 425.30, purchaseDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(), riskLevel: .low, notes: "Diversified S&P 500 exposure"),
        InvestmentItem(symbol: "BTC", name: "Bitcoin", type: .crypto, shares: 0.5, purchasePrice: 45000.00, currentPrice: 52000.00, purchaseDate: Calendar.current.date(byAdding: .month, value: -4, to: Date()) ?? Date(), riskLevel: .veryHigh, notes: "Digital gold hedge"),
        InvestmentItem(symbol: "VTIAX", name: "Vanguard Total International Stock", type: .mutualFunds, shares: 100.0, purchasePrice: 25.50, currentPrice: 27.20, purchaseDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date(), riskLevel: .moderate),
        InvestmentItem(symbol: "TLT", name: "iShares 20+ Year Treasury Bond", type: .bonds, shares: 15.0, purchasePrice: 120.00, currentPrice: 115.75, purchaseDate: Calendar.current.date(byAdding: .month, value: -5, to: Date()) ?? Date(), riskLevel: .low)
    ]
}

extension InvestmentPortfolio {
    static let samplePortfolio = InvestmentPortfolio(
        name: "My Investment Portfolio",
        investments: InvestmentItem.sampleInvestments,
        targetAllocation: [
            .stocks: 60.0,
            .bonds: 20.0,
            .etf: 10.0,
            .crypto: 5.0,
            .mutualFunds: 5.0
        ]
    )
}

extension NewsArticle {
    static let sampleNews: [NewsArticle] = [
        NewsArticle(
            title: "Federal Reserve Signals Potential Rate Cuts Amid Economic Uncertainty",
            summary: "The Federal Reserve indicated it may consider lowering interest rates in response to recent economic indicators showing slower growth and inflation concerns.",
            source: "Financial Times",
            publishedDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            category: .economy,
            isBookmarked: false
        ),
        NewsArticle(
            title: "Tech Stocks Rally as AI Investments Show Strong Returns",
            summary: "Major technology companies see significant gains as artificial intelligence investments begin to pay off, with several reporting better-than-expected quarterly earnings.",
            source: "MarketWatch",
            publishedDate: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date(),
            category: .markets,
            isBookmarked: true
        ),
        NewsArticle(
            title: "Bitcoin Reaches New Monthly High Amid Institutional Adoption",
            summary: "Bitcoin prices surge as more institutional investors add cryptocurrency to their portfolios, with several major corporations announcing Bitcoin treasury allocations.",
            source: "CoinDesk",
            publishedDate: Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date(),
            category: .crypto,
            isBookmarked: false
        ),
        NewsArticle(
            title: "5 Essential Tips for Building an Emergency Fund in 2024",
            summary: "Financial experts share practical strategies for building and maintaining an emergency fund that can weather economic uncertainties and unexpected expenses.",
            source: "NerdWallet",
            publishedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            category: .personal,
            isBookmarked: true
        ),
        NewsArticle(
            title: "Global Supply Chain Improvements Boost Manufacturing Stocks",
            summary: "Manufacturing sector sees renewed optimism as supply chain disruptions ease, leading to increased investor confidence and stock price improvements.",
            source: "Reuters",
            publishedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            category: .business,
            isBookmarked: false
        )
    ]
}

