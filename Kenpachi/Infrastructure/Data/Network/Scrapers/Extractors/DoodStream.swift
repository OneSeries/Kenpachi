// DoodStream.swift
// DoodStream video extractor
// Extracts streaming links from DoodStream embed pages

import Foundation

/// DoodStream video extractor
final class DoodStreamExtractor: ExtractorProtocol {
    var name: String { "DoodStream" }
    var supportedDomains: [String] {
        ["dood.to", "dood.watch", "dood.so", "dood.la", "dood.ws", "doodstream.com"]
    }
    
    /// Network client
    private let networkClient: NetworkClientProtocol
    
    /// Initializer
    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }
    
    /// Extracts video links from DoodStream
    /// - Parameter embedURL: DoodStream embed URL
    /// - Returns: Array of extracted links
    func extract(from embedURL: String) async throws -> [ExtractedLink] {
        // Fetch embed page
        let endpoint = DoodStreamEndpoint(url: embedURL)
        let html = try await networkClient.requestData(endpoint)
        let htmlString = String(data: html, encoding: .utf8) ?? ""
        
        // Extract video URL from JavaScript
        guard let passRegex = try? NSRegularExpression(pattern: "/pass_md5/[^']*", options: []),
              let passMatch = passRegex.firstMatch(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString)),
              let passRange = Range(passMatch.range, in: htmlString) else {
            throw ScraperError.extractionFailed("Could not find pass_md5 in DoodStream")
        }
        
        let passPath = String(htmlString[passRange])
        let passURL = "https://\(extractDomain(from: embedURL))\(passPath)"
        
        // Get token
        let tokenEndpoint = DoodStreamEndpoint(url: passURL)
        let tokenData = try await networkClient.requestData(tokenEndpoint)
        let token = String(data: tokenData, encoding: .utf8) ?? ""
        
        // Construct final URL
        let randomString = generateRandomString(length: 10)
        let videoURL = "\(token)\(randomString)?token=\(passPath)&expiry=\(Date().timeIntervalSince1970)"
        
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
    
    /// Extracts domain from URL
    private func extractDomain(from url: String) -> String {
        guard let urlObj = URL(string: url),
              let host = urlObj.host else {
            return "dood.to"
        }
        return host
    }
    
    /// Generates random string
    private func generateRandomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}

/// DoodStream endpoint
private struct DoodStreamEndpoint: Endpoint {
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
