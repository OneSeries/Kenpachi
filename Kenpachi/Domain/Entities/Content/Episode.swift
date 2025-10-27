// Episode.swift
// Model representing a TV show or anime episode
// Contains episode metadata and streaming information

import Foundation

/// Struct representing an episode of a TV show or anime
struct Episode: Codable, Identifiable, Equatable, Hashable {
    /// Unique identifier for the episode
    let id: String
    /// Episode number within the season
    let episodeNumber: Int
    /// Season number this episode belongs to
    let seasonNumber: Int
    /// Episode title/name
    let name: String
    /// Episode overview/synopsis
    let overview: String?
    /// URL path to episode still/thumbnail image
    let stillPath: String?
    /// Air date of the episode
    let airDate: Date?
    /// Episode runtime in minutes
    let runtime: Int?
    /// Average user rating for the episode
    let voteAverage: Double?
    /// Total number of votes for the episode
    let voteCount: Int?
    /// Production code
    let productionCode: String?
    
    /// Initializer for creating an Episode instance
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - episodeNumber: Episode number
    ///   - seasonNumber: Season number
    ///   - name: Episode title
    ///   - overview: Episode synopsis
    ///   - stillPath: Still image path
    ///   - airDate: Episode air date
    ///   - runtime: Runtime in minutes
    ///   - voteAverage: Average rating
    ///   - voteCount: Number of votes
    ///   - productionCode: Production code
    init(
        id: String,
        episodeNumber: Int,
        seasonNumber: Int,
        name: String,
        overview: String? = nil,
        stillPath: String? = nil,
        airDate: Date? = nil,
        runtime: Int? = nil,
        voteAverage: Double? = nil,
        voteCount: Int? = nil,
        productionCode: String? = nil
    ) {
        self.id = id
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.stillPath = stillPath
        self.airDate = airDate
        self.runtime = runtime
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.productionCode = productionCode
    }
}

// MARK: - Computed Properties
extension Episode {
    /// Full URL for episode still image
    var fullStillURL: URL? {
        guard let stillPath = stillPath else { return nil }
        return URL(string: APIConstants.TMDB.imageBaseURL + APIConstants.TMDB.ImageSize.backdrop + stillPath)
    }
    
    /// Formatted episode identifier (e.g., "S01E05")
    var formattedEpisodeId: String {
        return String(format: "S%02dE%02d", seasonNumber, episodeNumber)
    }
    
    /// Formatted runtime string (e.g., "45m")
    var formattedRuntime: String? {
        guard let runtime = runtime else { return nil }
        return "\(runtime)m"
    }
    
    /// Formatted rating string (e.g., "8.5")
    var formattedRating: String? {
        guard let voteAverage = voteAverage else { return nil }
        return String(format: "%.1f", voteAverage)
    }
}
