// AppState.swift
// Domain entity representing global app state
// Tracks app-level configuration and runtime state

import Foundation

/// Represents the global application state
struct AppState: Equatable, Codable {
  /// Whether user has completed onboarding
  var hasCompletedOnboarding: Bool
  /// First launch date
  var firstLaunchDate: Date?
  /// Last launched app version
  var lastLaunchedVersion: String?
  /// Current app version
  var currentVersion: String
  /// Whether app is in dark mode
  var isDarkMode: Bool
  /// Selected tab index
  var selectedTabIndex: Int
  /// Last selected scraper source
  var lastScraperSource: String
  
  /// Default initializer
  init(
    hasCompletedOnboarding: Bool = false,
    firstLaunchDate: Date? = nil,
    lastLaunchedVersion: String? = nil,
    currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
      ?? "1.0.0",
    isDarkMode: Bool = false,
    selectedTabIndex: Int = 0,
    lastScraperSource: String = "FlixHQ"
  ) {
    self.hasCompletedOnboarding = hasCompletedOnboarding
    self.firstLaunchDate = firstLaunchDate
    self.lastLaunchedVersion = lastLaunchedVersion
    self.currentVersion = currentVersion
    self.isDarkMode = isDarkMode
    self.selectedTabIndex = selectedTabIndex
    self.lastScraperSource = lastScraperSource
  }
  
  /// Check if this is first launch
  var isFirstLaunch: Bool {
    firstLaunchDate == nil
  }
  
  /// Check if app was updated
  var wasUpdated: Bool {
    guard let lastVersion = lastLaunchedVersion else { return false }
    return lastVersion != currentVersion
  }
}
