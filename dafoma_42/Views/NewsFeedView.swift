//
//  NewsFeedView.swift
//  FinFocus Most
//
//  Created by FinFocus Team
//

import SwiftUI

struct NewsFeedView: View {
    @EnvironmentObject private var viewModel: InvestmentManagerViewModel
    @EnvironmentObject private var appStorage: AppStorageHelper
    @State private var selectedCategory: NewsCategory? = nil
    @State private var showingBookmarks = false
    @State private var selectedArticle: NewsArticle?
    @State private var showingArticleDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter
                categoryFilterSection
                
                // News List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if viewModel.filteredNews.isEmpty {
                            EmptyNewsView()
                        } else {
                            ForEach(viewModel.filteredNews) { article in
                                NewsCardView(article: article) {
                                    selectedArticle = article
                                    showingArticleDetail = true
                                } onBookmarkToggle: {
                                    viewModel.toggleBookmark(for: article)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .refreshable {
                    viewModel.refreshNews()
                }
            }
            .navigationTitle("Financial News")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Menu {
                    Button("All Categories") {
                        selectedCategory = nil
                        viewModel.selectedNewsCategory = nil
                    }
                    
                    ForEach(NewsCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            viewModel.selectedNewsCategory = category
                        }) {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }
                } label: {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                        .foregroundColor(Color("FinFocusOrange"))
                },
                trailing: HStack(spacing: 12) {
                    Button {
                        showingBookmarks = true
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(Color("FinFocusOrange"))
                    }
                    
                    Button {
                        viewModel.refreshNews()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color("FinFocusOrange"))
                    }
                }
            )
            .searchable(text: $viewModel.searchText, prompt: "Search news...")
            .sheet(isPresented: $showingBookmarks) {
                BookmarkedNewsView()
                    .environmentObject(viewModel)
            }
            .sheet(item: $selectedArticle) { article in
                NewsDetailView(article: article)
                    .environmentObject(viewModel)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "All",
                    icon: "newspaper",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                    viewModel.selectedNewsCategory = nil
                }
                
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        viewModel.selectedNewsCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color("FinFocusWhite"))
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color("FinFocusOrange") : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : Color("FinFocusBlue"))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NewsCardView: View {
    let article: NewsArticle
    let onTap: () -> Void
    let onBookmarkToggle: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: article.category.icon)
                            .foregroundColor(article.category.color)
                            .font(.caption)
                        
                        Text(article.category.rawValue)
                            .font(.caption)
                            .foregroundColor(article.category.color)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(article.category.color.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    Button(action: onBookmarkToggle) {
                        Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(article.isBookmarked ? Color("FinFocusOrange") : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Title
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(Color("FinFocusBlue"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                // Summary
                Text(article.summary)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                
                // Footer
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text(article.source)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text(article.timeAgo)
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

struct EmptyNewsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "newspaper")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No News Available")
                    .font(.headline)
                    .foregroundColor(Color("FinFocusBlue"))
                
                Text("Pull down to refresh and get the latest financial news.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

struct BookmarkedNewsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewModel: InvestmentManagerViewModel
    @State private var selectedArticle: NewsArticle?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.bookmarkedNews.isEmpty {
                        EmptyBookmarksView()
                    } else {
                        ForEach(viewModel.bookmarkedNews) { article in
                            NewsCardView(article: article) {
                                selectedArticle = article
                            } onBookmarkToggle: {
                                viewModel.toggleBookmark(for: article)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Bookmarked News")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(item: $selectedArticle) { article in
                NewsDetailView(article: article)
                    .environmentObject(viewModel)
            }
        }
    }
}

struct EmptyBookmarksView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Bookmarked Articles")
                    .font(.headline)
                    .foregroundColor(Color("FinFocusBlue"))
                
                Text("Bookmark articles you want to read later by tapping the bookmark icon.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

struct NewsDetailView: View {
    let article: NewsArticle
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewModel: InvestmentManagerViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category Badge
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: article.category.icon)
                                .foregroundColor(article.category.color)
                                .font(.caption)
                            
                            Text(article.category.rawValue)
                                .font(.caption)
                                .foregroundColor(article.category.color)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(article.category.color.opacity(0.1))
                        .cornerRadius(16)
                        
                        Spacer()
                    }
                    
                    // Title
                    Text(article.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("FinFocusBlue"))
                        .multilineTextAlignment(.leading)
                    
                    // Metadata
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "building.2")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(article.source)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text(article.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Divider()
                    
                    // Summary/Content
                    Text(article.summary)
                        .font(.body)
                        .foregroundColor(Color("FinFocusBlue"))
                        .lineSpacing(6)
                    
                    // Extended content (simulated)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Market Analysis")
                            .font(.headline)
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        Text("This development reflects broader market trends and investor sentiment. Financial experts suggest monitoring key indicators and maintaining a diversified portfolio approach.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .lineSpacing(6)
                        
                        Text("Key Takeaways")
                            .font(.headline)
                            .foregroundColor(Color("FinFocusBlue"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Market volatility continues to present both challenges and opportunities")
                            BulletPoint(text: "Diversification remains a key strategy for risk management")
                            BulletPoint(text: "Long-term investors should focus on fundamental analysis")
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: {
                    viewModel.toggleBookmark(for: article)
                }) {
                    Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(article.isBookmarked ? Color("FinFocusOrange") : .gray)
                }
            )
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color("FinFocusOrange"))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            
            Text(text)
                .font(.body)
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
    }
}

#Preview {
    NewsFeedView()
        .environmentObject(InvestmentManagerViewModel())
        .environmentObject(AppStorageHelper())
}

