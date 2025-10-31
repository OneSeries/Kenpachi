// Download.swift
// Domain entity representing a download
// Contains download metadata, state, and progress information

import Foundation

/// Represents a content download with its current state and progress
struct Download: Equatable, Identifiable, Codable {
  /// Unique identifier for the download
  let id: String
  /// Content being downloaded
  let content: Content
  /// Episode being downloaded (for TV shows)
  let episode: Episode?
  /// Current download state
  var state: DownloadState
  /// Download progress (0.0 to 1.0)
  var progress: Double
  /// Download quality
  let quality: DownloadQuality?
  /// File size in bytes
  var fileSize: Int64?
  /// Downloaded bytes
  var downloadedBytes: Int64
  /// Download URL
  let downloadURL: URL?
  /// Local file path
  var localFilePath: URL?
  /// Date when download was created
  let createdAt: Date
  /// Date when download was last updated
  var updatedAt: Date
  /// Date when download was completed
  var completedAt: Date?
  
  /// Initializer
  init(
    id: String = UUID().uuidString,
    content: Content,
    episode: Episode? = nil,
    state: DownloadState = .pending,
    progress: Double = 0.0,
    quality: DownloadQuality? = nil,
    fileSize: Int64? = nil,
    downloadedBytes: Int64 = 0,
    downloadURL: URL? = nil,
    localFilePath: URL? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    completedAt: Date? = nil
  ) {
    self.id = id
    self.content = content
    self.episode = episode
    self.state = state
    self.progress = progress
    self.quality = quality
    self.fileSize = fileSize
    self.downloadedBytes = downloadedBytes
    self.downloadURL = downloadURL
    self.localFilePath = localFilePath
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.completedAt = completedAt
  }
  
  /// Formatted file size
  var formattedFileSize: String? {
    guard let fileSize = fileSize else { return nil }
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: fileSize)
  }
  
  /// Formatted downloaded size
  var formattedDownloadedSize: String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: downloadedBytes)
  }
  
  /// Whether download is active
  var isActive: Bool {
    state == .downloading || state == .pending
  }
  
  /// Whether download can be resumed
  var canResume: Bool {
    state == .paused || state == .failed
  }
  
  /// Whether download can be paused
  var canPause: Bool {
    state == .downloading
  }
}
