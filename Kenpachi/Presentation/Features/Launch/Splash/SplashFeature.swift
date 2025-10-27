// SplashFeature.swift
// TCA feature for splash screen with loading and animation logic
// Handles initial app setup and transitions to main content

import ComposableArchitecture
import Foundation

@Reducer
struct SplashFeature {
    
    @ObservableState
    struct State: Equatable {
        /// Whether the splash animation is complete
        var isAnimationComplete = false
        /// Whether initial data loading is complete
        var isLoadingComplete = false
        /// Current loading progress (0.0 to 1.0)
        var loadingProgress: Double = 0.0
        /// Error message if loading fails
        var errorMessage: String?
    }
    
    enum Action: Equatable {
        /// Triggered when splash screen appears
        case onAppear
        /// Updates loading progress
        case updateProgress(Double)
        /// Triggered when animation completes
        case animationCompleted
        /// Triggered when loading completes
        case loadingCompleted
        /// Triggered when loading fails
        case loadingFailed(String)
        /// Triggered when splash should dismiss
        case dismiss
    }
    
    @Dependency(\.continuousClock) var clock
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Start loading process
                return .run { send in
                    // Simulate loading with progress updates
                    for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                        await send(.updateProgress(progress))
                        try await clock.sleep(for: .milliseconds(100))
                    }
                    // Mark loading as complete
                    await send(.loadingCompleted)
                    // Wait for animation to complete
                    try await clock.sleep(for: .seconds(1))
                    await send(.animationCompleted)
                    // Dismiss splash
                    try await clock.sleep(for: .milliseconds(500))
                    await send(.dismiss)
                }
                
            case .updateProgress(let progress):
                // Update loading progress
                state.loadingProgress = progress
                return .none
                
            case .animationCompleted:
                // Mark animation as complete
                state.isAnimationComplete = true
                return .none
                
            case .loadingCompleted:
                // Mark loading as complete
                state.isLoadingComplete = true
                return .none
                
            case .loadingFailed(let message):
                // Handle loading failure
                state.errorMessage = message
                return .none
                
            case .dismiss:
                // Splash dismissal handled by parent
                return .none
            }
        }
    }
}
