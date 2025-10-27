// HTMLParser.swift
// HTML parsing utilities using SwiftSoup
// Provides helper methods for extracting data from HTML

import Foundation
import SwiftSoup

/// HTML parsing utility class
final class HTMLParser {
    
    /// Parses HTML string into Document
    /// - Parameter html: HTML string to parse
    /// - Returns: SwiftSoup Document
    /// - Throws: ScraperError if parsing fails
    static func parse(_ html: String) throws -> Document {
        do {
            return try SwiftSoup.parse(html)
        } catch {
            throw ScraperError.parsingFailed("Failed to parse HTML: \(error.localizedDescription)")
        }
    }
    
    /// Extracts text from element
    /// - Parameters:
    ///   - element: Element to extract from
    ///   - selector: CSS selector
    /// - Returns: Extracted text or nil
    static func extractText(from element: Element, selector: String) -> String? {
        try? element.select(selector).first()?.text()
    }
    
    /// Extracts attribute from element
    /// - Parameters:
    ///   - element: Element to extract from
    ///   - selector: CSS selector
    ///   - attribute: Attribute name
    /// - Returns: Attribute value or nil
    static func extractAttribute(from element: Element, selector: String, attribute: String) -> String? {
        try? element.select(selector).first()?.attr(attribute)
    }
    
    /// Extracts all elements matching selector
    /// - Parameters:
    ///   - document: Document to search
    ///   - selector: CSS selector
    /// - Returns: Array of elements
    static func extractElements(from document: Document, selector: String) -> [Element] {
        (try? document.select(selector).array()) ?? []
    }
}