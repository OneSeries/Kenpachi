// NetworkError.swift
// Network error types for handling API failures
// Provides detailed error information for debugging and user feedback

import Foundation

/// Enum representing all possible network errors
enum NetworkError: Error, LocalizedError {
    /// Invalid URL construction
    case invalidURL
    /// Invalid response from server
    case invalidResponse
    /// HTTP error with status code
    case httpError(Int)
    /// Failed to decode response
    case decodingFailed(Error)
    /// Failed to encode request
    case encodingFailed(Error)
    /// Network connection unavailable
    case noConnection
    /// Request timeout
    case timeout
    /// Unknown error
    case unknown
    
    /// User-friendly error description
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timeout"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}
