// WatchHistory.swift
// Domain entity representing a user's watch history
// Tracks content viewing history with progress and timestamps

import Foundation

/// Represents a single watch history entry
struct WatchHistoryEntry: Equatable, Identifiable, Codable {
  /// Unique identifier for the entry
  let id: String
  /// Content ID
  let contentId: String
  /// Episode ID (for TV shows)
  let episodeId: String?
  /// Watch progress (0.0 to 1.0)
  var progress: Double
  /// Current playback position in seconds
  var currentTime: TimeInterval
  /// Total duration in seconds
  var duration: TimeInterval
  /// Date when content was last watched
  var lastWatchedAt: Date
  /// Date when entry was created
  let createdAt: Date
  
  /// Initializer
  init(
    id: String = UUID().uuidString,
    contentId: String,
    episodeId: String? = nil,
    progress: Double = 0.0,
    currentTime: TimeInterval = 0,
    duration: TimeInterval = 0,
    lastWatchedAt: Date = Date(),
    createdAt: Date = Date()
  ) {
    self.id = id
    self.contentId = contentId
    self.episodeId = episodeId
    self.progress = progress
    self.currentTime = currentTime
    self.duration = duration
    self.lastWatchedAt = lastWatchedAt
    self.createdAt = createdAt
  }
  
  /// Whether content is completed (watched > 90%)
  var isCompleted: Bool {
    progress >= 0.9
  }
  
  /// Whether content is in progress (watched > 5% and < 90%)
  var isInProgress: Bool {
    progress > 0.05 && progress < 0.9
  }
  
  /// Formatted progress percentage
  var formattedProgress: String {
    "\(Int(progress * 100))%"
  }
}

/// Represents a user's complete watch history
struct WatchHistory: Equatable, Identifiable, Codable {
  /// Unique identifier for the watch history
  let id: String
  /// User ID who owns the history
  let userId: String
  /// List of watch history entries
  var entries: [WatchHistoryEntry]
  /// Date when history was created
  let createdAt: Date
  /// Date when history was last updated
  var updatedAt: Date
  
  /// Initializer
  init(
    id: String = UUID().uuidString,
    userId: String,
    entries: [WatchHistoryEntry] = [],
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.userId = userId
    self.entries = entries
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
  
  /// Get entry for specific content
  func entry(for contentId: String, episodeId: String? = nil) -> WatchHistoryEntry? {
    entries.first { entry in
      entry.contentId == contentId && entry.episodeId == episodeId
    }
  }
  
  /// Update or add entry
  mutating func updateEntry(_ entry: WatchHistoryEntry) {
    if let index = entries.firstIndex(where: { $0.id == entry.id }) {
      entries[index] = entry
    } else {
      entries.append(entry)
    }
    updatedAt = Date()
  }
  
  /// Remove entry
  mutating func removeEntry(_ entryId: String) {
    entries.removeAll { $0.id == entryId }
    updatedAt = Date()
  }
  
  /// Clear all history
  mutating func clear() {
    entries.removeAll()
    updatedAt = Date()
  }
  
  /// Get recent entries (sorted by last watched)
  func recentEntries(limit: Int = 20) -> [WatchHistoryEntry] {
    Array(entries.sorted { $0.lastWatchedAt > $1.lastWatchedAt }.prefix(limit))
  }
  
  /// Get in-progress entries
  var inProgressEntries: [WatchHistoryEntry] {
    entries.filter { $0.isInProgress }
  }
  
  /// Total watch time in seconds
  var totalWatchTime: TimeInterval {
    entries.reduce(0) { $0 + $1.currentTime }
  }
}
