// AppConstants.swift
// Application-wide constants for UI, features, and general configuration
// Provides centralized access to app-level settings and values

import Foundation
import SwiftUI

/// Enum containing all application-level constants
enum AppConstants {
    
    // MARK: - App Information
    /// Basic app metadata
    enum App {
        /// Application display name
        static let name = "Kenpachi"
        /// App bundle identifier
        static let bundleIdentifier = "com.kenpachi.app"
        /// Current app version
        static let version = "1.0.0"
        /// Build number
        static let buildNumber = "1"
        /// App Store ID (to be set after app store submission)
        static let appStoreID = ""
    }
    
    // MARK: - UI Constants
    /// User interface related constants
    enum UI {
        /// Standard corner radius for cards and buttons
        static let cornerRadius: CGFloat = 8
        /// Large corner radius for prominent elements
        static let largeCornerRadius: CGFloat = 16
        /// Small corner radius for subtle elements
        static let smallCornerRadius: CGFloat = 4
        
        /// Standard padding values
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        
        /// Animation durations
        static let shortAnimationDuration: Double = 0.2
        static let standardAnimationDuration: Double = 0.3
        static let longAnimationDuration: Double = 0.5
        
        /// Content card dimensions
        static let posterAspectRatio: CGFloat = 2.0 / 3.0 // Portrait poster (2:3)
        static let backdropAspectRatio: CGFloat = 16.0 / 9.0 // Landscape backdrop (16:9)
        static let cardWidth: CGFloat = 140
        static let cardHeight: CGFloat = 210
        
        /// Hero carousel settings
        static let heroCarouselHeight: CGFloat = 500
        static let heroAutoPlayInterval: TimeInterval = 5.0
        
        /// Tab bar configuration
        static let tabBarHeight: CGFloat = 60
    }
    
    // MARK: - Feature Flags
    /// Feature toggles for enabling/disabling functionality
    enum Features {
        /// Enable biometric authentication
        static let biometricAuthEnabled = true
        /// Enable push notifications
        static let pushNotificationsEnabled = true
        /// Enable downloads feature
        static let downloadsEnabled = true
        /// Enable Chromecast support
        static let chromecastEnabled = true
        /// Enable AirPlay support
        static let airPlayEnabled = true
        /// Enable Picture-in-Picture
        static let pipEnabled = true
        /// Enable analytics tracking
        static let analyticsEnabled = false // Disabled for privacy
        /// Enable crash reporting
        static let crashReportingEnabled = false
    }
    
    // MARK: - Content Configuration
    /// Content display and loading settings
    enum Content {
        /// Number of items to load per page
        static let itemsPerPage = 20
        /// Maximum number of items in continue watching
        static let maxContinueWatchingItems = 10
        /// Maximum number of items in watchlist preview
        static let maxWatchlistPreviewItems = 20
        /// Minimum watch progress to show in continue watching (10%)
        static let minWatchProgressPercentage: Double = 0.1
        /// Maximum watch progress to show in continue watching (90%)
        static let maxWatchProgressPercentage: Double = 0.9
    }
    
    // MARK: - Download Configuration
    /// Download feature settings
    enum Downloads {
        /// Available download quality options
        enum Quality: String, CaseIterable {
            case low = "480p"
            case medium = "720p"
            case high = "1080p"
        }
        
        /// Default download quality
        static let defaultQuality = Quality.medium
        /// Maximum concurrent downloads
        static let maxConcurrentDownloads = 3
        /// Download expiration period in days
        static let expirationDays = 30
        /// Minimum free storage required in bytes (1 GB)
        static let minFreeStorageRequired: Int64 = 1024 * 1024 * 1024
    }
    
    // MARK: - Player Configuration
    /// Video player settings
    enum Player {
        /// Available playback speeds
        static let playbackSpeeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
        /// Default playback speed
        static let defaultPlaybackSpeed: Float = 1.0
        /// Auto-play next episode delay in seconds
        static let autoPlayNextDelay: TimeInterval = 5.0
        /// Skip intro/outro duration in seconds
        static let skipDuration: TimeInterval = 85.0
        /// Player control hide delay in seconds
        static let controlsHideDelay: TimeInterval = 3.0
    }
    
    // MARK: - Search Configuration
    /// Search feature settings
    enum Search {
        /// Debounce delay for search input in seconds
        static let debounceDelay: TimeInterval = 0.5
        /// Maximum number of recent searches to store
        static let maxRecentSearches = 10
        /// Minimum search query length
        static let minQueryLength = 2
    }
    
    // MARK: - Storage Keys
    /// Keys for UserDefaults and other storage
    enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedTheme = "selectedTheme"
        static let biometricAuthEnabled = "biometricAuthEnabled"
        static let defaultScraperSource = "defaultScraperSource"
        static let downloadQuality = "downloadQuality"
        static let autoPlayEnabled = "autoPlayEnabled"
        static let subtitlesEnabled = "subtitlesEnabled"
        static let preferredLanguage = "preferredLanguage"
    }
}
