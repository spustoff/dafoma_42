//
//  NewsService.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import Foundation
import SwiftUI

// MARK: - News Service
class NewsService: ObservableObject {
    
    // MARK: - File URLs
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    private var newsURL: URL {
        documentsDirectory.appendingPathComponent("news.json")
    }
    
    private var bookmarksURL: URL {
        documentsDirectory.appendingPathComponent("bookmarked_news.json")
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
    
    // MARK: - News Loading
    func loadNews() async throws -> [NewsArticle] {
        if FileManager.default.fileExists(atPath: newsURL.path) {
            let data = try Data(contentsOf: newsURL)
            return try decoder.decode([NewsArticle].self, from: data)
        } else {
            // Return sample data for first launch and save it
            let sampleNews = NewsArticle.sampleNews
            try await saveNews(sampleNews)
            return sampleNews
        }
    }
    
    func saveNews(_ articles: [NewsArticle]) async throws {
        let data = try encoder.encode(articles)
        try data.write(to: newsURL)
    }
    
    // MARK: - News Fetching (Simulated)
    func fetchLatestNews() async throws -> [NewsArticle] {
        // In a real app, this would fetch from a news API
        // For now, we'll generate fresh sample data
        let freshNews = generateFreshNewsData()
        try await saveNews(freshNews)
        return freshNews
    }
    
    func fetchNewsByCategory(_ category: NewsCategory) async throws -> [NewsArticle] {
        let allNews = try await loadNews()
        return allNews.filter { $0.category == category }
    }
    
    func searchNews(query: String) async throws -> [NewsArticle] {
        let allNews = try await loadNews()
        return allNews.filter { article in
            article.title.localizedCaseInsensitiveContains(query) ||
            article.summary.localizedCaseInsensitiveContains(query) ||
            article.source.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Bookmark Management
    func loadBookmarkedNews() async throws -> [NewsArticle] {
        let allNews = try await loadNews()
        return allNews.filter { $0.isBookmarked }
    }
    
    func toggleBookmark(for articleId: UUID) async throws {
        var articles = try await loadNews()
        if let index = articles.firstIndex(where: { $0.id == articleId }) {
            articles[index].isBookmarked.toggle()
            try await saveNews(articles)
        }
    }
    
    func addBookmark(for articleId: UUID) async throws {
        var articles = try await loadNews()
        if let index = articles.firstIndex(where: { $0.id == articleId }) {
            articles[index].isBookmarked = true
            try await saveNews(articles)
        }
    }
    
    func removeBookmark(for articleId: UUID) async throws {
        var articles = try await loadNews()
        if let index = articles.firstIndex(where: { $0.id == articleId }) {
            articles[index].isBookmarked = false
            try await saveNews(articles)
        }
    }
    
    // MARK: - News Analytics
    func getNewsByTimeframe(_ timeframe: NewsTimeframe) async throws -> [NewsArticle] {
        let articles = try await loadNews()
        let cutoffDate = timeframe.cutoffDate
        
        return articles.filter { $0.publishedDate >= cutoffDate }
            .sorted { $0.publishedDate > $1.publishedDate }
    }
    
    func getTopNewsByCategory() async throws -> [NewsCategory: [NewsArticle]] {
        let articles = try await loadNews()
        var categorizedNews: [NewsCategory: [NewsArticle]] = [:]
        
        for category in NewsCategory.allCases {
            let categoryArticles = articles
                .filter { $0.category == category }
                .sorted { $0.publishedDate > $1.publishedDate }
                .prefix(5)
            categorizedNews[category] = Array(categoryArticles)
        }
        
        return categorizedNews
    }
    
    func getTrendingTopics() async throws -> [String] {
        let articles = try await loadNews()
        let recentArticles = articles.filter { 
            $0.publishedDate >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        }
        
        // Extract common words from titles (simplified trending analysis)
        var wordCounts: [String: Int] = [:]
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "as", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should"])
        
        for article in recentArticles {
            let words = article.title.lowercased()
                .components(separatedBy: .whitespacesAndNewlines)
                .compactMap { word in
                    let cleaned = word.trimmingCharacters(in: .punctuationCharacters)
                    return cleaned.count > 3 && !stopWords.contains(cleaned) ? cleaned : nil
                }
            
            for word in words {
                wordCounts[word, default: 0] += 1
            }
        }
        
        return wordCounts
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key.capitalized }
    }
    
    // MARK: - Data Management
    func cleanupOldNews(olderThan days: Int) async throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        var articles = try await loadNews()
        
        // Keep bookmarked articles even if they're old
        articles.removeAll { article in
            article.publishedDate < cutoffDate && !article.isBookmarked
        }
        
        try await saveNews(articles)
    }
    
    func resetNewsData() async throws {
        try? FileManager.default.removeItem(at: newsURL)
        try? FileManager.default.removeItem(at: bookmarksURL)
    }
    
    // MARK: - News Generation (Simulated)
    private func generateFreshNewsData() -> [NewsArticle] {
        let newsTemplates = [
            (category: NewsCategory.markets, titles: [
                "Stock Market Reaches New Heights Amid Economic Recovery",
                "Tech Giants Lead Market Rally in Strong Trading Session",
                "Emerging Markets Show Signs of Resilience",
                "Bond Yields Rise as Investors Shift Risk Appetite"
            ]),
            (category: NewsCategory.economy, titles: [
                "GDP Growth Exceeds Expectations in Latest Quarter",
                "Inflation Concerns Moderate as Supply Chains Stabilize",
                "Employment Numbers Show Continued Improvement",
                "Consumer Confidence Reaches Multi-Year High"
            ]),
            (category: NewsCategory.crypto, titles: [
                "Bitcoin Adoption Grows Among Institutional Investors",
                "Ethereum Network Upgrade Promises Better Efficiency",
                "Regulatory Clarity Boosts Cryptocurrency Market Sentiment",
                "DeFi Protocols Show Impressive Growth Numbers"
            ]),
            (category: NewsCategory.personal, titles: [
                "Smart Budgeting Strategies for the Modern Family",
                "How to Build Wealth Through Consistent Investing",
                "Emergency Fund Essentials: What You Need to Know",
                "Retirement Planning Tips for Different Life Stages"
            ]),
            (category: NewsCategory.investing, titles: [
                "Dividend Investing Strategies Gain Popularity",
                "ESG Funds Continue to Attract Investor Interest",
                "Value vs Growth: Finding the Right Balance",
                "International Diversification Benefits Explained"
            ])
        ]
        
        var freshArticles: [NewsArticle] = []
        let calendar = Calendar.current
        
        for template in newsTemplates {
            for (index, title) in template.titles.enumerated() {
                let publishDate = calendar.date(byAdding: .hour, value: -(index + 1), to: Date()) ?? Date()
                
                let article = NewsArticle(
                    title: title,
                    summary: generateSummary(for: title, category: template.category),
                    source: getRandomSource(),
                    publishedDate: publishDate,
                    category: template.category,
                    isBookmarked: false
                )
                
                freshArticles.append(article)
            }
        }
        
        return freshArticles.shuffled()
    }
    
    private func generateSummary(for title: String, category: NewsCategory) -> String {
        let summaryTemplates = [
            "Market analysts report positive trends as investors show renewed confidence in the financial sector. Key indicators suggest continued growth potential.",
            "Industry experts weigh in on recent developments, highlighting both opportunities and challenges facing investors in the current market environment.",
            "Economic data reveals significant insights into consumer behavior and spending patterns, providing valuable guidance for financial planning decisions.",
            "Financial advisors recommend strategic approaches to portfolio management, emphasizing the importance of diversification and long-term planning.",
            "Recent studies demonstrate the impact of global events on local markets, underscoring the need for adaptive investment strategies."
        ]
        
        return summaryTemplates.randomElement() ?? "Stay informed with the latest financial news and market insights."
    }
    
    private func getRandomSource() -> String {
        let sources = [
            "Financial Times", "Wall Street Journal", "Bloomberg", "MarketWatch", 
            "Reuters", "CNBC", "Yahoo Finance", "Investopedia", "Morningstar", 
            "The Economist", "Forbes", "Barron's"
        ]
        return sources.randomElement() ?? "Financial News"
    }
    
    // MARK: - News Preferences
    func getNewsForPreferences(_ categories: [NewsCategory]) async throws -> [NewsArticle] {
        let allNews = try await loadNews()
        return allNews.filter { categories.contains($0.category) }
            .sorted { $0.publishedDate > $1.publishedDate }
    }
    
    func getRecommendedNews(basedOn readArticles: [NewsArticle]) async throws -> [NewsArticle] {
        let allNews = try await loadNews()
        let readCategories = Set(readArticles.map { $0.category })
        
        // Recommend articles from categories the user has read
        return allNews.filter { article in
            readCategories.contains(article.category) && 
            !readArticles.contains { $0.id == article.id }
        }
        .sorted { $0.publishedDate > $1.publishedDate }
        .prefix(10)
        .map { $0 }
    }
    
    // MARK: - Export/Import
    func exportNewsData() async throws -> NewsDataExport {
        let articles = try await loadNews()
        let bookmarked = articles.filter { $0.isBookmarked }
        
        return NewsDataExport(
            articles: articles,
            bookmarkedArticles: bookmarked,
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
    }
    
    func importNewsData(_ data: NewsDataExport) async throws {
        try await saveNews(data.articles)
    }
}

// MARK: - Supporting Enums and Structures
enum NewsTimeframe {
    case lastHour
    case today
    case thisWeek
    case thisMonth
    case all
    
    var cutoffDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .lastHour:
            return calendar.date(byAdding: .hour, value: -1, to: now) ?? now
        case .today:
            return calendar.startOfDay(for: now)
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .all:
            return Date.distantPast
        }
    }
    
    var displayName: String {
        switch self {
        case .lastHour: return "Last Hour"
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .all: return "All Time"
        }
    }
}

struct NewsDataExport: Codable {
    let articles: [NewsArticle]
    let bookmarkedArticles: [NewsArticle]
    let exportDate: Date
    let appVersion: String
}

// MARK: - News API Response Models (for future real API integration)
struct NewsAPIResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [NewsAPIArticle]
}

struct NewsAPIArticle: Codable {
    let source: NewsAPISource
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?
}

struct NewsAPISource: Codable {
    let id: String?
    let name: String
}

// MARK: - News Service Extensions
extension NewsService {
    // Future method for real API integration
    func fetchFromAPI(apiKey: String, category: NewsCategory? = nil) async throws -> [NewsArticle] {
        // This would integrate with a real news API like NewsAPI.org
        // For now, return simulated data
        return try await fetchLatestNews()
    }
    
    // Method to convert API articles to our model
    private func convertAPIArticle(_ apiArticle: NewsAPIArticle) -> NewsArticle? {
        guard let publishedDate = ISO8601DateFormatter().date(from: apiArticle.publishedAt) else {
            return nil
        }
        
        return NewsArticle(
            title: apiArticle.title,
            summary: apiArticle.description ?? "No summary available",
            source: apiArticle.source.name,
            publishedDate: publishedDate,
            category: .business, // Would need logic to categorize
            imageURL: apiArticle.urlToImage,
            articleURL: apiArticle.url,
            isBookmarked: false
        )
    }
}

