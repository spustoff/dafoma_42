//
//  ContentView.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appStorage: AppStorageHelper
    @EnvironmentObject private var expenseViewModel: ExpenseTrackerViewModel
    @EnvironmentObject private var investmentViewModel: InvestmentManagerViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if !appStorage.hasCompletedOnboarding {
                OnboardingView()
            } else {
                mainTabView
            }
        }
        .onAppear {
            setupInitialData()
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // Expenses Tab
            ExpenseTrackerView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "creditcard.fill" : "creditcard")
                    Text("Expenses")
                }
                .tag(0)
            
            // Investments Tab
            InvestmentView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "chart.pie.fill" : "chart.pie")
                    Text("Investments")
                }
                .tag(1)
            
            // News Tab
            NewsFeedView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "newspaper.fill" : "newspaper")
                    Text("News")
                }
                .tag(2)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(Color("FinFocusOrange"))
        .onAppear {
            setupTabBarAppearance()
            
            // Show news tab on startup if enabled
            if appStorage.showNewsOnStartup {
                selectedTab = 2
            }
        }
    }
    
    private func setupInitialData() {
        // Load initial data if needed
        if appStorage.hasCompletedOnboarding {
            expenseViewModel.loadData()
            investmentViewModel.loadData()
        }
    }
    
    private func setupTabBarAppearance() {
        // Configure tab bar appearance to match app theme
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(named: "FinFocusWhite")
        
        // Selected tab color
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(named: "FinFocusOrange")
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(named: "FinFocusOrange") ?? UIColor.systemOrange
        ]
        
        // Unselected tab color
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStorageHelper())
        .environmentObject(ExpenseTrackerViewModel())
        .environmentObject(InvestmentManagerViewModel())
}
