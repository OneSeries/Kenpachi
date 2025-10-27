// ContentCarousel.swift
// Domain model for content carousel/row
// Represents a themed collection of content items

import Foundation

/// Struct representing a content carousel for home screen
struct ContentCarousel: Codable, Identifiable, Equatable {
    /// Unique identifier
    let id: String
    /// Carousel title
    let title: String
    /// Array of content items
    var items: [Content]
    /// Carousel type/category
    let type: CarouselType
    
    /// Enum defining carousel types
    enum CarouselType: String, Codable {
        case hero
        case trending
        case popular
        case recent
        case recommended
        case continueWatching
        case watchlist
        case genre
    }
    
    /// Initializer
    init(
        id: String = UUID().uuidString,
        title: String,
        items: [Content],
        type: CarouselType
    ) {
        self.id = id
        self.title = title
        self.items = items
        self.type = type
    }
}
