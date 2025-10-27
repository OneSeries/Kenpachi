// ContentSearchResult.swift
// Domain model for search results
// Represents search results from a scraper

import Foundation

/// Struct representing search results from a scraper
struct ContentSearchResult: Codable, Identifiable, Equatable {
    /// Unique identifier for the search result
    let id: String
    /// Array of content items found in the search
    var contents: [Content]
    /// Total number of results found
    let totalResults: Int
    /// Page number (for pagination)
    let page: Int
    /// Total pages available
    let totalPages: Int
    
    /// Indicates if there is a next page available
    var hasNextPage: Bool {
        page < totalPages
    }
    
    /// Indicates if this is the first page
    var isFirstPage: Bool {
        page == 1
    }
    
    /// Indicates if this is the last page
    var isLastPage: Bool {
        page == totalPages
    }
    
    /// Initializer for search results
    init(
        id: String,
        contents: [Content],
        totalResults: Int = 0,
        page: Int = 1,
        totalPages: Int = 1
    ) {
        self.id = id
        self.contents = contents
        self.totalResults = totalResults > 0 ? totalResults : contents.count
        self.page = page
        self.totalPages = totalPages > 0 ? totalPages : 1
    }
    
    /// Convenience initializer for simple cases
    init(contents: [Content]) {
        self.init(
            id: UUID().uuidString,
            contents: contents
        )
    }
}
