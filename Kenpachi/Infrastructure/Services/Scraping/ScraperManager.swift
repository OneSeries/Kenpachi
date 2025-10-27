// ScraperManager.swift
// Centralized scraper management and coordination
// Handles multiple scraper sources and content extraction
// Default scraper is FlixHQ as per requirements

import Foundation

/// Manager for coordinating multiple scraper sources
/// Manages scraper registration, selection, and content fetching
/// FlixHQ is set as the default scraper for movies and TV shows
final class ScraperManager {
  /// Shared singleton instance for app-wide access
  static let shared = ScraperManager()

  /// Dictionary of available scrapers keyed by name
  private var scrapers: [String: ScraperProtocol] = [:]

  /// Currently selected scraper name (default: FlixHQ)
  private var selectedScraperName: String

  /// Default scraper name constant
  private let defaultScraperName = "FlixHQ"

  /// Initializer - sets up scrapers and loads user preference
  init() {
    /// Load saved scraper source from UserDefaults or use FlixHQ as default
    selectedScraperName =
      UserDefaults.standard.string(forKey: UserDefaultsKeys.defaultScraperSource)
      ?? defaultScraperName

    /// Register all available scrapers
    registerDefaultScrapers()

    /// Log initialization with selected scraper
    AppLogger.shared.log(
      "ScraperManager initialized with scraper: \(selectedScraperName)",
      level: .info
    )
  }

  /// Registers default scrapers for movies, TV shows, and anime
  /// Includes FlixHQ (default), 111Movies, VidSrc, VidRock, VidFast, VidNest for movies/TV
  /// and HiAnime, GogoAnime, AnimeKai for anime content
  private func registerDefaultScrapers() {
    // Movie/TV scrapers - FlixHQ is primary/default
    registerScraper(FlixHQ())
    registerScraper(Movies111())
    registerScraper(VidSrc())
    registerScraper(VidRock())
    registerScraper(VidFast())
    registerScraper(VidNest())

    // Anime scrapers
    registerScraper(HiAnime())
    registerScraper(GogoAnime())
    registerScraper(AnimeKai())

    // Log registered scrapers
    AppLogger.shared.log(
      "Registered \(scrapers.count) scrapers: \(scrapers.keys.joined(separator: ", "))",
      level: .debug
    )
  }

  /// Registers a scraper instance
  /// Adds scraper to available scrapers dictionary
  /// - Parameter scraper: Scraper conforming to ScraperProtocol
  func registerScraper(_ scraper: ScraperProtocol) {
    // Add scraper to dictionary with name as key
    scrapers[scraper.name] = scraper
    // Log registration
    AppLogger.shared.log(
      "Registered scraper: \(scraper.name)",
      level: .debug
    )
  }

  /// Gets the currently selected/active scraper
  /// Returns the scraper instance that will be used for content fetching
  /// - Returns: Active scraper instance or nil if not found
  func getActiveScraper() -> ScraperProtocol? {
    // Return scraper for selected name
    return scrapers[selectedScraperName]
  }

  /// Sets the active scraper by name
  /// Updates selected scraper and saves preference to UserDefaults
  /// - Parameter name: Scraper name to activate
  func setActiveScraper(name: String) {
    // Check if scraper exists
    if scrapers[name] != nil {
      // Update selected scraper name
      selectedScraperName = name
      // Save preference to UserDefaults
      UserDefaults.standard.set(name, forKey: UserDefaultsKeys.defaultScraperSource)
      // Log scraper change
      AppLogger.shared.log(
        "Active scraper changed to: \(name)",
        level: .info
      )
    } else {
      // Log error if scraper not found
      AppLogger.shared.log(
        "Failed to set active scraper: \(name) not found",
        level: .error
      )
    }
  }

  /// Sets FlixHQ as the default scraper
  /// Called during app initialization to ensure default is set
  func setDefaultScraper() {
    // Check if no scraper is currently selected or saved
    if UserDefaults.standard.string(forKey: UserDefaultsKeys.defaultScraperSource) == nil {
      // Set FlixHQ as default
      setActiveScraper(name: defaultScraperName)
      // Log default set
      AppLogger.shared.log(
        "Default scraper set to: \(defaultScraperName)",
        level: .info
      )
    }
  }

  /// Gets names of all available scrapers
  /// Returns array of scraper names for display in settings
  /// - Returns: Array of scraper names
  func getAvailableScrapers() -> [String] {
    // Return array of scraper names from dictionary keys
    return Array(scrapers.keys)
  }

  /// Fetches home content from active scraper
  /// Retrieves content carousels for home screen display
  /// Uses currently selected scraper (default: FlixHQ)
  /// - Returns: Array of content carousels with hero, trending, popular sections
  /// - Throws: ScraperError if no scraper is active or fetch fails
  func fetchHomeContent() async throws -> [ContentCarousel] {
    // Get active scraper instance
    guard let scraper = getActiveScraper() else {
      // Log error
      AppLogger.shared.log(
        "No active scraper configured",
        level: .error
      )
      // Throw configuration error
      throw ScraperError.invalidConfiguration
    }

    // Log fetch start
    AppLogger.shared.log(
      "Fetching home content from: \(scraper.name)",
      level: .debug
    )

    // Fetch home content from scraper
    return try await scraper.fetchHomeContent()
  }

  /// Searches for content using active scraper
  /// Performs search query across movies, TV shows, and anime
  /// Supports pagination for large result sets
  /// - Parameters:
  ///   - query: Search query string entered by user
  ///   - page: Page number for pagination (default is 1)
  /// - Returns: Search result containing matched content items
  /// - Throws: ScraperError if no scraper is active or search fails
  func search(query: String, page: Int = 1) async throws -> ContentSearchResult {
    // Get active scraper instance
    guard let scraper = getActiveScraper() else {
      // Log error
      AppLogger.shared.log(
        "No active scraper configured for search",
        level: .error
      )
      // Throw configuration error
      throw ScraperError.invalidConfiguration
    }

    // Log search start
    AppLogger.shared.log(
      "Searching '\(query)' on: \(scraper.name) (page: \(page))",
      level: .debug
    )

    // Perform search using scraper
    return try await scraper.search(query: query, page: page)
  }

  /// Fetches detailed content information using active scraper
  /// Retrieves full metadata including cast, seasons, episodes, etc.
  /// - Parameters:
  ///   - id: Content identifier from scraper
  ///   - type: Content type (movie, TV show, anime) for optimization
  /// - Returns: Detailed content information with all metadata
  /// - Throws: ScraperError if no scraper is active or fetch fails
  func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
    // Get active scraper instance
    guard let scraper = getActiveScraper() else {
      // Log error
      AppLogger.shared.log(
        "No active scraper configured for content details",
        level: .error
      )
      // Throw configuration error
      throw ScraperError.invalidConfiguration
    }

    // Log fetch start
    AppLogger.shared.log(
      "Fetching content details for ID: \(id) from: \(scraper.name)",
      level: .debug
    )

    // Fetch content details from scraper
    return try await scraper.fetchContentDetails(id: id, type: type)
  }

  /// Extracts streaming links using active scraper
  /// Retrieves playable video URLs for content playback
  /// Supports movies (single link) and TV shows (episode-specific links)
  /// - Parameters:
  ///   - contentId: Content identifier (required)
  ///   - seasonId: Season identifier (optional, for TV shows)
  ///   - episodeId: Episode identifier (optional, for TV shows)
  /// - Returns: Array of extracted streaming links with quality options
  /// - Throws: ScraperError if no scraper is active or extraction fails
  func extractStreamingLinks(contentId: String, seasonId: String? = nil, episodeId: String? = nil)
    async throws -> [ExtractedLink]
  {
    // Get active scraper instance
    guard let scraper = getActiveScraper() else {
      // Log error
      AppLogger.shared.log(
        "No active scraper configured for link extraction",
        level: .error
      )
      // Throw configuration error
      throw ScraperError.invalidConfiguration
    }

    // Log extraction start
    AppLogger.shared.log(
      "Extracting streaming links for content: \(contentId) from: \(scraper.name)",
      level: .debug
    )

    // Extract streaming links from scraper
    return try await scraper.extractStreamingLinks(
      contentId: contentId, seasonId: seasonId, episodeId: episodeId)
  }
}
