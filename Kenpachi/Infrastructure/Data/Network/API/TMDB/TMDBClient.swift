// TMDBClient.swift
// TMDB API client for fetching movie and TV show data
// Provides methods for trending content, search, and details

import Foundation

/// Client for interacting with The Movie Database API
final class TMDBClient {
    /// Shared singleton instance
    static let shared = TMDBClient()
    
    /// Network client for making requests
    private let networkClient: NetworkClientProtocol
    
    /// Initializer with dependency injection
    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }
    
    /// Fetches trending movies
    /// - Parameter timeWindow: Time window for trending (day or week)
    /// - Returns: Array of trending movies
    func fetchTrendingMovies(timeWindow: TrendingTimeWindow = .day) async throws -> [Content] {
        let endpoint = TMDBEndpoint.trendingMovies(timeWindow: timeWindow)
        let response: TMDBPagedResponse<TMDBMovie> = try await networkClient.request(endpoint)
        return response.results.map { $0.toContent() }
    }
    
    /// Fetches trending TV shows
    /// - Parameter timeWindow: Time window for trending (day or week)
    /// - Returns: Array of trending TV shows
    func fetchTrendingTVShows(timeWindow: TrendingTimeWindow = .day) async throws -> [Content] {
        let endpoint = TMDBEndpoint.trendingTVShows(timeWindow: timeWindow)
        let response: TMDBPagedResponse<TMDBTVShow> = try await networkClient.request(endpoint)
        return response.results.map { $0.toContent() }
    }
    
    /// Fetches movie details
    /// - Parameter id: Movie ID
    /// - Returns: Detailed movie content
    func fetchMovieDetails(id: String) async throws -> Content {
        let endpoint = TMDBEndpoint.movieDetails(id: id)
        let movie: TMDBMovie = try await networkClient.request(endpoint)
        return movie.toContent()
    }
    
    /// Fetches TV show details
    /// - Parameter id: TV show ID
    /// - Returns: Detailed TV show content
    func fetchTVShowDetails(id: String) async throws -> Content {
        let endpoint = TMDBEndpoint.tvShowDetails(id: id)
        let tvShow: TMDBTVShow = try await networkClient.request(endpoint)
        return tvShow.toContent()
    }
    
    /// Searches for content
    /// - Parameters:
    ///   - query: Search query string
    ///   - type: Content type to search for
    /// - Returns: Array of matching content
    func search(query: String, type: ContentType) async throws -> [Content] {
        let endpoint = TMDBEndpoint.search(query: query, type: type)
        
        switch type {
        case .movie:
            let response: TMDBPagedResponse<TMDBMovie> = try await networkClient.request(endpoint)
            return response.results.map { $0.toContent() }
        case .tvShow:
            let response: TMDBPagedResponse<TMDBTVShow> = try await networkClient.request(endpoint)
            return response.results.map { $0.toContent() }
        case .anime:
            // Anime search handled by AniList
            return []
        }
    }
}

/// Time window for trending content
enum TrendingTimeWindow: String {
    case day
    case week
}
