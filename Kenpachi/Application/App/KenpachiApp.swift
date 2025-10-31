// KenpachiApp.swift
// This file serves as the main entry point for the Kenpachi application.
// It follows the SwiftUI App lifecycle, which was introduced in iOS 14.
// The primary responsibilities of this file are to initialize the app's architecture,
// set up dependency injection, and define the overall structure of the app,
// aiming to replicate the user experience of Disney+ with added features.

import ComposableArchitecture  // Imports the Composable Architecture library for state management.
import SwiftUI  // Imports the SwiftUI framework for building the user interface.
import UserNotifications  // Imports the framework for handling user notifications.

/// This is the main structure for the Kenpachi application, conforming to the `App` protocol.
/// The `@main` attribute designates this as the entry point for the application's execution.
@main
struct KenpachiApp: App {
  /// This property holds the shared `Store` for the entire application, a core concept in TCA.
  /// It manages the application's root state and handles all actions and side effects.
  /// `@State` is used to ensure that the view hierarchy is updated when the store's state changes.
  @State private var store = StoreOf<AppFeature>(
    initialState: AppFeature.State()  // Initializes the store with the initial state defined in `AppFeature`.
  ) {
    AppFeature()  // Provides the reducer for the `AppFeature` to the store.
  }

  /// This property holds an instance of the `ThemeManager`, which is responsible for managing the app's themes.
  /// It allows for dynamic switching between light and dark modes, with light mode as the default.
  @State private var themeManager = ThemeManager.shared

  /// This property holds an instance of the `NotificationService`, which handles push notifications.
  /// It manages the registration with Apple Push Notification service (APNs) and the delivery of notifications.
  @State private var notificationService = NotificationService.shared

  /// This property holds an instance of the `NetworkMonitor`, which tracks the device's network connectivity.
  /// It is crucial for implementing offline features and providing a seamless user experience.
  @State private var networkMonitor = NetworkMonitor.shared

  /// This computed property defines the app's scene configuration.
  /// A scene is a container for a window or a set of windows.
  var body: some Scene {
    // A `WindowGroup` is a scene that manages one or more windows.
    WindowGroup {
      // This is the root view of the application, connected to the TCA `Store`.
      AppView(store: store)
        // This modifier sets the preferred color scheme for the view hierarchy based on the `ThemeManager`.
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        // This injects the `ThemeManager` into the environment, making it accessible to child views.
        .environment(themeManager)
        // This injects the `NotificationService` into the environment.
        .environment(notificationService)
        // This injects the `NetworkMonitor` into the environment.
        .environment(networkMonitor)
        // This modifier registers a closure to be executed when the view appears.
        .onAppear {
          // This function is called to perform initial setup tasks when the app launches.
          setupApp()
        }
        // This modifier registers a closure to be executed when the app is about to enter the background.
        .onReceive(
          NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
        ) { _ in
          // This function is called to save the app's state.
          handleAppBackground()
        }
        // This modifier registers a closure to be executed when the app becomes active.
        .onReceive(
          NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        ) { _ in
          // This function is called to refresh content.
          handleAppForeground()
        }
    }
  }

  /// This private function performs the initial setup and configuration of the application.
  /// It is called once when the app first appears.
  private func setupApp() {
    // This function configures the global appearance of UI elements like the navigation bar and tab bar.
    configureAppearance()

    // This starts the network monitor to track connectivity changes.
    networkMonitor.startMonitoring()

    // This conditional block initializes the analytics service if it's enabled in the app's constants.
    if AppConstants.Features.analyticsEnabled {
      // Initializes the shared instance of the `AnalyticsService`.
      AnalyticsService.shared.initialize()
      // Logs an event to indicate that the app has been launched.
      AnalyticsService.shared.logEvent("app_launched")
    }

    // This conditional block handles the setup for push notifications if they are enabled.
    if AppConstants.Features.pushNotificationsEnabled {
      // Requests authorization from the user to send notifications.
      notificationService.requestAuthorization()
      // Registers the app for remote notifications with APNs.
      notificationService.registerForRemoteNotifications()
    }

    // This sets the default scraper for the `ScraperManager`.
    ScraperManager.shared.setDefaultScraper()

    // This conditional block initializes the download manager if the downloads feature is enabled.
    if AppConstants.Features.downloadsEnabled {
      // Initializes the shared instance of the `DownloadQueueManager`.
      DownloadQueueManager.shared.initialize()
      // Resumes any downloads that were pending from the previous session.
      DownloadQueueManager.shared.resumePendingDownloads()
    }

    // This conditional block initializes the biometric authentication service if it's enabled.
    if AppConstants.Features.biometricAuthEnabled {
      // Checks if biometric authentication (Face ID or Touch ID) is available on the device.
      BiometricAuthService.shared.checkAvailability()
    }

    // This conditional block initializes the Chromecast service if it's enabled.
    if AppConstants.Features.chromecastEnabled {
      // Sets up the Google Cast SDK.
      ChromecastService.shared.initialize()
    }

    // This function configures the caching policies for the app.
    configureCachePolicy()

    // This sets the default theme to light mode if no theme has been previously selected by the user.
    if UserDefaults.standard.string(forKey: AppConstants.StorageKeys.selectedTheme) == nil {
      themeManager.setTheme(.light)
    }

    // This logs the current version and build number of the app for debugging purposes.
    AppLogger.shared.log(
      "Kenpachi v\(AppConstants.App.version) (\(AppConstants.App.buildNumber)) launched",
      level: .info)
  }

  /// This private function configures the global appearance settings for UI elements.
  /// It ensures a consistent and immersive look and feel, similar to Disney+.
  private func configureAppearance() {
    // Creates a new appearance object for the navigation bar.
    let navigationBarAppearance = UINavigationBarAppearance()
    // Configures the navigation bar to have a transparent background.
    navigationBarAppearance.configureWithTransparentBackground()
    // Sets the background color of the navigation bar to clear.
    navigationBarAppearance.backgroundColor = .clear
    // Removes the shadow from the navigation bar for a seamless look.
    navigationBarAppearance.shadowColor = .clear
    // Applies the appearance to all states of the navigation bar.
    UINavigationBar.appearance().standardAppearance = navigationBarAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    UINavigationBar.appearance().compactAppearance = navigationBarAppearance

    // Creates a new appearance object for the tab bar.
    let tabBarAppearance = UITabBarAppearance()
    // Configures the tab bar with a default background that includes a blur effect.
    tabBarAppearance.configureWithDefaultBackground()
    // Sets the background color of the tab bar with high opacity for better visibility.
    tabBarAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.95)
    // Adds a subtle blur effect for depth
    tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    // Applies the appearance to all states of the tab bar.
    UITabBar.appearance().standardAppearance = tabBarAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

    // Configures the appearance of the page control used in the hero carousel.
    UIPageControl.appearance().currentPageIndicatorTintColor = .white
    UIPageControl.appearance().pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.3)
  }

  /// This private function configures the cache policies for network requests and content.
  /// This is crucial for optimizing performance and enabling offline functionality.
  private func configureCachePolicy() {
    // Creates a URLCache instance with specified memory and disk capacities.
    let urlCache = URLCache(
      memoryCapacity: 100 * 1024 * 1024,  // 100 MB of memory capacity.
      diskCapacity: 500 * 1024 * 1024,  // 500 MB of disk capacity.
      diskPath: "kenpachi_cache"  // The path for the on-disk cache.
    )
    // Assigns the created cache to the shared URLCache instance.
    URLCache.shared = urlCache

    // Configures the `CacheManager` with the maximum memory and disk sizes defined in the app's constants.
    CacheManager.shared.configure(
      maxMemorySize: AppConstants.Cache.maxMemorySize,
      maxDiskSize: AppConstants.Cache.maxDiskSize
    )
  }

  /// This private function handles the tasks to be performed when the app enters the background.
  /// It saves the app's state and pauses non-essential operations.
  private func handleAppBackground() {
    // Saves the current state of the app to persistent storage.
    AppStateManager.shared.saveState()

    // Pauses downloads if the device is on a cellular network and the corresponding setting is enabled.
    if !networkMonitor.isWiFiConnected {
      DownloadQueueManager.shared.pauseDownloadsOnCellular()
    }

    // Logs a debug message indicating that the app has entered the background.
    AppLogger.shared.log("App entered background", level: .debug)
  }

  /// This private function handles the tasks to be performed when the app returns to the foreground.
  /// It refreshes content and resumes operations that were paused.
  private func handleAppForeground() {
    // Refreshes the network monitor's status.
    networkMonitor.refreshStatus()

    // Resumes pending downloads if the device is connected to a network.
    if networkMonitor.isConnected {
      DownloadQueueManager.shared.resumePendingDownloads()
    }

    // Sends an action to the store to refresh the content on the home screen.
    store.send(.mainTab(.home(.refresh)))

    // Logs a debug message indicating that the app has entered the foreground.
    AppLogger.shared.log("App entered foreground", level: .debug)
  }
}
