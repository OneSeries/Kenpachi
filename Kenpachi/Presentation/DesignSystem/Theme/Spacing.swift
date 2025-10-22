// Spacing.swift
// Centralized spacing system for consistent layout
// Provides standardized spacing values throughout the app

import SwiftUI

/// Extension providing app-specific spacing values
extension CGFloat {
    
    // MARK: - Spacing Scale
    /// Extra small spacing (4pt)
    static let spacingXS: CGFloat = 4
    /// Small spacing (8pt)
    static let spacingS: CGFloat = 8
    /// Medium spacing (16pt) - Default
    static let spacingM: CGFloat = 16
    /// Large spacing (24pt)
    static let spacingL: CGFloat = 24
    /// Extra large spacing (32pt)
    static let spacingXL: CGFloat = 32
    /// Extra extra large spacing (48pt)
    static let spacingXXL: CGFloat = 48
    
    // MARK: - Corner Radius
    /// Small corner radius (4pt)
    static let radiusS: CGFloat = 4
    /// Medium corner radius (8pt)
    static let radiusM: CGFloat = 8
    /// Large corner radius (16pt)
    static let radiusL: CGFloat = 16
    /// Extra large corner radius (24pt)
    static let radiusXL: CGFloat = 24
    
    // MARK: - Border Width
    /// Thin border (1pt)
    static let borderThin: CGFloat = 1
    /// Medium border (2pt)
    static let borderMedium: CGFloat = 2
    /// Thick border (3pt)
    static let borderThick: CGFloat = 3
}

/// View modifier for applying consistent spacing
struct SpacingModifier: ViewModifier {
    let spacing: CGFloat

    // Use `Self.Content` to refer to the associated `Content` type from the
    // `ViewModifier` protocol and avoid colliding with the app's `Content` entity.
    func body(content: Self.Content) -> some View {
        content.padding(spacing)
    }
}

extension View {
    /// Applies extra small spacing
    func spacingXS() -> some View {
        modifier(SpacingModifier(spacing: .spacingXS))
    }
    
    /// Applies small spacing
    func spacingS() -> some View {
        modifier(SpacingModifier(spacing: .spacingS))
    }
    
    /// Applies medium spacing
    func spacingM() -> some View {
        modifier(SpacingModifier(spacing: .spacingM))
    }
    
    /// Applies large spacing
    func spacingL() -> some View {
        modifier(SpacingModifier(spacing: .spacingL))
    }
    
    /// Applies extra large spacing
    func spacingXL() -> some View {
        modifier(SpacingModifier(spacing: .spacingXL))
    }
}