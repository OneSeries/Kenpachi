// Typography.swift
// Centralized typography definitions for the app
// Provides consistent font styles across the application

import SwiftUI

/// Extension providing app-specific typography utilities
extension Font {
    
    // MARK: - Display Fonts
    /// Extra large display text (48pt, bold)
    static let displayLarge = Font.system(size: 48, weight: .bold)
    /// Large display text (36pt, bold)
    static let displayMedium = Font.system(size: 36, weight: .bold)
    /// Small display text (28pt, bold)
    static let displaySmall = Font.system(size: 28, weight: .bold)
    
    // MARK: - Headline Fonts
    /// Large headline (24pt, semibold)
    static let headlineLarge = Font.system(size: 24, weight: .semibold)
    /// Medium headline (20pt, semibold)
    static let headlineMedium = Font.system(size: 20, weight: .semibold)
    /// Small headline (18pt, semibold)
    static let headlineSmall = Font.system(size: 18, weight: .semibold)
    
    // MARK: - Body Fonts
    /// Large body text (17pt, regular)
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    /// Medium body text (15pt, regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    /// Small body text (13pt, regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)
    
    // MARK: - Label Fonts
    /// Large label (16pt, medium)
    static let labelLarge = Font.system(size: 16, weight: .medium)
    /// Medium label (14pt, medium)
    static let labelMedium = Font.system(size: 14, weight: .medium)
    /// Small label (12pt, medium)
    static let labelSmall = Font.system(size: 12, weight: .medium)
    
    // MARK: - Caption Fonts
    /// Large caption (12pt, regular)
    static let captionLarge = Font.system(size: 12, weight: .regular)
    /// Medium caption (11pt, regular)
    static let captionMedium = Font.system(size: 11, weight: .regular)
    /// Small caption (10pt, regular)
    static let captionSmall = Font.system(size: 10, weight: .regular)
}
