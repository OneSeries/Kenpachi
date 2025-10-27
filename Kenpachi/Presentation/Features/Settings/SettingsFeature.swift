// SettingsFeature.swift
// TCA feature for Settings screen
// Manages app settings and user preferences

import ComposableArchitecture
import Foundation
import SwiftUI

/// Settings feature reducer
@Reducer
struct SettingsFeature {
  /// Settings state
  @ObservableState
  struct State: Equatable {
    /// General settings
    var appVersion: String =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
      ?? "1.0.0"
    var buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    /// Theme settings
    var selectedTheme: ThemeMode = .system
    var accentColor: AccentColorOption = .blue

    /// Authentication settings
    var biometricAuthEnabled: Bool = false
    var biometricAuthType: BiometricType = .none
    var autoLockTimeout: AutoLockTimeout = .fiveMinutes

    /// Content preferences
    var defaultScraperSource: ScraperSource = .FlixHQ
    var preferredLanguage: ContentLanguage = .english
    var showAdultContent: Bool = false

    /// Parental Controls
    var parentalControlsEnabled: Bool = false
    var allowedContentRating: ContentRating = .unrestricted

    /// Player settings
    var autoPlayEnabled: Bool = true
    var autoPlayTrailers: Bool = true
    var defaultQuality: VideoQuality = .auto
    var subtitlesEnabled: Bool = false
    var preferredSubtitleLanguage: SubtitleLanguage = .english
    var preferredAudioLanguage: AudioLanguage = .original
    var playbackSpeed: PlaybackSpeed = .normal

    /// Download settings
    var downloadQuality: VideoQuality = .hd720
    var downloadOverCellular: Bool = false
    var autoDeleteWatchedDownloads: Bool = false

    /// Notification settings
    var pushNotificationsEnabled: Bool = true
    var newContentNotifications: Bool = true
    var downloadCompleteNotifications: Bool = true
    var recommendationNotifications: Bool = true

    /// Streaming settings
    var airPlayEnabled: Bool = true
    var chromecastEnabled: Bool = true
    var pipEnabled: Bool = true

    /// Privacy settings
    var analyticsEnabled: Bool = true
    var crashReportingEnabled: Bool = true
    var personalizedRecommendations: Bool = true
    var searchHistoryEnabled: Bool = true

    /// Storage info
    var totalStorageUsed: Int64 = 0
    var cacheSize: Int64 = 0
    var downloadsSize: Int64 = 0

    /// Loading states
    var isLoadingSettings: Bool = false
    var isClearingCache: Bool = false

    /// Alert state
    @Presents var alert: AlertState<Action.Alert>?
  }

  /// Settings actions
  enum Action: Equatable {
    /// View appeared
    case onAppear
    /// Load settings
    case loadSettings
    /// Settings loaded
    case settingsLoaded(UserPreferences, StorageInfo)

    /// Theme actions
    case themeChanged(ThemeMode)
    case accentColorChanged(AccentColorOption)

    /// Authentication actions
    case biometricAuthToggled(Bool)
    case autoLockTimeoutChanged(AutoLockTimeout)

    /// Content actions
    case scraperSourceChanged(ScraperSource)
    case preferredLanguageChanged(ContentLanguage)
    case showAdultContentToggled(Bool)

    /// Parental Controls
    case parentalControlsToggled(Bool)
    case allowedContentRatingChanged(ContentRating)

    /// Player actions
    case autoPlayToggled(Bool)
    case autoPlayTrailersToggled(Bool)
    case defaultQualityChanged(VideoQuality)
    case subtitlesToggled(Bool)
    case subtitleLanguageChanged(SubtitleLanguage)
    case audioLanguageChanged(AudioLanguage)
    case playbackSpeedChanged(PlaybackSpeed)

    /// Download actions
    case downloadQualityChanged(VideoQuality)
    case downloadOverCellularToggled(Bool)
    case autoDeleteWatchedToggled(Bool)

    /// Notification actions
    case pushNotificationsToggled(Bool)
    case newContentNotificationsToggled(Bool)
    case downloadNotificationsToggled(Bool)
    case recommendationNotificationsToggled(Bool)

    /// Streaming actions
    case airPlayToggled(Bool)
    case chromecastToggled(Bool)
    case pipToggled(Bool)

    /// Privacy actions
    case analyticsToggled(Bool)
    case crashReportingToggled(Bool)
    case personalizedRecommendationsToggled(Bool)
    case searchHistoryToggled(Bool)

    /// Storage actions
    case clearCacheTapped
    case clearCacheConfirmed
    case cacheCleared(Int64)
    case clearSearchHistoryTapped
    case searchHistoryCleared

    /// Other actions
    case aboutTapped
    case helpTapped
    case privacyPolicyTapped
    case termsOfServiceTapped
    case logoutTapped

    /// Alert actions
    case alert(PresentationAction<Alert>)

    /// Delegate actions
    case delegate(Delegate)

    /// Alert action enum
    enum Alert: Equatable {
      case confirmClearCache
      case confirmClearSearchHistory
      case confirmLogout
    }

    /// Delegate action enum
    enum Delegate: Equatable {
      case settingsUpdated
      case logout
    }
  }

  /// Dependencies
  @Dependency(\.userDefaults) var userDefaults

  /// Reducer body
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .send(.loadSettings)

      case .loadSettings:
        state.isLoadingSettings = true
        return .run { send in
          /// Load preferences from UserDefaults
          let preferences = loadUserPreferences()
          /// Get storage info
          let storageInfo = await getStorageInfo()
          await send(.settingsLoaded(preferences, storageInfo))
        }

      case .settingsLoaded(let preferences, let storageInfo):
        state.isLoadingSettings = false
        /// Update state with loaded preferences
        state.selectedTheme = preferences.theme
        state.accentColor = preferences.accentColor
        state.biometricAuthEnabled = preferences.biometricAuthEnabled
        state.autoLockTimeout = preferences.autoLockTimeout
        state.defaultScraperSource = preferences.defaultScraperSource
        state.preferredLanguage = preferences.preferredLanguage
        state.showAdultContent = preferences.showAdultContent
        state.parentalControlsEnabled = preferences.parentalControlsEnabled
        state.allowedContentRating = preferences.allowedContentRating
        state.autoPlayEnabled = preferences.autoPlayEnabled
        state.autoPlayTrailers = preferences.autoPlayTrailers
        state.defaultQuality = preferences.defaultQuality
        state.subtitlesEnabled = preferences.subtitlesEnabled
        state.preferredSubtitleLanguage = preferences.preferredSubtitleLanguage
        state.preferredAudioLanguage = preferences.preferredAudioLanguage
        state.playbackSpeed = preferences.playbackSpeed
        state.downloadQuality = preferences.downloadQuality
        state.downloadOverCellular = preferences.downloadOverCellular
        state.autoDeleteWatchedDownloads = preferences.autoDeleteWatchedDownloads
        state.pushNotificationsEnabled = preferences.pushNotificationsEnabled
        state.newContentNotifications = preferences.newContentNotifications
        state.downloadCompleteNotifications = preferences.downloadCompleteNotifications
        state.recommendationNotifications = preferences.recommendationNotifications
        state.airPlayEnabled = preferences.airPlayEnabled
        state.chromecastEnabled = preferences.chromecastEnabled
        state.pipEnabled = preferences.pipEnabled
        state.analyticsEnabled = preferences.analyticsEnabled
        state.crashReportingEnabled = preferences.crashReportingEnabled
        state.personalizedRecommendations = preferences.personalizedRecommendations
        state.searchHistoryEnabled = preferences.searchHistoryEnabled
        /// Update storage info
        state.totalStorageUsed = storageInfo.totalUsed
        state.cacheSize = storageInfo.cacheSize
        state.downloadsSize = storageInfo.downloadsSize
        return .none

      case .themeChanged(let theme):
        state.selectedTheme = theme
        return .run { _ in
          userDefaults.set(theme.rawValue, forKey: UserDefaultsKeys.selectedTheme)
          /// Apply theme immediately
          await MainActor.run {
            ThemeManager.shared.setThemeFromMode(theme)
          }
        }

      case .accentColorChanged(let color):
        state.accentColor = color
        return .run { _ in
          userDefaults.set(color.rawValue, forKey: UserDefaultsKeys.accentColor)
        }

      case .biometricAuthToggled(let enabled):
        state.biometricAuthEnabled = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.biometricAuthEnabled)
        }

      case .autoLockTimeoutChanged(let timeout):
        state.autoLockTimeout = timeout
        return .run { _ in
          userDefaults.set(timeout.rawValue, forKey: UserDefaultsKeys.autoLockTimeout)
        }

      case .scraperSourceChanged(let source):
        state.defaultScraperSource = source
        return .run { send in
          userDefaults.set(source.rawValue, forKey: UserDefaultsKeys.defaultScraperSource)
          /// Apply scraper source immediately
          await MainActor.run {
            let scraperName = source.displayName
            ScraperManager.shared.setActiveScraper(name: scraperName)
          }
          /// Notify that settings were updated to trigger home refresh
          await send(.delegate(.settingsUpdated))
        }

      case .preferredLanguageChanged(let language):
        state.preferredLanguage = language
        return .run { _ in
          userDefaults.set(language.rawValue, forKey: UserDefaultsKeys.preferredContentLanguage)
        }

      case .showAdultContentToggled(let enabled):
        state.showAdultContent = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.showAdultContent)
        }

      case .parentalControlsToggled(let enabled):
        state.parentalControlsEnabled = enabled
        return .run { _ in
            userDefaults.set(enabled, forKey: UserDefaultsKeys.parentalControlsEnabled)
        }

      case .allowedContentRatingChanged(let rating):
        state.allowedContentRating = rating
        return .run { _ in
            userDefaults.set(rating.rawValue, forKey: UserDefaultsKeys.allowedContentRating)
        }

      case .autoPlayToggled(let enabled):
        state.autoPlayEnabled = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.autoPlayEnabled)
        }

      case .autoPlayTrailersToggled(let enabled):
        state.autoPlayTrailers = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.autoPlayTrailers)
        }

      case .defaultQualityChanged(let quality):
        state.defaultQuality = quality
        return .run { _ in
          userDefaults.set(quality.rawValue, forKey: UserDefaultsKeys.defaultPlaybackQuality)
        }

      case .subtitlesToggled(let enabled):
        state.subtitlesEnabled = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.subtitlesEnabled)
        }

      case .subtitleLanguageChanged(let language):
        state.preferredSubtitleLanguage = language
        return .run { _ in
          userDefaults.set(language.rawValue, forKey: UserDefaultsKeys.preferredSubtitleLanguage)
        }

      case .audioLanguageChanged(let language):
        state.preferredAudioLanguage = language
        return .run { _ in
          userDefaults.set(language.rawValue, forKey: UserDefaultsKeys.preferredAudioLanguage)
        }

      case .playbackSpeedChanged(let speed):
        state.playbackSpeed = speed
        return .run { _ in
          userDefaults.set(speed.rawValue, forKey: UserDefaultsKeys.defaultPlaybackSpeed)
        }

      case .downloadQualityChanged(let quality):
        state.downloadQuality = quality
        return .run { _ in
          userDefaults.set(quality.rawValue, forKey: UserDefaultsKeys.downloadQuality)
        }

      case .downloadOverCellularToggled(let enabled):
        state.downloadOverCellular = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.downloadOverCellular)
        }

      case .autoDeleteWatchedToggled(let enabled):
        state.autoDeleteWatchedDownloads = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.autoDeleteWatchedDownloads)
        }

      case .pushNotificationsToggled(let enabled):
        state.pushNotificationsEnabled = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.pushNotificationsEnabled)
        }

      case .newContentNotificationsToggled(let enabled):
        state.newContentNotifications = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.newContentNotifications)
        }

      case .downloadNotificationsToggled(let enabled):
        state.downloadCompleteNotifications = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.downloadCompleteNotifications)
        }

      case .recommendationNotificationsToggled(let enabled):
        state.recommendationNotifications = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.recommendationNotifications)
        }

      case .airPlayToggled(let enabled):
        state.airPlayEnabled = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.airPlayEnabled)
        }

      case .chromecastToggled(let enabled):
        state.chromecastEnabled = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.chromecastEnabled)
        }

      case .pipToggled(let enabled):
        state.pipEnabled = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.pipEnabled)
        }

      case .analyticsToggled(let enabled):
        state.analyticsEnabled = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.analyticsEnabled)
        }

      case .crashReportingToggled(let enabled):
        state.crashReportingEnabled = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.crashReportingEnabled)
        }

      case .personalizedRecommendationsToggled(let enabled):
        state.personalizedRecommendations = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.personalizedRecommendations)
        }

      case .searchHistoryToggled(let enabled):
        state.searchHistoryEnabled = enabled
        return .run { _ in
          userDefaults.set(enabled, forKey: UserDefaultsKeys.searchHistoryEnabled)
        }

      case .clearCacheTapped:
        state.alert = AlertState {
          TextState("settings.cache.clear_alert_title")
        } actions: {
          ButtonState(role: .destructive, action: .confirmClearCache) {
            TextState("settings.cache.clear_confirm")
          }
          ButtonState(role: .cancel) {
            TextState("settings.cache.clear_cancel")
          }
        } message: {
          TextState("settings.cache.clear_alert_message")
        }
        return .none

      case .alert(.presented(.confirmClearCache)):
        return .send(.clearCacheConfirmed)

      case .clearCacheConfirmed:
        state.isClearingCache = true
        return .run { send in
          // Clear all caches using the shared managers
          await MainActor.run {
            // Clear content cache
            Task {
              await ContentCache.shared.clearAllCaches()
            }
            
            // Clear general cache manager
            CacheManager.shared.clearAllCaches()
            
            // Clear URL cache
            URLCache.shared.removeAllCachedResponses()
            
            print("✅ [Settings] All caches cleared successfully")
          }
          
          // Get updated cache size
          let newCacheSize = await getCacheSize()
          let clearedSize = await send(.cacheCleared(newCacheSize))
        }

      case .cacheCleared(let newSize):
        state.isClearingCache = false
        let clearedAmount = state.cacheSize - newSize
        state.cacheSize = newSize
        state.totalStorageUsed -= clearedAmount
        print("✅ [Settings] Cache cleared: \(formatBytes(clearedAmount))")
        return .none

      case .clearSearchHistoryTapped:
        return .run { send in
          userDefaults.removeObject(forKey: UserDefaultsKeys.recentSearches)
          await send(.searchHistoryCleared)
        }

      case .searchHistoryCleared:
        return .none

      case .aboutTapped, .helpTapped, .privacyPolicyTapped, .termsOfServiceTapped:
        /// TODO: Implement navigation to respective screens
        return .none

      case .logoutTapped:
        state.alert = AlertState {
          TextState("settings.logout_alert_title")
        } actions: {
          ButtonState(role: .destructive, action: .confirmLogout) {
            TextState("settings.logout_confirm")
          }
          ButtonState(role: .cancel) {
            TextState("settings.logout_cancel")
          }
        } message: {
          TextState("settings.logout_alert_message")
        }
        return .none

      case .alert(.presented(.confirmLogout)):
        return .send(.delegate(.logout))

      case .alert:
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }

  /// Load user preferences from UserDefaults
  private func loadUserPreferences() -> UserPreferences {
    UserPreferences(
      theme: ThemeMode(
        rawValue: userDefaults.string(forKey: UserDefaultsKeys.selectedTheme) ?? "system")
        ?? .system,
      accentColor: AccentColorOption(
        rawValue: userDefaults.string(forKey: UserDefaultsKeys.accentColor) ?? "blue") ?? .blue,
      biometricAuthEnabled: userDefaults.bool(forKey: UserDefaultsKeys.biometricAuthEnabled),
      autoLockTimeout: AutoLockTimeout(
        rawValue: userDefaults.integer(forKey: UserDefaultsKeys.autoLockTimeout)) ?? .fiveMinutes,
      defaultScraperSource: ScraperSource(
        rawValue: userDefaults.string(forKey: UserDefaultsKeys.defaultScraperSource) ?? "FlixHQ")
        ?? .FlixHQ,
      preferredLanguage: ContentLanguage(
        rawValue: userDefaults.string(forKey: UserDefaultsKeys.preferredContentLanguage)
          ?? "english") ?? .english,
      showAdultContent: userDefaults.bool(forKey: UserDefaultsKeys.showAdultContent),
      parentalControlsEnabled: userDefaults.bool(forKey: UserDefaultsKeys.parentalControlsEnabled),
      allowedContentRating: ContentRating(rawValue: userDefaults.string(forKey: UserDefaultsKeys.allowedContentRating) ?? "unrestricted") ?? .unrestricted,
      autoPlayEnabled: userDefaults.bool(forKey: UserDefaultsKeys.autoPlayEnabled),
      autoPlayTrailers: userDefaults.bool(forKey: UserDefaultsKeys.autoPlayTrailers),
      defaultQuality: VideoQuality(
        rawValue: userDefaults.string(forKey: UserDefaultsKeys.defaultPlaybackQuality) ?? "auto")
        ?? .auto,
      subtitlesEnabled: userDefaults.bool(forKey: UserDefaultsKeys.subtitlesEnabled),
      preferredSubtitleLanguage: SubtitleLanguage(
        rawValue: userDefaults.string(forKey: UserDefaultsKeys.preferredSubtitleLanguage)
          ?? "english") ?? .english,
      preferredAudioLanguage: AudioLanguage(
        rawValue: userDefaults.string(forKey: UserDefaultsKeys.preferredAudioLanguage)
          ?? "original") ?? .original,
      playbackSpeed: PlaybackSpeed(
        rawValue: userDefaults.double(forKey: UserDefaultsKeys.defaultPlaybackSpeed)) ?? .normal,
      downloadQuality: VideoQuality(
        rawValue: userDefaults.string(forKey: UserDefaultsKeys.downloadQuality) ?? "hd720")
        ?? .hd720,
      downloadOverCellular: userDefaults.bool(forKey: UserDefaultsKeys.downloadOverCellular),
      autoDeleteWatchedDownloads: userDefaults.bool(
        forKey: UserDefaultsKeys.autoDeleteWatchedDownloads),
      pushNotificationsEnabled: userDefaults.bool(
        forKey: UserDefaultsKeys.pushNotificationsEnabled),
      newContentNotifications: userDefaults.bool(forKey: UserDefaultsKeys.newContentNotifications),
      downloadCompleteNotifications: userDefaults.bool(
        forKey: UserDefaultsKeys.downloadCompleteNotifications),
      recommendationNotifications: userDefaults.bool(
        forKey: UserDefaultsKeys.recommendationNotifications),
      airPlayEnabled: userDefaults.bool(forKey: UserDefaultsKeys.airPlayEnabled),
      chromecastEnabled: userDefaults.bool(forKey: UserDefaultsKeys.chromecastEnabled),
      pipEnabled: userDefaults.bool(forKey: UserDefaultsKeys.pipEnabled),
      analyticsEnabled: userDefaults.bool(forKey: UserDefaultsKeys.analyticsEnabled),
      crashReportingEnabled: userDefaults.bool(forKey: UserDefaultsKeys.crashReportingEnabled),
      personalizedRecommendations: userDefaults.bool(
        forKey: UserDefaultsKeys.personalizedRecommendations),
      searchHistoryEnabled: userDefaults.bool(forKey: UserDefaultsKeys.searchHistoryEnabled)
    )
  }

  /// Get storage information
  private func getStorageInfo() async -> StorageInfo {
    let cacheSize = await getCacheSize()
    /// TODO: Get downloads size from download manager
    let downloadsSize: Int64 = 0
    return StorageInfo(
      totalUsed: cacheSize + downloadsSize,
      cacheSize: cacheSize,
      downloadsSize: downloadsSize
    )
  }
  
  /// Get current cache size
  private func getCacheSize() async -> Int64 {
    return await MainActor.run {
      var totalSize: Int64 = 0
      
      // Get CacheManager sizes
      totalSize += Int64(CacheManager.shared.currentMemorySize)
      totalSize += Int64(CacheManager.shared.currentDiskSize)
      
      // Get URLCache size
      totalSize += Int64(URLCache.shared.currentDiskUsage)
      totalSize += Int64(URLCache.shared.currentMemoryUsage)
      
      return totalSize
    }
  }
  
  /// Format bytes to human-readable string
  private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
}

// MARK: - Supporting Types

/// Biometric authentication type
enum BiometricType: String, Equatable {
  case none
  case faceID
  case touchID
}

/// Content rating for parental controls
enum ContentRating: String, CaseIterable, Equatable, Codable {
    case unrestricted
    case pg13
    case pg
    case g
    
    var displayName: String {
        switch self {
        case .unrestricted: return "Unrestricted"
        case .pg13: return "PG-13"
        case .pg: return "PG"
        case .g: return "G"
        }
    }
}

/// Storage information model
struct StorageInfo: Equatable {
  var totalUsed: Int64
  var cacheSize: Int64
  var downloadsSize: Int64
}
