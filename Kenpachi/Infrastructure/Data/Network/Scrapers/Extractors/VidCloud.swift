// VidCloud.swift
// VidCloud/MegaCloud video extractor
// Extracts streaming links from VidCloud/MegaCloud embed pages

import Foundation

/// VidCloud video extractor
final class VidCloudExtractor: ExtractorProtocol {
    var name: String { "VidCloud" }
    var supportedDomains: [String] {
        ["videostr.net", "cloudvidz.net", "rapid-cloud.co", "rabbitstream.net", "megacloud.tv", "streameeeeee.site"]
    }
    
    /// Network client
    private let networkClient: NetworkClientProtocol
    
    /// Main URL
    private let mainURL = "https://videostr.net"
    
    /// User agent
    private let userAgent = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36"
    
    /// Initializer
    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }
    
    /// Extracts video links from VidCloud
    func extract(from embedURL: String) async throws -> [ExtractedLink] {
        guard let embedIframeURL = URL(string: embedURL) else {
            throw ScraperError.extractionFailed("Invalid VidCloud URL")
        }
        
        // Step 1: Fetch HTML page
        let htmlData = try await fetchData(from: embedIframeURL, headers: [
            "User-Agent": userAgent,
            "Referer": embedIframeURL.absoluteString
        ])
        let html = String(decoding: htmlData, as: UTF8.self)
        
        // Step 2: Extract file ID using regex
        let fileIdPattern = #"data-id="([^"]+)""#
        guard let fileId = findFirstMatch(in: html, pattern: fileIdPattern) else {
            throw ScraperError.extractionFailed("Could not find file ID in embed page")
        }
        
        // Step 3: Extract nonce
        guard let nonce = extractNonce(from: html) else {
            throw ScraperError.extractionFailed("Could not extract nonce from embed page")
        }
        
        // Step 4: Call getSources endpoint
        let apiUrl = "\(embedIframeURL.scheme ?? "https")://\(embedIframeURL.host ?? "streameeeeee.site")/embed-1/v3/e-1/getSources?id=\(fileId)&_k=\(nonce)"
        guard let sourcesURL = URL(string: apiUrl) else {
            throw ScraperError.extractionFailed("Invalid sources URL")
        }
        
        let sourcesData = try await fetchData(from: sourcesURL, headers: [
            "Accept": "*/*",
            "X-Requested-With": "XMLHttpRequest",
            "Referer": embedIframeURL.absoluteString,
            "User-Agent": userAgent
        ])
        
        let extractedSrc = try JSONDecoder().decode(ExtractedSrc.self, from: sourcesData)
        
        // Step 5: Process sources
        var links: [ExtractedLink] = []
        
        switch extractedSrc.sources {
        case .array(let sourceArray):
            for source in sourceArray {
                let type: ExtractedLink.LinkType = (source.type == "hls" || source.file.contains(".m3u8")) ? .m3u8 : .direct
                links.append(
                    ExtractedLink(
                        url: source.file,
                        quality: "auto",
                        server: name,
                        requiresReferer: true,
                        headers: ["Referer": embedIframeURL.absoluteString],
                        type: type
                    )
                )
            }
        case .string(let sourceString):
            let type: ExtractedLink.LinkType = sourceString.contains(".m3u8") ? .m3u8 : .direct
            links.append(
                ExtractedLink(
                    url: sourceString,
                    quality: "auto",
                    server: name,
                    requiresReferer: true,
                    headers: ["Referer": embedIframeURL.absoluteString],
                    type: type
                )
            )
        }
        
        return links
    }
    
    // MARK: - Utility Functions
    
    /// Fetches data from a URL with optional headers
    private func fetchData(from url: URL, headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ScraperError.extractionFailed("HTTP request failed")
        }
        
        return data
    }
    
    /// Extracts nonce from HTML using regex patterns
    private func extractNonce(from html: String) -> String? {
        // Pattern 1: Single 48-character alphanumeric block
        let pattern48 = #"\b[a-zA-Z0-9]{48}\b"#
        if let match = findFirstMatch(in: html, pattern: pattern48) {
            return match
        }
        
        // Pattern 2: Three 16-character alphanumeric blocks
        let pattern3x16 = #"\b([a-zA-Z0-9]{16})\b.*?\b([a-zA-Z0-9]{16})\b.*?\b([a-zA-Z0-9]{16})\b"#
        let regex = try? NSRegularExpression(pattern: pattern3x16, options: .dotMatchesLineSeparators)
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        
        if let match = regex?.firstMatch(in: html, options: [], range: range) {
            return (1...3).compactMap { groupIndex in
                let groupRange = match.range(at: groupIndex)
                if let swiftRange = Range(groupRange, in: html) {
                    return String(html[swiftRange])
                }
                return nil
            }.joined()
        }
        
        return nil
    }
    
    /// Finds first regex match in text
    private func findFirstMatch(in text: String, pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            if match.numberOfRanges > 1 {
                if let swiftRange = Range(match.range(at: 1), in: text) {
                    return String(text[swiftRange])
                }
            } else {
                if let swiftRange = Range(match.range(at: 0), in: text) {
                    return String(text[swiftRange])
                }
            }
        }
        return nil
    }
}

// MARK: - Data Models

private struct Track: Decodable {
    let file: String
    let label: String?
    let kind: String
    let `default`: Bool?
}

private struct SourceItem: Decodable {
    let file: String
    let type: String?
}

private enum SourcesType: Decodable {
    case array([SourceItem])
    case string(String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([SourceItem].self) {
            self = .array(array)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            throw DecodingError.typeMismatch(
                SourcesType.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected array or string for sources"
                )
            )
        }
    }
}

private struct ExtractedSrc: Decodable {
    let sources: SourcesType
    let tracks: [Track]?
    let t: Int?
    let server: Int?
    let encrypted: Bool?
}
