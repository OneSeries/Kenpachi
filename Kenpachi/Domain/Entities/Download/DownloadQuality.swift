// DownloadQuality.swift
// Enum representing download quality options
// Defines available video quality levels for downloads

import Foundation

/// Represents the quality level for downloads
enum DownloadQuality: String, Codable, Equatable, CaseIterable, Identifiable {
  /// 480p SD quality
  case sd480 = "480p"
  /// 720p HD quality
  case hd720 = "720p"
  /// 1080p Full HD quality
  case hd1080 = "1080p"
  /// 4K Ultra HD quality
  case uhd4k = "4K"
  
  /// Unique identifier
  var id: String { rawValue }
  
  /// Display name for the quality
  var displayName: String {
    switch self {
    case .sd480:
      return "SD (480p)"
    case .hd720:
      return "HD (720p)"
    case .hd1080:
      return "Full HD (1080p)"
    case .uhd4k:
      return "4K Ultra HD"
    }
  }
  
  /// Estimated file size multiplier (relative to 1080p)
  var sizeMultiplier: Double {
    switch self {
    case .sd480:
      return 0.3
    case .hd720:
      return 0.6
    case .hd1080:
      return 1.0
    case .uhd4k:
      return 2.5
    }
  }
  
  /// Bitrate in kbps
  var bitrate: Int {
    switch self {
    case .sd480:
      return 1500
    case .hd720:
      return 3000
    case .hd1080:
      return 5000
    case .uhd4k:
      return 15000
    }
  }
}
