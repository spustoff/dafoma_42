//
//  SettingsView.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appStorage: AppStorageHelper
    @EnvironmentObject private var expenseViewModel: ExpenseTrackerViewModel
    @EnvironmentObject private var investmentViewModel: InvestmentManagerViewModel
    @State private var showingResetAlert = false
    @State private var showingDataExport = false
    @State private var showingAbout = false
    @State private var exportedData = ""
    
    var body: some View {
        NavigationView {
            Form {
                // User Profile Section
                userProfileSection
                
                // App Preferences Section
                appPreferencesSection
                
                // Notification Settings Section
                notificationSettingsSection
                
                // Data Management Section
                dataManagementSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset All Data", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all your expenses, budgets, and investment data. This action cannot be undone.")
            }
            .sheet(isPresented: $showingDataExport) {
                DataExportView(exportedData: $exportedData)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var userProfileSection: some View {
        Section(header: Text("Profile")) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(Color("FinFocusBlue"))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Name", text: $appStorage.userName)
                        .font(.headline)
                        .foregroundColor(Color("FinFocusBlue"))
                    
                    TextField("Email", text: $appStorage.userEmail)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var appPreferencesSection: some View {
        Section(header: Text("Preferences")) {
            // Currency Setting
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(Color("FinFocusOrange"))
                    .frame(width: 24)
                
                Text("Currency")
                    .foregroundColor(Color("FinFocusBlue"))
                
                Spacer()
                
                Picker("Currency", selection: $appStorage.userPreferredCurrency) {
                    ForEach(SupportedCurrency.allCases, id: \.self) { currency in
                        Text(currency.displayName).tag(currency.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Theme Setting
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(Color("FinFocusOrange"))
                    .frame(width: 24)
                
                Text("Theme")
                    .foregroundColor(Color("FinFocusBlue"))
                
                Spacer()
                
                Picker("Theme", selection: $appStorage.preferredTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Default Expense Category
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(Color("FinFocusOrange"))
                    .frame(width: 24)
                
                Text("Default Category")
                    .foregroundColor(Color("FinFocusBlue"))
                
                Spacer()
                
                Picker("Category", selection: $appStorage.defaultExpenseCategoryEnum) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Show News on Startup
            HStack {
                Image(systemName: "newspaper.fill")
                    .foregroundColor(Color("FinFocusOrange"))
                    .frame(width: 24)
                
                Text("Show News on Startup")
                    .foregroundColor(Color("FinFocusBlue"))
                
                Spacer()
                
                Toggle("", isOn: $appStorage.showNewsOnStartup)
                    .toggleStyle(SwitchToggleStyle(tint: Color("FinFocusOrange")))
            }
        }
    }
    
    private var notificationSettingsSection: some View {
        Section(header: Text("Notifications")) {
            // Enable Notifications
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(Color("FinFocusOrange"))
                    .frame(width: 24)
                
                Text("Enable Notifications")
                    .foregroundColor(Color("FinFocusBlue"))
                
                Spacer()
                
                Toggle("", isOn: $appStorage.enableNotifications)
                    .toggleStyle(SwitchToggleStyle(tint: Color("FinFocusOrange")))
            }
            
            if appStorage.enableNotifications {
                // Budget Alerts
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(Color("FinFocusOrange"))
                        .frame(width: 24)
                    
                    Text("Budget Alerts")
                        .foregroundColor(Color("FinFocusBlue"))
                    
                    Spacer()
                    
                    Toggle("", isOn: $appStorage.enableBudgetAlerts)
                        .toggleStyle(SwitchToggleStyle(tint: Color("FinFocusOrange")))
                }
                
                // Investment Alerts
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Color("FinFocusOrange"))
                        .frame(width: 24)
                    
                    Text("Investment Alerts")
                        .foregroundColor(Color("FinFocusBlue"))
                    
                    Spacer()
                    
                    Toggle("", isOn: $appStorage.enableInvestmentAlerts)
                        .toggleStyle(SwitchToggleStyle(tint: Color("FinFocusOrange")))
                }
                
                if appStorage.enableBudgetAlerts {
                    // Budget Alert Threshold
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(Color("FinFocusOrange"))
                                .frame(width: 24)
                            
                            Text("Budget Alert Threshold")
                                .foregroundColor(Color("FinFocusBlue"))
                            
                            Spacer()
                            
                            Text("\(Int(appStorage.budgetAlertThreshold))%")
                                .foregroundColor(.gray)
                        }
                        
                        Slider(value: $appStorage.budgetAlertThreshold, in: 50...100, step: 5)
                            .accentColor(Color("FinFocusOrange"))
                    }
                }
            }
        }
    }
    
    private var dataManagementSection: some View {
        Section(header: Text("Data Management")) {
            // Auto Sync
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(Color("FinFocusOrange"))
                    .frame(width: 24)
                
                Text("Auto Sync")
                    .foregroundColor(Color("FinFocusBlue"))
                
                Spacer()
                
                Toggle("", isOn: $appStorage.autoSyncEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color("FinFocusOrange")))
            }
            
            // Data Retention
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(Color("FinFocusOrange"))
                    .frame(width: 24)
                
                Text("Data Retention")
                    .foregroundColor(Color("FinFocusBlue"))
                
                Spacer()
                
                Picker("Retention", selection: $appStorage.dataRetentionPeriod) {
                    ForEach(DataRetentionPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Export Data
            Button(action: {
                exportData()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color("FinFocusOrange"))
                        .frame(width: 24)
                    
                    Text("Export Data")
                        .foregroundColor(Color("FinFocusBlue"))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            // Last Sync
            if let lastSync = appStorage.lastSyncDate {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Sync")
                            .foregroundColor(Color("FinFocusBlue"))
                        Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text("About")) {
            // App Version
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color("FinFocusOrange"))
                    .frame(width: 24)
                
                Text("Version")
                    .foregroundColor(Color("FinFocusBlue"))
                
                Spacer()
                
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundColor(.gray)
            }
            
            // About App
            Button(action: {
                showingAbout = true
            }) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(Color("FinFocusOrange"))
                        .frame(width: 24)
                    
                    Text("About FinFocus Most")
                        .foregroundColor(Color("FinFocusBlue"))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            // Privacy & Analytics
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(Color("FinFocusOrange"))
                    .frame(width: 24)
                
                Text("Enable Analytics")
                    .foregroundColor(Color("FinFocusBlue"))
                
                Spacer()
                
                Toggle("", isOn: $appStorage.enableAnalytics)
                    .toggleStyle(SwitchToggleStyle(tint: Color("FinFocusOrange")))
            }
            
            // Reset Data
            Button(action: {
                showingResetAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Reset All Data")
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func exportData() {
        // Create a simple export of settings
        let settings = appStorage.exportSettings()
        
        // Convert to JSON manually since [String: Any] can't be encoded directly
        var jsonString = "{\n"
        let sortedKeys = settings.keys.sorted()
        for (index, key) in sortedKeys.enumerated() {
            let value = settings[key]!
            let valueString: String
            
            if let stringValue = value as? String {
                valueString = "\"\(stringValue)\""
            } else if let boolValue = value as? Bool {
                valueString = boolValue ? "true" : "false"
            } else if let numberValue = value as? NSNumber {
                valueString = "\(numberValue)"
            } else {
                valueString = "\"\(value)\""
            }
            
            jsonString += "  \"\(key)\": \(valueString)"
            if index < sortedKeys.count - 1 {
                jsonString += ","
            }
            jsonString += "\n"
        }
        jsonString += "}"
        
        exportedData = jsonString
        showingDataExport = true
    }
    
    private func resetAllData() {
        // Reset all app data
        appStorage.resetAllSettings()
        expenseViewModel.resetAllData()
        investmentViewModel.resetPortfolio()
        
        // Reset onboarding to show it again
        appStorage.resetOnboarding()
    }
}

struct DataExportView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var exportedData: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your exported settings data:")
                        .font(.headline)
                        .foregroundColor(Color("FinFocusBlue"))
                    
                    Text(exportedData)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                    
                    Text("You can copy this data and save it as a backup of your app settings.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Title
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        Text("FinFocus Most")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        Text("Your Financial Companion")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        Text("FinFocus Most is a comprehensive financial management app designed to help you track expenses, manage investments, and stay informed with the latest financial news. Built with modern iOS design principles and user privacy in mind.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "creditcard.fill", title: "Expense Tracking", description: "Categorize and monitor your spending")
                            FeatureRow(icon: "chart.pie.fill", title: "Investment Management", description: "Track your portfolio performance")
                            FeatureRow(icon: "newspaper.fill", title: "Financial News", description: "Stay updated with market insights")
                            FeatureRow(icon: "target", title: "Budget Planning", description: "Set and track spending goals")
                            FeatureRow(icon: "bell.fill", title: "Smart Alerts", description: "Get notified about important changes")
                        }
                    }
                    
                    // Privacy
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Privacy")
                            .font(.headline)
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        Text("Your financial data is stored locally on your device and never shared with third parties. We believe your financial information should remain private and secure.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                    }
                    
                    // Version Info
                    VStack(spacing: 8) {
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("Made with ❤️ for iOS")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("FinFocusOrange"))
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("FinFocusBlue"))
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStorageHelper())
        .environmentObject(ExpenseTrackerViewModel())
        .environmentObject(InvestmentManagerViewModel())
}
