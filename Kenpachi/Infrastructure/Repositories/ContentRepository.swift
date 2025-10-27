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
        let content = cachedContent
            .filter { $0.type == .trending || $0.type == .popular }
            .flatMap { $0.items }
        return applyParentalControls(to: content)
    }

    // Fetch from scraper if not cached
    let content = try await fetchHomeContent()

    // Extract trending items from carousels
    let trendingContent =
      content
      .filter { $0.type == .trending || $0.type == .hero }
      .flatMap { $0.items }

    return applyParentalControls(to: trendingContent)
  }

  /// Fetches home page content from scraper with caching
  func fetchHomeContent() async throws -> [ContentCarousel] {
    // Get current scraper source name
    let sourceName = scraperManager.getActiveScraper()?.name ?? ""

    // Check cache first with source-specific key
    if let cachedContent = await contentCache.getHomeContent(sourceName: sourceName) {
      return cachedContent.map { carousel in
          var carousel = carousel
          carousel.items = applyParentalControls(to: carousel.items)
          return carousel
      }
    }

    // Fetch from scraper if not cached
    let content = try await scraperManager.fetchHomeContent()
    
    let filteredContent = content.map { carousel in
        var carousel = carousel
        carousel.items = applyParentalControls(to: carousel.items)
        return carousel
    }

    // Cache the result with source name
    await contentCache.cacheHomeContent(filteredContent, sourceName: sourceName)

    return filteredContent
  }

  /// Searches for content across sources with caching
  func searchContent(query: String, page: Int = 1) async throws -> ContentSearchResult {
    // Get current scraper source name
    let sourceName = scraperManager.getActiveScraper()?.name ?? ""

    // Check cache first with source-specific key
    if let cachedResults = await contentCache.getSearchResults(
      forQuery: query, page: page, sourceName: sourceName)
    {
        var results = cachedResults
        results.contents = applyParentalControls(to: results.contents)
        return results
    }

    // Search scraper manager if not cached
    var results = try await scraperManager.search(query: query, page: page)
    results.contents = applyParentalControls(to: results.contents)

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

  private func applyParentalControls(to content: [Content]) -> [Content] {
    let parentalControlsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.parentalControlsEnabled)
    if !parentalControlsEnabled {
        return content
    }

    let allowedRatingRaw = UserDefaults.standard.string(forKey: UserDefaultsKeys.allowedContentRating) ?? "unrestricted"
    let allowedRating = ContentRating(rawValue: allowedRatingRaw) ?? .unrestricted

    return content.filter { item in
        if item.adult {
            return false
        }

        guard let itemRating = item.rating else {
            return true // If no rating, assume it's safe
        }

        switch allowedRating {
        case .unrestricted:
            return true
        case .pg13:
            return itemRating != "R" && itemRating != "NC-17"
        case .pg:
            return itemRating != "R" && itemRating != "NC-17" && itemRating != "PG-13"
        case .g:
            return itemRating == "G"
        }
    }
  }
}
