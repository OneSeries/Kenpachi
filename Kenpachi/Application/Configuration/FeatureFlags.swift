// FeatureFlags.swift
// Feature flag management for gradual feature rollout
// Enables/disables features dynamically without app updates

import Foundation

/// Feature flags manager for controlling feature availability
/// Allows enabling/disabling features without app updates
@Observable
final class FeatureFlags {
  /// Shared singleton instance
  static let shared = FeatureFlags()

  /// Whether new home screen layout is enabled
  var newHomeScreenEnabled: Bool = true
  /// Whether enhanced search is enabled
  var enhancedSearchEnabled: Bool = true
  /// Whether offline mode is enabled
  var offlineModeEnabled: Bool = true
  /// Whether social features are enabled
  var socialFeaturesEnabled: Bool = false
  /// Whether parental controls are enabled
  var parentalControlsEnabled: Bool = true
  /// Whether voice search is enabled
  var voiceSearchEnabled: Bool = false
  /// Whether QR code scanning is enabled
  var qrCodeScanningEnabled: Bool = false
  /// Whether watch party feature is enabled
  var watchPartyEnabled: Bool = false
  /// Whether content recommendations are enabled
  var recommendationsEnabled: Bool = true
  /// Whether auto-play trailers are enabled
  var autoPlayTrailersEnabled: Bool = true

  /// Private initializer for singleton
  private init() {
    // Load feature flags from remote config or local storage
    loadFeatureFlags()

    // Log initialization
    AppLogger.shared.log(
      "FeatureFlags initialized",
      level: .debug
    )
  }

  /// Loads feature flags from storage
  /// Checks remote config first, falls back to local defaults
  private func loadFeatureFlags() {
    // TODO: Load from remote config service (e.g., Firebase Remote Config)
    // For now, using local defaults

    // Log loaded flags
    AppLogger.shared.log(
      "Feature flags loaded with defaults",
      level: .debug
    )
  }

  /// Refreshes feature flags from remote config
  /// Should be called periodically to get latest flags
  func refresh() async {
    // TODO: Fetch from remote config service

    // Log refresh
    AppLogger.shared.log(
      "Feature flags refreshed",
      level: .debug
    )
  }

  /// Checks if a feature is enabled
  /// - Parameter feature: Feature name to check
  /// - Returns: True if feature is enabled
  func isEnabled(_ feature: Feature) -> Bool {
    switch feature {
    case .newHomeScreen:
      return newHomeScreenEnabled
    case .enhancedSearch:
      return enhancedSearchEnabled
    case .offlineMode:
      return offlineModeEnabled
    case .socialFeatures:
      return socialFeaturesEnabled
    case .parentalControls:
      return parentalControlsEnabled
    case .voiceSearch:
      return voiceSearchEnabled
    case .qrCodeScanning:
      return qrCodeScanningEnabled
    case .watchParty:
      return watchPartyEnabled
    case .recommendations:
      return recommendationsEnabled
    case .autoPlayTrailers:
      return autoPlayTrailersEnabled
    }
  }

  /// Feature enum for type-safe feature checking
  enum Feature {
    /// New home screen layout
    case newHomeScreen
    /// Enhanced search with filters
    case enhancedSearch
    /// Offline mode with downloads
    case offlineMode
    /// Social features (sharing, comments)
    case socialFeatures
    /// Parental controls
    case parentalControls
    /// Voice search
    case voiceSearch
    /// QR code scanning
    case qrCodeScanning
    /// Watch party feature
    case watchParty
    /// Content recommendations
    case recommendations
    /// Auto-play trailers
    case autoPlayTrailers
  }
}
