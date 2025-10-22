// View+Extensions.swift
// SwiftUI View extensions for common UI patterns
// Provides reusable view modifiers and utilities

import SwiftUI

extension View {
    /// Applies a card style with shadow and corner radius
    func cardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(AppConstants.UI.cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    /// Applies a shimmer loading effect
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
    
    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Hides the view based on a condition
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
}
