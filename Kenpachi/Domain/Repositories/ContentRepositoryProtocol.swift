// ContentRepositoryProtocol.swift
// Protocol defining content repository interface
// Abstracts data sources for content retrieval

import Foundation

/// Protocol for content repository operations
protocol ContentRepositoryProtocol {
    /// Fetches trending movies
    /// - Returns: Array of trending movies
    func fetchTrendingContent() async throws -> [Content]
    
    /// Fetches home page content
    /// - Returns: Array of content carousels
    func fetchHomeContent() async throws -> [ContentCarousel]
    
    /// Searches for content
    /// - Parameter query: Search query string
    /// - Returns: Array of matching content
    func searchContent(query: String, page: Int) async throws -> ContentSearchResult
    
    /// Fetches content details
    /// - Parameter id: Content identifier
    /// - Returns: Detailed content information
    func fetchContentDetails(id: String, type: ContentType?) async throws -> Content
    
    /// Extracts streaming links for content
    /// - Parameters:
    ///   - contentId: Content identifier (required)
    ///   - seasonId: Season identifier (optional, for TV shows)
    ///   - episodeId: Episode identifier (optional, for TV shows)
    /// - Returns: Array of streaming links
    func extractStreamingLinks(contentId: String, seasonId: String?, episodeId: String?) async throws -> [ExtractedLink]
}
