// String+Extensions.swift
// Useful string extensions for common operations
// Provides utility methods for string manipulation and validation

import Foundation
import UIKit

extension String {
    
    // MARK: - Validation
    /// Checks if string is empty or contains only whitespace
    var isBlank: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Checks if string is a valid email address
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Checks if string contains only digits
    var isNumeric: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    // MARK: - Formatting
    /// Trims whitespace and newlines from both ends
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Capitalizes first letter of string
    var capitalizedFirst: String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }
    
    /// Converts string to URL-safe slug
    var slugified: String {
        let lowercased = self.lowercased()
        let components = lowercased.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return components.filter { !$0.isEmpty }.joined(separator: "-")
    }
    
    // MARK: - Truncation
    /// Truncates string to specified length with ellipsis
    /// - Parameters:
    ///   - length: Maximum length before truncation
    ///   - trailing: Trailing string to append (default: "...")
    /// - Returns: Truncated string
    func truncated(to length: Int, trailing: String = "...") -> String {
        guard self.count > length else { return self }
        return String(self.prefix(length)) + trailing
    }
    
    // MARK: - Subscript
    /// Safe subscript for accessing characters by index
    subscript(safe index: Int) -> Character? {
        guard index >= 0 && index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
    
    // MARK: - HTML
    /// Removes HTML tags from string
    var strippingHTML: String {
        return replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
    
    /// Decodes HTML entities
    var decodingHTMLEntities: String {
        guard let data = data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        return attributedString.string
    }
}