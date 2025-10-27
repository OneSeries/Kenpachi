// APIConstants.swift
// Centralized API configuration for all external services
// Contains base URLs, API keys, and endpoint definitions

import Foundation

/// Enum containing all API-related constants organized by service
enum APIConstants {

  // MARK: - TMDB API Configuration
  /// The Movie Database API constants for movies and TV shows
  enum TMDB {
    /// Base URL for TMDB API v3
    static let baseURL = "https://api.themoviedb.org/3"
    /// Base URL for TMDB images
    static let imageBaseURL = "https://image.tmdb.org/t/p"
    /// API key for TMDB (should be moved to Keychain in production)
    static var apiKey: String {
        let key = "tmdb_api_key"
        if let data = KeychainService.shared.load(key: key),
           let apiKey = String(data: data, encoding: .utf8) {
            return apiKey
        } else {
            let apiKey = "1865f43a0549ca50d341dd9ab8b29f49" // Replace with your actual key
            let data = Data(apiKey.utf8)
            _ = KeychainService.shared.save(key: key, data: data)
            return apiKey
        }
    }
    /// API read access token for v4 endpoints
    static let readAccessToken = "YOUR_TMDB_READ_ACCESS_TOKEN"

    /// Image size configurations
    enum ImageSize {
      static let poster = "/w500"
      static let backdrop = "/original"
      static let profile = "/w185"
      static let logo = "/w300"
      static let still = "/w300"
    }

    /// API endpoints
    enum Endpoints {
      static let trending = "/trending"
      static let movie = "/movie"
      static let tv = "/tv"
      static let search = "/search"
      static let discover = "/discover"
      static let genre = "/genre"
    }
  }

  // MARK: - AniList API Configuration
  /// AniList GraphQL API constants for anime content
  enum AniList {
    /// Base URL for AniList GraphQL API
    static let baseURL = "https://graphql.anilist.co"
    /// CDN URL for anime images
    static let imageBaseURL = "https://s4.anilist.co"
    /// Rate limit: 90 requests per minute
    static let rateLimit = 90
    /// Rate limit window in seconds
    static let rateLimitWindow = 60
  }

  // MARK: - Scraper Configuration
  /// Base URLs for various scraper sources
  enum Scrapers {
    /// FlixHQ scraper (default for movies/TV)
    static let flixHQBaseURL = "https://flixhq.to"
    /// FMovies scraper (alternative for movies/TV)
    static let fmoviesBaseURL = "https://fmovies.to"
    /// VidSrc scraper (alternative for movies/TV)
    static let vidSrcBaseURL = "https://vidsrc.to"
    /// HiAnime scraper (default for anime)
    static let hiAnimeBaseURL = "https://hianime.to"
    /// GogoAnime scraper (alternative for anime)
    static let gogoAnimeBaseURL = "https://gogoanime.lu"
    /// AnimeKai scraper (alternative for anime)
    static let animeKaiBaseURL = "https://animekai.ru"
  }

  // MARK: - Network Configuration
  /// General network settings
  enum Network {
    /// Request timeout interval in seconds
    static let timeoutInterval: TimeInterval = 30
    /// Maximum number of retry attempts for failed requests
    static let maxRetryAttempts = 3
    /// Delay between retry attempts in seconds
    static let retryDelay: TimeInterval = 2
    /// Maximum concurrent network operations
    static let maxConcurrentOperations = 4
  }

  // MARK: - Cache Configuration
  /// Cache settings for API responses
  enum Cache {
    /// Cache duration for trending content in seconds (1 hour)
    static let trendingCacheDuration: TimeInterval = 3600
    /// Cache duration for content details in seconds (24 hours)
    static let detailsCacheDuration: TimeInterval = 86400
    /// Cache duration for search results in seconds (30 minutes)
    static let searchCacheDuration: TimeInterval = 1800
    /// Maximum cache size in bytes (100 MB)
    static let maxCacheSize: Int = 100 * 1024 * 1024
  }
}
