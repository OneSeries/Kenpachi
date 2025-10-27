// AppConfiguration.swift
// Application configuration management
// Handles environment-specific settings and feature flags

import Foundation

/// Application configuration manager
/// Manages environment-specific settings and build configurations
final class AppConfiguration {
    /// Shared singleton instance
    static let shared = AppConfiguration()
    
    /// Current environment (development, staging, production)
    let environment: Environment
    /// Whether running in debug mode
    let isDebug: Bool
    /// Whether running in simulator
    let isSimulator: Bool
    
    /// Private initializer for singleton
    private init() {
        // Determine environment from build configuration
        #if DEBUG
        environment = .development
        isDebug = true
        #elseif STAGING
        environment = .staging
        isDebug = false
        #else
        environment = .production
        isDebug = false
        #endif
        
        // Check if running in simulator
        #if targetEnvironment(simulator)
        isSimulator = true
        #else
        isSimulator = false
        #endif
        
        // Log configuration
        AppLogger.shared.log(
            "App configured for environment: \(environment.rawValue)",
            level: .info
        )
    }
    
    /// Gets API base URL for current environment
    /// - Returns: Base URL string
    func getAPIBaseURL() -> String {
        return environment.apiBaseURL
    }
    
    /// Gets whether analytics is enabled for current environment
    /// - Returns: True if analytics should be enabled
    func isAnalyticsEnabled() -> Bool {
        return environment.analyticsEnabled && AppConstants.Features.analyticsEnabled
    }
    
    /// Gets whether crash reporting is enabled for current environment
    /// - Returns: True if crash reporting should be enabled
    func isCrashReportingEnabled() -> Bool {
        return environment.crashReportingEnabled && AppConstants.Features.crashReportingEnabled
    }
}

/// Environment enum for different build configurations
enum Environment: String {
    /// Development environment (local testing)
    case development
    /// Staging environment (pre-production testing)
    case staging
    /// Production environment (live app)
    case production
    
    /// API base URL for environment
    var apiBaseURL: String {
        switch self {
        case .development:
            return "https://dev-api.kenpachi.app"
        case .staging:
            return "https://staging-api.kenpachi.app"
        case .production:
            return "https://api.kenpachi.app"
        }
    }
    
    /// Whether analytics is enabled for environment
    var analyticsEnabled: Bool {
        switch self {
        case .development:
            return false
        case .staging:
            return true
        case .production:
            return true
        }
    }
    
    /// Whether crash reporting is enabled for environment
    var crashReportingEnabled: Bool {
        switch self {
        case .development:
            return false
        case .staging:
            return true
        case .production:
            return true
        }
    }
    
    /// Log level for environment
    var logLevel: LogLevel {
        switch self {
        case .development:
            return .debug
        case .staging:
            return .info
        case .production:
            return .warning
        }
    }
}
