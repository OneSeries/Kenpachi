// WatchHistoryManager.swift
// Service for managing user watch history
// Provides centralized watch history operations

import Foundation

/// Manager for watch history operations
final class WatchHistoryManager {
  /// Shared singleton instance
  static let shared = WatchHistoryManager()

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

    AppLogger.shared.log("WatchHistoryManager initialized", level: .debug)
  }

  // MARK: - Watch History Operations

  /// Fetch watch history with full content details
  func fetchWatchHistory() async throws -> [Content] {
    AppLogger.shared.log("Fetching watch history", level: .debug)

    let history = try await userRepository.fetchWatchHistory()

    guard !history.entries.isEmpty else {
      AppLogger.shared.log("Watch history is empty", level: .debug)
      return []
    }

    /// Get unique content IDs from history entries
    let uniqueContentIds = Array(Set(history.entries.map { $0.contentId }))

    /// Fetch content details for each item
    var contents: [Content] = []
    for contentId in uniqueContentIds {
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

    /// Sort by most recently watched
    let sortedContents = contents.sorted { content1, content2 in
      let entry1 = history.entries.first { $0.contentId == content1.id }
      let entry2 = history.entries.first { $0.contentId == content2.id }
      return (entry1?.lastWatchedAt ?? Date.distantPast)
        > (entry2?.lastWatchedAt ?? Date.distantPast)
    }

    AppLogger.shared.log("Fetched \(sortedContents.count) watch history items", level: .debug)
    return sortedContents
  }

  /// Update watch history entry
  func updateWatchHistory(
    contentId: String,
    progress: Double,
    duration: TimeInterval
  ) async throws {
    AppLogger.shared.log(
      "Updating watch history for content \(contentId): \(progress)%",
      level: .debug
    )

    let entry = WatchHistoryEntry(
      id: UUID().uuidString,
      contentId: contentId,
      progress: progress,
      duration: duration,
      lastWatchedAt: Date()
    )

    try await userRepository.updateWatchHistoryEntry(entry)

    AppLogger.shared.log("Watch history updated for content \(contentId)", level: .info)
  }

  /// Remove entry from watch history
  func removeFromHistory(contentId: String) async throws {
    AppLogger.shared.log("Removing content \(contentId) from watch history", level: .debug)

    try await userRepository.removeWatchHistoryEntry(id: contentId)

    AppLogger.shared.log("Content \(contentId) removed from watch history", level: .info)
  }

  /// Clear all watch history
  func clearHistory() async throws {
    AppLogger.shared.log("Clearing all watch history", level: .debug)

    try await userRepository.clearWatchHistory()

    AppLogger.shared.log("Watch history cleared", level: .info)
  }
}
