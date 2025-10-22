// StreamTape.swift
// StreamTape video extractor
// Extracts streaming links from StreamTape embed pages

import Foundation

/// StreamTape video extractor
final class StreamTapeExtractor: ExtractorProtocol {
    var name: String { "StreamTape" }
    var supportedDomains: [String] {
        ["streamtape.com", "streamtape.to", "streamtape.net"]
    }
    
    /// Network client
    private let networkClient: NetworkClientProtocol
    
    /// Initializer
    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }
    
    /// Extracts video links from StreamTape
    /// - Parameter embedURL: StreamTape embed URL
    /// - Returns: Array of extracted links
    func extract(from embedURL: String) async throws -> [ExtractedLink] {
        // Fetch embed page
        let endpoint = StreamTapeEndpoint(url: embedURL)
        let html = try await networkClient.requestData(endpoint)
        let htmlString = String(data: html, encoding: .utf8) ?? ""
        
        // Extract video ID and token from JavaScript
        guard let idRegex = try? NSRegularExpression(pattern: "getElementById\\('robotlink'\\)\\.innerHTML = '([^']+)", options: []),
              let idMatch = idRegex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
              let idRange = Range(idMatch.range(at: 1), in: htmlString) else {
            throw ScraperError.extractionFailed("Could not find video ID in StreamTape")
        }
        
        let videoPath = String(htmlString[idRange])
        
        // Extract token
        guard let tokenRegex = try? NSRegularExpression(pattern: "token=([^&'\"]+)", options: []),
              let tokenMatch = tokenRegex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
              let tokenRange = Range(tokenMatch.range(at: 1), in: htmlString) else {
            throw ScraperError.extractionFailed("Could not find token in StreamTape")
        }
        
        let token = String(htmlString[tokenRange])
        let videoURL = "https://\(videoPath)&token=\(token)"
        
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

/// StreamTape endpoint
private struct StreamTapeEndpoint: Endpoint {
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
