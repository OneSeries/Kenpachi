// Content.swift
// Core domain model representing any piece of content (movie, TV show, anime)
// This is the primary entity used throughout the application

import Foundation

/// Struct representing a piece of content (movie, TV show, or anime)
struct Content: Codable, Identifiable, Equatable, Hashable {
    /// Unique identifier for the content
    let id: String
    /// Content type (movie, TV show, or anime)
    let type: ContentType
    /// Title of the content
    let title: String
    /// Original title in native language
    let originalTitle: String?
    /// Brief overview/synopsis of the content
    let overview: String?
    /// URL path to poster image
    let posterPath: String?
    /// URL path to backdrop image
    let backdropPath: String?
    /// Release date for movies or first air date for TV shows
    let releaseDate: Date?
    /// Average user rating (0-10 scale)
    let voteAverage: Double?
    /// Total number of votes/ratings
    let voteCount: Int?
    /// Popularity score
    let popularity: Double?
    /// Original language code (e.g., "en", "ja")
    let originalLanguage: String?
    /// Array of genre IDs associated with the content
    let genreIds: [Int]?
    /// Array of full genre objects
    let genres: [Genre]?
    /// Whether the content is marked as adult/mature
    let adult: Bool
    /// Content rating (e.g., "PG-13")
    let rating: String?
    /// Runtime in minutes (for movies)
    let runtime: Int?
    /// Number of seasons (for TV shows)
    let numberOfSeasons: Int?
    /// Number of episodes (for TV shows)
    let numberOfEpisodes: Int?
    /// Current status (e.g., "Released", "Returning Series")
    let status: String?
    /// Tagline or catchphrase
    let tagline: String?
    /// Official homepage URL
    let homepage: String?
    /// Production companies
    let productionCompanies: [String]?
    /// Available seasons (for TV shows)
    let seasons: [Season]?
    /// Cast members
    let cast: [Cast]?
    /// Trailer URL
    let trailerUrl: String?
    /// Country of origin
    let country: String?
    /// Duration of the content
    let duration: String?
    /// Recommended content
    let recommendations: [Content]?
    
    /// Initializer for creating a Content instance
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - type: Content type (movie/TV/anime)
    ///   - title: Content title
    ///   - originalTitle: Original title in native language
    ///   - overview: Content synopsis
    ///   - posterPath: Poster image path
    ///   - backdropPath: Backdrop image path
    ///   - releaseDate: Release or first air date
    ///   - voteAverage: Average rating
    ///   - voteCount: Number of votes
    ///   - popularity: Popularity score
    ///   - originalLanguage: Original language code
    ///   - genreIds: Array of genre IDs
    ///   - genres: Array of genre objects
    ///   - adult: Adult content flag
    ///   - rating: Content rating (e.g., "PG-13")
    ///   - runtime: Runtime in minutes
    ///   - numberOfSeasons: Number of seasons
    ///   - numberOfEpisodes: Number of episodes
    ///   - status: Content status
    ///   - tagline: Content tagline
    ///   - homepage: Official homepage
    ///   - productionCompanies: Production companies
    ///   - seasons: Available seasons
    ///   - cast: Cast members
    ///   - trailerUrl: Trailer URL
    ///   - country: Country of origin
    ///   - duration: Duration of the content
    ///   - recommendations: Recommended content
    init(
        id: String,
        type: ContentType,
        title: String,
        originalTitle: String? = nil,
        overview: String? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        releaseDate: Date? = nil,
        voteAverage: Double? = nil,
        voteCount: Int? = nil,
        popularity: Double? = nil,
        originalLanguage: String? = nil,
        genreIds: [Int]? = nil,
        genres: [Genre]? = nil,
        adult: Bool = false,
        rating: String? = nil,
        runtime: Int? = nil,
        numberOfSeasons: Int? = nil,
        numberOfEpisodes: Int? = nil,
        status: String? = nil,
        tagline: String? = nil,
        homepage: String? = nil,
        productionCompanies: [String]? = nil,
        seasons: [Season]? = nil,
        cast: [Cast]? = nil,
        trailerUrl: String? = nil,
        country: String? = nil,
        duration: String? = nil,
        recommendations: [Content]? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.popularity = popularity
        self.originalLanguage = originalLanguage
        self.genreIds = genreIds
        self.genres = genres
        self.adult = adult
        self.rating = rating
        self.runtime = runtime
        self.numberOfSeasons = numberOfSeasons
        self.numberOfEpisodes = numberOfEpisodes
        self.status = status
        self.tagline = tagline
        self.homepage = homepage
        self.productionCompanies = productionCompanies
        self.seasons = seasons
        self.cast = cast
        self.trailerUrl = trailerUrl
        self.country = country
        self.duration = duration
        self.recommendations = recommendations
    }
}

// MARK: - Computed Properties
extension Content {
    /// Full URL for poster image
    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        if posterPath.hasPrefix("http://") || posterPath.hasPrefix("https://") {
            return URL(string: posterPath)
        }
        return URL(string: APIConstants.TMDB.imageBaseURL + APIConstants.TMDB.ImageSize.poster + posterPath)
    }
    
    /// Full URL for backdrop image
    var fullBackdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        if backdropPath.hasPrefix("http://") || backdropPath.hasPrefix("https://") {
            return URL(string: backdropPath)
        }
        return URL(string: APIConstants.TMDB.imageBaseURL + APIConstants.TMDB.ImageSize.backdrop + backdropPath)
    }
    
    /// Formatted release year
    var releaseYear: String? {
        guard let releaseDate = releaseDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: releaseDate)
    }
    
    /// Formatted rating string (e.g., "8.5")
    var formattedRating: String? {
        guard let voteAverage = voteAverage else { return nil }
        return String(format: "%.1f", voteAverage)
    }
    
    /// Formatted runtime string (e.g., "2h 30m")
    var formattedRuntime: String? {
        guard let runtime = runtime else { return nil }
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview Data
extension Content {
    /// Sample content for SwiftUI previews
    static let preview = Content(
        id: "preview-1",
        type: .movie,
        title: "Sample Movie",
        originalTitle: "Sample Movie",
        overview: "This is a sample movie for preview purposes. It demonstrates how content cards and details will look in the app.",
        posterPath: nil,
        backdropPath: nil,
        releaseDate: Date(),
        voteAverage: 8.5,
        voteCount: 1000,
        popularity: 100.0,
        originalLanguage: "en",
        genreIds: [28, 12],
        genres: [
            Genre(id: 28, name: "Action"),
            Genre(id: 12, name: "Adventure")
        ],
        adult: false,
        rating: "PG-13",
        runtime: 150,
        numberOfSeasons: nil,
        numberOfEpisodes: nil,
        status: "Released",
        tagline: "An epic adventure awaits",
        homepage: nil,
        productionCompanies: ["Sample Studios"],
        seasons: nil,
        cast: nil,
        trailerUrl: nil,
        country: "US",
        duration: "2h 30m",
        recommendations: nil
    )
}