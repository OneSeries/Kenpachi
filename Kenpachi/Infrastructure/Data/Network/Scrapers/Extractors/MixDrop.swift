// MixDrop.swift
// MixDrop video extractor
// Extracts streaming links from MixDrop embed pages

import Foundation

/// MixDrop video extractor
final class MixDropExtractor: ExtractorProtocol {
    var name: String { "MixDrop" }
    var supportedDomains: [String] {
        ["mixdrop.co", "mixdrop.to", "mixdrop.sx"]
    }
    
    /// Network client
    private let networkClient: NetworkClientProtocol
    
    /// Initializer
    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }
    
    /// Extracts video links from MixDrop
    /// - Parameter embedURL: MixDrop embed URL
    /// - Returns: Array of extracted links
    func extract(from embedURL: String) async throws -> [ExtractedLink] {
        // Fetch embed page
        let endpoint = MixDropEndpoint(url: embedURL)
        let html = try await networkClient.requestData(endpoint)
        let htmlString = String(data: html, encoding: .utf8) ?? ""
        
        // Extract video URL from packed JavaScript
        guard let regex = try? NSRegularExpression(pattern: "MDCore\\.wurl=\"([^\"]+)", options: []),
              let match = regex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
              let range = Range(match.range(at: 1), in: htmlString) else {
            throw ScraperError.extractionFailed("Could not find video URL in MixDrop")
        }
        
        let videoPath = String(htmlString[range])
        let videoURL = "https:\(videoPath)"
        
        return [
            ExtractedLink(
                url: videoURL,
                quality: "720p",
                server: name,
                requiresReferer: true,
                headers: ["Referer": embedURL],
                type: .direct
            )
        ]
    }
}

/// MixDrop endpoint
private struct MixDropEndpoint: Endpoint {
    let url: String
    
    var baseURL: String { "" }
    var path: String { url }
    var method: HTTPMethod { .get }
    var queryItems: [URLQueryItem]? { nil }
    var headers: [String: String]? {
        ["User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"]
    }
    var body: Data? { nil }
}
