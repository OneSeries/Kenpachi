// Animations.swift
// Centralized animation definitions for consistent motion design
// Provides reusable animation curves and durations

import SwiftUI

/// Extension providing app-specific animation definitions
extension Animation {
    
    // MARK: - Standard Animations
    /// Quick animation for micro-interactions (0.2s)
    static let quick = Animation.easeInOut(duration: 0.2)
    /// Standard animation for most UI transitions (0.3s)
    static let standard = Animation.easeInOut(duration: 0.3)
    /// Smooth animation for larger transitions (0.5s)
    static let smooth = Animation.easeInOut(duration: 0.5)
    
    // MARK: - Spring Animations
    /// Bouncy spring animation for playful interactions
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)
    /// Gentle spring animation for subtle movements
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    /// Snappy spring animation for quick feedback
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
    
    // MARK: - Custom Curves
    /// Ease out animation for entering elements
    static let easeOut = Animation.timingCurve(0.0, 0.0, 0.2, 1.0, duration: 0.3)
    /// Ease in animation for exiting elements
    static let easeIn = Animation.timingCurve(0.4, 0.0, 1.0, 1.0, duration: 0.3)
    /// Emphasized animation for important transitions
    static let emphasized = Animation.timingCurve(0.2, 0.0, 0.0, 1.0, duration: 0.5)
}

/// Transition presets for common UI patterns
extension AnyTransition {
    /// Fade and scale transition
    static var fadeScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.2).combined(with: .opacity)
        )
    }
    
    /// Slide from bottom transition
    static var slideFromBottom: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
    
    /// Slide from top transition
    static var slideFromTop: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }
    
    /// Slide from leading transition
    static var slideFromLeading: AnyTransition {
        .move(edge: .leading).combined(with: .opacity)
    }
    
    /// Slide from trailing transition
    static var slideFromTrailing: AnyTransition {
        .move(edge: .trailing).combined(with: .opacity)
    }
}
