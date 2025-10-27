// ScraperProtocol.swift
// Protocol defining scraper capabilities
// All scraper implementations must conform to this protocol

import Foundation

/// Protocol for content scrapers
protocol ScraperProtocol {
    /// Scraper name identifier
    var name: String { get }
    /// Base URL for the scraper source
    var baseURL: String { get }
    /// Supported content types
    var supportedTypes: [ContentType] { get }
    
    /// Fetches home page content
    /// - Returns: Array of content carousels
    func fetchHomeContent() async throws -> [ContentCarousel]
    
    /// Searches for content
    /// - Parameters:
    ///   - query: Search query string
    ///   - page: Page number for pagination (default is 1)
    /// - Returns: Search result containing matching content
    func search(query: String, page: Int) async throws -> ContentSearchResult
    
    /// Fetches content details
    /// - Parameter id: Content identifier
    /// - Returns: Detailed content information
    func fetchContentDetails(id: String, type: ContentType?) async throws -> Content
    
    /// Extracts streaming links
    /// - Parameters:
    ///   - contentId: Content identifier (required)
    ///   - seasonId: Season identifier (optional, for TV shows)
    ///   - episodeId: Episode identifier (optional, for TV shows)
    /// - Returns: Array of extracted streaming links
    func extractStreamingLinks(contentId: String, seasonId: String?, episodeId: String?) async throws -> [ExtractedLink]
}

/// Default implementations for optional methods
extension ScraperProtocol {
    /// Default implementation returns empty array
    func fetchHomeContent() async throws -> [ContentCarousel] {
        []
    }
    
    /// Default implementation with page parameter defaulting to 1
    func search(query: String, page: Int = 1) async throws -> ContentSearchResult {
        try await search(query: query, page: page)
    }
}