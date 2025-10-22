// ExtractedLink.swift
// Domain model for extracted streaming links
// Represents a streaming source with quality and server information

import Foundation

/// Struct representing an extracted streaming link
struct ExtractedLink: Codable, Identifiable, Equatable {
    /// Unique identifier
    let id: String
    /// Streaming URL
    let url: String
    /// Quality (e.g., "1080p", "720p")
    let quality: String?
    /// Server/source name
    let server: String
    /// Whether link requires referer header
    let requiresReferer: Bool
    /// Additional headers required
    let headers: [String: String]?
    /// Link type (direct, m3u8, etc.)
    let type: LinkType
    
    /// Enum defining link types
    enum LinkType: String, Codable {
        case direct
        case m3u8
        case dash
        case hls
    }
    
    /// Initializer
    init(
        id: String = UUID().uuidString,
        url: String,
        quality: String? = nil,
        server: String,
        requiresReferer: Bool = false,
        headers: [String: String]? = nil,
        type: LinkType = .direct
    ) {
        self.id = id
        self.url = url
        self.quality = quality
        self.server = server
        self.requiresReferer = requiresReferer
        self.headers = headers
        self.type = type
    }
}
