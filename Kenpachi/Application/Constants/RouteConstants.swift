// RouteConstants.swift
// Navigation route constants and deep link URL schemes
// Defines all navigation paths and deep linking structure

import Foundation

/// Enum containing all navigation and routing constants
enum RouteConstants {
    
    // MARK: - Deep Link Scheme
    /// App's custom URL scheme for deep linking
    static let scheme = "kenpachi"
    /// Universal link domain
    static let universalLinkDomain = "kenpachi.app"
    
    // MARK: - Route Paths
    /// Navigation route path identifiers
    enum Path {
        /// Home screen route
        static let home = "/home"
        /// Search screen route
        static let search = "/search"
        /// Downloads screen route
        static let downloads = "/downloads"
        /// MySpace (profile) screen route
        static let mySpace = "/myspace"
        /// Settings screen route
        static let settings = "/settings"
        /// Content detail screen route with ID parameter
        static let contentDetail = "/content/:id"
        /// Player screen route with content ID parameter
        static let player = "/player/:id"
        /// Watchlist screen route
        static let watchlist = "/watchlist"
        /// Continue watching screen route
        static let continueWatching = "/continue-watching"
    }
    
    // MARK: - Tab Identifiers
    /// Main tab bar item identifiers
    enum Tab: String, CaseIterable {
        /// Home tab identifier
        case home = "home"
        /// Search tab identifier
        case search = "search"
        /// Downloads tab identifier
        case downloads = "downloads"
        /// MySpace tab identifier
        case mySpace = "myspace"
        
        /// Display title for tab
        var title: String {
            switch self {
            case .home: return "Home"
            case .search: return "Search"
            case .downloads: return "Downloads"
            case .mySpace: return "MySpace"
            }
        }
        
        /// SF Symbol icon name for tab
        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .search: return "magnifyingglass"
            case .downloads: return "arrow.down.circle.fill"
            case .mySpace: return "person.fill"
            }
        }
    }
    
    // MARK: - Query Parameters
    /// URL query parameter keys
    enum QueryParam {
        /// Content ID parameter
        static let id = "id"
        /// Content type parameter
        static let type = "type"
        /// Search query parameter
        static let query = "q"
        /// Season number parameter
        static let season = "season"
        /// Episode number parameter
        static let episode = "episode"
    }
}
