// SearchFeature.swift
// TCA feature for search screen
// Manages search queries, filters, and results with debouncing

import ComposableArchitecture
import Foundation

@Reducer
struct SearchFeature {
    
    @ObservableState
    struct State: Equatable {
        /// Current search query
        var searchQuery = ""
        /// Search results
        var searchResults: [Content] = []
        /// Loading state for search
        var isSearching = false
        /// Loading state for next page
        var isLoadingNextPage = false
        /// Error message if search fails
        var errorMessage: String?
        /// Recent search queries
        var recentSearches: [String] = []
        /// Selected content type filter
        var selectedContentType: ContentType?
        /// Selected genre filter
        var selectedGenre: Genre?
        /// Show filters sheet
        var showFilters = false
        /// Trending searches
        var trendingSearches: [String] = []
        /// Popular content (shown when no search)
        var popularContent: [Content] = []
        /// Whether search bar is focused
        var isSearchFocused = false
        /// Current page number
        var currentPage = 1
        /// Total pages available
        var totalPages = 1
        /// Whether there is a next page
        var hasNextPage = false
    }
    
    enum Action: Equatable {
        /// Triggered when search view appears
        case onAppear
        /// Search query changed
        case searchQueryChanged(String)
        /// Perform search
        case performSearch(String, page: Int)
        /// Search completed successfully
        case searchCompleted(ContentSearchResult)
        /// Search failed
        case searchFailed(String)
        /// Recent search tapped
        case recentSearchTapped(String)
        /// Clear recent searches
        case clearRecentSearches
        /// Content type filter selected
        case contentTypeFilterSelected(ContentType?)
        /// Genre filter selected
        case genreFilterSelected(Genre?)
        /// Show filters tapped
        case showFiltersTapped
        /// Hide filters
        case hideFilters
        /// Apply filters
        case applyFilters
        /// Clear filters
        case clearFilters
        /// Search result tapped
        case searchResultTapped(Content)
        /// Load popular content
        case loadPopularContent
        /// Popular content loaded
        case popularContentLoaded([Content])
        /// Search bar focused
        case searchFocusChanged(Bool)
        /// Load next page
        case loadNextPage
        /// Reached bottom of scroll
        case reachedBottom
    }
    
    @Dependency(\.continuousClock) var clock
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                /// Load recent searches and popular content
                state.recentSearches = loadRecentSearches()
                state.trendingSearches = [
                    "Avengers",
                    "Stranger Things",
                    "One Piece",
                    "Breaking Bad",
                    "Demon Slayer"
                ]
                return .send(.loadPopularContent)
                
            case .searchQueryChanged(let query):
                /// Update search query
                state.searchQuery = query
                
                /// Cancel previous search and debounce new search
                guard !query.isEmpty else {
                    state.searchResults = []
                    state.currentPage = 1
                    state.totalPages = 1
                    state.hasNextPage = false
                    return .cancel(id: "search")
                }
                
                return .run { send in
                    /// Debounce search by 500ms
                    try await clock.sleep(for: .milliseconds(500))
                    await send(.performSearch(query, page: 1))
                }
                .cancellable(id: "search")
                
            case .performSearch(let query, let page):
                /// Perform search with current query and page
                guard !query.isEmpty else { return .none }
                
                /// Set loading state based on page
                if page == 1 {
                    state.isSearching = true
                    state.searchResults = []
                } else {
                    state.isLoadingNextPage = true
                }
                state.errorMessage = nil
                
                return .run { [contentType = state.selectedContentType, genre = state.selectedGenre] send in
                    do {
                        /// Create repository instance
                        let contentRepository = ContentRepository()
                        
                        /// Search for content with pagination
                        var searchResult = try await contentRepository.searchContent(query: query, page: page)
                        
                        /// Apply content type filter
                        if let contentType = contentType {
                            let filteredContents = searchResult.contents.filter { $0.type == contentType }
                            searchResult = ContentSearchResult(
                                id: searchResult.id,
                                contents: filteredContents,
                                totalResults: searchResult.totalResults,
                                page: searchResult.page,
                                totalPages: searchResult.totalPages
                            )
                        }
                        
                        /// Apply genre filter
                        if let genre = genre {
                            let filteredContents = searchResult.contents.filter { content in
                                content.genreIds?.contains(genre.id) ?? false
                            }
                            searchResult = ContentSearchResult(
                                id: searchResult.id,
                                contents: filteredContents,
                                totalResults: searchResult.totalResults,
                                page: searchResult.page,
                                totalPages: searchResult.totalPages
                            )
                        }
                        
                        await send(.searchCompleted(searchResult))
                    } catch {
                        await send(.searchFailed(error.localizedDescription))
                    }
                }
                
            case .searchCompleted(let searchResult):
                /// Update state with search results
                state.isSearching = false
                state.isLoadingNextPage = false
                
                /// Append or replace results based on page
                if searchResult.page == 1 {
                    state.searchResults = searchResult.contents
                } else {
                    state.searchResults.append(contentsOf: searchResult.contents)
                }
                
                /// Update pagination info
                state.currentPage = searchResult.page
                state.totalPages = searchResult.totalPages
                state.hasNextPage = searchResult.hasNextPage
                
                /// Save to recent searches (only for first page)
                if searchResult.page == 1 && !state.searchQuery.isEmpty {
                    saveRecentSearch(state.searchQuery)
                    state.recentSearches = loadRecentSearches()
                }
                
                return .none
                
            case .searchFailed(let message):
                /// Handle search failure
                state.isSearching = false
                state.errorMessage = message
                return .none
                
            case .recentSearchTapped(let query):
                /// Perform search with recent query
                state.searchQuery = query
                return .send(.performSearch(query, page: 1))
                
            case .clearRecentSearches:
                /// Clear all recent searches
                clearRecentSearches()
                state.recentSearches = []
                return .none
                
            case .contentTypeFilterSelected(let contentType):
                /// Update content type filter
                state.selectedContentType = contentType
                return .none
                
            case .genreFilterSelected(let genre):
                /// Update genre filter
                state.selectedGenre = genre
                return .none
                
            case .showFiltersTapped:
                /// Show filters sheet
                state.showFilters = true
                return .none
                
            case .hideFilters:
                /// Hide filters sheet
                state.showFilters = false
                return .none
                
            case .applyFilters:
                /// Apply filters and re-search
                state.showFilters = false
                guard !state.searchQuery.isEmpty else { return .none }
                return .send(.performSearch(state.searchQuery, page: 1))
                
            case .clearFilters:
                /// Clear all filters
                state.selectedContentType = nil
                state.selectedGenre = nil
                return .none
                
            case .searchResultTapped(let content):
                /// Navigate to content detail
                /// TODO: Implement navigation
                return .none
                
            case .loadPopularContent:
                /// Load popular content for empty state
                return .run { send in
                    do {
                        /// Create repository instance
                        let contentRepository = ContentRepository()
                        
                        /// Fetch trending content
                        let popular = try await contentRepository.fetchTrendingContent()
                        
                        await send(.popularContentLoaded(Array(popular)))
                    } catch {
                        /// Silently fail for popular content
                    }
                }
                
            case .popularContentLoaded(let content):
                /// Update state with popular content
                state.popularContent = content
                return .none
                
            case .searchFocusChanged(let isFocused):
                /// Update search focus state
                state.isSearchFocused = isFocused
                return .none
                
            case .reachedBottom:
                /// Load next page when reaching bottom
                guard !state.isLoadingNextPage,
                      state.hasNextPage,
                      !state.searchQuery.isEmpty else {
                    return .none
                }
                return .send(.loadNextPage)
                
            case .loadNextPage:
                /// Load next page of search results
                guard state.hasNextPage,
                      !state.isLoadingNextPage else {
                    return .none
                }
                let nextPage = state.currentPage + 1
                return .send(.performSearch(state.searchQuery, page: nextPage))
            }
        }
    }
}

// MARK: - Helper Functions
extension SearchFeature {
    /// Load recent searches from UserDefaults
    private func loadRecentSearches() -> [String] {
        UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.recentSearches) ?? []
    }
    
    /// Save search query to recent searches
    private func saveRecentSearch(_ query: String) {
        var searches = loadRecentSearches()
        /// Remove if already exists
        searches.removeAll { $0 == query }
        /// Add to beginning
        searches.insert(query, at: 0)
        /// Keep only last 10
        searches = Array(searches.prefix(10))
        /// Save to UserDefaults
        UserDefaults.standard.set(searches, forKey: UserDefaultsKeys.recentSearches)
    }
    
    /// Clear all recent searches
    private func clearRecentSearches() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.recentSearches)
    }
}