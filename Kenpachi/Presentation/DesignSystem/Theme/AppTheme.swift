// AppTheme.swift
// Theme management system for the application
// Handles light/dark mode switching and theme preferences

import SwiftUI
import Combine
import Foundation

/// Enum representing available app themes
enum AppTheme: String, CaseIterable, Identifiable {
    /// System theme (follows device settings)
    case system
    /// Light theme
    case light
    /// Dark theme
    case dark
    
    /// Unique identifier for Identifiable conformance
    var id: String { rawValue }
    
    /// Display name for the theme
    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    /// SF Symbol icon name for the theme
    var iconName: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
    
    /// Converts theme to SwiftUI ColorScheme
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

/// Observable theme manager for handling app-wide theme changes
/// Manages theme selection with light theme as default per Disney+ style
@Observable
final class ThemeManager {
    /// Shared singleton instance
    static let shared = ThemeManager()
    
    /// Current selected theme
    var currentTheme: AppTheme {
        didSet {
            // Save theme preference to UserDefaults
            UserDefaults.standard.set(currentTheme.rawValue, forKey: AppConstants.StorageKeys.selectedTheme)
            // Log theme change
            AppLogger.shared.log(
                "Theme changed to: \(currentTheme.displayName)",
                level: .info
            )
        }
    }
    
    /// Private initializer for singleton
    private init() {
        // Load saved theme preference or default to light theme (Disney+ style)
        if let savedTheme = UserDefaults.standard.string(forKey: AppConstants.StorageKeys.selectedTheme),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            // Default to light theme as per requirements
            self.currentTheme = .light
        }
        
        // Log initial theme
        AppLogger.shared.log(
            "ThemeManager initialized with theme: \(currentTheme.displayName)",
            level: .debug
        )
    }
    
    /// Updates the current theme
    /// - Parameter theme: New theme to apply
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
    
    /// Updates theme from ThemeMode (from settings)
    /// - Parameter themeMode: Theme mode from settings
    func setThemeFromMode(_ themeMode: ThemeMode) {
        switch themeMode {
        case .light:
            currentTheme = .light
        case .dark:
            currentTheme = .dark
        case .system:
            currentTheme = .system
        }
    }
}

/// Extension to convert ThemeMode to AppTheme
extension ThemeMode {
    var toAppTheme: AppTheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return .system
        }
    }
}
