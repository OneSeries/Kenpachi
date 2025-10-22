// VidSrc.swift
// VidSrc scraper implementation
// Uses TMDB for content metadata and VidSrc for streaming links

import Foundation
import SwiftSoup

/// VidSrc scraper implementation
/// Uses TMDB API for content discovery and VidSrc embeds for streaming
struct VidSrc: ScraperProtocol {
  /// Scraper name
  let name = "VidSrc"
  /// Base URL for VidSrc embeds
  let baseURL = "https://vidsrc.to"
  /// Supported content types
  let supportedTypes: [ContentType] = [.movie, .tvShow]

  /// Network client for making requests
  private let networkClient: NetworkClientProtocol
  /// Extractor resolver for streaming links
  private let extractorResolver: ExtractorResolver
  /// TMDB client for content metadata
  private let tmdbClient: TMDBClient

  /// Initializer
  /// - Parameters:
  ///   - networkClient: Network client instance
  ///   - extractorResolver: Extractor resolver instance
  ///   - tmdbClient: TMDB client instance
  init(
    networkClient: NetworkClientProtocol = NetworkClient.shared,
    extractorResolver: ExtractorResolver = ExtractorResolver(),
    tmdbClient: TMDBClient = TMDBClient.shared
  ) {
    self.networkClient = networkClient
    self.extractorResolver = extractorResolver
    self.tmdbClient = tmdbClient
  }

  /// Fetches home page content using TMDB
  /// - Returns: Array of content carousels for home screen
  func fetchHomeContent() async throws -> [ContentCarousel] {
    // Fetch trending content from TMDB
    async let trendingMovies = tmdbClient.fetchTrendingMovies(timeWindow: .day)
    async let trendingTVShows = tmdbClient.fetchTrendingTVShows(timeWindow: .day)
    async let popularMovies = tmdbClient.fetchTrendingMovies(timeWindow: .week)
    async let popularTVShows = tmdbClient.fetchTrendingTVShows(timeWindow: .week)

    // Wait for all requests to complete
    let (movies, tvShows, weeklyMovies, weeklyTVShows) = try await (
      trendingMovies,
      trendingTVShows,
      popularMovies,
      popularTVShows
    )

    // Create carousels
    var carousels: [ContentCarousel] = []

    // Hero carousel - mix of top trending content
    let heroItems = (movies.prefix(5) + tvShows.prefix(5)).shuffled().prefix(10)
    if !heroItems.isEmpty {
      carousels.append(
        ContentCarousel(
          title: "Featured",
          items: Array(heroItems),
          type: .hero
        ))
    }

    // Trending Movies
    if !movies.isEmpty {
      carousels.append(
        ContentCarousel(
          title: "Trending Movies",
          items: movies,
          type: .trending
        ))
    }

    // Trending TV Shows
    if !tvShows.isEmpty {
      carousels.append(
        ContentCarousel(
          title: "Trending TV Shows",
          items: tvShows,
          type: .trending
        ))
    }

    // Popular Movies (weekly)
    if !weeklyMovies.isEmpty {
      carousels.append(
        ContentCarousel(
          title: "Popular Movies",
          items: weeklyMovies,
          type: .popular
        ))
    }

    // Popular TV Shows (weekly)
    if !weeklyTVShows.isEmpty {
      carousels.append(
        ContentCarousel(
          title: "Popular TV Shows",
          items: weeklyTVShows,
          type: .popular
        ))
    }

    return carousels
  }

  /// Searches for content using TMDB
  /// - Parameters:
  ///   - query: Search query string
  ///   - page: Page number for pagination (default is 1)
  /// - Returns: Search result containing matching content
  func search(query: String, page: Int = 1) async throws -> ContentSearchResult {
    // Search both movies and TV shows using TMDB
    async let movieResults = tmdbClient.search(query: query, type: .movie)
    async let tvResults = tmdbClient.search(query: query, type: .tvShow)

    // Wait for both searches to complete
    let (movies, tvShows) = try await (movieResults, tvResults)

    // Combine results
    let allResults = movies + tvShows

    // Sort by popularity
    let sortedResults = allResults.sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }

    // Return search result
    return ContentSearchResult(
      id: "vidsrc-search-\(query)-\(page)",
      contents: sortedResults,
      totalResults: sortedResults.count,
      page: page,
      totalPages: 1
    )
  }

  /// Fetches content details using TMDB
  /// - Parameter id: Content identifier (format: "123" or "456")
  /// - Returns: Detailed content information
  func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
    switch type {
    case .movie:
      return try await tmdbClient.fetchMovieDetails(id: id)
    case .tvShow:
      return try await tmdbClient.fetchTVShowDetails(id: id)
    case .anime, .none:
      // Default to movie for anime or when type is not specified
      return try await tmdbClient.fetchMovieDetails(id: id)
    }
  }

  /// Extracts streaming links from VidSrc embed
  /// - Parameters:
  ///   - contentId: Content identifier (required, format: "tmdb-movie-123" or "tmdb-tv-456")
  ///   - seasonId: Season identifier (optional, for TV shows, e.g., "1" or "01")
  ///   - episodeId: Episode identifier (optional, for TV shows, e.g., "1" or "01")
  /// - Returns: Array of extracted streaming links
  func extractStreamingLinks(contentId: String, seasonId: String? = nil, episodeId: String? = nil)
    async throws -> [ExtractedLink]
  {

    // Build VidSrc embed URL
    let embedURL: String

    // Determine if it's a movie or TV show based on seasonId/episodeId
    if seasonId == nil && episodeId == nil {
      // Movie embed: https://vidsrc.to/embed/movie/TMDB_ID
      embedURL = "\(baseURL)/embed/movie/\(contentId)"
    } else {
      // Parse season and episode numbers (handle both "1" and "01" formats)
      let season = Int(seasonId ?? "1") ?? 1
      let episode = Int(episodeId ?? "1") ?? 1

      embedURL = "\(baseURL)/embed/tv/\(contentId)/\(season)/\(episode)"
    }

    // Extract streaming links from the embed URL
    let links = try await extractLinksFromEmbed(embedURL)
    return links
  }

  // MARK: - Private Helper Methods

  /// Extracts streaming links from VidSrc embed page
  /// - Parameter embedURL: VidSrc embed URL
  /// - Returns: Array of extracted streaming links
  private func extractLinksFromEmbed(_ embedURL: String) async throws -> [ExtractedLink] {
    var currentURL = embedURL
    var currentDomain = baseURL

    // Step 1: Fetch initial embed page and get #player_iframe
    guard let url = URL(string: currentURL) else {
      throw ScraperError.invalidURL
    }

    var request = URLRequest(url: url)
    request.setValue(
      "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36",
      forHTTPHeaderField: "User-Agent")
    request.setValue(currentDomain, forHTTPHeaderField: "Referer")

    let (data, _) = try await URLSession.shared.data(for: request)
    guard var html = String(data: data, encoding: .utf8) else {
      throw ScraperError.parsingFailed("Failed to decode HTML response")
    }

    var document = try SwiftSoup.parse(html)

    // Try to find #player_iframe
    var rcpIframe: String?
    if let iframeElement = try document.select("#player_iframe").first(),
      let src = try? iframeElement.attr("src"), !src.isEmpty
    {
      rcpIframe = src.hasPrefix("//") ? "https:\(src)" : src
    } else {
      // Fallback to .xyz domain
      currentURL = currentURL.replacingOccurrences(of: ".to", with: ".xyz")

      guard let fallbackURL = URL(string: currentURL) else {
        throw ScraperError.invalidURL
      }

      var fallbackRequest = URLRequest(url: fallbackURL)
      fallbackRequest.setValue(
        "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36",
        forHTTPHeaderField: "User-Agent")
      fallbackRequest.setValue(currentDomain, forHTTPHeaderField: "Referer")

      let (fallbackData, _) = try await URLSession.shared.data(for: fallbackRequest)
      guard let fallbackHTML = String(data: fallbackData, encoding: .utf8) else {
        throw ScraperError.parsingFailed("Failed to decode fallback HTML response")
      }

      document = try SwiftSoup.parse(fallbackHTML)
      if let iframeElement = try document.select("#player_iframe").first(),
        let src = try? iframeElement.attr("src"), !src.isEmpty
      {
        rcpIframe = src.hasPrefix("//") ? "https:\(src)" : src
      }
    }

    guard let rcpIframeURL = rcpIframe else {
      throw ScraperError.parsingFailed("Failed to find player_iframe")
    }

    // Step 2: Fetch rcp iframe page and extract prorcp iframe from src: 'xxx' pattern
    guard let rcpURL = URL(string: rcpIframeURL) else {
      throw ScraperError.invalidURL
    }

    // Update domain for referer
    if let urlComponents = URLComponents(url: rcpURL, resolvingAgainstBaseURL: false) {
      currentDomain = "\(urlComponents.scheme ?? "https")://\(urlComponents.host ?? "")"
    }

    var rcpRequest = URLRequest(url: rcpURL)
    rcpRequest.setValue(
      "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36",
      forHTTPHeaderField: "User-Agent")
    rcpRequest.setValue(currentDomain, forHTTPHeaderField: "Referer")

    let (rcpData, _) = try await URLSession.shared.data(for: rcpRequest)
    guard let rcpHTML = String(data: rcpData, encoding: .utf8) else {
      throw ScraperError.parsingFailed("Failed to decode rcp HTML response")
    }

    // Extract src: 'xxx' pattern using regex
    guard let srcRegex = try? NSRegularExpression(pattern: "src:\\s*'([^']*)'", options: []),
      let match = srcRegex.firstMatch(
        in: rcpHTML, options: [], range: NSRange(rcpHTML.startIndex..., in: rcpHTML)),
      let srcRange = Range(match.range(at: 1), in: rcpHTML)
    else {
      throw ScraperError.parsingFailed("Failed to find prorcp iframe src")
    }

    let prorcp = String(rcpHTML[srcRange])

    // Step 3: Build final iframe URL and extract video URL from file: 'xxx' pattern
    let finalIframeURL = "\(currentDomain)\(prorcp)"

    guard let finalURL = URL(string: finalIframeURL) else {
      throw ScraperError.invalidURL
    }

    var finalRequest = URLRequest(url: finalURL)
    finalRequest.setValue(
      "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36",
      forHTTPHeaderField: "User-Agent")
    finalRequest.setValue(currentDomain, forHTTPHeaderField: "Referer")

    let (finalData, _) = try await URLSession.shared.data(for: finalRequest)
    guard let finalHTML = String(data: finalData, encoding: .utf8) else {
      throw ScraperError.parsingFailed("Failed to decode final HTML response")
    }

    // Extract file: 'xxx' pattern using regex
    guard let fileRegex = try? NSRegularExpression(pattern: "file:\\s*'([^']*)'", options: []),
      let fileMatch = fileRegex.firstMatch(
        in: finalHTML, options: [], range: NSRange(finalHTML.startIndex..., in: finalHTML)),
      let fileRange = Range(fileMatch.range(at: 1), in: finalHTML)
    else {
      throw ScraperError.parsingFailed("Failed to find video URL")
    }

    let videoURL = String(finalHTML[fileRange])

    // Return the extracted video link
    return [
      ExtractedLink(
        url: videoURL,
        quality: "Auto",
        server: "VidSrc",
        requiresReferer: true,
        headers: [
          "Referer": currentDomain,
          "User-Agent":
            "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36",
        ]
      )
    ]
  }
}
