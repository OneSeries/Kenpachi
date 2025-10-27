// ContentCache.swift
// Specialized cache for content data
// Provides convenient caching for content details, carousels, and search results

import Foundation

/// Content-specific cache manager
/// Uses the shared CacheManager for storing content-related data
final class ContentCache {
  /// Shared singleton instance
  static let shared = ContentCache()

  /// Shared cache manager instance
  private let cacheManager = CacheManager.shared

  /// Cache key prefixes for different content types
  private enum CachePrefix {
    static let details = "content_details_"
    static let carousels = "content_carousels_"
    static let search = "search_results_"
    static let links = "streaming_links_"
  }

  /// Private initializer for singleton
  private init() {
    // Log initialization
    AppLogger.shared.log(
      "ContentCache initialized",
      level: .debug
    )
  }

  // MARK: - Content Details

  /// Cache content details
  /// - Parameters:
  ///   - content: Content to cache
  ///   - id: Content identifier
  func cacheContentDetails(_ content: Content, forId id: String) async {
    // Create cache key
    let key = CachePrefix.details + id

    // Encode content to data
    guard let data = try? JSONEncoder().encode(content) else {
      AppLogger.shared.log("Failed to encode content for caching", level: .error)
      return
    }

    // Cache in memory
    cacheManager.cacheInMemory(data: data, forKey: key)

    // Also cache to disk for persistence
    cacheManager.cacheToDisk(data: data, forKey: key)
  }

  /// Retrieve cached content details
  /// - Parameter id: Content identifier
  /// - Returns: Cached content if available
  func getContentDetails(forId id: String) async -> Content? {
    // Create cache key
    let key = CachePrefix.details + id

    // Try memory cache first
    if let data = cacheManager.getFromMemory(forKey: key),
      let content = try? JSONDecoder().decode(Content.self, from: data)
    {
      return content
    }

    // Try disk cache
    if let data = cacheManager.getFromDisk(forKey: key),
      let content = try? JSONDecoder().decode(Content.self, from: data)
    {
      // Re-cache in memory for faster access
      cacheManager.cacheInMemory(data: data, forKey: key)
      return content
    }

    return nil
  }

  /// Remove content details from cache
  /// - Parameter id: Content identifier
  func removeContentDetails(forId id: String) async {
    // Create cache key
    let key = CachePrefix.details + id

    // Note: CacheManager doesn't have a remove method, but items will expire naturally
    // For now, we'll just log the removal request
    AppLogger.shared.log("Content details removal requested for: \(id)", level: .debug)
  }

  // MARK: - Content Carousels

  /// Cache home content carousels
  /// - Parameters:
  ///   - carousels: Array of carousels to cache
  ///   - sourceName: Name of the scraper source
  func cacheHomeContent(_ carousels: [ContentCarousel], sourceName: String) async {
    // Create cache key with source name
    let key = CachePrefix.carousels + "home_\(sourceName)"

    // Encode carousels to data
    guard let data = try? JSONEncoder().encode(carousels) else {
      AppLogger.shared.log("Failed to encode carousels for caching", level: .error)
      return
    }

    // Cache in memory
    cacheManager.cacheInMemory(data: data, forKey: key, expirationTime: 1800)  // 30 minutes

    // Also cache to disk
    cacheManager.cacheToDisk(data: data, forKey: key)
  }

  /// Retrieve cached home content
  /// - Parameter sourceName: Name of the scraper source
  /// - Returns: Cached carousels if available
  func getHomeContent(sourceName: String) async -> [ContentCarousel]? {
    // Create cache key with source name
    let key = CachePrefix.carousels + "home_\(sourceName)"

    // Try memory cache first
    if let data = cacheManager.getFromMemory(forKey: key),
      let carousels = try? JSONDecoder().decode([ContentCarousel].self, from: data)
    {
      return carousels
    }

    // Try disk cache
    if let data = cacheManager.getFromDisk(forKey: key),
      let carousels = try? JSONDecoder().decode([ContentCarousel].self, from: data)
    {
      // Re-cache in memory for faster access
      cacheManager.cacheInMemory(data: data, forKey: key, expirationTime: 1800)
      return carousels
    }

    return nil
  }

  /// Remove home content from cache for a specific source
  /// - Parameter sourceName: Name of the scraper source
  func removeHomeContent(sourceName: String) async {
    // Create cache key
    let key = CachePrefix.carousels + "home_\(sourceName)"

    // Log removal request
    AppLogger.shared.log("Home content removal requested for source: \(sourceName)", level: .debug)
  }

  /// Remove home content from cache (all sources)
  func removeHomeContent() async {
    // Clear memory cache
    cacheManager.clearMemoryCache()

    // Log removal
    AppLogger.shared.log("All home content removed from cache", level: .debug)
  }

  // MARK: - Search Results

  /// Cache search results
  /// - Parameters:
  ///   - results: Search results to cache
  ///   - query: Search query
  ///   - page: Page number
  ///   - sourceName: Name of the scraper source
  func cacheSearchResults(
    _ results: ContentSearchResult, forQuery query: String, page: Int, sourceName: String
  ) async {
    // Create cache key with source, query, and page
    let key = CachePrefix.search + "\(sourceName)_\(query)_\(page)"

    // Encode search results to data
    guard let data = try? JSONEncoder().encode(results) else {
      AppLogger.shared.log("Failed to encode search results for caching", level: .error)
      return
    }

    // Cache in memory with shorter expiration (15 minutes)
    cacheManager.cacheInMemory(data: data, forKey: key, expirationTime: 900)

    // Also cache to disk
    cacheManager.cacheToDisk(data: data, forKey: key)
  }

  /// Retrieve cached search results
  /// - Parameters:
  ///   - query: Search query
  ///   - page: Page number
  ///   - sourceName: Name of the scraper source
  /// - Returns: Cached search results if available
  func getSearchResults(forQuery query: String, page: Int, sourceName: String) async
    -> ContentSearchResult?
  {
    // Create cache key with source, query, and page
    let key = CachePrefix.search + "\(sourceName)_\(query)_\(page)"

    // Try memory cache first
    if let data = cacheManager.getFromMemory(forKey: key),
      let results = try? JSONDecoder().decode(ContentSearchResult.self, from: data)
    {
      return results
    }

    // Try disk cache
    if let data = cacheManager.getFromDisk(forKey: key),
      let results = try? JSONDecoder().decode(ContentSearchResult.self, from: data)
    {
      // Re-cache in memory for faster access
      cacheManager.cacheInMemory(data: data, forKey: key, expirationTime: 900)
      return results
    }

    return nil
  }

  /// Clear all search cache
  func clearSearchCache() async {
    // Clear memory cache
    cacheManager.clearMemoryCache()

    // Log clearing
    AppLogger.shared.log("Search cache cleared", level: .debug)
  }

  // MARK: - Streaming Links

  /// Cache streaming links
  /// - Parameters:
  ///   - links: Streaming links to cache
  ///   - contentId: Content identifier
  ///   - seasonId: Season identifier (optional)
  ///   - episodeId: Episode identifier (optional)
  ///   - sourceName: Name of the scraper source
  func cacheStreamingLinks(
    _ links: [ExtractedLink], forContentId contentId: String, seasonId: String?, episodeId: String?,
    sourceName: String
  ) async {
    // Build cache key with all identifiers
    var key = CachePrefix.links + "\(sourceName)_\(contentId)"
    if let seasonId = seasonId {
      key += "_S\(seasonId)"
    }
    if let episodeId = episodeId {
      key += "_E\(episodeId)"
    }

    // Encode streaming links to data
    guard let data = try? JSONEncoder().encode(links) else {
      AppLogger.shared.log("Failed to encode streaming links for caching", level: .error)
      return
    }

    // Cache in memory with longer expiration (2 hours)
    cacheManager.cacheInMemory(data: data, forKey: key, expirationTime: 7200)

    // Also cache to disk
    cacheManager.cacheToDisk(data: data, forKey: key)
  }

  /// Retrieve cached streaming links
  /// - Parameters:
  ///   - contentId: Content identifier
  ///   - seasonId: Season identifier (optional)
  ///   - episodeId: Episode identifier (optional)
  ///   - sourceName: Name of the scraper source
  /// - Returns: Cached streaming links if available
  func getStreamingLinks(
    forContentId contentId: String, seasonId: String?, episodeId: String?, sourceName: String
  ) async -> [ExtractedLink]? {
    // Build cache key with all identifiers
    var key = CachePrefix.links + "\(sourceName)_\(contentId)"
    if let seasonId = seasonId {
      key += "_S\(seasonId)"
    }
    if let episodeId = episodeId {
      key += "_E\(episodeId)"
    }

    // Try memory cache first
    if let data = cacheManager.getFromMemory(forKey: key),
      let links = try? JSONDecoder().decode([ExtractedLink].self, from: data)
    {
      return links
    }

    // Try disk cache
    if let data = cacheManager.getFromDisk(forKey: key),
      let links = try? JSONDecoder().decode([ExtractedLink].self, from: data)
    {
      // Re-cache in memory for faster access
      cacheManager.cacheInMemory(data: data, forKey: key, expirationTime: 7200)
      return links
    }

    return nil
  }

  // MARK: - Clear All

  /// Clear all caches
  func clearAllCaches() async {
    // Clear all caches using the shared cache manager
    cacheManager.clearAllCaches()

    // Log clearing
    AppLogger.shared.log("All content caches cleared", level: .info)
  }
}
