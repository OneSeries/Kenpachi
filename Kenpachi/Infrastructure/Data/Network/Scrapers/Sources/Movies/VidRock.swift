// VidRock.swift
// VidRock scraper implementation
// Uses TMDB for content metadata and VidRock API for streaming links with AES encryption

import CommonCrypto
import CryptoKit
import Foundation
import SwiftSoup

/// VidRock scraper implementation
/// Uses TMDB API for content discovery and VidRock API with AES encryption for streaming
struct VidRock: ScraperProtocol {
  // MARK: - Properties
  
  /// Scraper name
  let name = "VidRock"
  /// Base URL for VidRock embeds
  let baseURL = "https://vidrock.net"
  /// Supported content types
  let supportedTypes: [ContentType] = [.movie, .tvShow]
  
  /// Network client for making requests
  private let networkClient: NetworkClientProtocol
  /// Extractor resolver for streaming links
  private let extractorResolver: ExtractorResolver
  /// TMDB client for content metadata
  private let tmdbClient: TMDBClient
  
  // MARK: - Initialization
  
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
  
  // MARK: - Home Content
  
  /// Fetches home page content using TMDB
  /// - Returns: Array of content carousels for home screen
  func fetchHomeContent() async throws -> [ContentCarousel] {
    print("📡 [VidRock] Fetching home content using TMDB")
    
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
      print("✅ [VidRock] Featured carousel: \(heroItems.count) items")
    }
    
    // Trending Movies
    if !movies.isEmpty {
      carousels.append(
        ContentCarousel(
          title: "Trending Movies",
          items: movies,
          type: .trending
        ))
      print("✅ [VidRock] Trending movies: \(movies.count) items")
    }
    
    // Trending TV Shows
    if !tvShows.isEmpty {
      carousels.append(
        ContentCarousel(
          title: "Trending TV Shows",
          items: tvShows,
          type: .trending
        ))
      print("✅ [VidRock] Trending TV shows: \(tvShows.count) items")
    }
    
    // Popular Movies (weekly)
    if !weeklyMovies.isEmpty {
      carousels.append(
        ContentCarousel(
          title: "Popular Movies",
          items: weeklyMovies,
          type: .popular
        ))
      print("✅ [VidRock] Popular movies: \(weeklyMovies.count) items")
    }
    
    // Popular TV Shows (weekly)
    if !weeklyTVShows.isEmpty {
      carousels.append(
        ContentCarousel(
          title: "Popular TV Shows",
          items: weeklyTVShows,
          type: .popular
        ))
      print("✅ [VidRock] Popular TV shows: \(weeklyTVShows.count) items")
    }
    
    print("✅ [VidRock] Total carousels: \(carousels.count)")
    return carousels
  }
  
  // MARK: - Search
  
  /// Searches for content using TMDB
  /// - Parameters:
  ///   - query: Search query string
  ///   - page: Page number for pagination (default is 1)
  /// - Returns: Search result containing matching content
  func search(query: String, page: Int = 1) async throws -> ContentSearchResult {
    print("📡 [VidRock] Searching for: '\(query)' (page: \(page))")
    
    // Search both movies and TV shows using TMDB
    async let movieResults = tmdbClient.search(query: query, type: .movie)
    async let tvResults = tmdbClient.search(query: query, type: .tvShow)
    
    // Wait for both searches to complete
    let (movies, tvShows) = try await (movieResults, tvResults)
    
    // Combine results
    let allResults = movies + tvShows
    
    // Sort by popularity
    let sortedResults = allResults.sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }
    
    print("✅ [VidRock] Found \(sortedResults.count) results")
    
    // Return search result
    return ContentSearchResult(
      id: "vidrock-search-\(query)-\(page)",
      contents: sortedResults,
      totalResults: sortedResults.count,
      page: page,
      totalPages: 1
    )
  }
  
  // MARK: - Content Details
  
  /// Fetches content details using TMDB
  /// - Parameters:
  ///   - id: Content identifier (TMDB ID)
  ///   - type: Content type (movie or TV show)
  /// - Returns: Detailed content information
  func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
    print("📡 [VidRock] Fetching content details for ID: \(id)")
    
    let content: Content
    switch type {
    case .movie:
      content = try await tmdbClient.fetchMovieDetails(id: id)
    case .tvShow:
      content = try await tmdbClient.fetchTVShowDetails(id: id)
    case .anime, .none:
      // Default to movie for anime or when type is not specified
      content = try await tmdbClient.fetchMovieDetails(id: id)
    }
    
    print("✅ [VidRock] Fetched details for: \(content.title)")
    return content
  }
  
  // MARK: - Streaming Links
  
  /// Extracts streaming links from VidRock using AES encryption
  /// - Parameters:
  ///   - contentId: Content identifier (TMDB ID)
  ///   - seasonId: Season identifier (optional, for TV shows)
  ///   - episodeId: Episode identifier (optional, for TV shows)
  /// - Returns: Array of extracted streaming links
  func extractStreamingLinks(
    contentId: String,
    seasonId: String? = nil,
    episodeId: String? = nil
  ) async throws -> [ExtractedLink] {
    print("📡 [VidRock] Extracting streaming links for: \(contentId)")
    
    // Determine item type and build item ID
    let itemType: String
    let itemId: String
    
    if seasonId == nil && episodeId == nil {
      // Movie
      itemType = "movie"
      itemId = contentId
    } else {
      // TV show - format: {tmdb_id}_{season}_{episode}
      let season = Int(seasonId ?? "1") ?? 1
      let episode = Int(episodeId ?? "1") ?? 1
      itemType = "tv"
      itemId = "\(contentId)_\(season)_\(episode)"
    }
    
    print("📡 [VidRock] Item type: \(itemType), Item ID: \(itemId)")
    
    // Extract streaming links using VidRock API
    let links = try await extractLinksFromAPI(itemType: itemType, itemId: itemId)
    
    print("✅ [VidRock] Extracted \(links.count) streaming links")
    
    return links
  }
  
  // MARK: - Private Helper Methods
  
  /// Extracts streaming links from VidRock API using AES encryption
  /// - Parameters:
  ///   - itemType: Type of content ("movie" or "tv")
  ///   - itemId: Item identifier (movie: "123", tv: "123_1_1")
  /// - Returns: Array of extracted streaming links
  private func extractLinksFromAPI(itemType: String, itemId: String) async throws
    -> [ExtractedLink]
  {
    // VidRock API uses AES encryption with a passphrase
    let passphrase = "x7k9mPqT2rWvY8zA5bC3nF6hJ2lK4mN9"
    let domain = baseURL
    
    // Encrypt the item ID using AES-256-CBC
    guard let encryptedId = try? encryptAES(text: itemId, passphrase: passphrase) else {
      throw ScraperError.parsingFailed("Failed to encrypt item ID")
    }
    
    // URL encode the encrypted ID
    guard
      let encodedId = encryptedId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    else {
      throw ScraperError.parsingFailed("Failed to URL encode encrypted ID")
    }
    
    // Build API URL
    let apiURL = "\(domain)/api/\(itemType)/\(encodedId)"
    print("📡 [VidRock] API URL: \(apiURL)")
    
    // Make API request
    guard let url = URL(string: apiURL) else {
      throw ScraperError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.setValue(
      "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36",
      forHTTPHeaderField: "User-Agent")
    request.setValue(domain, forHTTPHeaderField: "Referer")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    
    // Parse JSON response
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]]
    else {
      throw ScraperError.parsingFailed("Failed to parse API response")
    }
    
    // Extract all valid source URLs
    var sources: [String] = []
    for (_, value) in json {
      if let urlString = value["url"] as? String, !urlString.isEmpty {
        sources.append(urlString)
      }
    }
    
    guard !sources.isEmpty else {
      throw ScraperError.parsingFailed("No streaming sources found")
    }
    
    print("✅ [VidRock] Found \(sources.count) streaming sources")
    
    // Convert to ExtractedLink objects
    let links = sources.enumerated().map { index, urlString in
      ExtractedLink(
        url: urlString,
        quality: "Auto",
        server: "VidRock Server \(index + 1)",
        requiresReferer: true,
        headers: [
          "Referer": domain,
          "User-Agent":
            "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36",
        ]
      )
    }
    
    return links
  }
  
  /// Encrypts text using AES-256-CBC encryption
  /// - Parameters:
  ///   - text: Text to encrypt
  ///   - passphrase: Encryption passphrase
  /// - Returns: Base64 encoded encrypted string
  private func encryptAES(text: String, passphrase: String) throws -> String {
    // Convert passphrase to key data
    guard let keyData = passphrase.data(using: .utf8) else {
      throw ScraperError.parsingFailed("Failed to convert passphrase to data")
    }
    
    // Use first 16 bytes of key as IV (matching Python implementation)
    let ivData = keyData.prefix(16)
    
    // Convert text to data
    guard let textData = text.data(using: .utf8) else {
      throw ScraperError.parsingFailed("Failed to convert text to data")
    }
    
    // Perform AES-CBC encryption using CommonCrypto
    let encrypted = try performAESCBCEncryption(data: textData, key: keyData, iv: ivData)
    
    // Return base64 encoded result
    return encrypted.base64EncodedString()
  }
  
  /// Performs AES-CBC encryption using CommonCrypto
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - iv: Initialization vector
  /// - Returns: Encrypted data
  private func performAESCBCEncryption(data: Data, key: Data, iv: Data) throws -> Data {
    // Add PKCS7 padding
    let paddedData = addPKCS7Padding(to: data, blockSize: kCCBlockSizeAES128)
    
    // Prepare output buffer
    let cryptLength = paddedData.count + kCCBlockSizeAES128
    var cryptData = Data(count: cryptLength)
    
    var numBytesEncrypted: size_t = 0
    
    let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
      paddedData.withUnsafeBytes { dataBytes in
        key.withUnsafeBytes { keyBytes in
          iv.withUnsafeBytes { ivBytes in
            CCCrypt(
              CCOperation(kCCEncrypt),
              CCAlgorithm(kCCAlgorithmAES),
              CCOptions(kCCOptionPKCS7Padding),
              keyBytes.baseAddress, key.count,
              ivBytes.baseAddress,
              dataBytes.baseAddress, paddedData.count,
              cryptBytes.baseAddress, cryptLength,
              &numBytesEncrypted
            )
          }
        }
      }
    }
    
    guard cryptStatus == kCCSuccess else {
      throw ScraperError.parsingFailed("AES encryption failed")
    }
    
    cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
    return cryptData
  }
  
  /// Adds PKCS7 padding to data
  /// - Parameters:
  ///   - data: Data to pad
  ///   - blockSize: Block size for padding
  /// - Returns: Padded data
  private func addPKCS7Padding(to data: Data, blockSize: Int) -> Data {
    let paddingLength = blockSize - (data.count % blockSize)
    let paddingByte = UInt8(paddingLength)
    var paddedData = data
    paddedData.append(contentsOf: [UInt8](repeating: paddingByte, count: paddingLength))
    return paddedData
  }
}
