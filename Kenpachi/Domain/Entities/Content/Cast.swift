// Cast.swift
// Model representing cast and crew members
// Used for displaying actor/director information in content details

import Foundation

/// Struct representing a cast or crew member
struct Cast: Codable, Identifiable, Equatable, Hashable {
    /// Unique identifier for the person
    let id: Int
    /// Person's name
    let name: String
    /// Character name they play (for actors)
    let character: String?
    /// Job title (for crew members, e.g., "Director", "Producer")
    let job: String?
    /// Department (e.g., "Acting", "Directing", "Writing")
    let department: String?
    /// URL path to profile image
    let profilePath: String?
    /// Order in credits (lower numbers appear first)
    let order: Int?
    
    /// Initializer for creating a Cast instance
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - name: Person's name
    ///   - character: Character name (for actors)
    ///   - job: Job title (for crew)
    ///   - department: Department
    ///   - profilePath: Profile image path
    ///   - order: Credit order
    init(
        id: Int,
        name: String,
        character: String? = nil,
        job: String? = nil,
        department: String? = nil,
        profilePath: String? = nil,
        order: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.character = character
        self.job = job
        self.department = department
        self.profilePath = profilePath
        self.order = order
    }
}

// MARK: - Computed Properties
extension Cast {
    /// Full URL for profile image
    var fullProfileURL: URL? {
        guard let profilePath = profilePath else { return nil }
        return URL(string: APIConstants.TMDB.imageBaseURL + APIConstants.TMDB.ImageSize.profile + profilePath)
    }
    
    /// Display role (character name or job title)
    var displayRole: String? {
        return character ?? job
    }
    
    /// Whether this person is an actor
    var isActor: Bool {
        return department?.lowercased() == "acting"
    }
    
    /// Whether this person is a director
    var isDirector: Bool {
        return job?.lowercased() == "director"
    }
}
