//
//  FinFocusApp.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import SwiftUI

@main
struct FinFocusApp: App {
    @StateObject private var appStorageHelper = AppStorageHelper()
    @StateObject private var expenseTrackerViewModel = ExpenseTrackerViewModel()
    @StateObject private var investmentManagerViewModel = InvestmentManagerViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appStorageHelper)
                .environmentObject(expenseTrackerViewModel)
                .environmentObject(investmentManagerViewModel)
                .preferredColorScheme(appStorageHelper.themeMode)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Configure app-wide settings
        configureNavigationBarAppearance()
        
        // Load initial data if needed
        if !appStorageHelper.hasCompletedOnboarding {
            // App will show onboarding flow
        }
    }
    
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "FinFocusBlue")
        appearance.titleTextAttributes = [.foregroundColor: UIColor(named: "FinFocusWhite") ?? UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "FinFocusWhite") ?? UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(named: "FinFocusWhite")
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
