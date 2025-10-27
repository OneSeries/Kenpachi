// Watchlist.swift
// Domain entity representing a user's watchlist
// Contains content items saved for later viewing

import Foundation

/// Represents a user's watchlist with saved content
struct Watchlist: Equatable, Identifiable, Codable {
  /// Unique identifier for the watchlist
  let id: String
  /// User ID who owns the watchlist
  let userId: String
  /// Scraper source name (e.g., "FlixHQ", "VidFast")
  var scraperSource: String?
  /// List of content IDs in the watchlist
  var contentIds: [String]
  /// Date when watchlist was created
  let createdAt: Date
  /// Date when watchlist was last updated
  var updatedAt: Date
  
  /// Initializer
  init(
    id: String = UUID().uuidString,
    userId: String,
    scraperSource: String? = nil,
    contentIds: [String] = [],
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.userId = userId
    self.scraperSource = scraperSource
    self.contentIds = contentIds
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
  
  /// Number of items in watchlist
  var count: Int {
    contentIds.count
  }
  
  /// Whether watchlist is empty
  var isEmpty: Bool {
    contentIds.isEmpty
  }
  
  /// Check if content is in watchlist
  func contains(_ contentId: String) -> Bool {
    contentIds.contains(contentId)
  }
  
  /// Add content to watchlist
  mutating func add(_ contentId: String) {
    guard !contentIds.contains(contentId) else { return }
    contentIds.append(contentId)
    updatedAt = Date()
  }
  
  /// Remove content from watchlist
  mutating func remove(_ contentId: String) {
    contentIds.removeAll { $0 == contentId }
    updatedAt = Date()
  }
}
