// HiAnime.swift
// HiAnime scraper implementation
// Provides anime content scraping from HiAnime source

import Foundation
import SwiftSoup

/// HiAnime scraper implementation
struct HiAnime: ScraperProtocol {
  /// Scraper name
  let name = "HiAnime"
  /// Base URL for HiAnime
  let baseURL = "https://hianime.to"
  /// Supported content types
  let supportedTypes: [ContentType] = [.anime]

  /// Network client for making requests
  private let networkClient: NetworkClientProtocol
  /// Extractor resolver for streaming links
  private let extractorResolver: ExtractorResolver

  /// Initializer
  /// - Parameters:
  ///   - networkClient: Network client instance
  ///   - extractorResolver: Extractor resolver instance
  init(
    networkClient: NetworkClientProtocol = NetworkClient.shared,
    extractorResolver: ExtractorResolver = ExtractorResolver()
  ) {
    self.networkClient = networkClient
    self.extractorResolver = extractorResolver
  }

  /// Fetches home page content
  /// - Returns: Array of content carousels
  func fetchHomeContent() async throws -> [ContentCarousel] {
    let endpoint = HiAnimeEndpoint(baseURL: baseURL, path: "/home")
    let html = try await networkClient.requestData(endpoint)
    let htmlString = String(data: html, encoding: .utf8) ?? ""

    let doc = try HTMLParser.parse(htmlString)
    let elements = HTMLParser.extractElements(from: doc, selector: ".film_list-wrap .flw-item")

    let contents: [Content] = elements.compactMap { element in
      guard let title = HTMLParser.extractText(from: element, selector: ".film-name a"),
        let href = HTMLParser.extractAttribute(
          from: element, selector: ".film-poster a", attribute: "href"),
        let id = href.components(separatedBy: "/").last
      else {
        return nil
      }

      let posterPath = HTMLParser.extractAttribute(
        from: element, selector: ".film-poster img", attribute: "data-src")
      let year = HTMLParser.extractText(from: element, selector: ".fdi-item:first-child")
      let description = HTMLParser.extractText(
        from: element, selector: ".film-infor .description")

      return Content(
        id: "hianime-\(id)",
        type: .anime,
        title: title,
        overview: description,
        posterPath: posterPath,
        releaseDate: year.flatMap { Int($0) }.flatMap { year in
          DateComponents(calendar: Calendar.current, year: year).date
        },
        adult: false
      )
    }

    // Create a single carousel for trending content
    return [
      ContentCarousel(
        title: "Trending on HiAnime",
        items: contents,
        type: .trending
      )
    ]
  }

  /// Searches for anime
  /// - Parameters:
  ///   - query: Search query string
  ///   - page: Page number for pagination (default is 1)
  /// - Returns: Search result containing matching content
  func search(query: String, page: Int = 1) async throws -> ContentSearchResult {
    let searchPath =
      "/search?keyword=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&page=\(page)"
    let endpoint = HiAnimeEndpoint(baseURL: baseURL, path: searchPath)
    let html = try await networkClient.requestData(endpoint)
    let htmlString = String(data: html, encoding: .utf8) ?? ""

    let doc = try HTMLParser.parse(htmlString)
    let elements = HTMLParser.extractElements(from: doc, selector: ".film_list-wrap .flw-item")

    let contents: [Content] = elements.compactMap { element in
      guard let title = HTMLParser.extractText(from: element, selector: ".film-name a"),
        let href = HTMLParser.extractAttribute(
          from: element, selector: ".film-poster a", attribute: "href"),
        let id = href.components(separatedBy: "/").last
      else {
        return nil
      }

      let posterPath = HTMLParser.extractAttribute(
        from: element, selector: ".film-poster img", attribute: "data-src")
      let year = HTMLParser.extractText(from: element, selector: ".fdi-item:first-child")
      let description = HTMLParser.extractText(
        from: element, selector: ".film-infor .description")

      return Content(
        id: "hianime-\(id)",
        type: .anime,
        title: title,
        overview: description,
        posterPath: posterPath,
        releaseDate: year.flatMap { Int($0) }.flatMap { year in
          DateComponents(calendar: Calendar.current, year: year).date
        },
        adult: false
      )
    }

    // Extract pagination information if available
    let totalPages = 1  // Default to 1 page
    let totalResults = contents.count  // Default to contents count

    // Return a ContentSearchResult with the search results
    return ContentSearchResult(
      id: "hianime-search-\(query)-\(page)",
      contents: contents,
      totalResults: totalResults,
      page: page,
      totalPages: totalPages
    )
  }

  /// Fetches content details
  /// - Parameter id: Content identifier
  /// - Returns: Detailed content information
  func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
    let cleanId = id.replacingOccurrences(of: "hianime-", with: "")
    let endpoint = HiAnimeEndpoint(baseURL: baseURL, path: "/\(cleanId)")
    let html = try await networkClient.requestData(endpoint)
    let htmlString = String(data: html, encoding: .utf8) ?? ""

    let doc = try HTMLParser.parse(htmlString)

    guard let title = HTMLParser.extractText(from: doc, selector: ".heading-name") else {
      throw ScraperError.contentNotFound
    }

    let overview = HTMLParser.extractText(from: doc, selector: ".description")
    let posterPath = HTMLParser.extractAttribute(
      from: doc, selector: ".film-poster img", attribute: "src")
    let backdropPath = HTMLParser.extractAttribute(
      from: doc, selector: ".cover_follow", attribute: "style")?
      .components(separatedBy: "url(").last?
      .components(separatedBy: ")").first

    _ = HTMLParser.extractText(from: doc, selector: ".fdi-type")
    let type: ContentType = .anime  // HiAnime is specifically for anime

    _ = HTMLParser.extractText(from: doc, selector: ".fdi-item:contains(Released)")
    let ratingText = HTMLParser.extractText(from: doc, selector: ".fs-item .imdb")

    return Content(
      id: id,
      type: type,
      title: title,
      overview: overview,
      posterPath: posterPath,
      backdropPath: backdropPath,
      voteAverage: Double(ratingText ?? "0"),
      adult: false
    )
  }

  /// Extracts streaming links
  /// - Parameters:
  ///   - contentId: Content identifier (required)
  ///   - seasonId: Season identifier (optional, for anime)
  ///   - episodeId: Episode identifier (optional, for anime)
  /// - Returns: Array of extracted streaming links
  func extractStreamingLinks(contentId: String, seasonId: String? = nil, episodeId: String? = nil)
    async throws -> [ExtractedLink]
  {
    // HiAnime implementation would go here
    return []
  }
}

/// HiAnime endpoint
private struct HiAnimeEndpoint: Endpoint {
  let baseURL: String
  let path: String

  var method: HTTPMethod { .get }
  var queryItems: [URLQueryItem]? { nil }
  var headers: [String: String]? {
    ["User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"]
  }
  var body: Data? { nil }
}
