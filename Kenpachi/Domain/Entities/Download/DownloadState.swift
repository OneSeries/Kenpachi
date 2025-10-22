// DownloadState.swift
// Enum representing the state of a download
// Tracks download lifecycle from pending to completion or failure

import Foundation

/// Represents the current state of a download
enum DownloadState: String, Codable, Equatable {
  /// Download is waiting to start
  case pending
  /// Download is in progress
  case downloading
  /// Download is paused
  case paused
  /// Download completed successfully
  case completed
  /// Download failed
  case failed
  
  /// Display name for the state
  var displayName: String {
    switch self {
    case .pending:
      return "Pending"
    case .downloading:
      return "Downloading"
    case .paused:
      return "Paused"
    case .completed:
      return "Completed"
    case .failed:
      return "Failed"
    }
  }
  
  /// Icon name for the state
  var iconName: String {
    switch self {
    case .pending:
      return "clock.fill"
    case .downloading:
      return "arrow.down.circle.fill"
    case .paused:
      return "pause.circle.fill"
    case .completed:
      return "checkmark.circle.fill"
    case .failed:
      return "exclamationmark.circle.fill"
    }
  }
}
