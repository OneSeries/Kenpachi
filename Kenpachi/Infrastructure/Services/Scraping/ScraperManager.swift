// ScraperManager.swift
// Centralized scraper management and coordination
// Handles multiple scraper sources and content extraction

import Foundation

/// Manager for coordinating multiple scraper sources
final class ScraperManager {
  /// Shared singleton instance
  static let shared = ScraperManager()

  /// Available scrapers
  private var scrapers: [String: ScraperProtocol] = [:]

  /// Currently selected scraper name
  private var selectedScraperName: String

  /// Initializer
  init() {
    /// Load saved scraper source from UserDefaults or use default
    selectedScraperName =
      UserDefaults.standard.string(forKey: UserDefaultsKeys.defaultScraperSource) ?? "FlixHQ"

    registerDefaultScrapers()
  }

  /// Registers default scrapers
  private func registerDefaultScrapers() {
    // Movie/TV scrapers
    registerScraper(FlixHQ())
    registerScraper(FMovies())
    registerScraper(VidSrc())

    // Anime scrapers
    registerScraper(HiAnime())
    registerScraper(GogoAnime())
    registerScraper(AnimeKai())
  }

  /// Registers a scraper
  /// - Parameter scraper: Scraper to register
  func registerScraper(_ scraper: ScraperProtocol) {
    scrapers[scraper.name] = scraper
  }

  /// Gets the currently selected scraper
  /// - Returns: Active scraper instance
  func getActiveScraper() -> ScraperProtocol? {
    scrapers[selectedScraperName]
  }

  /// Sets the active scraper
  /// - Parameter name: Scraper name to activate
  func setActiveScraper(name: String) {
    if scrapers[name] != nil {
      selectedScraperName = name
    }
  }

  /// Gets names of all available scrapers
  /// - Returns: Array of scraper names
  func getAvailableScrapers() -> [String] {
    Array(scrapers.keys)
  }

  /// Fetches home content from active scraper
  /// - Returns: Array of content carousels
  func fetchHomeContent() async throws -> [ContentCarousel] {
    guard let scraper = getActiveScraper() else {
      throw ScraperError.invalidConfiguration
    }
    return try await scraper.fetchHomeContent()
  }

  /// Searches for content using active scraper
  /// - Parameters:
  ///   - query: Search query
  ///   - page: Page number for pagination (default is 1)
  /// - Returns: Search result
  func search(query: String, page: Int = 1) async throws -> ContentSearchResult {
    guard let scraper = getActiveScraper() else {
      throw ScraperError.invalidConfiguration
    }
    return try await scraper.search(query: query, page: page)
  }

  /// Fetches content details using active scraper
  /// - Parameter id: Content identifier
  /// - Returns: Detailed content information
  func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
    guard let scraper = getActiveScraper() else {
      throw ScraperError.invalidConfiguration
    }
    return try await scraper.fetchContentDetails(id: id, type: type)
  }

  /// Extracts streaming links using active scraper
  /// - Parameters:
  ///   - contentId: Content identifier (required)
  ///   - seasonId: Season identifier (optional, for TV shows)
  ///   - episodeId: Episode identifier (optional, for TV shows)
  /// - Returns: Array of streaming links
  func extractStreamingLinks(contentId: String, seasonId: String? = nil, episodeId: String? = nil)
    async throws -> [ExtractedLink]
  {
    guard let scraper = getActiveScraper() else {
      throw ScraperError.invalidConfiguration
    }
    return try await scraper.extractStreamingLinks(
      contentId: contentId, seasonId: seasonId, episodeId: episodeId)
  }
}
