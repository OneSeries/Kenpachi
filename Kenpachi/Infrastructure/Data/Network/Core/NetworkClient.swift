// NetworkClient.swift
// Core network client for making HTTP requests
// Provides async/await interface with error handling and retry logic

import Foundation

/// Protocol defining network client capabilities
protocol NetworkClientProtocol {
    /// Performs a network request and returns decoded response
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    /// Performs a network request and returns raw data
    func requestData(_ endpoint: Endpoint) async throws -> Data
}

/// Core network client implementation
final class NetworkClient: NetworkClientProtocol {
    /// Shared singleton instance
    static let shared = NetworkClient()
    
    /// URLSession for network requests
    private let session: URLSession
    
    /// Initializer with custom URLSession configuration
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Performs a network request and returns decoded response
    /// - Parameter endpoint: The endpoint to request
    /// - Returns: Decoded response of type T
    /// - Throws: NetworkError if request fails
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await requestData(endpoint)
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    /// Performs a network request and returns raw data
    /// - Parameter endpoint: The endpoint to request
    /// - Returns: Raw response data
    /// - Throws: NetworkError if request fails
    func requestData(_ endpoint: Endpoint) async throws -> Data {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = APIConstants.Network.timeoutInterval
        
        // Add headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if present
        if let body = endpoint.body {
            request.httpBody = body
        }
        
        // Perform request with retry logic
        return try await performRequestWithRetry(request)
    }
    
    /// Performs request with automatic retry on failure
    /// - Parameter request: URLRequest to perform
    /// - Returns: Response data
    /// - Throws: NetworkError if all retry attempts fail
    private func performRequestWithRetry(_ request: URLRequest) async throws -> Data {
        var lastError: Error?
        
        for attempt in 0..<APIConstants.Network.maxRetryAttempts {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
                
                return data
            } catch {
                lastError = error
                
                // Don't retry on client errors (4xx)
                if let networkError = error as? NetworkError,
                   case .httpError(let code) = networkError,
                   (400...499).contains(code) {
                    throw error
                }
                
                // Wait before retry (except on last attempt)
                if attempt < APIConstants.Network.maxRetryAttempts - 1 {
                    try await Task.sleep(nanoseconds: UInt64(APIConstants.Network.retryDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NetworkError.unknown
    }
}

/// Endpoint protocol defining request configuration
protocol Endpoint {
    /// Base URL for the endpoint
    var baseURL: String { get }
    /// Path component of the URL
    var path: String { get }
    /// HTTP method
    var method: HTTPMethod { get }
    /// Query parameters
    var queryItems: [URLQueryItem]? { get }
    /// HTTP headers
    var headers: [String: String]? { get }
    /// Request body
    var body: Data? { get }
}

extension Endpoint {
    /// Constructs full URL from components
    var url: URL? {
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems
        return components?.url
    }
}
