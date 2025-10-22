// Genre.swift
// Model representing content genres/categories
// Used for filtering and categorizing content across the app

import Foundation

/// Struct representing a content genre
struct Genre: Codable, Identifiable, Equatable, Hashable {
    /// Unique identifier for the genre
    let id: Int
    /// Genre name (e.g., "Action", "Comedy", "Drama")
    let name: String
    
    /// Initializer for creating a Genre instance
    /// - Parameters:
    ///   - id: Unique identifier for the genre
    ///   - name: Display name of the genre
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Predefined Genres
extension Genre {
    /// Common movie and TV genres
    static let action = Genre(id: 28, name: "Action")
    static let adventure = Genre(id: 12, name: "Adventure")
    static let animation = Genre(id: 16, name: "Animation")
    static let comedy = Genre(id: 35, name: "Comedy")
    static let crime = Genre(id: 80, name: "Crime")
    static let documentary = Genre(id: 99, name: "Documentary")
    static let drama = Genre(id: 18, name: "Drama")
    static let family = Genre(id: 10751, name: "Family")
    static let fantasy = Genre(id: 14, name: "Fantasy")
    static let history = Genre(id: 36, name: "History")
    static let horror = Genre(id: 27, name: "Horror")
    static let music = Genre(id: 10402, name: "Music")
    static let mystery = Genre(id: 9648, name: "Mystery")
    static let romance = Genre(id: 10749, name: "Romance")
    static let scienceFiction = Genre(id: 878, name: "Science Fiction")
    static let thriller = Genre(id: 53, name: "Thriller")
    static let war = Genre(id: 10752, name: "War")
    static let western = Genre(id: 37, name: "Western")
}
