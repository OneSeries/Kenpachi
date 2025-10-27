// AnimeKai.swift
// AnimeKai scraper implementation
// Provides anime content scraping from AnimeKai source

import Foundation
import SwiftSoup

/// AnimeKai scraper implementation
struct AnimeKai: ScraperProtocol {
  /// Scraper name
  let name = "AnimeKai"
  /// Base URL for AnimeKai
  let baseURL = "https://animekai.to"
  /// API endpoint for encryption/decryption
  private let apiURL = "https://enc-dec.app/api"
  /// Supported content types
  let supportedTypes: [ContentType] = [.anime]

  /// Network client for making requests
  private let networkClient: NetworkClientProtocol
  /// Extractor resolver for streaming links
  private let extractorResolver: ExtractorResolver

  /// Initializer
  init(
    networkClient: NetworkClientProtocol = NetworkClient.shared,
    extractorResolver: ExtractorResolver = ExtractorResolver()
  ) {
    self.networkClient = networkClient
    self.extractorResolver = extractorResolver
  }

  // MARK: - Home Content

  /// Fetches home page content by parsing the single home page document.
  /// - Returns: An array of content carousels for different sections.
  func fetchHomeContent() async throws -> [ContentCarousel] {
    let endpoint = AnimeKaiEndpoint(baseURL: baseURL, path: "/home")
    let data = try await networkClient.requestData(endpoint)
    guard let html = String(data: data, encoding: .utf8) else {
      throw ScraperError.parsingFailed("Failed to decode HTML")
    }
    let doc = try SwiftSoup.parse(html)

    var carousels = [ContentCarousel]()

    // 1. Parse the main "Featured" carousel at the top of the page.
    if let featuredCarousel = parseFeaturedCarousel(from: doc) {
      carousels.append(featuredCarousel)
    }

    // 2. Parse the "Latest Updates" section.
    if let latestUpdatesSection = try doc.select("#latest-updates").first(),
      let latestCarousel = parseStandardCarousel(
        from: latestUpdatesSection, title: "Latest Updates")
    {
      carousels.append(latestCarousel)
    }

    // 3. Parse the side-by-side "New Releases" and other sections.
    let listGroupSections = try doc.select(".alist-group .swiper-slide")
    for section in listGroupSections {
      if let title = try? section.select(".shead .stitle").text(),
        let miniCarousel = parseMiniCarousel(from: section, title: title)
      {
        carousels.append(miniCarousel)
      }
    }

    // 4. Parse the "Top Trending" sidebar.
    if let trendingCarousel = parseTrendingSidebar(from: doc) {
      carousels.append(trendingCarousel)
    }

    return carousels
  }

  // MARK: - Parsing Helpers

  /// Parses the main "Featured" hero slider.
  private func parseFeaturedCarousel(from doc: Document) -> ContentCarousel? {
    guard let elements = try? doc.select("#featured .swiper-slide"), !elements.isEmpty() else {
      return nil
    }

    let contents: [Content] = elements.compactMap { element in
      guard let href = try? element.select("a.watch-btn").attr("href"),
        let title = try? element.select("p.title").text()
      else { return nil }
      let style = try? element.attr("style")
      let backdropPath = style?.components(separatedBy: "url(").last?.components(separatedBy: ")")
        .first
      let overview = try? element.select("p.desc").text()
      let japaneseTitle = try? element.select("p.title").attr("data-jp")

      return Content(
        id: href, type: .anime, title: title, originalTitle: japaneseTitle, overview: overview,
        backdropPath: backdropPath, adult: false)
    }
    return ContentCarousel(title: "Featured", items: contents, type: .hero)
  }

  /// Parses a standard content grid, like "Latest Updates".
  private func parseStandardCarousel(from element: Element, title: String) -> ContentCarousel? {
    guard let items = try? element.select(".aitem"), !items.isEmpty() else { return nil }
    let contents = items.compactMap { parseContentElement(from: $0) }
    return ContentCarousel(title: title, items: contents, type: .trending)
  }

  /// Parses a compact list, like "New Releases" or "Completed".
  private func parseMiniCarousel(from element: Element, title: String) -> ContentCarousel? {
    guard let items = try? element.select(".aitem"), !items.isEmpty() else { return nil }
    let contents: [Content] = items.compactMap { item in
      guard let href = try? item.attr("href"),
        let title = try? item.select("h6.title").text(),
        let posterPath = try? item.select(".poster img").attr("data-src")
      else { return nil }
      return Content(id: href, type: .anime, title: title, posterPath: posterPath, adult: false)
    }
    return ContentCarousel(title: title, items: contents, type: .trending)
  }

  /// Parses the "Top Trending" sidebar.
  private func parseTrendingSidebar(from doc: Document) -> ContentCarousel? {
    guard let items = try? doc.select("#trending-anime .aitem"), !items.isEmpty() else {
      return nil
    }
    let contents: [Content] = items.compactMap { item in
      guard let href = try? item.attr("href"),
        let title = try? item.select(".detail .title").text()
      else { return nil }
      let style = try? item.attr("style")
      let posterPath = style?.components(separatedBy: "url(").last?.components(separatedBy: ")")
        .first
      return Content(id: href, type: .anime, title: title, posterPath: posterPath, adult: false)
    }
    return ContentCarousel(title: "Top Trending", items: contents, type: .trending)
  }

  /// Generic parser for a standard anime item card.
  private func parseContentElement(from element: Element) -> Content? {
    guard let href = try? element.select("a.poster").attr("href"),
      let title = try? element.select("a.title").text(),
      let posterUrl = try? element.select("a.poster img").attr("data-src")
    else { return nil }
    return Content(
      id: href, type: .anime, title: title,
      posterPath: posterUrl.hasPrefix("http") ? posterUrl : "\(baseURL)\(posterUrl)", adult: false)
  }

  // MARK: - Search

  func search(query: String, page: Int = 1) async throws -> ContentSearchResult {
    let searchURL =
      "\(baseURL)/browser?keyword=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
    let endpoint = AnimeKaiEndpoint(baseURL: baseURL, path: searchURL)
    let data = try await networkClient.requestData(endpoint)
    guard let html = String(data: data, encoding: .utf8) else {
      throw ScraperError.parsingFailed("Failed to decode HTML")
    }
    let doc = try SwiftSoup.parse(html)
    let items = try doc.select("div.aitem-wrapper div.aitem")
    let contents: [Content] = items.compactMap { parseContentElement(from: $0) }
    return ContentSearchResult(
      id: "animekai-search-\(query)-\(page)", contents: contents, page: page, totalPages: 1)
  }

  // MARK: - Details & Streaming

  /// Fetches detailed information for a specific anime, including its full episode list.
  /// This method performs multiple network requests: main page, ani.zip metadata, and episode list.
  /// - Parameter id: The content identifier, which is the URL path (e.g., "/watch/one-piece-dk6r").
  /// - Returns: A detailed `Content` object including seasons and episodes.
  func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
    let endpoint = AnimeKaiEndpoint(baseURL: baseURL, path: id)
    let data = try await networkClient.requestData(endpoint)
    guard let html = String(data: data, encoding: .utf8) else {
      throw ScraperError.parsingFailed("Failed to decode HTML")
    }
    let doc = try SwiftSoup.parse(html)

    guard let title = try? doc.select("h1.title").text() else {
      throw ScraperError.contentNotFound
    }

    // --- Parse Main Details ---
    let watchSection = try? doc.select("div.watch-section").first()
    _ = try? watchSection?.attr("data-mal-id")
    let anilistId = try? watchSection?.attr("data-al-id")

    let posterUrl = try? doc.select("div.poster img").attr("src")
    let overview = try? doc.select("div.desc").text()
    let japaneseTitle = try? doc.select("h1.title").attr("data-jp")

    // --- Fetch metadata from ani.zip ---
    var backdropPath: String? = nil
    if let aniId = anilistId, !aniId.isEmpty {
      backdropPath = try? await fetchAniZipBackdrop(anilistId: aniId)
    }

    // Fallback to local backdrop if ani.zip fails
    if backdropPath == nil {
      let backdropStyle = try? doc.select(".anisc-poster img").attr("src")
      backdropPath = backdropStyle
    }

    // --- Parse Metadata from the Detail Block ---
    let detailBlock = try doc.select("div.detail").first()
    let genreElements = try? detailBlock?.select("a[href*='/genres/']")
    let genreNames = (try? genreElements?.compactMap { try $0.text() }) ?? []
    let genres = genreNames.enumerated().map { index, name in Genre(id: index, name: name) }
    let status = try? doc.select("div:containsOwn(Status) span").first()?.text()
      .trimmingCharacters(in: .whitespaces)

    // --- Parse episode counts ---
    let subCount = try? doc.select("#main-entity div.info span.sub").first()?.text()
    let dubCount = try? doc.select("#main-entity div.info span.dub").first()?.text()
    let subEpisodeCount = subCount.flatMap { Int($0) }
    let dubEpisodeCount = dubCount.flatMap { Int($0) }

    // --- Fetch Episodes via AJAX ---
    var seasons: [Season]? = nil
    if let animeId = try? doc.select("div.rate-box").first()?.attr("data-id"), !animeId.isEmpty {
      print("Found anime_id: \(animeId). Fetching episodes...")
      seasons = try? await fetchEpisodes(
        for: animeId, subCount: subEpisodeCount, dubCount: dubEpisodeCount, anilistId: anilistId)
    }

    // --- Parse recommendations ---
    let recommendationElements = try? doc.select("div.aitem-col a")
    let recommendations = recommendationElements?.compactMap { element -> Content? in
      guard let href = try? element.attr("href"),
        let recTitle = try? element.select(".title").text(),
        let recPoster = try? element.select("img").attr("src")
      else { return nil }
      return Content(id: href, type: .anime, title: recTitle, posterPath: recPoster, adult: false)
    }

    // --- Final Assembly ---
    return Content(
      id: id, type: .anime, title: title, originalTitle: japaneseTitle,
      overview: overview, posterPath: posterUrl, backdropPath: backdropPath,
      genres: genres.isEmpty ? nil : genres, adult: false, status: status,
      seasons: seasons, recommendations: recommendations
    )
  }

  /// Fetches backdrop image from ani.zip API
  private func fetchAniZipBackdrop(anilistId: String) async throws -> String? {
    let aniZipURL = "https://api.ani.zip/mappings?anilist_id=\(anilistId)"
    let endpoint = AnimeKaiEndpoint(baseURL: "", path: aniZipURL)

    struct AniZipImage: Decodable {
      let coverType: String
      let url: String
    }

    struct AniZipResponse: Decodable {
      let images: [AniZipImage]?
    }

    guard let response: AniZipResponse = try? await networkClient.request(endpoint),
      let images = response.images
    else {
      return nil
    }

    return images.first(where: { $0.coverType == "Fanart" })?.url
  }

  /// Fetches the episode list for a given internal anime ID via an AJAX request.
  /// - Parameters:
  ///   - animeId: The internal ID found on the watch page
  ///   - subCount: Number of subbed episodes
  ///   - dubCount: Number of dubbed episodes
  ///   - anilistId: AniList ID for fetching metadata
  /// - Returns: An array of seasons (sub and dub) populated with episodes.
  private func fetchEpisodes(
    for animeId: String, subCount: Int?, dubCount: Int?, anilistId: String?
  ) async throws -> [Season] {
    // Get decoded token (simulating the BuildConfig.KAISVA endpoint)
    // Note: In production, you'd need to implement the actual decoding endpoint
    let decoded = try? await fetchDecodedToken(animeId: animeId)

    // Construct the AJAX URL for the episode list with decoded token
    var episodesURL = "/ajax/episodes/list?ani_id=\(animeId)"
    if let decodedToken = decoded {
      episodesURL += "&_=\(decodedToken)"
    }
    let endpoint = AnimeKaiEndpoint(baseURL: baseURL, path: episodesURL, referer: "\(baseURL)/")

    let data = try await networkClient.requestData(endpoint)

    // Decode the standard AJAX response which wraps HTML content in a JSON object.
    struct AjaxResponse: Decodable {
      let status: Bool
      let result: String  // HTML content
    }

    let response = try JSONDecoder().decode(AjaxResponse.self, from: data)
    guard response.status else {
      throw ScraperError.parsingFailed("AJAX request for episodes failed (status: false)")
    }

    // Parse the HTML result to extract episode information.
    let doc = try SwiftSoup.parse(response.result)
    let episodeElements = try doc.select("div.eplist a")

    var subEpisodes: [Episode] = []
    var dubEpisodes: [Episode] = []

    for (index, element) in episodeElements.enumerated() {
      guard let token = try? element.attr("data-token") else { continue }

      let episodeNum = index + 1
      let episodeTitle =
        (try? element.select("span").text()) ?? (try? element.attr("title"))
        ?? "Episode \(episodeNum)"

      // Create sub episode if within sub count
      if let subTotal = subCount, index < subTotal {
        let subEpisode = Episode(
          id: "sub|\(token)",
          episodeNumber: episodeNum,
          seasonNumber: 1,
          name: episodeTitle
        )
        subEpisodes.append(subEpisode)
      }

      // Create dub episode if within dub count
      if let dubTotal = dubCount, index < dubTotal {
        let dubEpisodeNum = (try? element.attr("num")).flatMap { Int($0) } ?? episodeNum
        let dubEpisode = Episode(
          id: "dub|\(token)",
          episodeNumber: dubEpisodeNum,
          seasonNumber: 2,
          name: episodeTitle
        )
        dubEpisodes.append(dubEpisode)
      }
    }

    var seasons: [Season] = []

    // Add sub season if episodes exist
    if !subEpisodes.isEmpty {
      let subSeason = Season(
        id: "\(animeId)-sub",
        seasonNumber: 1,
        name: "Subbed",
        episodeCount: subEpisodes.count,
        episodes: subEpisodes
      )
      seasons.append(subSeason)
    }

    // Add dub season if episodes exist
    if !dubEpisodes.isEmpty {
      let dubSeason = Season(
        id: "\(animeId)-dub",
        seasonNumber: 2,
        name: "Dubbed",
        episodeCount: dubEpisodes.count,
        episodes: dubEpisodes
      )
      seasons.append(dubSeason)
    }

    return seasons
  }

  /// Encrypts text using AnimeKai encryption service
  private func encryptKai(_ text: String) async throws -> String {
    guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: "\(apiURL)/enc-kai?text=\(encodedText)") else {
      throw ScraperError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    
    struct EncryptResponse: Decodable {
      let result: String
    }
    
    let response = try JSONDecoder().decode(EncryptResponse.self, from: data)
    return response.result
  }
  
  /// Decrypts text using AnimeKai decryption service
  private func decryptKai(_ text: String) async throws -> String {
    guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: "\(apiURL)/dec-kai?text=\(encodedText)") else {
      throw ScraperError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    
    struct DecryptResponse: Decodable {
      let result: String
    }
    
    let response = try JSONDecoder().decode(DecryptResponse.self, from: data)
    return response.result
  }
  
  /// Fetches decoded token for episode list request
  private func fetchDecodedToken(animeId: String) async throws -> String? {
    return try? await encryptKai(animeId)
  }
  func extractStreamingLinks(contentId: String, seasonId: String? = nil, episodeId: String? = nil)
    async throws -> [ExtractedLink]
  {
    guard let episodeToken = episodeId else { throw ScraperError.missingEpisodeInfo }
    
    // Encrypt the token for the request
    let encryptedToken = try await encryptKai(episodeToken)
    let linksURL = "\(baseURL)/ajax/links/list?token=\(episodeToken)&_=\(encryptedToken)"
    let linksEndpoint = AnimeKaiEndpoint(baseURL: baseURL, path: linksURL, referer: baseURL)
    let linksData = try await networkClient.requestData(linksEndpoint)

    struct LinksResponse: Decodable {
      let status: Bool
      let result: String
    }
    let response = try JSONDecoder().decode(LinksResponse.self, from: linksData)
    let doc = try SwiftSoup.parse(response.result)
    let servers = try doc.select("div.server-items span.server[data-lid]")

    var allLinks: [ExtractedLink] = []
    for server in servers {
      guard let lid = try? server.attr("data-lid"), let serverName = try? server.text() else {
        continue
      }
      
      // Encrypt the lid for the view request
      let encryptedLid = try await encryptKai(lid)
      let viewURL = "\(baseURL)/ajax/links/view?id=\(lid)&_=\(encryptedLid)"
      let viewEndpoint = AnimeKaiEndpoint(baseURL: baseURL, path: viewURL, referer: baseURL)
      let viewData = try await networkClient.requestData(viewEndpoint)
      guard let viewResponse = try? JSONDecoder().decode(LinksResponse.self, from: viewData) else {
        continue
      }
      
      // Decrypt the response
      let decryptedResult = try await decryptKai(viewResponse.result)
      guard let iframeURL = extractIframeURL(from: decryptedResult) else { continue }

      // Use a task to allow for concurrent extraction from multiple servers.
      let extractedLinks = try await extractorResolver.extract(from: iframeURL)
      allLinks.append(contentsOf: extractedLinks.map { $0.withServer("AnimeKai - \(serverName)") })
    }
    return allLinks
  }

  private func extractIframeURL(from jsonString: String) -> String? {
    guard let data = jsonString.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let url = json["url"] as? String
    else { return nil }
    return url
  }
}

// MARK: - Endpoint

/// Generic endpoint for AnimeKai requests.
private struct AnimeKaiEndpoint: Endpoint {
  let baseURL: String
  let path: String
  var referer: String? = nil

  var method: HTTPMethod { .get }
  var queryItems: [URLQueryItem]? { nil }
  var headers: [String: String]? {
    var h: [String: String] = [
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    ]
    if let referer = referer { h["Referer"] = referer }
    return h
  }
  var body: Data? { nil }
}

// MARK: - Helper Extensions

extension ExtractedLink {
  /// Helper to create a new link with an updated server name.
  func withServer(_ name: String) -> ExtractedLink {
    return ExtractedLink(
      id: self.id,
      url: self.url,
      quality: self.quality,
      server: name,
      requiresReferer: self.requiresReferer,
      headers: self.headers,
      type: self.type
    )
  }
}
