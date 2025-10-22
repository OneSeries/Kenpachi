// ContentCache.swift
// Specialized cache for content data
// Provides convenient caching for content details, carousels, and search results

import Foundation

/// Content-specific cache manager
final class ContentCache {
    /// Shared singleton instance
    static let shared = ContentCache()
    
    /// Cache for content details
    private let detailsCache: CacheManager<String, Content>
    /// Cache for content carousels
    private let carouselsCache: CacheManager<String, [ContentCarousel]>
    /// Cache for search results
    private let searchCache: CacheManager<String, ContentSearchResult>
    /// Cache for streaming links
    private let linksCache: CacheManager<String, [ExtractedLink]>
    
    /// Private initializer for singleton
    private init() {
        // Initialize caches with different expiration times
        self.detailsCache = CacheManager(
            cacheName: "ContentDetails",
            defaultExpiration: 3600, // 1 hour
            maxMemoryCacheSize: 50
        )
        self.carouselsCache = CacheManager(
            cacheName: "ContentCarousels",
            defaultExpiration: 1800, // 30 minutes
            maxMemoryCacheSize: 20
        )
        self.searchCache = CacheManager(
            cacheName: "SearchResults",
            defaultExpiration: 900, // 15 minutes
            maxMemoryCacheSize: 30
        )
        self.linksCache = CacheManager(
            cacheName: "StreamingLinks",
            defaultExpiration: 7200, // 2 hours
            maxMemoryCacheSize: 20
        )
    }
    
    // MARK: - Content Details
    
    /// Cache content details
    /// - Parameters:
    ///   - content: Content to cache
    ///   - id: Content identifier
    func cacheContentDetails(_ content: Content, forId id: String) async {
        await detailsCache.set(content, forKey: id)
    }
    
    /// Retrieve cached content details
    /// - Parameter id: Content identifier
    /// - Returns: Cached content if available
    func getContentDetails(forId id: String) async -> Content? {
        await detailsCache.get(forKey: id)
    }
    
    /// Remove content details from cache
    /// - Parameter id: Content identifier
    func removeContentDetails(forId id: String) async {
        await detailsCache.remove(forKey: id)
    }
    
    // MARK: - Content Carousels
    
    /// Cache home content carousels
    /// - Parameters:
    ///   - carousels: Array of carousels to cache
    ///   - sourceName: Name of the scraper source
    func cacheHomeContent(_ carousels: [ContentCarousel], sourceName: String) async {
        let key = "home_\(sourceName)"
        await carouselsCache.set(carousels, forKey: key)
    }
    
    /// Retrieve cached home content
    /// - Parameter sourceName: Name of the scraper source
    /// - Returns: Cached carousels if available
    func getHomeContent(sourceName: String) async -> [ContentCarousel]? {
        let key = "home_\(sourceName)"
        return await carouselsCache.get(forKey: key)
    }
    
    /// Remove home content from cache for a specific source
    /// - Parameter sourceName: Name of the scraper source
    func removeHomeContent(sourceName: String) async {
        let key = "home_\(sourceName)"
        await carouselsCache.remove(forKey: key)
    }
    
    /// Remove home content from cache (all sources)
    func removeHomeContent() async {
        // Clear all carousel cache to remove all source-specific caches
        await carouselsCache.clearAll()
    }
    
    // MARK: - Search Results
    
    /// Cache search results
    /// - Parameters:
    ///   - results: Search results to cache
    ///   - query: Search query
    ///   - page: Page number
    ///   - sourceName: Name of the scraper source
    func cacheSearchResults(_ results: ContentSearchResult, forQuery query: String, page: Int, sourceName: String) async {
        let key = "\(sourceName)_\(query)_\(page)"
        await searchCache.set(results, forKey: key)
    }
    
    /// Retrieve cached search results
    /// - Parameters:
    ///   - query: Search query
    ///   - page: Page number
    ///   - sourceName: Name of the scraper source
    /// - Returns: Cached search results if available
    func getSearchResults(forQuery query: String, page: Int, sourceName: String) async -> ContentSearchResult? {
        let key = "\(sourceName)_\(query)_\(page)"
        return await searchCache.get(forKey: key)
    }
    
    /// Clear all search cache
    func clearSearchCache() async {
        await searchCache.clearAll()
    }
    
    // MARK: - Streaming Links
    
    /// Cache streaming links
    /// - Parameters:
    ///   - links: Streaming links to cache
    ///   - contentId: Content identifier
    ///   - seasonId: Season identifier (optional)
    ///   - episodeId: Episode identifier (optional)
    ///   - sourceName: Name of the scraper source
    func cacheStreamingLinks(_ links: [ExtractedLink], forContentId contentId: String, seasonId: String?, episodeId: String?, sourceName: String) async {
        var key = "\(sourceName)_\(contentId)"
        if let seasonId = seasonId {
            key += "_S\(seasonId)"
        }
        if let episodeId = episodeId {
            key += "_E\(episodeId)"
        }
        await linksCache.set(links, forKey: key)
    }
    
    /// Retrieve cached streaming links
    /// - Parameters:
    ///   - contentId: Content identifier
    ///   - seasonId: Season identifier (optional)
    ///   - episodeId: Episode identifier (optional)
    ///   - sourceName: Name of the scraper source
    /// - Returns: Cached streaming links if available
    func getStreamingLinks(forContentId contentId: String, seasonId: String?, episodeId: String?, sourceName: String) async -> [ExtractedLink]? {
        var key = "\(sourceName)_\(contentId)"
        if let seasonId = seasonId {
            key += "_S\(seasonId)"
        }
        if let episodeId = episodeId {
            key += "_E\(episodeId)"
        }
        return await linksCache.get(forKey: key)
    }
    
    // MARK: - Clear All
    
    /// Clear all caches
    func clearAllCaches() async {
        await detailsCache.clearAll()
        await carouselsCache.clearAll()
        await searchCache.clearAll()
        await linksCache.clearAll()
    }
}
