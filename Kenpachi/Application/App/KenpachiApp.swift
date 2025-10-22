// KenpachiApp.swift
// Main application entry point using SwiftUI App lifecycle
// Initializes the app with TCA architecture and dependency injection

import SwiftUI
import ComposableArchitecture

/// Main application struct conforming to the App protocol
@main
struct KenpachiApp: App {
    /// Shared store for the entire application using TCA
    /// This store manages the root app state and coordinates all features
    @State private var store = StoreOf<AppFeature>(
        initialState: AppFeature.State()
    ) {
        AppFeature()
    }
    
    /// Theme manager for app-wide theme control
    @State private var themeManager = ThemeManager.shared
    
    /// Scene configuration for the app
    var body: some Scene {
        WindowGroup {
            // Root app view connected to the TCA store
            AppView(store: store)
                // Apply theme based on ThemeManager
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                // Provide theme manager to environment
                .environment(themeManager)
                // Handle app lifecycle events
                .onAppear {
                    // Perform initial setup tasks
                    setupApp()
                }
        }
    }
    
    /// Performs initial app setup and configuration
    /// Called when the app first appears
    private func setupApp() {
        // Configure appearance proxies for global UI styling
        configureAppearance()
        
        // Initialize analytics if enabled
        if AppConstants.Features.analyticsEnabled {
            // Analytics setup would go here
        }
        
        // Register for push notifications if enabled
        if AppConstants.Features.pushNotificationsEnabled {
            // Notification registration would go here
        }
    }
    
    /// Configures global UI appearance settings
    /// Sets up navigation bar, tab bar, and other UI element styling
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}