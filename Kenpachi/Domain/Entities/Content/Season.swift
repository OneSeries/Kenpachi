// Season.swift
// Model representing a TV show season
// Contains season metadata and episode information

import Foundation

/// Struct representing a season of a TV show
struct Season: Codable, Identifiable, Equatable, Hashable {
    /// Unique identifier for the season
    let id: String
    /// Season number (1, 2, 3, etc.)
    let seasonNumber: Int
    /// Season name/title
    let name: String
    /// Season overview/description
    let overview: String?
    /// URL path to season poster image
    let posterPath: String?
    /// Air date of the season
    let airDate: Date?
    /// Number of episodes in the season
    let episodeCount: Int
    /// Array of episodes in the season
    let episodes: [Episode]?
    
    /// Initializer for creating a Season instance
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - seasonNumber: Season number
    ///   - name: Season name
    ///   - overview: Season description
    ///   - posterPath: Poster image path
    ///   - airDate: Season air date
    ///   - episodeCount: Number of episodes
    ///   - episodes: Array of episodes
    init(
        id: String,
        seasonNumber: Int,
        name: String,
        overview: String? = nil,
        posterPath: String? = nil,
        airDate: Date? = nil,
        episodeCount: Int,
        episodes: [Episode]? = nil
    ) {
        self.id = id
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.airDate = airDate
        self.episodeCount = episodeCount
        self.episodes = episodes
    }
}

// MARK: - Computed Properties
extension Season {
    /// Full URL for season poster image
    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: APIConstants.TMDB.imageBaseURL + APIConstants.TMDB.ImageSize.poster + posterPath)
    }
    
    /// Formatted season number (e.g., "Season 1")
    var formattedSeasonNumber: String {
        return "Season \(seasonNumber)"
    }
}
