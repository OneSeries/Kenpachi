// VidNest.swift
// VidNest scraper implementation
// Uses TMDB for content metadata and VidNest backend for streaming links

import CryptoKit
import Foundation

/// VidNest scraper implementation
/// Uses TMDB API for content discovery and VidNest backend for streaming
struct VidNest: ScraperProtocol {
  /// Scraper name
  let name = "VidNest"
  /// Base URL for VidNest backend
  let baseURL = "https://backend.vidnest.fun"
  /// Supported content types
  let supportedTypes: [ContentType] = [.movie, .tvShow]

  /// VidNest servers
  private let servers = ["allmovies", "hollymoviehd"]
  /// AES-GCM passphrase for decryption
  private let passphrase = "T8c8PQlSQVU4mBuW4CbE/g57VBbM5009QHd+ym93aZZ5pEeVpToY6OdpYPvRMVYp"
  /// Decryption service URL
  private let decryptionServiceURL = "https://aesdec.nuvioapp.space/decrypt"

  /// Network client for making requests
  private let networkClient: NetworkClientProtocol
  /// TMDB client for content metadata
  private let tmdbClient: TMDBClient

  /// Initializer
  init(
    networkClient: NetworkClientProtocol = NetworkClient.shared,
    tmdbClient: TMDBClient = TMDBClient.shared
  ) {
    self.networkClient = networkClient
    self.tmdbClient = tmdbClient
  }

  /// Fetches home page content using TMDB
  func fetchHomeContent() async throws -> [ContentCarousel] {
    // Fetch trending content from TMDB
    async let trendingMovies = tmdbClient.fetchTrendingMovies(timeWindow: .day)
    async let trendingTVShows = tmdbClient.fetchTrendingTVShows(timeWindow: .day)
    async let popularMovies = tmdbClient.fetchTrendingMovies(timeWindow: .week)
    async let popularTVShows = tmdbClient.fetchTrendingTVShows(timeWindow: .week)

    let (movies, tvShows, weeklyMovies, weeklyTVShows) = try await (
      trendingMovies, trendingTVShows, popularMovies, popularTVShows
    )

    var carousels: [ContentCarousel] = []

    // Hero carousel
    let heroItems = (movies.prefix(5) + tvShows.prefix(5)).shuffled().prefix(10)
    if !heroItems.isEmpty {
      carousels.append(
        ContentCarousel(title: "Featured", items: Array(heroItems), type: .hero))
    }

    // Trending Movies
    if !movies.isEmpty {
      carousels.append(
        ContentCarousel(title: "Trending Movies", items: movies, type: .trending))
    }

    // Trending TV Shows
    if !tvShows.isEmpty {
      carousels.append(
        ContentCarousel(title: "Trending TV Shows", items: tvShows, type: .trending))
    }

    // Popular Movies
    if !weeklyMovies.isEmpty {
      carousels.append(
        ContentCarousel(title: "Popular Movies", items: weeklyMovies, type: .popular))
    }

    // Popular TV Shows
    if !weeklyTVShows.isEmpty {
      carousels.append(
        ContentCarousel(title: "Popular TV Shows", items: weeklyTVShows, type: .popular))
    }

    return carousels
  }

  /// Searches for content using TMDB
  func search(query: String, page: Int = 1) async throws -> ContentSearchResult {
    async let movieResults = tmdbClient.search(query: query, type: .movie)
    async let tvResults = tmdbClient.search(query: query, type: .tvShow)

    let (movies, tvShows) = try await (movieResults, tvResults)
    let allResults = movies + tvShows
    let sortedResults = allResults.sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }

    return ContentSearchResult(
      id: "vidnest-search-\(query)-\(page)",
      contents: sortedResults,
      totalResults: sortedResults.count,
      page: page,
      totalPages: 1
    )
  }

  /// Fetches content details using TMDB
  func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
    switch type {
    case .movie:
      return try await tmdbClient.fetchMovieDetails(id: id)
    case .tvShow:
      return try await tmdbClient.fetchTVShowDetails(id: id)
    case .anime, .none:
      return try await tmdbClient.fetchMovieDetails(id: id)
    }
  }

  /// Extracts streaming links from VidNest backend
  func extractStreamingLinks(
    contentId: String, seasonId: String? = nil, episodeId: String? = nil
  ) async throws -> [ExtractedLink] {

    // Determine media type
    let mediaType = (seasonId != nil && episodeId != nil) ? "tv" : "movie"

    // Fetch streams from all servers in parallel
    let results = await withTaskGroup(of: [ExtractedLink].self) { group in
      for server in servers {
        group.addTask {
          await self.fetchFromServer(
            tmdbId: contentId,
            server: server,
            mediaType: mediaType,
            seasonNum: seasonId,
            episodeNum: episodeId
          )
        }
      }

      var allLinks: [ExtractedLink] = []
      for await links in group {
        allLinks.append(contentsOf: links)
      }
      return allLinks
    }

    // Remove duplicates by URL
    var uniqueLinks: [ExtractedLink] = []
    var seenURLs = Set<String>()

    for link in results {
      if !seenURLs.contains(link.url) {
        seenURLs.insert(link.url)
        uniqueLinks.append(link)
      }
    }

    // Sort by quality (highest first)
      return uniqueLinks.sorted { getQualityValue($0.quality ?? "unknown") > getQualityValue($1.quality ?? "unknown") }
  }

  // MARK: - Private Helper Methods

  /// Fetches streams from a single VidNest server
  private func fetchFromServer(
    tmdbId: String,
    server: String,
    mediaType: String,
    seasonNum: String?,
    episodeNum: String?
  ) async -> [ExtractedLink] {

    // Build API URL
    var apiURL = "\(baseURL)/\(server)/\(mediaType)/\(tmdbId)"
    if mediaType == "tv", let season = seasonNum, let episode = episodeNum {
      apiURL += "/\(season)/\(episode)"
    }

    guard let url = URL(string: apiURL) else {
      return []
    }

    var request = URLRequest(url: url)
    request.setValue(
      "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36",
      forHTTPHeaderField: "User-Agent")
    request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
    request.setValue("https://vidnest.fun/", forHTTPHeaderField: "Referer")
    request.setValue("https://vidnest.fun", forHTTPHeaderField: "Origin")

    do {
      let (data, _) = try await URLSession.shared.data(for: request)

      // Parse JSON response
      guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return []
      }

      // Check if response is encrypted
      if let encrypted = json["encrypted"] as? Bool, encrypted,
        let encryptedData = json["data"] as? String
      {
        // Decrypt the data
        guard let decryptedJSON = await decryptData(encryptedData) else {
          return []
        }
        return processVidNestResponse(decryptedJSON, server: server)
      } else {
        // Process non-encrypted response
        return processVidNestResponse(json, server: server)
      }

    } catch {
      return []
    }
  }

  /// Decrypts AES-GCM encrypted data using external service
  private func decryptData(_ encryptedData: String) async -> [String: Any]? {
    guard let url = URL(string: decryptionServiceURL) else {
      return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: String] = [
      "encryptedData": encryptedData,
      "passphrase": passphrase,
    ]

    guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
      return nil
    }

    request.httpBody = jsonData

    do {
      let (data, _) = try await URLSession.shared.data(for: request)

      guard let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let decryptedString = response["decrypted"] as? String
      else {
        return nil
      }

      // Parse decrypted JSON string
      guard let decryptedData = decryptedString.data(using: .utf8),
        let decryptedJSON = try? JSONSerialization.jsonObject(with: decryptedData)
          as? [String: Any]
      else {
        return nil
      }

      return decryptedJSON

    } catch {
      return nil
    }
  }

  /// Processes VidNest API response and extracts streaming links
  private func processVidNestResponse(_ json: [String: Any], server: String) -> [ExtractedLink] {
    var links: [ExtractedLink] = []

    // Extract sources or streams array
    guard let sources = (json["sources"] ?? json["streams"]) as? [[String: Any]] else {
      return links
    }

    for source in sources {
      // Extract video URL
      guard
        let videoURL = (source["file"] ?? source["url"] ?? source["src"] ?? source["link"])
          as? String
      else {
        continue
      }

      // Extract quality
      var quality = extractQuality(from: videoURL)

      // Check if it's HLS stream
      if videoURL.contains(".m3u8") {
        quality = quality == "Unknown" ? "Auto" : quality
      }

      // Extract language info
      let language = source["language"] as? String
      let label = source["label"] as? String

      // Build server name
      var serverName = "VidNest \(server.capitalized)"
      if let label = label {
        serverName += " - \(label)"
      }
      if let language = language {
        serverName += " [\(language)]"
      }

      links.append(
        ExtractedLink(
          url: videoURL,
          quality: quality,
          server: serverName,
          requiresReferer: true,
          headers: [
            "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
            "Accept":
              "video/webm,video/ogg,video/*;q=0.9,application/ogg;q=0.7,audio/*;q=0.6,*/*;q=0.5",
            "Referer": "https://vidnest.fun/",
          ]
        ))
    }

    return links
  }

  /// Extracts quality from URL
  private func extractQuality(from url: String) -> String {
    // Quality patterns
    let patterns = [
      #"(\d{3,4})p"#,
      #"(\d{3,4})k"#,
      #"quality[_-]?(\d{3,4})"#,
      #"res[_-]?(\d{3,4})"#,
      #"(\d{3,4})x\d{3,4}"#,
    ]

    for pattern in patterns {
      if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
        let match = regex.firstMatch(
          in: url, options: [], range: NSRange(url.startIndex..., in: url)),
        let range = Range(match.range(at: 1), in: url),
        let qualityNum = Int(url[range])
      {
        if qualityNum >= 240 && qualityNum <= 4320 {
          return "\(qualityNum)p"
        }
      }
    }

    // Fallback quality detection
    if url.contains("1080") || url.contains("1920") { return "1080p" }
    if url.contains("720") || url.contains("1280") { return "720p" }
    if url.contains("480") || url.contains("854") { return "480p" }
    if url.contains("360") || url.contains("640") { return "360p" }
    if url.contains("240") || url.contains("426") { return "240p" }

    return "Unknown"
  }

  /// Gets numeric value for quality sorting
  private func getQualityValue(_ quality: String) -> Int {
    let q = quality.lowercased().replacingOccurrences(of: "p", with: "")

    if q == "4k" || q == "2160" { return 2160 }
    if q == "1440" { return 1440 }
    if q == "1080" { return 1080 }
    if q == "720" { return 720 }
    if q == "480" { return 480 }
    if q == "360" { return 360 }
    if q == "240" { return 240 }
    if q == "auto" || q == "adaptive" { return 1080 }  // Treat adaptive as high quality
    if q == "unknown" { return 0 }

    return Int(q) ?? 1
  }
}
