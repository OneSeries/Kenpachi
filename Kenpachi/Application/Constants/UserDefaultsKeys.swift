// UserDefaultsKeys.swift
// Type-safe keys for UserDefaults storage
// Provides compile-time safety for user preferences and app state

import Foundation

/// Type-safe wrapper for UserDefaults keys
enum UserDefaultsKeys {
    
    // MARK: - Onboarding & First Launch
    /// Key for tracking if user has completed onboarding
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    /// Key for tracking first launch date
    static let firstLaunchDate = "firstLaunchDate"
    /// Key for tracking app version on last launch
    static let lastLaunchedVersion = "lastLaunchedVersion"
    
    // MARK: - Theme & Appearance
    /// Key for selected theme mode (light/dark/system)
    static let selectedTheme = "selectedTheme"
    /// Key for custom accent color
    static let accentColor = "accentColor"
    /// Key for reduced motion preference
    static let reducedMotionEnabled = "reducedMotionEnabled"
    
    // MARK: - Authentication
    /// Key for biometric authentication enabled state
    static let biometricAuthEnabled = "biometricAuthEnabled"
    /// Key for biometric authentication type (FaceID/TouchID)
    static let biometricAuthType = "biometricAuthType"
    /// Key for auto-lock timeout in seconds
    static let autoLockTimeout = "autoLockTimeout"
    
    // MARK: - Content Preferences
    /// Key for default scraper source selection
    static let defaultScraperSource = "defaultScraperSource"
    /// Key for preferred content language
    static let preferredContentLanguage = "preferredContentLanguage"
    /// Key for content maturity rating filter
    static let maturityRatingFilter = "maturityRatingFilter"
    /// Key for show adult content preference
    static let showAdultContent = "showAdultContent"
    /// Key for parental controls enabled state
    static let parentalControlsEnabled = "parentalControlsEnabled"
    /// Key for allowed content rating
    static let allowedContentRating = "allowedContentRating"
    
    // MARK: - Player Settings
    /// Key for auto-play next episode setting
    static let autoPlayEnabled = "autoPlayEnabled"
    /// Key for auto-play trailers on detail pages
    static let autoPlayTrailers = "autoPlayTrailers"
    /// Key for default playback quality
    static let defaultPlaybackQuality = "defaultPlaybackQuality"
    /// Key for subtitles enabled by default
    static let subtitlesEnabled = "subtitlesEnabled"
    /// Key for preferred subtitle language
    static let preferredSubtitleLanguage = "preferredSubtitleLanguage"
    /// Key for preferred audio language
    static let preferredAudioLanguage = "preferredAudioLanguage"
    /// Key for default playback speed
    static let defaultPlaybackSpeed = "defaultPlaybackSpeed"
    
    // MARK: - Download Settings
    /// Key for download quality preference
    static let downloadQuality = "downloadQuality"
    /// Key for download over cellular data permission
    static let downloadOverCellular = "downloadOverCellular"
    /// Key for auto-delete watched downloads
    static let autoDeleteWatchedDownloads = "autoDeleteWatchedDownloads"
    /// Key for download location path
    static let downloadLocation = "downloadLocation"
    
    // MARK: - Notification Settings
    /// Key for push notifications enabled state
    static let pushNotificationsEnabled = "pushNotificationsEnabled"
    /// Key for new content notifications
    static let newContentNotifications = "newContentNotifications"
    /// Key for download complete notifications
    static let downloadCompleteNotifications = "downloadCompleteNotifications"
    /// Key for recommendation notifications
    static let recommendationNotifications = "recommendationNotifications"
    
    // MARK: - Search History
    /// Key for recent search queries array
    static let recentSearches = "recentSearches"
    /// Key for search history enabled state
    static let searchHistoryEnabled = "searchHistoryEnabled"
    
    // MARK: - Streaming Settings
    /// Key for AirPlay enabled state
    static let airPlayEnabled = "airPlayEnabled"
    /// Key for Chromecast enabled state
    static let chromecastEnabled = "chromecastEnabled"
    /// Key for Picture-in-Picture enabled state
    static let pipEnabled = "pipEnabled"
    
    // MARK: - Analytics & Privacy
    /// Key for analytics tracking consent
    static let analyticsEnabled = "analyticsEnabled"
    /// Key for crash reporting consent
    static let crashReportingEnabled = "crashReportingEnabled"
    /// Key for personalized recommendations consent
    static let personalizedRecommendations = "personalizedRecommendations"
}

// MARK: - UserDefaults Extension
/// Extension providing type-safe access to UserDefaults
extension UserDefaults {
    
    /// Convenience method to check if onboarding is completed
    var hasCompletedOnboarding: Bool {
        get { bool(forKey: UserDefaultsKeys.hasCompletedOnboarding) }
        set { set(newValue, forKey: UserDefaultsKeys.hasCompletedOnboarding) }
    }
    
    /// Convenience method to get/set selected theme
    var selectedTheme: String? {
        get { string(forKey: UserDefaultsKeys.selectedTheme) }
        set { set(newValue, forKey: UserDefaultsKeys.selectedTheme) }
    }
    
    /// Convenience method to check if biometric auth is enabled
    var isBiometricAuthEnabled: Bool {
        get { bool(forKey: UserDefaultsKeys.biometricAuthEnabled) }
        set { set(newValue, forKey: UserDefaultsKeys.biometricAuthEnabled) }
    }
    
    /// Convenience method to get/set default scraper source
    var defaultScraperSource: String? {
        get { string(forKey: UserDefaultsKeys.defaultScraperSource) }
        set { set(newValue, forKey: UserDefaultsKeys.defaultScraperSource) }
    }
}
