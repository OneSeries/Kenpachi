// GogoAnime.swift
// GogoAnime scraper implementation
// Provides anime content scraping from GogoAnime source

import Foundation
import SwiftSoup

/// GogoAnime scraper implementation
struct GogoAnime: ScraperProtocol {
    /// Scraper name
    let name = "GogoAnime"
    /// Base URL for GogoAnime
    let baseURL = "https://gogoanime.cl"
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
        let endpoint = GogoAnimeEndpoint(baseURL: baseURL, path: "/")
        let html = try await networkClient.requestData(endpoint)
        let htmlString = String(data: html, encoding: .utf8) ?? ""
        
        let doc = try HTMLParser.parse(htmlString)
        let elements = HTMLParser.extractElements(from: doc, selector: ".items .img")
        
        let contents: [Content] = elements.compactMap { element in
            guard let title = HTMLParser.extractAttribute(from: element, selector: "a", attribute: "title"),
                  let href = HTMLParser.extractAttribute(from: element, selector: "a", attribute: "href"),
                  let id = href.components(separatedBy: "/").last else {
                return nil
            }
            
            let posterPath = HTMLParser.extractAttribute(from: element, selector: "img", attribute: "src")
            let year = HTMLParser.extractText(from: element, selector: ".released")
            
            return Content(
                id: "gogoanime-\(id)",
                type: .anime,
                title: title,
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
                title: "Trending on GogoAnime",
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
        let searchPath = "/search.html?keyword=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&page=\(page)"
        let endpoint = GogoAnimeEndpoint(baseURL: baseURL, path: searchPath)
        let html = try await networkClient.requestData(endpoint)
        let htmlString = String(data: html, encoding: .utf8) ?? ""
        
        let doc = try HTMLParser.parse(htmlString)
        let elements = HTMLParser.extractElements(from: doc, selector: ".items .img")
        
        let contents: [Content] = elements.compactMap { element in
            guard let title = HTMLParser.extractAttribute(from: element, selector: "a", attribute: "title"),
                  let href = HTMLParser.extractAttribute(from: element, selector: "a", attribute: "href"),
                  let id = href.components(separatedBy: "/").last else {
                return nil
            }
            
            let posterPath = HTMLParser.extractAttribute(from: element, selector: "img", attribute: "src")
            let year = HTMLParser.extractText(from: element, selector: ".released")
            
            return Content(
                id: "gogoanime-\(id)",
                type: .anime,
                title: title,
                posterPath: posterPath,
                releaseDate: year.flatMap { Int($0) }.flatMap { year in
                    DateComponents(calendar: Calendar.current, year: year).date
                },
                adult: false
            )
        }
        
        // Extract pagination information if available
        let totalPages = 1 // Default to 1 page
        let totalResults = contents.count // Default to contents count
        
        // Return a ContentSearchResult with the search results
        return ContentSearchResult(
            id: "gogoanime-search-\(query)-\(page)",
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
        let cleanId = id.replacingOccurrences(of: "gogoanime-", with: "")
        let endpoint = GogoAnimeEndpoint(baseURL: baseURL, path: "/category/\(cleanId)")
        let html = try await networkClient.requestData(endpoint)
        let htmlString = String(data: html, encoding: .utf8) ?? ""
        
        let doc = try HTMLParser.parse(htmlString)
        
        guard let title = HTMLParser.extractAttribute(from: doc, selector: ".anime_info_body_bg h1", attribute: "text") else {
            throw ScraperError.contentNotFound
        }
        
        let overview = HTMLParser.extractText(from: doc, selector: ".anime_info_body_bg .description")
        let posterPath = HTMLParser.extractAttribute(from: doc, selector: ".anime_info_body_bg img", attribute: "src")
        
        _ = HTMLParser.extractText(from: doc, selector: ".anime_info_body_bg p.type:eq(0)")
        _ = HTMLParser.extractText(from: doc, selector: ".anime_info_body_bg p.type:eq(2)")
        
        return Content(
            id: id,
            type: .anime,
            title: title,
            overview: overview,
            posterPath: posterPath,
            adult: false
        )
    }
    
    /// Extracts streaming links
    /// - Parameters:
    ///   - contentId: Content identifier (required)
    ///   - seasonId: Season identifier (optional, for anime)
    ///   - episodeId: Episode identifier (optional, for anime)
    /// - Returns: Array of extracted streaming links
    func extractStreamingLinks(contentId: String, seasonId: String? = nil, episodeId: String? = nil) async throws -> [ExtractedLink] {
        // GogoAnime implementation would go here
        return []
    }
}

/// GogoAnime endpoint
private struct GogoAnimeEndpoint: Endpoint {
    let baseURL: String
    let path: String
    
    var method: HTTPMethod { .get }
    var queryItems: [URLQueryItem]? { nil }
    var headers: [String: String]? {
        ["User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"]
    }
    var body: Data? { nil }
}