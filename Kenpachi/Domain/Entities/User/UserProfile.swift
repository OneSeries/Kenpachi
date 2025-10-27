// UserProfile.swift
// Domain entity representing a user profile
// Contains user information and preferences

import Foundation

/// Represents a user profile with personal information
struct UserProfile: Equatable, Identifiable, Codable {
  /// Unique identifier for the user
  let id: String
  /// User's display name
  var name: String
  /// User's email address
  var email: String?
  /// User's avatar URL
  var avatarURL: URL?
  /// Date when profile was created
  let createdAt: Date
  /// Date when profile was last updated
  var updatedAt: Date
  
  /// Initializer
  init(
    id: String = UUID().uuidString,
    name: String,
    email: String? = nil,
    avatarURL: URL? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.email = email
    self.avatarURL = avatarURL
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
  
  /// User initials for avatar placeholder
  var initials: String {
    let components = name.components(separatedBy: " ")
    let firstInitial = components.first?.first.map(String.init) ?? ""
    let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
    return (firstInitial + lastInitial).uppercased()
  }
}
