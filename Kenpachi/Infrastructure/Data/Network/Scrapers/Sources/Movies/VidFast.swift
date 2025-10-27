// VidFast.swift
// VidFast scraper implementation
// Uses TMDB for content metadata and VidFast API for streaming links with AES encryption

import CommonCrypto
import CryptoKit
import Foundation
import SwiftSoup

/// VidFast scraper implementation
/// Uses TMDB API for content discovery and VidFast API with AES encryption for streaming
struct VidFast: ScraperProtocol {
  // MARK: - Properties

  /// Scraper name
  let name = "VidFast"
  /// Base URL for VidFast embeds
  let baseURL = "https://vidfast.pro"
  /// Supported content types
  let supportedTypes: [ContentType] = [.movie, .tvShow]

  /// Network client for making requests
  private let networkClient: NetworkClientProtocol
  /// Extractor resolver for streaming links
  private let extractorResolver: ExtractorResolver
  /// TMDB client for content metadata
  private let tmdbClient: TMDBClient

  // AES encryption constants
  private let aesKeyHex = "1dc203af0fd5e9fe9afb00b3c493f99d2afd4079bfbc3e6215905307a5f94c60"
  private let aesIVHex = "88e64b5e95213ab779e234c89a4d586d"
  private let xorKeyHex = "6f9772dfe44c"
  private let staticPath =
    "hezushon/88e9184396861e1614ca54216944f038181ac569d8598024ac05ebbd918f11f8/t"

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
    print("📡 [VidFast] Fetching home content using TMDB")

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
      id: "vidfast-search-\(query)-\(page)",
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
    print("\n🎬 [VidFast] ========== EXTRACT STREAMING LINKS START ==========")
    print(
      "📥 [VidFast] Input - contentId: \(contentId), seasonId: \(seasonId ?? "nil"), episodeId: \(episodeId ?? "nil")"
    )

    let isTVShow = seasonId != nil && episodeId != nil
    let embedURL: String

    if isTVShow, let season = seasonId, let episode = episodeId {
      embedURL = "/tv/\(contentId)/\(season)/\(episode)"
    } else {
      embedURL = "/movie/\(contentId)"
    }

    print("🔗 [VidFast] Step 1: Fetching embed page")
    print("   URL: \(baseURL)\(embedURL)")

    let endpoint = VidFastEndpoint(baseURL: baseURL, path: embedURL)
    let data = try await networkClient.requestData(endpoint)

    print("✅ [VidFast] Step 1: Received \(data.count) bytes of HTML")

    guard let html = String(data: data, encoding: .utf8) else {
      print("❌ [VidFast] Failed to decode HTML from data")
      throw ScraperError.parsingFailed("Failed to decode HTML")
    }

    print("✅ [VidFast] Step 1: HTML decoded successfully (\(html.count) characters)")
    print("📄 [VidFast] HTML preview (first 500 chars): \(String(html.prefix(500)))")

    print("\n🔍 [VidFast] Step 2: Extracting raw data from HTML")
    guard let rawData = extractRawData(from: html) else {
      print("❌ [VidFast] Failed to extract raw data from HTML")
      throw ScraperError.parsingFailed("Failed to extract raw data")
    }

    print("✅ [VidFast] Step 2: Raw data extracted successfully")
    print("📊 [VidFast] Raw data length: \(rawData.count) characters")
    print("📝 [VidFast] Raw data preview: \(String(rawData.prefix(100)))...")

    print("\n🔐 [VidFast] Step 3: Processing encryption pipeline")
    let encodedData = try processEncryptionPipeline(rawData: rawData)

    print("✅ [VidFast] Step 3: Encryption pipeline completed")
    print("📊 [VidFast] Encoded data length: \(encodedData.count) characters")
    print("📝 [VidFast] Encoded data preview: \(String(encodedData.prefix(100)))...")

    let apiServers = "/\(staticPath)/3xNAjSIxZx0b/\(encodedData)"
    print("\n🌐 [VidFast] Step 4: Fetching servers list")
    print("   URL: \(baseURL)\(apiServers)")

    let serversEndpoint = VidFastEndpoint(baseURL: baseURL, path: apiServers)
    let serversData: Data
    do {
      serversData = try await networkClient.requestData(serversEndpoint)
    } catch {
      print("❌ [VidFast] Step 4: Network request failed")
      print("   Error: \(error)")
      throw ScraperError.networkError(error)
    }

    print("✅ [VidFast] Step 4: Received \(serversData.count) bytes of server data")

    if let serversJSON = String(data: serversData, encoding: .utf8) {
      print("📄 [VidFast] Servers JSON: \(serversJSON)")
    }

    struct ServerResponse: Decodable {
      let data: String
    }

    let servers: [ServerResponse]
    do {
      servers = try JSONDecoder().decode([ServerResponse].self, from: serversData)
    } catch {
      print("❌ [VidFast] Step 4: Failed to decode servers JSON")
      print("   Error: \(error)")
      if let jsonString = String(data: serversData, encoding: .utf8) {
        print("   Raw response: \(jsonString)")
      }
      throw ScraperError.parsingFailed("Failed to decode servers: \(error.localizedDescription)")
    }

    print("✅ [VidFast] Step 4: Decoded \(servers.count) servers")
    for (index, server) in servers.enumerated() {
      print("   Server \(index + 1): \(server.data)")
    }

    guard let randomServer = servers.randomElement() else {
      print("❌ [VidFast] No servers available")
      throw ScraperError.parsingFailed("No servers available")
    }

    print("✅ [VidFast] Step 4: Selected random server: \(randomServer.data)")

    let apiStream = "/\(staticPath)/Ici0cUs4soE/\(randomServer.data)"
    print("\n🎥 [VidFast] Step 5: Fetching stream URL")
    print("   URL: \(baseURL)\(apiStream)")

    let streamEndpoint = VidFastEndpoint(baseURL: baseURL, path: apiStream)
    let streamData: Data
    do {
      streamData = try await networkClient.requestData(streamEndpoint)
    } catch {
      print("❌ [VidFast] Step 5: Network request failed")
      print("   Error: \(error)")
      throw ScraperError.networkError(error)
    }

    print("✅ [VidFast] Step 5: Received \(streamData.count) bytes of stream data")

    if let streamJSON = String(data: streamData, encoding: .utf8) {
      print("📄 [VidFast] Stream JSON: \(streamJSON)")
    }

    struct StreamResponse: Decodable {
      let url: String
    }

    let streamResponse: StreamResponse
    do {
      streamResponse = try JSONDecoder().decode(StreamResponse.self, from: streamData)
    } catch {
      print("❌ [VidFast] Step 5: Failed to decode stream JSON")
      print("   Error: \(error)")
      if let jsonString = String(data: streamData, encoding: .utf8) {
        print("   Raw response: \(jsonString)")
      }
      throw ScraperError.parsingFailed("Failed to decode stream: \(error.localizedDescription)")
    }

    print("✅ [VidFast] Step 5: Decoded stream URL")
    print("🎬 [VidFast] Final streaming URL: \(streamResponse.url)")

    let extractedLink = ExtractedLink(
      url: streamResponse.url,
      quality: "Auto",
      server: "VidFast",
      requiresReferer: true,
      headers: [
        "Referer": baseURL + "/",
        "Origin": baseURL,
        "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36",
      ],
      type: .m3u8
    )

    print("✅ [VidFast] ========== EXTRACT STREAMING LINKS SUCCESS ==========\n")

    return [extractedLink]
  }

  // MARK: - Helper Methods

  private func extractRawData(from html: String) -> String? {
    print("   🔍 [VidFast.extractRawData] Searching for pattern in HTML")
    print("   📏 [VidFast.extractRawData] HTML length: \(html.count) characters")

    let pattern = #"\\"en\\":\\"(.*?)\\""#
    print("   🔎 [VidFast.extractRawData] Using regex pattern: \(pattern)")

    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
      print("   ❌ [VidFast.extractRawData] Failed to create regex")
      return nil
    }

    guard
      let match = regex.firstMatch(
        in: html, options: [], range: NSRange(html.startIndex..., in: html))
    else {
      print("   ❌ [VidFast.extractRawData] No match found in HTML")
      return nil
    }

    guard let range = Range(match.range(at: 1), in: html) else {
      print("   ❌ [VidFast.extractRawData] Failed to convert match range")
      return nil
    }

    let extracted = String(html[range])
    print("   ✅ [VidFast.extractRawData] Successfully extracted data")
    print("   📊 [VidFast.extractRawData] Extracted length: \(extracted.count) characters")

    return extracted
  }

  private func processEncryptionPipeline(rawData: String) throws -> String {
    print("   🔐 [VidFast.processEncryptionPipeline] Starting encryption pipeline")
    print("   📥 [VidFast.processEncryptionPipeline] Input raw data length: \(rawData.count)")

    print("   🔑 [VidFast.processEncryptionPipeline] Preparing AES keys")
    print("   🔑 [VidFast.processEncryptionPipeline] AES Key (hex): \(aesKeyHex)")
    print("   🔑 [VidFast.processEncryptionPipeline] AES IV (hex): \(aesIVHex)")

    guard let aesKey = Data(hexString: aesKeyHex),
      let aesIV = Data(hexString: aesIVHex)
    else {
      print("   ❌ [VidFast.processEncryptionPipeline] Failed to prepare AES keys")
      throw ScraperError.parsingFailed("Failed to prepare AES keys")
    }

    print(
      "   ✅ [VidFast.processEncryptionPipeline] AES keys prepared - Key: \(aesKey.count) bytes, IV: \(aesIV.count) bytes"
    )

    print("   🔒 [VidFast.processEncryptionPipeline] Step 1: Performing AES-256-CBC encryption")
    let aesEncrypted = try performAESCBCEncryption(data: rawData, key: aesKey, iv: aesIV)
    print(
      "   ✅ [VidFast.processEncryptionPipeline] Step 1: AES encryption complete - \(aesEncrypted.count) bytes"
    )

    print("   🔑 [VidFast.processEncryptionPipeline] Preparing XOR key")
    print("   🔑 [VidFast.processEncryptionPipeline] XOR Key (hex): \(xorKeyHex)")

    guard let xorKey = Data(hexString: xorKeyHex) else {
      print("   ❌ [VidFast.processEncryptionPipeline] Failed to prepare XOR key")
      throw ScraperError.parsingFailed("Failed to prepare XOR key")
    }

    print("   ✅ [VidFast.processEncryptionPipeline] XOR key prepared - \(xorKey.count) bytes")

    print("   ⚡ [VidFast.processEncryptionPipeline] Step 2: Performing XOR operation")
    let xorResult = performXOR(data: aesEncrypted, key: xorKey)
    print(
      "   ✅ [VidFast.processEncryptionPipeline] Step 2: XOR complete - \(xorResult.count) bytes")

    print("   📝 [VidFast.processEncryptionPipeline] Step 3: Performing custom Base64 encoding")
    let encoded = customBase64Encode(data: xorResult)
    print(
      "   ✅ [VidFast.processEncryptionPipeline] Step 3: Encoding complete - \(encoded.count) characters"
    )
    print(
      "   📤 [VidFast.processEncryptionPipeline] Final encoded output: \(String(encoded.prefix(100)))..."
    )

    return encoded
  }

  private func performAESCBCEncryption(data: String, key: Data, iv: Data) throws -> Data {
    print("      🔒 [VidFast.performAESCBCEncryption] Starting AES encryption")
    print("      📥 [VidFast.performAESCBCEncryption] Input string length: \(data.count)")

    guard let inputData = data.data(using: .utf8) else {
      print("      ❌ [VidFast.performAESCBCEncryption] Failed to convert string to data")
      throw ScraperError.parsingFailed("Failed to convert string to data")
    }

    print("      ✅ [VidFast.performAESCBCEncryption] Converted to data: \(inputData.count) bytes")

    let paddedData = addPKCS7Padding(data: inputData, blockSize: kCCBlockSizeAES128)
    print(
      "      ✅ [VidFast.performAESCBCEncryption] PKCS7 padding added: \(paddedData.count) bytes")

    let bufferSize = paddedData.count + kCCBlockSizeAES128
    var buffer = Data(count: bufferSize)
    var numBytesEncrypted: size_t = 0

    print("      🔐 [VidFast.performAESCBCEncryption] Calling CCCrypt with:")
    print("         - Algorithm: AES")
    print("         - Mode: CBC")
    print("         - Key size: \(key.count) bytes")
    print("         - IV size: \(iv.count) bytes")
    print("         - Input size: \(paddedData.count) bytes")

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

    print("      📊 [VidFast.performAESCBCEncryption] CCCrypt status: \(cryptStatus)")
    print("      📊 [VidFast.performAESCBCEncryption] Bytes encrypted: \(numBytesEncrypted)")

    guard cryptStatus == kCCSuccess else {
      print(
        "      ❌ [VidFast.performAESCBCEncryption] AES encryption failed with status: \(cryptStatus)"
      )
      throw ScraperError.parsingFailed("AES encryption failed")
    }

    let result = buffer.prefix(numBytesEncrypted)
    print("      ✅ [VidFast.performAESCBCEncryption] Encryption successful: \(result.count) bytes")

    return result
  }

  private func addPKCS7Padding(data: Data, blockSize: Int) -> Data {
    let paddingLength = blockSize - (data.count % blockSize)
    let paddingByte = UInt8(paddingLength)
    print(
      "         📦 [VidFast.addPKCS7Padding] Adding padding: \(paddingLength) bytes (value: \(paddingByte))"
    )
    var paddedData = data
    paddedData.append(contentsOf: [UInt8](repeating: paddingByte, count: paddingLength))
    return paddedData
  }

  private func performXOR(data: Data, key: Data) -> Data {
    print("      ⚡ [VidFast.performXOR] Starting XOR operation")
    print("      📥 [VidFast.performXOR] Data size: \(data.count) bytes")
    print("      🔑 [VidFast.performXOR] Key size: \(key.count) bytes")

    var result = Data(count: data.count)
    for (i, byte) in data.enumerated() {
      result[i] = byte ^ key[i % key.count]
    }

    print("      ✅ [VidFast.performXOR] XOR complete: \(result.count) bytes")
    print(
      "      📊 [VidFast.performXOR] First 16 bytes (hex): \(result.prefix(16).map { String(format: "%02x", $0) }.joined())"
    )

    return result
  }

  private func customBase64Encode(data: Data) -> String {
    print("      📝 [VidFast.customBase64Encode] Starting custom Base64 encoding")
    print("      📥 [VidFast.customBase64Encode] Input data size: \(data.count) bytes")

    let sourceChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
    let targetChars = "MDhk5KB7sdVtpTOE-A80mNa4F9CYfeWo3QzRuZIqcL_SUH1yJibGrvX26xjlPwgn"

    var base64 = data.base64EncodedString()
    print("      📊 [VidFast.customBase64Encode] Standard Base64 length: \(base64.count)")

    base64 = base64.replacingOccurrences(of: "+", with: "-")
    base64 = base64.replacingOccurrences(of: "/", with: "_")
    base64 = base64.replacingOccurrences(of: "=", with: "")

    print("      📊 [VidFast.customBase64Encode] URL-safe Base64 length: \(base64.count)")
    print(
      "      📝 [VidFast.customBase64Encode] URL-safe Base64 preview: \(String(base64.prefix(50)))..."
    )

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

    print(
      "      ✅ [VidFast.customBase64Encode] Custom encoding complete: \(result.count) characters")
    print("      📝 [VidFast.customBase64Encode] Result preview: \(String(result.prefix(50)))...")

    return result
  }
}

// MARK: - Endpoint

private struct VidFastEndpoint: Endpoint {
  let baseURL: String
  let path: String

  var method: HTTPMethod { .get }
  var queryItems: [URLQueryItem]? { nil }
  var headers: [String: String]? {
    [
      "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36",
      "Referer": baseURL + "/",
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language": "en-US,en;q=0.9",
      "X-Requested-With": "XMLHttpRequest",
    ]
  }
  var body: Data? { nil }
}

// MARK: - Data Extension

extension Data {
  init?(hexString: String) {
    let len = hexString.count / 2
    var data = Data(capacity: len)
    var i = hexString.startIndex
    for _ in 0..<len {
      let j = hexString.index(i, offsetBy: 2)
      let bytes = hexString[i..<j]
      if var num = UInt8(bytes, radix: 16) {
        data.append(&num, count: 1)
      } else {
        return nil
      }
      i = j
    }
    self = data
  }
}
