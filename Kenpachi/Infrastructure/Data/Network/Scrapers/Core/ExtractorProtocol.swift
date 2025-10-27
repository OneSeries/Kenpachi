// ExtractorProtocol.swift
// Protocol for video link extractors
// Extracts direct streaming links from embed pages

import Foundation

/// Protocol for video link extractors
protocol ExtractorProtocol {
    /// Extractor name
    var name: String { get }
    /// Supported domains
    var supportedDomains: [String] { get }
    
    /// Extracts video links from embed URL
    /// - Parameter embedURL: Embed page URL
    /// - Returns: Array of extracted links
    func extract(from embedURL: String) async throws -> [ExtractedLink]
}

/// Helper to determine which extractor to use
final class ExtractorResolver {
    /// Registered extractors
    private var extractors: [ExtractorProtocol] = []
    
    /// Shared instance
    static let shared = ExtractorResolver()
    
    /// Initializer
    init() {
        registerDefaultExtractors()
    }
    
    /// Registers default extractors
    private func registerDefaultExtractors() {
        extractors = [
            DoodStreamExtractor(),
            StreamTapeExtractor(),
            VidCloudExtractor(),
            MixDropExtractor()
        ]
    }
    
    /// Finds appropriate extractor for URL
    /// - Parameter url: Embed URL
    /// - Returns: Matching extractor or nil
    func findExtractor(for url: String) -> ExtractorProtocol? {
        extractors.first { extractor in
            extractor.supportedDomains.contains { domain in
                url.contains(domain)
            }
        }
    }
    
    /// Extracts links using appropriate extractor
    /// - Parameter url: Embed URL
    /// - Returns: Array of extracted links
    func extract(from url: String) async throws -> [ExtractedLink] {
        guard let extractor = findExtractor(for: url) else {
            throw ScraperError.extractionFailed("No extractor found for URL: \(url)")
        }
        return try await extractor.extract(from: url)
    }
}