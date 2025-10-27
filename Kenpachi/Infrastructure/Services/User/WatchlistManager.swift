// WatchlistManager.swift
// Service for managing user watchlist
// Provides centralized watchlist operations

import Foundation

/// Manager for watchlist operations
final class WatchlistManager {
  /// Shared singleton instance
  static let shared = WatchlistManager()

  /// User repository
  private let userRepository: UserRepositoryProtocol
  /// Content repository
  private let contentRepository: ContentRepositoryProtocol

  /// Initializer with dependency injection
  init(
    userRepository: UserRepositoryProtocol = UserRepository.shared,
    contentRepository: ContentRepositoryProtocol = ContentRepository()
  ) {
    self.userRepository = userRepository
    self.contentRepository = contentRepository

    AppLogger.shared.log("WatchlistManager initialized", level: .debug)
  }

  // MARK: - Watchlist Operations

  /// Fetch watchlist with full content details for current scraper
  func fetchWatchlist() async throws -> [Content] {
    let currentScraper = ScraperManager.shared.getActiveScraper()?.name ?? "Unknown"
    AppLogger.shared.log("Fetching watchlist for scraper: \(currentScraper)", level: .debug)

    let watchlist = try await userRepository.fetchWatchlist()

    guard !watchlist.isEmpty else {
      AppLogger.shared.log("Watchlist is empty for \(currentScraper)", level: .debug)
      return []
    }

    /// Fetch content details for each item
    var contents: [Content] = []
    for contentId in watchlist.contentIds {
      do {
        let content = try await contentRepository.fetchContentDetails(id: contentId, type: nil)
        contents.append(content)
      } catch {
        AppLogger.shared.log(
          "Failed to fetch content \(contentId): \(error.localizedDescription)",
          level: .warning
        )
      }
    }

    AppLogger.shared.log(
      "Fetched \(contents.count) watchlist items for \(currentScraper)",
      level: .debug
    )
    return contents
  }

  /// Add content to watchlist for current scraper
  func addToWatchlist(contentId: String) async throws {
    let currentScraper = ScraperManager.shared.getActiveScraper()?.name ?? "Unknown"
    AppLogger.shared.log(
      "Adding content \(contentId) to watchlist for \(currentScraper)",
      level: .debug
    )

    try await userRepository.addToWatchlist(contentId: contentId)

    AppLogger.shared.log(
      "Content \(contentId) added to watchlist for \(currentScraper)",
      level: .info
    )
  }

  /// Remove content from watchlist for current scraper
  func removeFromWatchlist(contentId: String) async throws {
    let currentScraper = ScraperManager.shared.getActiveScraper()?.name ?? "Unknown"
    AppLogger.shared.log(
      "Removing content \(contentId) from watchlist for \(currentScraper)",
      level: .debug
    )

    try await userRepository.removeFromWatchlist(contentId: contentId)

    AppLogger.shared.log(
      "Content \(contentId) removed from watchlist for \(currentScraper)",
      level: .info
    )
  }

  /// Check if content is in watchlist
  func isInWatchlist(contentId: String) async throws -> Bool {
    let isInWatchlist = try await userRepository.isInWatchlist(contentId: contentId)

    AppLogger.shared.log(
      "Content \(contentId) in watchlist: \(isInWatchlist)",
      level: .debug
    )

    return isInWatchlist
  }

  /// Toggle watchlist status
  func toggleWatchlist(contentId: String) async throws -> Bool {
    let isInWatchlist = try await isInWatchlist(contentId: contentId)

    if isInWatchlist {
      try await removeFromWatchlist(contentId: contentId)
      return false
    } else {
      try await addToWatchlist(contentId: contentId)
      return true
    }
  }

  /// Get watchlist count
  func getWatchlistCount() async throws -> Int {
    let watchlist = try await userRepository.fetchWatchlist()
    return watchlist.count
  }
}
