// HTTPMethod.swift
// HTTP method definitions for network requests
// Provides type-safe HTTP method constants

import Foundation

/// Enum representing HTTP methods
enum HTTPMethod: String {
    /// GET method for retrieving data
    case get = "GET"
    /// POST method for creating data
    case post = "POST"
    /// PUT method for updating data
    case put = "PUT"
    /// DELETE method for removing data
    case delete = "DELETE"
    /// PATCH method for partial updates
    case patch = "PATCH"
    /// HEAD method for retrieving headers only
    case head = "HEAD"
}
