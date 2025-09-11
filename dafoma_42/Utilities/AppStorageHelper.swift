//
//  AppStorageHelper.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import Foundation
import SwiftUI

// MARK: - AppStorage Keys
enum AppStorageKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let userPreferredCurrency = "userPreferredCurrency"
    static let enableNotifications = "enableNotifications"
    static let enableBudgetAlerts = "enableBudgetAlerts"
    static let enableInvestmentAlerts = "enableInvestmentAlerts"
    static let preferredTheme = "preferredTheme"
    static let lastSyncDate = "lastSyncDate"
    static let userName = "userName"
    static let userEmail = "userEmail"
    static let budgetAlertThreshold = "budgetAlertThreshold"
    static let showNewsOnStartup = "showNewsOnStartup"
    static let defaultExpenseCategory = "defaultExpenseCategory"
    static let enableBiometricAuth = "enableBiometricAuth"
    static let dataRetentionPeriod = "dataRetentionPeriod"
    static let enableAnalytics = "enableAnalytics"
    static let preferredNewsCategories = "preferredNewsCategories"
    static let autoSyncEnabled = "autoSyncEnabled"
}

// MARK: - AppStorage Helper
class AppStorageHelper: ObservableObject {
    
    // MARK: - Onboarding
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) 
    var hasCompletedOnboarding: Bool = false
    
    // MARK: - User Preferences
    @AppStorage(AppStorageKeys.userPreferredCurrency) 
    var userPreferredCurrency: String = "USD"
    
    @AppStorage(AppStorageKeys.userName) 
    var userName: String = ""
    
    @AppStorage(AppStorageKeys.userEmail) 
    var userEmail: String = ""
    
    @AppStorage(AppStorageKeys.preferredTheme) 
    var preferredTheme: String = "system"
    
    // MARK: - Notification Settings
    @AppStorage(AppStorageKeys.enableNotifications) 
    var enableNotifications: Bool = true
    
    @AppStorage(AppStorageKeys.enableBudgetAlerts) 
    var enableBudgetAlerts: Bool = true
    
    @AppStorage(AppStorageKeys.enableInvestmentAlerts) 
    var enableInvestmentAlerts: Bool = true
    
    @AppStorage(AppStorageKeys.budgetAlertThreshold) 
    var budgetAlertThreshold: Double = 80.0 // Alert when 80% of budget is used
    
    // MARK: - App Behavior
    @AppStorage(AppStorageKeys.showNewsOnStartup) 
    var showNewsOnStartup: Bool = false
    
    @AppStorage(AppStorageKeys.defaultExpenseCategory) 
    var defaultExpenseCategory: String = ExpenseCategory.other.rawValue
    
    @AppStorage(AppStorageKeys.autoSyncEnabled) 
    var autoSyncEnabled: Bool = true
    
    // MARK: - Security
    @AppStorage(AppStorageKeys.enableBiometricAuth) 
    var enableBiometricAuth: Bool = false
    
    // MARK: - Data Management
    @AppStorage(AppStorageKeys.dataRetentionPeriod) 
    var dataRetentionPeriod: Int = 365 // Days to keep data
    
    @AppStorage(AppStorageKeys.enableAnalytics) 
    var enableAnalytics: Bool = true
    
    // MARK: - Sync
    @AppStorage(AppStorageKeys.lastSyncDate) 
    private var lastSyncDateString: String = ""
    
    var lastSyncDate: Date? {
        get {
            guard !lastSyncDateString.isEmpty else { return nil }
            return ISO8601DateFormatter().date(from: lastSyncDateString)
        }
        set {
            lastSyncDateString = newValue?.ISO8601Format() ?? ""
        }
    }
    
    // MARK: - News Preferences
    @AppStorage(AppStorageKeys.preferredNewsCategories) 
    private var preferredNewsCategoriesString: String = ""
    
    var preferredNewsCategories: [NewsCategory] {
        get {
            guard !preferredNewsCategoriesString.isEmpty else { 
                return NewsCategory.allCases 
            }
            let categoryStrings = preferredNewsCategoriesString.components(separatedBy: ",")
            return categoryStrings.compactMap { NewsCategory(rawValue: $0) }
        }
        set {
            preferredNewsCategoriesString = newValue.map { $0.rawValue }.joined(separator: ",")
        }
    }
    
    // MARK: - Computed Properties
    var defaultExpenseCategoryEnum: ExpenseCategory {
        get {
            ExpenseCategory(rawValue: defaultExpenseCategory) ?? .other
        }
        set {
            defaultExpenseCategory = newValue.rawValue
        }
    }
    
    var themeMode: ColorScheme? {
        switch preferredTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // System
        }
    }
    
    var currencySymbol: String {
        let locale = Locale(identifier: userPreferredCurrency == "USD" ? "en_US" : "en_US")
        return locale.currencySymbol ?? "$"
    }
    
    var shouldShowBudgetAlert: Bool {
        enableNotifications && enableBudgetAlerts
    }
    
    var shouldShowInvestmentAlert: Bool {
        enableNotifications && enableInvestmentAlerts
    }
    
    // MARK: - Methods
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
    
    func resetAllSettings() {
        hasCompletedOnboarding = false
        userPreferredCurrency = "USD"
        enableNotifications = true
        enableBudgetAlerts = true
        enableInvestmentAlerts = true
        preferredTheme = "system"
        userName = ""
        userEmail = ""
        budgetAlertThreshold = 80.0
        showNewsOnStartup = false
        defaultExpenseCategory = ExpenseCategory.other.rawValue
        enableBiometricAuth = false
        dataRetentionPeriod = 365
        enableAnalytics = true
        preferredNewsCategoriesString = ""
        autoSyncEnabled = true
        lastSyncDateString = ""
    }
    
    func updateLastSyncDate() {
        lastSyncDate = Date()
    }
    
    func exportSettings() -> [String: Any] {
        return [
            AppStorageKeys.hasCompletedOnboarding: hasCompletedOnboarding,
            AppStorageKeys.userPreferredCurrency: userPreferredCurrency,
            AppStorageKeys.enableNotifications: enableNotifications,
            AppStorageKeys.enableBudgetAlerts: enableBudgetAlerts,
            AppStorageKeys.enableInvestmentAlerts: enableInvestmentAlerts,
            AppStorageKeys.preferredTheme: preferredTheme,
            AppStorageKeys.userName: userName,
            AppStorageKeys.userEmail: userEmail,
            AppStorageKeys.budgetAlertThreshold: budgetAlertThreshold,
            AppStorageKeys.showNewsOnStartup: showNewsOnStartup,
            AppStorageKeys.defaultExpenseCategory: defaultExpenseCategory,
            AppStorageKeys.enableBiometricAuth: enableBiometricAuth,
            AppStorageKeys.dataRetentionPeriod: dataRetentionPeriod,
            AppStorageKeys.enableAnalytics: enableAnalytics,
            AppStorageKeys.preferredNewsCategories: preferredNewsCategoriesString,
            AppStorageKeys.autoSyncEnabled: autoSyncEnabled,
            AppStorageKeys.lastSyncDate: lastSyncDateString
        ]
    }
    
    func importSettings(_ settings: [String: Any]) {
        hasCompletedOnboarding = settings[AppStorageKeys.hasCompletedOnboarding] as? Bool ?? false
        userPreferredCurrency = settings[AppStorageKeys.userPreferredCurrency] as? String ?? "USD"
        enableNotifications = settings[AppStorageKeys.enableNotifications] as? Bool ?? true
        enableBudgetAlerts = settings[AppStorageKeys.enableBudgetAlerts] as? Bool ?? true
        enableInvestmentAlerts = settings[AppStorageKeys.enableInvestmentAlerts] as? Bool ?? true
        preferredTheme = settings[AppStorageKeys.preferredTheme] as? String ?? "system"
        userName = settings[AppStorageKeys.userName] as? String ?? ""
        userEmail = settings[AppStorageKeys.userEmail] as? String ?? ""
        budgetAlertThreshold = settings[AppStorageKeys.budgetAlertThreshold] as? Double ?? 80.0
        showNewsOnStartup = settings[AppStorageKeys.showNewsOnStartup] as? Bool ?? false
        defaultExpenseCategory = settings[AppStorageKeys.defaultExpenseCategory] as? String ?? ExpenseCategory.other.rawValue
        enableBiometricAuth = settings[AppStorageKeys.enableBiometricAuth] as? Bool ?? false
        dataRetentionPeriod = settings[AppStorageKeys.dataRetentionPeriod] as? Int ?? 365
        enableAnalytics = settings[AppStorageKeys.enableAnalytics] as? Bool ?? true
        preferredNewsCategoriesString = settings[AppStorageKeys.preferredNewsCategories] as? String ?? ""
        autoSyncEnabled = settings[AppStorageKeys.autoSyncEnabled] as? Bool ?? true
        lastSyncDateString = settings[AppStorageKeys.lastSyncDate] as? String ?? ""
    }
    
    // MARK: - Validation Methods
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func isValidUserName(_ name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count >= 2
    }
    
    // MARK: - Helper Methods for UI
    func getThemeDisplayName() -> String {
        switch preferredTheme {
        case "light": return "Light"
        case "dark": return "Dark"
        default: return "System"
        }
    }
    
    func getCurrencyDisplayName() -> String {
        switch userPreferredCurrency {
        case "USD": return "US Dollar ($)"
        case "EUR": return "Euro (€)"
        case "GBP": return "British Pound (£)"
        case "JPY": return "Japanese Yen (¥)"
        default: return "US Dollar ($)"
        }
    }
    
    func getDataRetentionDisplayName() -> String {
        switch dataRetentionPeriod {
        case 30: return "1 Month"
        case 90: return "3 Months"
        case 180: return "6 Months"
        case 365: return "1 Year"
        case 730: return "2 Years"
        default: return "1 Year"
        }
    }
}

// MARK: - Theme Support
enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Currency Support
enum SupportedCurrency: String, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    
    var displayName: String {
        switch self {
        case .usd: return "US Dollar ($)"
        case .eur: return "Euro (€)"
        case .gbp: return "British Pound (£)"
        case .jpy: return "Japanese Yen (¥)"
        }
    }
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        }
    }
    
    var locale: Locale {
        switch self {
        case .usd: return Locale(identifier: "en_US")
        case .eur: return Locale(identifier: "en_EU")
        case .gbp: return Locale(identifier: "en_GB")
        case .jpy: return Locale(identifier: "ja_JP")
        }
    }
}

// MARK: - Data Retention Periods
enum DataRetentionPeriod: Int, CaseIterable {
    case oneMonth = 30
    case threeMonths = 90
    case sixMonths = 180
    case oneYear = 365
    case twoYears = 730
    
    var displayName: String {
        switch self {
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        case .twoYears: return "2 Years"
        }
    }
}

