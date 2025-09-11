//
//  OnboardingView.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appStorage: AppStorageHelper
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var selectedCurrency = SupportedCurrency.usd
    @State private var enableNotifications = true
    @State private var showingNameError = false
    @State private var showingEmailError = false
    
    private let onboardingPages = [
        OnboardingPage(
            title: "Welcome to FinFocus Most",
            description: "Your comprehensive financial companion for tracking expenses, managing investments, and staying informed with the latest financial news.",
            imageName: "chart.line.uptrend.xyaxis",
            color: Color("FinFocusBlue")
        ),
        OnboardingPage(
            title: "Track Your Expenses",
            description: "Easily categorize and monitor your spending with beautiful visualizations and smart budgeting tools.",
            imageName: "creditcard.fill",
            color: Color("FinFocusOrange")
        ),
        OnboardingPage(
            title: "Manage Investments",
            description: "Keep track of your investment portfolio with real-time updates and performance analytics.",
            imageName: "chart.pie.fill",
            color: Color("FinFocusBlue")
        ),
        OnboardingPage(
            title: "Stay Informed",
            description: "Get the latest financial news and market insights to make informed decisions.",
            imageName: "newspaper.fill",
            color: Color("FinFocusOrange")
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if currentPage < onboardingPages.count {
                    // Onboarding Pages
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            OnboardingPageView(page: onboardingPages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                } else {
                    // Setup Page
                    setupView
                }
                
                // Navigation Buttons
                VStack(spacing: 16) {
                    if currentPage < onboardingPages.count {
                        HStack {
                            if currentPage > 0 {
                                Button("Back") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentPage -= 1
                                    }
                                }
                                .foregroundColor(Color("FinFocusBlue"))
                            }
                            
                            Spacer()
                            
                            Button(currentPage == onboardingPages.count - 1 ? "Get Started" : "Next") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color("FinFocusOrange"))
                            .cornerRadius(25)
                        }
                        .padding(.horizontal, 24)
                    } else {
                        Button("Complete Setup") {
                            completeOnboarding()
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("FinFocusOrange"))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .disabled(!isSetupValid)
                        .opacity(isSetupValid ? 1.0 : 0.6)
                    }
                }
                .padding(.bottom, 34)
            }
            .background(Color("FinFocusWhite"))
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var setupView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("FinFocusBlue"))
                    
                    Text("Personal Setup")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("FinFocusBlue"))
                    
                    Text("Help us personalize your experience")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Form Fields
                VStack(spacing: 20) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Name")
                            .font(.headline)
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        TextField("Enter your name", text: $userName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(showingNameError ? Color.red : Color.clear, lineWidth: 1)
                            )
                        
                        if showingNameError {
                            Text("Please enter a valid name (at least 2 characters)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.headline)
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        TextField("Enter your email", text: $userEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(showingEmailError ? Color.red : Color.clear, lineWidth: 1)
                            )
                        
                        if showingEmailError {
                            Text("Please enter a valid email address")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Currency Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferred Currency")
                            .font(.headline)
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        Picker("Currency", selection: $selectedCurrency) {
                            ForEach(SupportedCurrency.allCases, id: \.self) { currency in
                                Text(currency.displayName)
                                    .tag(currency)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Notifications Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enable Notifications")
                                    .font(.headline)
                                    .foregroundColor(Color("FinFocusBlue"))
                                
                                Text("Get alerts for budget limits and investment updates")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $enableNotifications)
                                .toggleStyle(SwitchToggleStyle(tint: Color("FinFocusOrange")))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
    
    private var isSetupValid: Bool {
        appStorage.isValidUserName(userName) && appStorage.isValidEmail(userEmail)
    }
    
    private func completeOnboarding() {
        // Validate inputs
        showingNameError = !appStorage.isValidUserName(userName)
        showingEmailError = !appStorage.isValidEmail(userEmail)
        
        guard isSetupValid else { return }
        
        // Save user preferences
        appStorage.userName = userName
        appStorage.userEmail = userEmail
        appStorage.userPreferredCurrency = selectedCurrency.rawValue
        appStorage.enableNotifications = enableNotifications
        appStorage.enableBudgetAlerts = enableNotifications
        appStorage.enableInvestmentAlerts = enableNotifications
        
        // Complete onboarding
        appStorage.completeOnboarding()
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 100))
                .foregroundColor(page.color)
                .shadow(color: page.color.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("FinFocusBlue"))
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

#Preview {
    OnboardingView()
        .environmentObject(AppStorageHelper())
}

