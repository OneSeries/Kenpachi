// AppView.swift
// Root view of the application that switches between different app phases
// Displays splash, onboarding, or main tab based on current app state

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    /// TCA store for app feature
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        ZStack {
            // Main content based on app phase
            switch store.appPhase {
            case .splash:
                // Show splash screen
                SplashView(store: store.scope(state: \.splash, action: \.splash))
                    .transition(.opacity)
                
            case .main:
                // Show main app content
                MainTabView(store: store.scope(state: \.mainTab, action: \.mainTab))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: AppConstants.UI.standardAnimationDuration), value: store.appPhase)
    }
}
