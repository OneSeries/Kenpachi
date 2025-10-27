// ContentType.swift
// Enum defining all supported content types in the application
// Used for categorizing movies, TV shows, anime, and other media

import Foundation

/// Enum representing different types of content available in the app
enum ContentType: String, Codable, CaseIterable, Identifiable {
    /// Movie content type
    case movie
    /// TV show/series content type
    case tvShow = "tv"
    /// Anime content type
    case anime
    
    /// Unique identifier for Identifiable conformance
    var id: String { rawValue }
    
    /// Human-readable display name for the content type
    var displayName: String {
        switch self {
        case .movie:
            return "Movie"
        case .tvShow:
            return "TV Show"
        case .anime:
            return "Anime"
        }
    }
    
    /// Plural form of the display name
    var pluralName: String {
        switch self {
        case .movie:
            return "Movies"
        case .tvShow:
            return "TV Shows"
        case .anime:
            return "Anime"
        }
    }
    
    /// SF Symbol icon name for the content type
    var iconName: String {
        switch self {
        case .movie:
            return "film"
        case .tvShow:
            return "tv"
        case .anime:
            return "sparkles.tv"
        }
    }
}
