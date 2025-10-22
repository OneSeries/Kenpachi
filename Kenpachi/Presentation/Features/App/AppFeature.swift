// AppFeature.swift
// Root TCA feature coordinating app-wide state and navigation
// Manages splash screen, main tabs, and app lifecycle

import ComposableArchitecture

@Reducer
struct AppFeature {
    
    @ObservableState
    struct State: Equatable {
        /// Current app phase
        var appPhase: AppPhase = .splash
        /// Splash screen state
        var splash = SplashFeature.State()
        /// Main tab state
        var mainTab = MainTabFeature.State()
        
        /// App phases
        enum AppPhase: Equatable {
            case splash
            case main
        }
    }
    
    enum Action: Equatable {
        /// Splash screen actions
        case splash(SplashFeature.Action)
        /// Main tab actions
        case mainTab(MainTabFeature.Action)
        /// Transition to main app
        case transitionToMain
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.splash, action: \.splash) {
            SplashFeature()
        }
        
        Scope(state: \.mainTab, action: \.mainTab) {
            MainTabFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .splash(.dismiss):
                // Transition from splash to main app
                return .send(.transitionToMain)
                
            case .splash:
                // Other splash actions handled by SplashFeature
                return .none
                
            case .mainTab:
                // Main tab actions handled by MainTabFeature
                return .none
                
            case .transitionToMain:
                // Update app phase to show main content
                state.appPhase = .main
                return .none
            }
        }
    }
}