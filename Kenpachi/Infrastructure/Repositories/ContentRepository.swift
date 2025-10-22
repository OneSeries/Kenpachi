// ContentRepository.swift
// Implementation of content repository
// Coordinates between TMDB API, scrapers, and cache

import Foundation

/// Content repository implementation
final class ContentRepository: ContentRepositoryProtocol {
  /// TMDB client for movies and TV shows
  private let tmdbClient: TMDBClient
  /// Scraper manager for streaming sources
  private let scraperManager: ScraperManager
  /// Content cache for performance optimization
  private let contentCache: ContentCache

  /// Initializer with dependency injection
  init(
    tmdbClient: TMDBClient = .shared,
    scraperManager: ScraperManager = .shared,
    contentCache: ContentCache = .shared
  ) {
    self.tmdbClient = tmdbClient
    self.scraperManager = scraperManager
    self.contentCache = contentCache
  }

  /// Fetches trending content from scraper with caching
  /// - Parameter timeWindow: Time window for trending (day or week)
  /// - Returns: Array of trending content
  func fetchTrendingContent() async throws -> [Content] {
    // Get current scraper source name
    let sourceName = scraperManager.getActiveScraper()?.name ?? ""

    // Check cache first with source-specific key
    if let cachedContent = await contentCache.getHomeContent(sourceName: sourceName) {
      return cachedContent
            .filter { $0.type == .trending || $0.type == .popular }
        .flatMap { $0.items }
    }

    // Fetch from scraper if not cached
    let content = try await fetchHomeContent()

    // Extract trending items from carousels
    let trendingContent =
      content
      .filter { $0.type == .trending || $0.type == .hero }
      .flatMap { $0.items }

    return trendingContent
  }

  /// Fetches home page content from scraper with caching
  func fetchHomeContent() async throws -> [ContentCarousel] {
    // Get current scraper source name
    let sourceName = scraperManager.getActiveScraper()?.name ?? ""

    // Check cache first with source-specific key
    if let cachedContent = await contentCache.getHomeContent(sourceName: sourceName) {
      return cachedContent
    }

    // Fetch from scraper if not cached
    let content = try await scraperManager.fetchHomeContent()

    // Cache the result with source name
    await contentCache.cacheHomeContent(content, sourceName: sourceName)

    return content
  }

  /// Searches for content across sources with caching
  func searchContent(query: String, page: Int = 1) async throws -> ContentSearchResult {
    // Get current scraper source name
    let sourceName = scraperManager.getActiveScraper()?.name ?? ""

    // Check cache first with source-specific key
    if let cachedResults = await contentCache.getSearchResults(
      forQuery: query, page: page, sourceName: sourceName)
    {
      return cachedResults
    }

    // Search scraper manager if not cached
    let results = try await scraperManager.search(query: query, page: page)

    // Cache the results with source name
    await contentCache.cacheSearchResults(
      results, forQuery: query, page: page, sourceName: sourceName)

    return results
  }

  /// Fetches content details with caching
  func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
    // Get current scraper source name for scraper-based content
    let sourceName = scraperManager.getActiveScraper()?.name

    // Check cache first with source-specific key for scraper content
    let cacheKey = "\(sourceName)_\(id)"
    if let cachedContent = await contentCache.getContentDetails(forId: cacheKey) {
      return cachedContent
    }

    // Fetch from appropriate source
    let content: Content = try await scraperManager.fetchContentDetails(id: id, type: type)

    // Cache the result with source-specific key
    await contentCache.cacheContentDetails(content, forId: cacheKey)

    return content
  }

  /// Extracts streaming links with caching
  /// - Parameters:
  ///   - contentId: Content identifier (required)
  ///   - seasonId: Season identifier (optional, for TV shows)
  ///   - episodeId: Episode identifier (optional, for TV shows)
  /// - Returns: Array of extracted streaming links
  func extractStreamingLinks(contentId: String, seasonId: String? = nil, episodeId: String? = nil)
    async throws -> [ExtractedLink]
  {
    // Get current scraper source name
    let sourceName = scraperManager.getActiveScraper()?.name ?? ""

    // Check cache first with source-specific key
    if let cachedLinks = await contentCache.getStreamingLinks(
      forContentId: contentId, seasonId: seasonId, episodeId: episodeId, sourceName: sourceName)
    {
      return cachedLinks
    }

    // Extract from scraper if not cached
    let links = try await scraperManager.extractStreamingLinks(
      contentId: contentId, seasonId: seasonId, episodeId: episodeId)

    // Cache the result with source name
    await contentCache.cacheStreamingLinks(
      links, forContentId: contentId, seasonId: seasonId, episodeId: episodeId,
      sourceName: sourceName)

    return links
  }
}
