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
    
    // MARK: - Cache Configuration
    /// Cache settings for performance optimization
    enum Cache {
        /// Maximum memory cache size in bytes (50 MB)
        static let maxMemorySize: Int = 50 * 1024 * 1024
        /// Maximum disk cache size in bytes (200 MB)
        static let maxDiskSize: Int = 200 * 1024 * 1024
        /// Cache expiration time in seconds (7 days)
        static let expirationTime: TimeInterval = 7 * 24 * 60 * 60
        /// Image cache size in bytes (100 MB)
        static let imageCacheSize: Int = 100 * 1024 * 1024
    }
    
    // MARK: - Accessibility
    /// Accessibility configuration
    enum Accessibility {
        /// Minimum touch target size (44x44 points per Apple HIG)
        static let minTouchTargetSize: CGFloat = 44
        /// Enable VoiceOver support
        static let voiceOverEnabled = true
        /// Enable Dynamic Type support
        static let dynamicTypeEnabled = true
        /// Minimum WCAG compliance level
        static let wcagLevel = "AA"
    }
    
    // MARK: - Localization
    /// Localization settings
    enum Localization {
        /// Supported languages
        static let supportedLanguages = ["en", "hi", "ta", "te", "ml", "kn", "bn", "mr"]
        /// Default language
        static let defaultLanguage = "en"
        /// Enable RTL support
        static let rtlEnabled = true
    }
    
    // MARK: - Security
    /// Security and privacy settings
    enum Security {
        /// Enable certificate pinning for API calls
        static let certificatePinningEnabled = false
        /// Use Keychain for sensitive data
        static let useKeychainStorage = true
        /// Enable encrypted local storage
        static let encryptedStorageEnabled = true
        /// Biometric authentication timeout in seconds
        static let biometricTimeout: TimeInterval = 300
    }
    
    // MARK: - Performance
    /// Performance optimization settings
    enum Performance {
        /// Enable lazy loading for images
        static let lazyLoadingEnabled = true
        /// Maximum concurrent image loads
        static let maxConcurrentImageLoads = 6
        /// Enable background processing
        static let backgroundProcessingEnabled = true
        /// Database query timeout in seconds
        static let databaseTimeout: TimeInterval = 10
    }
    
    // MARK: - Deep Linking
    /// Deep linking configuration
    enum DeepLink {
        /// URL scheme for deep links
        static let urlScheme = "kenpachi"
        /// Universal link domain
        static let universalLinkDomain = "kenpachi.app"
        /// Enable deep linking
        static let enabled = true
    }
    
    // MARK: - Storage Keys
    /// Keys for UserDefaults and other storage
    enum StorageKeys {
        /// Onboarding completion flag
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        /// Selected theme preference
        static let selectedTheme = "selectedTheme"
        /// Biometric authentication enabled flag
        static let biometricAuthEnabled = "biometricAuthEnabled"
        /// Default scraper source selection
        static let defaultScraperSource = "defaultScraperSource"
        /// Download quality preference
        static let downloadQuality = "downloadQuality"
        /// Auto-play next episode flag
        static let autoPlayEnabled = "autoPlayEnabled"
        /// Subtitles enabled flag
        static let subtitlesEnabled = "subtitlesEnabled"
        /// Preferred language code
        static let preferredLanguage = "preferredLanguage"
        /// Preferred subtitle language
        static let preferredSubtitleLanguage = "preferredSubtitleLanguage"
        /// Download over cellular flag
        static let downloadOverCellular = "downloadOverCellular"
        /// Video quality preference
        static let videoQuality = "videoQuality"
        /// Playback speed preference
        static let playbackSpeed = "playbackSpeed"
        /// Continue watching data
        static let continueWatching = "continueWatching"
        /// Watchlist data
        static let watchlist = "watchlist"
        /// Watch history data
        static let watchHistory = "watchHistory"
        /// Recent searches
        static let recentSearches = "recentSearches"
        /// Notification preferences
        static let notificationPreferences = "notificationPreferences"
        /// Last app version
        static let lastAppVersion = "lastAppVersion"
        /// First launch date
        static let firstLaunchDate = "firstLaunchDate"
        /// Total watch time in seconds
        static let totalWatchTime = "totalWatchTime"
        /// Parental control PIN
        static let parentalControlPIN = "parentalControlPIN"
        /// Parental control enabled flag
        static let parentalControlEnabled = "parentalControlEnabled"
    }
}
