// AppStateManager.swift
// Manages application state persistence
// Saves and restores app state across launches

import Foundation

/// App state manager for persisting application state
/// Handles saving and loading of app state to/from disk
final class AppStateManager {
  /// Shared singleton instance
  static let shared = AppStateManager()

  /// File manager instance for file operations
  private let fileManager = FileManager.default
  /// URL for app state file
  private let stateFileURL: URL

  /// Private initializer for singleton
  private init() {
    // Get documents directory URL
    let documentsDirectory = fileManager.urls(
      for: .documentDirectory,
      in: .userDomainMask
    ).first!

    // Create app state file URL
    stateFileURL = documentsDirectory.appendingPathComponent("app_state.json")

    // Log initialization
    AppLogger.shared.log(
      "AppStateManager initialized with state file: \(stateFileURL.path)",
      level: .debug
    )
  }

  /// Saves current app state to disk
  /// Persists important app data for restoration
  func saveState() {
    // Get current app state from UserDefaults or create new one
    var state = loadState() ?? AppState()

    // Update current version
    state.currentVersion = AppConstants.App.version

    // Update last launched version
    state.lastLaunchedVersion = AppConstants.App.version

    // Set first launch date if not set
    if state.firstLaunchDate == nil {
      state.firstLaunchDate = Date()
    }

    do {
      // Encode state to JSON
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let data = try encoder.encode(state)

      // Write to file with atomic write option
      try data.write(to: stateFileURL, options: [.atomic])

      // Log successful save
      AppLogger.shared.log(
        "App state saved successfully",
        level: .debug
      )
    } catch {
      // Log save error
      AppLogger.shared.log(
        "Failed to save app state: \(error.localizedDescription)",
        level: .error
      )
    }
  }

  /// Loads app state from disk
  /// - Returns: Loaded app state or nil if not found
  func loadState() -> AppState? {
    // Check if state file exists
    guard fileManager.fileExists(atPath: stateFileURL.path) else {
      // Log file not found
      AppLogger.shared.log(
        "App state file not found",
        level: .debug
      )
      return nil
    }

    do {
      // Read data from file
      let data = try Data(contentsOf: stateFileURL)

      // Decode JSON to app state
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      let state = try decoder.decode(AppState.self, from: data)

      // Log successful load
      AppLogger.shared.log(
        "App state loaded successfully",
        level: .debug
      )

      return state
    } catch {
      // Log load error
      AppLogger.shared.log(
        "Failed to load app state: \(error.localizedDescription)",
        level: .error
      )
      return nil
    }
  }

  /// Clears saved app state
  /// Removes state file from disk
  func clearState() {
    // Check if state file exists
    guard fileManager.fileExists(atPath: stateFileURL.path) else {
      return
    }

    do {
      // Delete state file
      try fileManager.removeItem(at: stateFileURL)

      // Log successful deletion
      AppLogger.shared.log(
        "App state cleared successfully",
        level: .debug
      )
    } catch {
      // Log deletion error
      AppLogger.shared.log(
        "Failed to clear app state: \(error.localizedDescription)",
        level: .error
      )
    }
  }
}
