// FlixHQ.swift
// FlixHQ scraper implementation
// Provides content scraping from FlixHQ source

import Foundation
import SwiftSoup

/// A scraper for the FlixHQ website, capable of fetching home page content, searching,
/// getting content details, and extracting streaming links.
struct FlixHQ: ScraperProtocol {
  /// The display name of the scraper.
  let name = "FlixHQ"
  /// The base URL of the FlixHQ website.
  let baseURL = "https://flixhq.to"
  /// The content types supported by this scraper.
  let supportedTypes: [ContentType] = [.movie, .tvShow]

  /// The network client used for making HTTP requests.
  private let networkClient: NetworkClientProtocol
  /// The resolver used to extract direct streaming links from embed URLs.
  private let extractorResolver: ExtractorResolver

  /// Initializes the scraper with optional network and extractor dependencies.
  /// - Parameters:
  ///   - networkClient: An object conforming to `NetworkClientProtocol` for network requests.
  ///   - extractorResolver: An `ExtractorResolver` instance for handling video extraction.
  init(
    networkClient: NetworkClientProtocol = NetworkClient.shared,
    extractorResolver: ExtractorResolver = ExtractorResolver()
  ) {
    self.networkClient = networkClient
    self.extractorResolver = extractorResolver
  }

  // MARK: - Home Content

  /// Fetches the main content displayed on the home page, organized into carousels.
  /// - Returns: An array of `ContentCarousel` objects representing sections like "Featured", "Trending", etc.
  /// - Throws: A `ScraperError` if the network request or parsing fails.
  func fetchHomeContent() async throws -> [ContentCarousel] {
    let endpoint = FlixHQEndpoint(baseURL: baseURL, path: "/home")
    let html = try await networkClient.requestData(endpoint)
    let doc = try HTMLParser.parse(String(data: html, encoding: .utf8) ?? "")
    var carousels = [ContentCarousel]()

    // 1. Parse and add the main "Featured" carousel from the top slider.
    if let featuredCarousel = parseFeaturedCarousel(from: doc) {
      carousels.append(featuredCarousel)
    }

    // 2. Parse the "Trending" movies and TV shows sections.
    let trendingMovieElements = HTMLParser.extractElements(
      from: doc, selector: "#trending-movies .flw-item")
    let trendingMovies = trendingMovieElements.compactMap { parseContentElement($0, type: .movie) }

    let trendingTVElements = HTMLParser.extractElements(
      from: doc, selector: "#trending-tv .flw-item")
    let trendingTV = trendingTVElements.compactMap { parseContentElement($0, type: .tvShow) }

    // 3. Parse "Latest" sections by iterating through all content blocks and identifying them by their heading text.
    // This is more robust than relying on CSS IDs which can be duplicated or incorrect.
    var latestMovies: [Content] = []
    var latestTV: [Content] = []
    let contentSections = try doc.select("section.block_area_home")
    for section in contentSections {
      guard let heading = try section.select("h2.cat-heading").first()?.text() else { continue }
      if heading == "Latest Movies" {
        let elements = try section.select(".film_list-wrap .flw-item")
        latestMovies = elements.compactMap { parseContentElement($0, type: .movie) }
      } else if heading == "Latest TV Shows" {
        let elements = try section.select(".film_list-wrap .flw-item")
        latestTV = elements.compactMap { parseContentElement($0, type: .tvShow) }
      }
    }

    // 4. Assemble and append the remaining carousels to the final array.
    carousels.append(contentsOf: [
      ContentCarousel(title: "Trending Movies", items: trendingMovies, type: .trending),
      ContentCarousel(title: "Trending TV Shows", items: trendingTV, type: .trending),
      ContentCarousel(title: "Latest Movies", items: latestMovies, type: .recent),
      ContentCarousel(title: "Latest TV Shows", items: latestTV, type: .recent),
    ])
    return carousels
  }

  // MARK: - Parsing Helpers

  /// Parses the featured content carousel from the main slider on the home page.
  /// - Parameter doc: The parsed HTML `Document` of the home page.
  /// - Returns: A `ContentCarousel` for the featured items, or `nil` if none are found.
  private func parseFeaturedCarousel(from doc: Document) -> ContentCarousel? {
    // Selector for each slide in the main hero slider.
    let featuredElements = HTMLParser.extractElements(from: doc, selector: "#slider .swiper-slide")

    let featuredItems: [Content] = featuredElements.compactMap { element in
      guard
        var id = HTMLParser.extractAttribute(
          from: element, selector: "a.slide-link", attribute: "href"),
        let title = HTMLParser.extractText(from: element, selector: "h3.film-title a")
      else {
        return nil
      }
      // Clean the ID to be a relative path (e.g., "tv/watch-name-id").
      if id.hasPrefix("/") { id.removeFirst() }
      let type: ContentType = id.starts(with: "tv/") ? .tvShow : .movie
      let overview = HTMLParser.extractText(from: element, selector: "p.sc-desc")
      // The backdrop image URL is embedded in an inline `style` attribute.
      let styleAttribute = try? element.attr("style")
      let backdropPath = styleAttribute?.components(separatedBy: "url(").last?.components(
        separatedBy: ")"
      ).first
      return Content(
        id: id, type: type, title: title, overview: overview, backdropPath: backdropPath,
        adult: false)
    }
    guard !featuredItems.isEmpty else { return nil }
    return ContentCarousel(title: "Featured", items: featuredItems, type: .hero)
  }

  /// Parses a standard content item card (used in home page sections, search results, and recommendations).
  /// - Parameters:
  ///   - element: The HTML `Element` representing the content card.
  ///   - type: The `ContentType` (.movie or .tvShow) to assign to the parsed content.
  /// - Returns: A `Content` object, or `nil` if parsing fails.
  private func parseContentElement(_ element: Element, type: ContentType) -> Content? {
    guard let title = HTMLParser.extractText(from: element, selector: ".film-name a"),
      var id = HTMLParser.extractAttribute(
        from: element, selector: ".film-poster a", attribute: "href")
    else {
      return nil
    }
    // Clean the ID to be a relative path.
    if id.hasPrefix("/") { id.removeFirst() }
    // Handle lazy-loaded images by prioritizing `data-src` over `src`.
    let posterPath =
      HTMLParser.extractAttribute(
        from: element, selector: ".film-poster img", attribute: "data-src")
      ?? HTMLParser.extractAttribute(from: element, selector: ".film-poster img", attribute: "src")
    // Parse the year, ensuring it's a 4-digit number.
    let yearText = HTMLParser.extractText(from: element, selector: ".fdi-item:first-child")
    let year = yearText.flatMap { text -> Int? in text.count == 4 ? Int(text) : nil }
    var releaseDate: Date? = nil
    if let validYear = year {
      releaseDate = DateComponents(calendar: .current, year: validYear).date
    }
    return Content(
      id: id, type: type, title: title, posterPath: posterPath, releaseDate: releaseDate,
      adult: false)
  }

  /// Parses the "You May Also Like" section from a content details page.
  /// - Parameter doc: The parsed HTML `Document` of the details page.
  /// - Returns: An array of recommended `Content` objects.
  private func parseRecommendations(from doc: Document) throws -> [Content] {
    let recommendationElements = HTMLParser.extractElements(
      from: doc, selector: ".film-related .flw-item")
    return recommendationElements.compactMap { element in
      guard let href = HTMLParser.extractAttribute(from: element, selector: "a", attribute: "href")
      else { return nil }
      let type: ContentType = href.contains("/tv/") ? .tvShow : .movie
      return parseContentElement(element, type: type)
    }
  }

  // MARK: - Search

  /// Searches for content with pagination support.
  /// - Parameters:
  ///   - query: The search term.
  ///   - page: The page number to fetch.
  /// - Returns: A `ContentSearchResult` object containing the results and pagination info.
  /// - Throws: A `ScraperError` if the network request or parsing fails.
  func search(query: String, page: Int = 1) async throws -> ContentSearchResult {
    let searchPath: String =
      "/search/\(query.replacingOccurrences(of: " ", with: "-").addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query.replacingOccurrences(of: " ", with: "-"))"
    let queryItems: [URLQueryItem]? =
      page > 1 ? [URLQueryItem(name: "page", value: "\(page)")] : nil
    let endpoint = FlixHQEndpoint(baseURL: baseURL, path: searchPath, queryItems: queryItems)
    let html = try await networkClient.requestData(endpoint)
    let doc = try HTMLParser.parse(String(data: html, encoding: .utf8) ?? "")

    // Parse the list of content items from the search results.
    let elements = HTMLParser.extractElements(from: doc, selector: ".film_list-wrap .flw-item")
    let contents: [Content] = elements.compactMap { element in
      let typeText = HTMLParser.extractText(from: element, selector: ".fdi-type")
      let type: ContentType = typeText?.lowercased().contains("tv") == true ? .tvShow : .movie
      return parseContentElement(element, type: type)
    }

    // --- Pagination Parsing Logic ---
    var currentPage = page
    var totalPages = 1
    // Get the current page from the 'active' pagination element.
    if let activePageText = try? doc.select(
      ".pagination .page-item.active a, .pagination .page-item.active span"
    ).text(), let activePage = Int(activePageText) {
      currentPage = activePage
      totalPages = max(totalPages, currentPage)
    }
    // Get the total number of pages from the "Last" button's link.
    if let lastPageHref = try? doc.select(".pagination a[title=Last], .pagination a[title='Last']")
      .attr("href"),
      let urlComponents = URLComponents(string: lastPageHref),
      let pageQueryItem = urlComponents.queryItems?.first(where: { $0.name == "page" }),
      let pageValue = pageQueryItem.value, let lastPage = Int(pageValue)
    {
      totalPages = lastPage
    } else {
      // Fallback: if no "Last" button, find the highest visible page number.
      let pageLinks = try doc.select(".pagination .page-item a.page-link")
      let pageNumbers = pageLinks.compactMap { try? Int($0.text()) }
      if let maxPage = pageNumbers.max() { totalPages = max(totalPages, maxPage) }
    }

    return ContentSearchResult(
      id: "\(query)-\(page)", contents: contents, totalResults: 0, page: currentPage,
      totalPages: totalPages)
  }

  // MARK: - Content Details

  /// Fetches detailed information for a specific movie or TV show.
  /// - Parameter id: The relative path of the content (e.g., "tv/watch-peacemaker-76321").
  /// - Returns: A detailed `Content` object.
  /// - Throws: A `ScraperError` if the content is not found or parsing fails.
  func fetchContentDetails(id: String, type: ContentType?) async throws -> Content {
    let endpoint = FlixHQEndpoint(baseURL: baseURL, path: "/\(id)")
    let html = try await networkClient.requestData(endpoint)
    let doc = try HTMLParser.parse(String(data: html, encoding: .utf8) ?? "")

    guard let title = HTMLParser.extractText(from: doc, selector: "h2.heading-name") else {
      throw ScraperError.contentNotFound
    }

    // --- Main Details ---
    let overview = HTMLParser.extractText(from: doc, selector: ".description")
    let posterPath = HTMLParser.extractAttribute(
      from: doc, selector: ".film-poster-img", attribute: "src")
    let backdropPath = HTMLParser.extractAttribute(
      from: doc, selector: ".w_b-cover", attribute: "style")?.components(separatedBy: "url(").last?
      .components(separatedBy: ")").first
    let type: ContentType = id.starts(with: "tv/") ? .tvShow : .movie

    // --- Stats Block (Rating, Duration) ---
    let ratingText = try? doc.select(".stats .item:has(i.fa-star)").first()?.text()
    let rating = ratingText.flatMap { Double($0.trimmingCharacters(in: .whitespaces)) }
    let duration = HTMLParser.extractText(from: doc, selector: ".stats .item:contains(min)")

    // --- Elements Block (Directly select each item without a helper function) ---
    let elementsBlock = try doc.select(".elements").first()
    let country = try? elementsBlock?.select(".row-line:has(span:contains(Country)) a").first()?
      .text()
    let genres: [String] =
      (try? elementsBlock?.select(".row-line:has(span:contains(Genre)) a").compactMap {
        try? $0.text()
      }) ?? []
    let production: [String] =
      (try? elementsBlock?.select(".row-line:has(span:contains(Production)) a").compactMap {
        try? $0.text()
      }) ?? []
    let casts: [String] =
      (try? elementsBlock?.select(".row-line:has(span:contains(Casts)) a").compactMap {
        try? $0.text()
      }) ?? []

    // Parse release date separately.
    var releaseDate: Date? = nil
    if let releaseRowText = try? doc.select(".row-line:has(span:contains(Released))").text() {
      let dateString = releaseRowText.replacingOccurrences(of: "Released:", with: "")
        .trimmingCharacters(in: .whitespaces)
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      releaseDate = formatter.date(from: dateString)
    }

    // --- Recommendations ---
    let recommendations = try parseRecommendations(from: doc)

    // --- Seasons & Episodes (for TV Shows) ---
    var seasons: [Season]? = nil
    if type == .tvShow {
      guard
        let uid = HTMLParser.extractAttribute(
          from: doc, selector: ".watch_block", attribute: "data-id")
      else {
        throw ScraperError.parsingFailed("Could not find content UID for fetching seasons.")
      }
      seasons = try await fetchSeasonsAndEpisodes(for: uid)
    }

    // --- Final Assembly ---
    let genreObjects = genres.enumerated().map { (index, name) in Genre(id: index, name: name) }
    let castObjects = casts.enumerated().map { (index, name) in Cast(id: index, name: name) }

    return Content(
      id: id,
      type: type,
      title: title,
      overview: overview,
      posterPath: posterPath,
      backdropPath: backdropPath,
      releaseDate: releaseDate,
      voteAverage: rating,
      genres: genreObjects,
      adult: false,
      productionCompanies: production,
      seasons: seasons,
      cast: castObjects,
      country: country,
      duration: duration,
      recommendations: recommendations
    )
  }

  /// Fetches all seasons and their episodes for a given TV show's numeric ID via AJAX requests.
  /// - Parameter tvNumericId: The internal numeric ID of the TV show.
  /// - Returns: An array of `Season` objects, each populated with its episodes.
  private func fetchSeasonsAndEpisodes(for tvNumericId: String) async throws -> [Season] {
    // 1. Fetch Season List using the correct `v2` AJAX endpoint.
    let seasonsEndpoint = FlixHQEndpoint(
      baseURL: baseURL, path: "/ajax/v2/tv/seasons/\(tvNumericId)")
    let seasonsHtmlData = try await networkClient.requestData(seasonsEndpoint)
    let seasonsDoc = try await MainActor.run { try HTMLParser.parse(String(data: seasonsHtmlData, encoding: .utf8) ?? "") }
    // In the response, season links are `<a>` tags inside the dropdown menu.
    let seasonElements = await MainActor.run { HTMLParser.extractElements(from: seasonsDoc, selector: ".dropdown-menu a") }

    // 2. Fetch Episodes for each season concurrently using a TaskGroup for performance.
    return try await withThrowingTaskGroup(of: Season.self) { group in
      var seasons: [Season] = []

      // A simple counter is reliable for determining the season number, as seen in the TS example.
      for (index, seasonElement) in seasonElements.enumerated() {
        guard let seasonId = try? await MainActor.run(body: { try seasonElement.attr("data-id") }) else { continue }
        let seasonNumber = index + 1

        // Add a new asynchronous task to the group for each season.
        group.addTask {
          // Fetch episodes using the correct `v2` AJAX endpoint.
          let episodesEndpoint = FlixHQEndpoint(
            baseURL: self.baseURL, path: "/ajax/v2/season/episodes/\(seasonId)")
          let episodesHtmlData = try await self.networkClient.requestData(episodesEndpoint)
          let episodesDoc = try await MainActor.run { try HTMLParser.parse(
            String(data: episodesHtmlData, encoding: .utf8) ?? "") }

          // In the new response, episode items are `<li>` tags inside a `.nav`.
          let episodeElements = await MainActor.run { HTMLParser.extractElements(from: episodesDoc, selector: ".nav > li") }

          let episodes = try await MainActor.run {
            episodeElements.compactMap { el -> Episode? in
              guard let aTag = try? el.select("a").first(),
                // The numeric ID is parsed from the element's `id` attribute (e.g., "episode-12345").
                let rawId = try? aTag.attr("id"),
                let episodeId = rawId.components(separatedBy: "-").last,
                let titleAttr = try? aTag.attr("title")
              else {
                return nil
              }
              // Logic to parse "Eps X: Title" format.
              let parts = titleAttr.components(separatedBy: ":")
              let epNumberStr =
                parts.first?.replacingOccurrences(of: "Eps", with: "").trimmingCharacters(
                  in: .whitespaces) ?? ""
              let epName =
                parts.count > 1
                ? parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                : titleAttr
              guard let episodeNumber = Int(epNumberStr) else { return nil }

              return Episode(
                id: episodeId, episodeNumber: episodeNumber, seasonNumber: seasonNumber, name: epName)
            }
          }
          let seasonName = "Season \(seasonNumber)"
          return Season(
            id: seasonId, seasonNumber: seasonNumber, name: seasonName,
            episodeCount: episodes.count, episodes: episodes)
        }
      }
      // Collect the results from all completed tasks.
      for try await season in group { seasons.append(season) }
      // Sort the seasons by number before returning.
      return seasons.sorted { $0.seasonNumber < $1.seasonNumber }
    }
  }

  // MARK: - Streaming Links

  /// Extracts direct streaming links for a movie or a specific TV show episode.
  /// This method uses the correct v2 endpoints for TV shows and handles movies appropriately.
  /// - Parameters:
  ///   - contentId: The relative path of the content (required, e.g., "movie/watch-the-matrix-123").
  ///   - seasonId: Season identifier (optional, not used by FlixHQ - uses episodeId directly)
  ///   - episodeId: For TV shows, the numeric ID of the episode. For movies, this is `nil`.
  /// - Returns: An array of `ExtractedLink` objects with video URLs.
  /// - Throws: A `ScraperError` if parsing or network requests fail.
  func extractStreamingLinks(contentId: String, seasonId: String? = nil, episodeId: String? = nil)
    async throws -> [ExtractedLink]
  {
    // 1. Determine the correct endpoint for fetching servers
    let serversPath: String
    let isMovie = contentId.starts(with: "movie/")

    if let epId = episodeId, !isMovie {
      // For TV shows, use the v2 endpoint for fetching episode servers
      serversPath = "/ajax/v2/episode/servers/\(epId)"
    } else {
      // For movies, extract the numeric ID from the content's relative path
      guard let numericId = contentId.components(separatedBy: "-").last else {
        throw ScraperError.parsingFailed(
          "Could not extract numeric ID from movie contentId: \(contentId)")
      }
      // Movies use a different endpoint to get their single "episode" which contains the servers
      serversPath = "/ajax/movie/episodes/\(numericId)"
    }

    // 2. Fetch the server list HTML
    let endpoint = FlixHQEndpoint(baseURL: baseURL, path: serversPath)
    let htmlData = try await networkClient.requestData(endpoint)
    let doc = try HTMLParser.parse(String(data: htmlData, encoding: .utf8) ?? "")

    // 3. Parse server elements (contained within `<li>` elements inside a `.nav`)
    let serverElements = HTMLParser.extractElements(from: doc, selector: ".nav > li")

    // 4. Use a TaskGroup to fetch embed links from all servers concurrently
    return await withTaskGroup(of: [ExtractedLink].self, returning: [ExtractedLink].self) { group in
      for serverElement in serverElements {
        group.addTask {
          // Parse server information
          guard let aTag = try? serverElement.select("a").first() else { return [] }

          // For movies, the server ID is in `data-linkid`. For TV, it's in `data-id`
          let serverId = isMovie ? (try? aTag.attr("data-linkid")) : (try? aTag.attr("data-id"))
          let serverName = try? aTag.attr("title")

          guard let id = serverId else { return [] }

          // Clean up the server name (e.g., "Server UpCloud" -> "UpCloud")
          let cleanedName =
            serverName?.replacingOccurrences(of: "Server", with: "").trimmingCharacters(
              in: .whitespaces) ?? "Unknown"

          // Make an AJAX call to get the source embed link
          let sourceEndpoint = FlixHQEndpoint(
            baseURL: self.baseURL, path: "/ajax/episode/sources/\(id)")

          do {
            let sourceData = try await self.networkClient.requestData(sourceEndpoint)
            struct EmbedResponse: Decodable { let link: String }
            let embedResponse = try JSONDecoder().decode(EmbedResponse.self, from: sourceData)

            // Special handling for VidCloud and Upcloud - use VidCloudExtractor directly
            let cleanedNameLower = cleanedName.lowercased()
            if cleanedNameLower.contains("vidcloud") || cleanedNameLower.contains("upcloud") {
              let vidCloudExtractor = VidCloudExtractor(networkClient: self.networkClient)
              let links = try? await vidCloudExtractor.extract(from: embedResponse.link)
              if let links = links {
                return links
              }
            } else {
              // Use the ExtractorResolver to get the final, direct video links from the embed URL
              let links = try? await self.extractorResolver.extract(from: embedResponse.link)
              if let links = links {
                return links.map { link in
                  ExtractedLink(
                    id: link.id,
                    url: link.url,
                    quality: link.quality,
                    server: cleanedName,
                    requiresReferer: link.requiresReferer,
                    headers: link.headers,
                    type: link.type
                  )
                }
              }
            }
          } catch {
            print("Error fetching/extracting from server \(cleanedName): \(error)")
          }

          // Return an empty array if a specific server fails
          return []
        }
      }

      // Collect all links from all servers
      var allLinks: [ExtractedLink] = []
      for await links in group {
        allLinks.append(contentsOf: links)
      }
      return allLinks
    }
  }
}

/// Defines the structure for an API endpoint for FlixHQ.
private struct FlixHQEndpoint: Endpoint {
  let baseURL: String, path: String
  var queryItems: [URLQueryItem]?

  var method: HTTPMethod { .get }
  var headers: [String: String]? {
    [
      // A realistic User-Agent is important to avoid being blocked.
      "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      // The referer header can also be important for some sites.
      "Referer": baseURL + "/",
      // This header is crucial for the site's AJAX endpoints to identify the request as valid.
      "X-Requested-With": "XMLHttpRequest",
    ]
  }
  var body: Data? { nil }

  init(baseURL: String, path: String, queryItems: [URLQueryItem]? = nil) {
    self.baseURL = baseURL
    self.path = path
    self.queryItems = queryItems
  }
}
