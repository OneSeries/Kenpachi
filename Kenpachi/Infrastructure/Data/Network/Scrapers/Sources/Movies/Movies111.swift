// Movies111.swift
// 111Movies scraper implementation
// Uses TMDB for content metadata and 111Movies API for streaming links with AES encryption

import CommonCrypto
import CryptoKit
import Foundation
import SwiftSoup

/// 111Movies scraper implementation
/// Uses TMDB API for content discovery and 111Movies API with AES encryption for streaming
struct Movies111: ScraperProtocol {
  // MARK: - Properties

  /// Scraper name
  let name = "Movies111"
  /// Base URL for 111Movies
  let baseURL = "https://111movies.com"
  /// Supported content types
  let supportedTypes: [ContentType] = [.movie, .tvShow]

  /// Network client for making requests
  private let networkClient: NetworkClientProtocol
  /// Extractor resolver for streaming links
  private let extractorResolver: ExtractorResolver
  /// TMDB client for content metadata
  private let tmdbClient: TMDBClient

  // AES encryption constants
  private let aesKeyHex = "912660f3d9f3f35cee36396d31ed73366ab53c22c70710ce029697d17762997e"
  private let aesIVHex = "f91f2863783814f51c56f341d6ce1677"
  private let xorKeyHex = "be430a"
  private let staticPath =
    "to/1000003134441812/c945be05/2f30b6e198562e7015537bb71a738ff8245942a7/y/2c20617150078ad280239d1cc3a8b6ee9331acef9b0bdc6b742435597c38edb4/c8ddbffe-3efb-53e1-b883-3b6ce90ba310"

  // MARK: - Initialization

  init(
    networkClient: NetworkClientProtocol = NetworkClient.shared,
    extractorResolver: ExtractorResolver = ExtractorResolver(),
    tmdbClient: TMDBClient = TMDBClient.shared
  ) {
    self.networkClient = networkClient
    self.extractorResolver = extractorResolver
    self.tmdbClient = tmdbClient
  }

  // MARK: - ScraperProtocol Methods

  func fetchHomeContent() async throws -> [ContentCarousel] {
    async let trendingMovies = tmdbClient.fetchTrendingMovies(timeWindow: .day)
    async let trendingTVShows = tmdbClient.fetchTrendingTVShows(timeWindow: .day)
    async let popularMovies = tmdbClient.fetchTrendingMovies(timeWindow: .week)
    async let popularTVShows = tmdbClient.fetchTrendingTVShows(timeWindow: .week)

    let (movies, tvShows, weeklyMovies, weeklyTVShows) = try await (
      trendingMovies, trendingTVShows, popularMovies, popularTVShows
    )

    var carousels: [ContentCarousel] = []

    let heroItems = (movies.prefix(5) + tvShows.prefix(5)).shuffled().prefix(10)
    if !heroItems.isEmpty {
      carousels.append(ContentCarousel(title: "Featured", items: Array(heroItems), type: .hero))
    }

    if !movies.isEmpty {
      carousels.append(ContentCarousel(title: "Trending Movies", items: movies, type: .trending))
    }
    if !tvShows.isEmpty {
      carousels.append(ContentCarousel(title: "Trending TV Shows", items: tvShows, type: .trending))
    }
    if !weeklyMovies.isEmpty {
      carousels.append(
        ContentCarousel(title: "Popular Movies", items: weeklyMovies, type: .popular))
    }
    if !weeklyTVShows.isEmpty {
      carousels.append(
        ContentCarousel(title: "Popular TV Shows", items: weeklyTVShows, type: .popular))
    }

    return carousels
  }

  func search(query: String, page: Int = 1) async throws -> ContentSearchResult {
    let movieResults = try await tmdbClient.search(query: query, type: .movie)
    let tvResults = try await tmdbClient.search(query: query, type: .tvShow)
    let allResults = movieResults + tvResults

    return ContentSearchResult(
      id: "111movies-search-\(query)-\(page)",
      contents: allResults,
      totalResults: allResults.count,
      page: page,
      totalPages: 1
    )
  }

  func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
    if type == .tvShow {
      return try await tmdbClient.fetchTVShowDetails(id: id)
    } else {
      return try await tmdbClient.fetchMovieDetails(id: id)
    }
  }

  func extractStreamingLinks(
    contentId: String, seasonId: String? = nil, episodeId: String? = nil
  ) async throws -> [ExtractedLink] {
    let isTVShow = seasonId != nil && episodeId != nil
    let embedURL: String

    if isTVShow, let season = seasonId, let episode = episodeId {
      embedURL = "/tv/\(contentId)/\(season)/\(episode)"
    } else {
      embedURL = "/movie/\(contentId)"
    }

    print("\n🎬 [111Movies] ========== EXTRACT STREAMING LINKS START ==========")
    print("📥 [111Movies] Input - contentId: \(contentId)")
    print("🔗 [111Movies] Step 1: Fetching embed page: \(baseURL)\(embedURL)")

    let endpoint = Movies111Endpoint(baseURL: baseURL, path: embedURL)
    let data = try await networkClient.requestData(endpoint)

    guard let html = String(data: data, encoding: .utf8) else {
      throw ScraperError.parsingFailed("Failed to decode HTML")
    }

    print("✅ [111Movies] Step 1: Received HTML (\(html.count) characters)")

    guard let rawData = extractRawData(from: html) else {
      throw ScraperError.parsingFailed("Failed to extract raw data")
    }

    print("✅ [111Movies] Step 2: Extracted raw data (\(rawData.count) characters)")

    let encodedData = try processEncryptionPipeline(rawData: rawData)

    print("✅ [111Movies] Step 3: Encryption complete (\(encodedData.count) characters)")

    let serversPath = "/\(staticPath)/\(encodedData)/sr"
    print("🌐 [111Movies] Step 4: Fetching servers: \(baseURL)\(serversPath)")

    let serversEndpoint = Movies111Endpoint(baseURL: baseURL, path: serversPath, method: .post)
    let serversData = try await networkClient.requestData(serversEndpoint)

    struct ServerResponse: Decodable {
      let data: String
    }

    let servers = try JSONDecoder().decode([ServerResponse].self, from: serversData)
    print("✅ [111Movies] Step 4: Got \(servers.count) servers")

    guard let randomServer = servers.randomElement() else {
      throw ScraperError.parsingFailed("No servers available")
    }

    let streamPath = "/\(staticPath)/\(randomServer.data)"
    print("🎥 [111Movies] Step 5: Fetching stream: \(baseURL)\(streamPath)")

    let streamEndpoint = Movies111Endpoint(baseURL: baseURL, path: streamPath, method: .post)
    let streamData = try await networkClient.requestData(streamEndpoint)

    struct StreamResponse: Decodable {
      let url: String
    }

    let streamResponse = try JSONDecoder().decode(StreamResponse.self, from: streamData)

    print("✅ [111Movies] Got streaming URL: \(streamResponse.url)")
    print("✅ [111Movies] ========== EXTRACT STREAMING LINKS SUCCESS ==========\n")

    return [
      ExtractedLink(
        url: streamResponse.url,
        quality: "Auto",
        server: "111Movies",
        requiresReferer: true,
        headers: [
          "Referer": baseURL + "/",
          "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36",
        ],
        type: .m3u8
      )
    ]
  }

  // MARK: - Helper Methods

  private func extractRawData(from html: String) -> String? {
    let pattern = #"\{\"data\":\"(.*?)\""#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
      let match = regex.firstMatch(
        in: html, options: [], range: NSRange(html.startIndex..., in: html)),
      let range = Range(match.range(at: 1), in: html)
    else {
      return nil
    }
    return String(html[range])
  }

  private func processEncryptionPipeline(rawData: String) throws -> String {
    guard let aesKey = Data(hexString: aesKeyHex),
      let aesIV = Data(hexString: aesIVHex)
    else {
      throw ScraperError.parsingFailed("Failed to prepare AES keys")
    }

    let aesEncrypted = try performAESCBCEncryption(data: rawData, key: aesKey, iv: aesIV)
    let hexString = aesEncrypted.map { String(format: "%02x", $0) }.joined()

    guard let xorKey = Data(hexString: xorKeyHex) else {
      throw ScraperError.parsingFailed("Failed to prepare XOR key")
    }

    let xorResult = performXOROnHex(hexString: hexString, key: xorKey)
    let encoded = customBase64Encode(string: xorResult)

    return encoded
  }

  private func performAESCBCEncryption(data: String, key: Data, iv: Data) throws -> Data {
    guard let inputData = data.data(using: .utf8) else {
      throw ScraperError.parsingFailed("Failed to convert string to data")
    }

    let paddedData = addPKCS7Padding(data: inputData, blockSize: kCCBlockSizeAES128)

    let bufferSize = paddedData.count + kCCBlockSizeAES128
    var buffer = Data(count: bufferSize)
    var numBytesEncrypted: size_t = 0

    let cryptStatus = buffer.withUnsafeMutableBytes { bufferBytes in
      paddedData.withUnsafeBytes { dataBytes in
        key.withUnsafeBytes { keyBytes in
          iv.withUnsafeBytes { ivBytes in
            CCCrypt(
              CCOperation(kCCEncrypt),
              CCAlgorithm(kCCAlgorithmAES),
              CCOptions(0),
              keyBytes.baseAddress, key.count,
              ivBytes.baseAddress,
              dataBytes.baseAddress, paddedData.count,
              bufferBytes.baseAddress, bufferSize,
              &numBytesEncrypted
            )
          }
        }
      }
    }

    guard cryptStatus == kCCSuccess else {
      throw ScraperError.parsingFailed("AES encryption failed")
    }

    return buffer.prefix(numBytesEncrypted)
  }

  private func addPKCS7Padding(data: Data, blockSize: Int) -> Data {
    let paddingLength = blockSize - (data.count % blockSize)
    let paddingByte = UInt8(paddingLength)
    var paddedData = data
    paddedData.append(contentsOf: [UInt8](repeating: paddingByte, count: paddingLength))
    return paddedData
  }

  private func performXOROnHex(hexString: String, key: Data) -> String {
    var result = ""
    for (i, char) in hexString.enumerated() {
      let charCode = char.unicodeScalars.first!.value
      let xorByte = key[i % key.count]
      let xorResult = charCode ^ UInt32(xorByte)
      result.append(Character(UnicodeScalar(xorResult)!))
    }
    return result
  }

  private func customBase64Encode(string: String) -> String {
    let sourceChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
    let targetChars = "BdNqfj2X1RalybZHxP50e8UGz4Tv6mg3QS-7JnAWIsiKrCpFktVM9D_chuYOoEwL"

    guard let data = string.data(using: .utf8) else { return "" }

    var base64 = data.base64EncodedString()
    base64 = base64.replacingOccurrences(of: "+", with: "-")
    base64 = base64.replacingOccurrences(of: "/", with: "_")
    base64 = base64.replacingOccurrences(of: "=", with: "")

    var result = ""
    for char in base64 {
      if let index = sourceChars.firstIndex(of: char) {
        let targetIndex = sourceChars.distance(from: sourceChars.startIndex, to: index)
        let targetChar = targetChars[
          targetChars.index(targetChars.startIndex, offsetBy: targetIndex)]
        result.append(targetChar)
      } else {
        result.append(char)
      }
    }

    return result
  }
}

// MARK: - Endpoint

private struct Movies111Endpoint: Endpoint {
  let baseURL: String
  let path: String
  let method: HTTPMethod

  init(baseURL: String, path: String, method: HTTPMethod = .get) {
    self.baseURL = baseURL
    self.path = path
    self.method = method
  }

  var queryItems: [URLQueryItem]? { nil }
  var headers: [String: String]? {
    [
      "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36",
      "Referer": baseURL + "/",
      "X-Requested-With": "XMLHttpRequest",
    ]
  }
  var body: Data? { nil }
}
