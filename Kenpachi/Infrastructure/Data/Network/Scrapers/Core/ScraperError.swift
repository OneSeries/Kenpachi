// ScraperError.swift
// Error types for scraping operations
// Provides detailed error information for scraping failures

import Foundation

/// Enum representing all possible scraper errors
enum ScraperError: Error, LocalizedError {
  /// Failed to parse HTML content
  case parsingFailed(String)
  /// Content not found on source
  case contentNotFound
  /// Streaming link extraction failed
  case extractionFailed(String)
  /// Source website structure changed
  case sourceChanged
  /// Rate limit exceeded
  case rateLimitExceeded
  /// Invalid scraper configuration
  case invalidConfiguration
  /// Network error during scraping
  case networkError(Error)
  /// Invalid content ID format
  case invalidContentId
  /// Invalid URL
  case invalidURL
  /// Missing episode information for TV show
  case missingEpisodeInfo
  /// Unknown scraping error
  case unknown(String)

  /// User-friendly error description
  var errorDescription: String? {
    switch self {
    case .parsingFailed(let details):
      return "Failed to parse content: \(details)"
    case .contentNotFound:
      return "Content not found on source"
    case .extractionFailed(let details):
      return "Failed to extract streaming links: \(details)"
    case .sourceChanged:
      return "Source website structure has changed"
    case .rateLimitExceeded:
      return "Rate limit exceeded, please try again later"
    case .invalidConfiguration:
      return "Invalid scraper configuration"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .invalidContentId:
      return "Invalid content identifier format"
    case .invalidURL:
      return "Invalid URL format"
    case .missingEpisodeInfo:
      return "Missing season or episode information for TV show"
    case .unknown(let message):
      return "Unknown error: \(message)"
    }
  }
}
