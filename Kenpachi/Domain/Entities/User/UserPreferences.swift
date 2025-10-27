// UserPreferences.swift
// Domain entity representing user preferences and settings
// Stores all app configuration and user choices

import Foundation

/// Theme mode options
enum ThemeMode: String, Equatable, Codable, CaseIterable {
  case light
  case dark
  case system
}

/// Accent color options
enum AccentColorOption: String, Equatable, Codable, CaseIterable {
  case blue
  case purple
  case pink
  case red
  case orange
  case yellow
  case green
  case teal
}

/// Auto-lock timeout options
enum AutoLockTimeout: Int, Equatable, Codable, CaseIterable {
  case oneMinute = 60
  case fiveMinutes = 300
  case tenMinutes = 600
  case thirtyMinutes = 1800
  case never = 0
}

/// Scraper source options
enum ScraperSource: String, Equatable, CaseIterable {
  case FlixHQ
  case Movies111 = "111Movies"
  case VidSrc
  case VidRock
  case VidFast
  case VidNest
  case AnimeKai
  case GogoAnime
  case HiAnime
}

// MARK: - ScraperSource Codable
extension ScraperSource: Codable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    
    // Handle both case name and raw value
    switch rawValue {
    case "FlixHQ": self = .FlixHQ
    case "111Movies", "Movies111": self = .Movies111
    case "VidSrc": self = .VidSrc
    case "VidRock": self = .VidRock
    case "VidFast": self = .VidFast
    case "VidNest": self = .VidNest
    case "AnimeKai": self = .AnimeKai
    case "GogoAnime": self = .GogoAnime
    case "HiAnime": self = .HiAnime
    default:
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid scraper source: \(rawValue)"
      )
    }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.rawValue)
  }
}

/// Content language options
enum ContentLanguage: String, Equatable, Codable, CaseIterable {
  case english
  case hindi
  case tamil
  case telugu
  case malayalam
  case kannada
}

/// Video quality options
enum VideoQuality: String, Equatable, Codable, CaseIterable {
  case auto
  case sd480 = "480p"
  case hd720 = "720p"
  case hd1080 = "1080p"
  case uhd4k = "4K"
}

/// Subtitle language options
enum SubtitleLanguage: String, Equatable, Codable, CaseIterable {
  case english
  case hindi
  case tamil
  case telugu
  case malayalam
  case kannada
  case none
}

/// Audio language options
enum AudioLanguage: String, Equatable, Codable, CaseIterable {
  case original
  case english
  case hindi
  case tamil
  case telugu
}

/// Playback speed options
enum PlaybackSpeed: Double, Equatable, Codable, CaseIterable {
  case slow = 0.5
  case normal = 1.0
  case fast = 1.25
  case faster = 1.5
  case fastest = 2.0
}

/// Represents comprehensive user preferences for the app
struct UserPreferences: Equatable, Codable {
  /// Theme and appearance
  var theme: ThemeMode
  var accentColor: AccentColorOption

  /// Security
  var biometricAuthEnabled: Bool
  var autoLockTimeout: AutoLockTimeout

  /// Content preferences
  var defaultScraperSource: ScraperSource
  var preferredLanguage: ContentLanguage
  var showAdultContent: Bool

  /// Parental Controls
  var parentalControlsEnabled: Bool
  var allowedContentRating: ContentRating

  /// Player settings
  var autoPlayEnabled: Bool
  var autoPlayTrailers: Bool
  var defaultQuality: VideoQuality
  var subtitlesEnabled: Bool
  var preferredSubtitleLanguage: SubtitleLanguage
  var preferredAudioLanguage: AudioLanguage
  var playbackSpeed: PlaybackSpeed

  /// Download settings
  var downloadQuality: VideoQuality
  var downloadOverCellular: Bool
  var autoDeleteWatchedDownloads: Bool

  /// Notification settings
  var pushNotificationsEnabled: Bool
  var newContentNotifications: Bool
  var downloadCompleteNotifications: Bool
  var recommendationNotifications: Bool

  /// Streaming settings
  var airPlayEnabled: Bool
  var chromecastEnabled: Bool
  var pipEnabled: Bool

  /// Privacy settings
  var analyticsEnabled: Bool
  var crashReportingEnabled: Bool
  var personalizedRecommendations: Bool
  var searchHistoryEnabled: Bool

  /// Default initializer with sensible defaults
  init(
    theme: ThemeMode = .system,
    accentColor: AccentColorOption = .blue,
    biometricAuthEnabled: Bool = false,
    autoLockTimeout: AutoLockTimeout = .fiveMinutes,
    defaultScraperSource: ScraperSource = .FlixHQ,
    preferredLanguage: ContentLanguage = .english,
    showAdultContent: Bool = false,
    parentalControlsEnabled: Bool = false,
    allowedContentRating: ContentRating = .unrestricted,
    autoPlayEnabled: Bool = true,
    autoPlayTrailers: Bool = true,
    defaultQuality: VideoQuality = .auto,
    subtitlesEnabled: Bool = false,
    preferredSubtitleLanguage: SubtitleLanguage = .english,
    preferredAudioLanguage: AudioLanguage = .original,
    playbackSpeed: PlaybackSpeed = .normal,
    downloadQuality: VideoQuality = .hd720,
    downloadOverCellular: Bool = false,
    autoDeleteWatchedDownloads: Bool = false,
    pushNotificationsEnabled: Bool = true,
    newContentNotifications: Bool = true,
    downloadCompleteNotifications: Bool = true,
    recommendationNotifications: Bool = true,
    airPlayEnabled: Bool = true,
    chromecastEnabled: Bool = true,
    pipEnabled: Bool = true,
    analyticsEnabled: Bool = true,
    crashReportingEnabled: Bool = true,
    personalizedRecommendations: Bool = true,
    searchHistoryEnabled: Bool = true
  ) {
    self.theme = theme
    self.accentColor = accentColor
    self.biometricAuthEnabled = biometricAuthEnabled
    self.autoLockTimeout = autoLockTimeout
    self.defaultScraperSource = defaultScraperSource
    self.preferredLanguage = preferredLanguage
    self.showAdultContent = showAdultContent
    self.parentalControlsEnabled = parentalControlsEnabled
    self.allowedContentRating = allowedContentRating
    self.autoPlayEnabled = autoPlayEnabled
    self.autoPlayTrailers = autoPlayTrailers
    self.defaultQuality = defaultQuality
    self.subtitlesEnabled = subtitlesEnabled
    self.preferredSubtitleLanguage = preferredSubtitleLanguage
    self.preferredAudioLanguage = preferredAudioLanguage
    self.playbackSpeed = playbackSpeed
    self.downloadQuality = downloadQuality
    self.downloadOverCellular = downloadOverCellular
    self.autoDeleteWatchedDownloads = autoDeleteWatchedDownloads
    self.pushNotificationsEnabled = pushNotificationsEnabled
    self.newContentNotifications = newContentNotifications
    self.downloadCompleteNotifications = downloadCompleteNotifications
    self.recommendationNotifications = recommendationNotifications
    self.airPlayEnabled = airPlayEnabled
    self.chromecastEnabled = chromecastEnabled
    self.pipEnabled = pipEnabled
    self.analyticsEnabled = analyticsEnabled
    self.crashReportingEnabled = crashReportingEnabled
    self.personalizedRecommendations = personalizedRecommendations
    self.searchHistoryEnabled = searchHistoryEnabled
  }
}
