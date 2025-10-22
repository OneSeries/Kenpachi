# Kenpachi - Disney Plus Clone App

Create a Disney Plus clone app using Swift, TMDB API, Anilist API, and the TCA (The Composable Architecture) pattern along with SwiftSoup for scrapers. The app will be named Kenpachi and will replicate the features and experience of Disney Plus while introducing customizations such as anime integration.

## App Name: Kenpachi

### 1. Architecture & Codebase
The app must be built using Swift and the latest TCA (The Composable Architecture) to ensure a modular, maintainable, and testable codebase. All views, services, features, and models should be separated into appropriately named files and folders following a clean and scalable project structure. Use Swift Concurrency (async/await) throughout the application for all network operations and background tasks.

### 2. Design Compatibility
The app should follow modern iOS 26+ standards and use the SwiftUI lifecycle. All code must be compatible with the latest version of Xcode and adopt features like Swift Concurrency, native SwiftUI animations, and reusable components. Implement proper dependency injection for services and managers to ensure testability.

### 3. Launch & Theming
A Disney+ style splash screen must be implemented to deliver a polished launch experience with smooth animations and brand presentation. The app must support both light and dark themes, with light as default, using a centralized ThemeManager to dynamically apply UI changes based on system preferences or in-app settings. Include support for custom accent colors and adaptive layouts.

### 4. Home Screen
The Home screen should replicate Disney Plus's layout, including multiple horizontally scrollable content carousels and tabs for categories like Home, TV, Movies, Sports, News, and Premium. A "Continue Watching" section must display ongoing titles with progress indicators, and a "Watchlist/Favorites" feature must allow users to save titles for later viewing.

#### Key characteristics of the real Disney Plus UI that we will implement:
- **Immersive, Full-Screen Layout:** The content scrolls edge-to-edge, especially at the top. The navigation bar is not a standard one; it's integrated or absent for maximum content visibility.
- **Hero Carousel:** A large, auto-playing, paginated TabView at the top is the most prominent feature, showcasing featured content with smooth transitions and gesture controls.
- **Content Rows (Carousels):** Vertical stacks of themed horizontal carousels (e.g., "Popular Movies," "Latest & Trending," "Recommended for You") with lazy loading for performance.
- **Correct Poster Aspect Ratios:** The items in the carousels have proper aspect ratios for movie posters (2:3 portrait) or series banners (16:9 landscape) with consistent sizing.
- **No Top Category Tabs:** The categories (TV, Movies, Sports) are part of the main bottom tab bar, not a secondary tab bar on the Home screen itself. The Home tab presents a curated mix of all content types.

### 5. Search Functionality
Implement a powerful search screen that allows users to find movies, TV shows, anime content. It should support real-time search with debouncing, display recent queries with persistence, and offer intelligent suggestions based on trends, popular content, or watch history. Include search filters for content type, genre, year, rating, and language.

### 6. Downloads
The app must support offline downloads for movies, TV shows, anime episodes. It should feature a comprehensive Download Manager with options for download progress tracking, pause/resume functionality, deletion management, available storage display, and intelligent management of downloaded files. Include download quality selection (480p, 720p, 1080p) and automatic cleanup of expired content.

### 7. User Profile (MySpace)
Create a "MySpace" screen similar to Disney Plus's profile section. This screen must include a settings icon to access user preferences, followed content management, theme selection, notification settings, and downloaded content overview. It should also host Watchlist management, app information, help & support options, and account settings. Include user statistics like watch time and favorite genres.

### 8. Splash, Onboarding & Navigation
On first launch, show the custom splash screen with app logo animation and loading indicators. Once inside, navigation should be tab-based (for main categories) and use NavigationStack for screens like details, player, search, and settings. Implement deep linking support for content sharing and universal links. Add swipe gestures for intuitive navigation between content.

### 9. Video Player Experience
The app must have a YouTube-style video player with comprehensive controls for stream quality selection, subtitle management, playback speed control, volume control, mute toggle, and fullscreen mode. The player should auto-start in preview mode on detail pages and allow seamless transition to full-screen playback. It should also support AirPlay for Apple TV streaming, PIP (Picture-in-Picture) for background viewing, and Google Chromecast casting functionality with proper session management.

### 10. Streaming Features
Integrate Picture-in-Picture (PIP) support for background video playback with mini player controls. Use AirPlay for Apple TV streaming via AVRoutePickerView with automatic device discovery. Add Google Chromecast support using Google Cast SDK, allowing casting to supported devices directly from the player UI with queue management and remote control capabilities.

### 11. Local Caching & Offline Content
Implement comprehensive local caching for frequently accessed content, user preferences, and downloaded media using CoreData for structured data, UserDefaults for settings, and FileManager for media files. This must improve load times significantly and enable offline usage where necessary. Include cache size management and automatic cleanup policies.

### 12. Accessibility
The app must support comprehensive accessibility features including VoiceOver with proper labels and hints, Dynamic Type for text scaling, proper accessibility traits, high contrast mode support, reduced motion preferences, and other inclusive design features. Accessibility must be verified across all UI components and user flows with minimum AA WCAG compliance.

### 13. Push Notifications
Add push notification support for new content alerts, personalized recommendations, download completion notifications, and updates related to followed movies, shows, or anime series. Use APNs (Apple Push Notification service) with proper certificate management. Notifications should be fully customizable from the MySpace screen with granular control over notification types and frequency.

### 14. Error Handling & Logging
Implement structured error logging using OSLog for system integration, with optional Crashlytics or custom Logger class for crash reporting and analytics. This must cover API failures, network errors, player issues, scraping failures, and system errors. Include user-friendly error messages and recovery suggestions. Optional debug logging can be toggled via environment configuration or developer settings.

### 15. Constants & Config Management
Create a well-structured Constants.swift file to manage reusable values like API keys, base URLs, scraper endpoints, UI strings, asset names, and system identifiers. Group constants under structured enums such as API, UI, Assets, Routes, and Timeouts to promote clean usage and prevent duplication. Include environment-specific configurations for development, staging, and production builds.

### 16. API Integration
Integrate TMDB API for comprehensive movie and TV show metadata including cast, crew, ratings, and images. Use Anilist API for detailed anime information, episode lists, and user ratings. Implement reliable scrapers or parsers for streaming content from sources like hianime, fmovies, vidsrc, and similar sites. Make sure all API calls are well-abstracted into dedicated service classes using async/await pattern and can be easily mocked for testing purposes.

### 17. Permissions & Info Tab
As Info.plist manual editing should be avoided, any required permissions (e.g., notifications, local storage, media access, microphone for voice search, camera for QR codes) should be added via Xcode's Info tab only as necessary. Include proper usage descriptions for all permissions. Avoid any manual plist editing unless absolutely required for specific entitlements or advanced feature configuration.

### 18. Release Process & Code Delivery
Development should follow a modular, step-by-step approach, sharing code in logical incremental stages (e.g., App Setup → Splash Screen → Home Screen → Search Functionality → API Integration → Video Player → Download Manager). This enables easy code review, continuous progress tracking, and iterative testing. GitHub commits or zipped code modules should reflect development progress logically with meaningful commit messages and proper branching strategy.

### 19. Localization Support
Add comprehensive localization support using Swift's native localization system with xcstrings file format. Support for multiple languages including English, Hindi, Tamil, Telugu, and other Indian regional languages. Include proper RTL (Right-to-Left) language support, date/time formatting for different locales, and culturally appropriate content recommendations.

### 20. Scrapers Definition
In the context of this project, "scrapers" refer to custom-built Swift classes or utilities designed to extract (or "scrape") streaming data from websites that do not offer a public API. This approach will be used for obtaining streaming links and content metadata for movies, TV shows, anime, especially from sites like hianime, fmovies, vidsrc, gogoanime. The scraping process involves:

- **HTTP Requests:** Making network requests to retrieve the HTML content of web pages using URLSession.
- **HTML Parsing:** Analyzing the HTML structure using libraries like SwiftSoup to locate and extract relevant data (streaming URLs, metadata, chapter images).
- **Data Structuring:** Organizing the extracted data into proper Swift models for use throughout the application.
- **Error Handling:** Robust error handling for network failures, parsing errors, and source changes.
- **Rate Limiting:** Implementing proper delays and request limiting to avoid overwhelming source servers.

The use of scrapers is a primary mechanism to ensure comprehensive content availability, allowing for integration of a wider range of streaming content into the application. The default scraper source will be user-selectable in the Settings tab to provide flexibility and reliability.

### 21. Detail Screens
Add comprehensive support for movie, TV show, anime screens similar to Disney Plus applications. Include rich media previews, detailed cast and crew information, user ratings and reviews, similar content recommendations, season/episode listings for series, chapter listings for, and social sharing capabilities. Implement auto-playing trailers with mute controls and seamless transition to full player.

### 22. Populate Home and Search Screens
Populate home screen content carousels and search results based on configured scrapers and API data. Implement intelligent content curation algorithms that mix trending content, personalized recommendations, and recently added items. Include proper loading states, error handling for failed requests, and fallback content when primary sources are unavailable. Add content filtering based on user psreferences and parental controls.

### 23. Performance Optimization
Implement comprehensive performance optimizations including image lazy loading with SDWebImage or native AsyncImage, memory management for large content lists, background processing for downloads and cache management, and optimized database queries. Include performance monitoring and analytics to track app responsiveness and user experience metrics.

### 24. Security & Privacy
Implement robust security measures including secure API key storage using Keychain, encrypted local storage for sensitive data, certificate pinning for API communications, and user privacy protection with minimal data collection. Include proper handling of user-generated content and compliance with privacy regulations.

## Additional Requirements

- **Add Comments for every line:** Ensure that all code includes detailed comments explaining each line's purpose.
- **Make Home View Dynamic:** The home view should be dynamic to populate home page views and details from scraper providers, with the default set to FlixHQ.
- **Authentication:** Auth should be only for biometric authentication like FaceID, and only after the user enables it in the settings menu.

## Folder Structure

Kenpachi/
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── cd.yml
│   │   └── release.yml
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── CODEOWNERS
│
├── Application/
│   ├── App/
│   │   ├── KenpachiApp.swift
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift
│   ├── Configuration/
│   │   ├── AppConfiguration.swift
│   │   ├── Environment/
│   │   │   ├── Environment.swift
│   │   │   ├── Development.swift
│   │   │   ├── Staging.swift
│   │   │   └── Production.swift
│   │   ├── FeatureFlags.swift
│   │   └── RemoteConfig/
│   │       ├── RemoteConfigService.swift
│   │       └── ConfigKeys.swift
│   ├── Constants/
│   │   ├── APIConstants.swift
│   │   ├── AppConstants.swift
│   │   ├── UserDefaultsKeys.swift
│   │   ├── NotificationConstants.swift
│   │   └── RouteConstants.swift
│   └── DependencyInjection/
│       ├── DIContainer.swift
│       ├── ServiceLocator.swift
│       ├── Assemblers/
│       │   ├── NetworkAssembler.swift
│       │   ├── RepositoryAssembler.swift
│       │   ├── ServiceAssembler.swift
│       │   └── UseCaseAssembler.swift
│       └── Scopes.swift
│
├── Domain/
│   ├── Entities/
│   │   ├── Content/
│   │   │   ├── Content.swift
│   │   │   ├── ContentType.swift
│   │   │   ├── Genre.swift
│   │   │   ├── Episode.swift
│   │   │   ├── Season.swift
│   │   │   ├── Cast.swift
│   │   │   └── ContentMetadata.swift
│   │   ├── Download/
│   │   │   ├── Download.swift
│   │   │   ├── DownloadState.swift
│   │   │   ├── DownloadTask.swift
│   │   │   └── DownloadQuality.swift
│   │   ├── Scraping/
│   │   │   ├── ScrapedSource.swift
│   │   │   ├── ExtractedLink.swift
│   │   │   ├── ContentSearchResult.swift
│   │   │   └── ContentCarousel.swift
│   │   ├── Streaming/
│   │   │   ├── StreamingQuality.swift
│   │   │   ├── StreamingServer.swift
│   │   │   ├── VideoSource.swift
│   │   │   ├── Subtitle.swift
│   │   │   └── AudioTrack.swift
│   │   └── User/
│   │       ├── AppState.swift
│   │       ├── UserPreferences.swift
│   │       ├── WatchHistory.swift
│   │       ├── Watchlist.swift
│   │       └── UserProfile.swift
│   ├── UseCases/
│   │   ├── Content/
│   │   │   ├── FetchTrendingContentUseCase.swift
│   │   │   ├── GetContentDetailsUseCase.swift
│   │   │   ├── SearchContentUseCase.swift
│   │   │   └── GetRecommendationsUseCase.swift
│   │   ├── Download/
│   │   │   ├── StartDownloadUseCase.swift
│   │   │   ├── ManageDownloadUseCase.swift
│   │   │   └── CleanupDownloadsUseCase.swift
│   │   ├── Streaming/
│   │   │   ├── ExtractStreamingLinksUseCase.swift
│   │   │   ├── GetSubtitlesUseCase.swift
│   │   │   └── SelectQualityUseCase.swift
│   │   └── User/
│   │       ├── AddToWatchlistUseCase.swift
│   │       ├── UpdateWatchHistoryUseCase.swift
│   │       └── ManagePreferencesUseCase.swift
│   ├── Errors/
│   │   ├── DomainError.swift
│   │   ├── ContentError.swift
│   │   ├── DownloadError.swift
│   │   ├── ScrapingError.swift
│   │   └── AuthenticationError.swift
│   └── Repositories/
│       ├── ContentRepositoryProtocol.swift
│       ├── DownloadRepositoryProtocol.swift
│       ├── UserRepositoryProtocol.swift
│       └── CacheRepositoryProtocol.swift
│
├── Infrastructure/
│   ├── Data/
│   │   ├── Network/
│   │   │   ├── Core/
│   │   │   │   ├── NetworkClient.swift
│   │   │   │   ├── NetworkError.swift
│   │   │   │   ├── HTTPMethod.swift
│   │   │   │   └── RequestBuilder.swift
│   │   │   ├── API/
│   │   │   │   ├── TMDB/
│   │   │   │   │   ├── TMDBClient.swift
│   │   │   │   │   ├── TMDBModels.swift
│   │   │   │   │   └── TMDBEndpoints.swift
│   │   │   │   └── AniList/
│   │   │   │       ├── AniListClient.swift
│   │   │   │       ├── AniListModels.swift
│   │   │   │       └── AniListQueries.swift
│   │   │   └── Scrapers/
│   │   │       ├── Core/
│   │   │       │   ├── ScraperProtocol.swift
│   │   │       │   ├── ExtractorProtocol.swift
│   │   │       │   └── ScraperError.swift
│   │   │       ├── Extractors/
│   │   │       │   ├── DoodStream.swift
│   │   │       │   ├── StreamTape.swift
│   │   │       │   └── VidCloud.swift
│   │   │       └── Sources/
│   │   │           ├── Movies/
│   │   │           │   ├── FlixHQ.swift
│   │   │           │   ├── FMovies.swift
│   │   │           │   └── VidSrc.swift
│   │   │           └── Anime/
│   │   │               ├── HiAnime.swift
│   │   │               ├── GogoAnime.swift
│   │   │               └── AnimeKai.swift
│   │   └── Persistence/
│   │       ├── CoreData/
│   │       │   ├── CoreDataStack.swift
│   │       │   ├── PersistenceController.swift
│   │       │   └── Models/
│   │       │       ├── DownloadEntity.swift
│   │       │       ├── WatchHistoryEntity.swift
│   │       │       └── WatchlistEntity.swift
│   │       ├── Cache/
│   │       │   ├── CacheManager.swift
│   │       │   ├── ImageCache.swift
│   │       │   └── ContentCache.swift
│   │       └── UserDefaults/
│   │           ├── UserPreferencesStorage.swift
│   │           ├── AppSettingsStorage.swift
│   │           └── SearchHistoryStorage.swift
│   ├── Repositories/
│   │   ├── ContentRepository.swift
│   │   ├── DownloadRepository.swift
│   │   ├── UserRepository.swift
│   │   └── CacheRepository.swift
│   └── Services/
│       ├── Analytics/
│       │   ├── AnalyticsService.swift
│       │   ├── EventLogger.swift
│       │   └── PerformanceMonitor.swift
│       ├── Authentication/
│       │   └── BiometricAuthService.swift
│       ├── Downloader/
│       │   ├── AVDownloaderService.swift
│       │   ├── DownloadQueueManager.swift
│       │   └── DownloadProgressTracker.swift
│       ├── Networking/
│       │   ├── NetworkMonitor.swift
│       │   └── ReachabilityService.swift
│       ├── Notifications/
│       │   ├── NotificationService.swift
│       │   └── NotificationHandler.swift
│       ├── Player/
│       │   ├── VideoPlayerService.swift
│       │   ├── AirPlayService.swift
│       │   ├── ChromecastService.swift
│       │   └── PictureInPictureService.swift
│       ├── Scraping/
│       │   ├── ScraperManager.swift
│       │   └── ScraperCoordinator.swift
│       └── Storage/
│           ├── FileManager+App.swift
│           ├── KeychainService.swift
│           └── SecureStorage.swift
│
├── Presentation/
│   ├── DesignSystem/
│   │   ├── Theme/
│   │   │   ├── AppTheme.swift
│   │   │   ├── Colors.swift
│   │   │   ├── Typography.swift
│   │   │   ├── Spacing.swift
│   │   │   ├── Shadows.swift
│   │   │   └── Animations.swift
│   │   └── Tokens/
│   │       ├── CornerRadius.swift
│   │       ├── BorderWidth.swift
│   │       └── OpacityLevels.swift
│   ├── Common/
│   │   ├── Components/
│   │   │   ├── Buttons/
│   │   │   │   ├── PrimaryButton.swift
│   │   │   │   ├── SecondaryButton.swift
│   │   │   │   └── IconButton.swift
│   │   │   ├── Cards/
│   │   │   │   ├── ContentCard.swift
│   │   │   │   ├── EpisodeCard.swift
│   │   │   │   └── DownloadCard.swift
│   │   │   ├── Carousels/
│   │   │   │   ├── HorizontalCarousel.swift
│   │   │   │   ├── HeroCarousel.swift
│   │   │   │   └── ContentRow.swift
│   │   │   ├── Loading/
│   │   │   │   ├── LoadingView.swift
│   │   │   │   ├── SkeletonView.swift
│   │   │   │   └── ProgressIndicator.swift
│   │   │   ├── Empty/
│   │   │   │   ├── EmptyStateView.swift
│   │   │   │   └── NoResultsView.swift
│   │   │   └── Errors/
│   │   │       ├── ErrorView.swift
│   │   │       └── RetryView.swift
│   │   ├── ViewModifiers/
│   │   │   ├── ShimmerModifier.swift
│   │   │   ├── CardStyleModifier.swift
│   │   │   └── NavigationBarModifier.swift
│   │   └── Navigation/
│   │       ├── NavigationCoordinator.swift
│   │       ├── Route.swift
│   │       └── DeepLinkHandler.swift
│   └── Features/
│       ├── App/
│       │   ├── AppFeature.swift
│       │   └── AppView.swift
│       ├── Launch/
│       │   ├── Splash/
│       │   │   ├── SplashFeature.swift
│       │   │   └── SplashView.swift
│       │   └── Onboarding/
│       │       ├── OnboardingFeature.swift
│       │       └── OnboardingView.swift
│       ├── MainTab/
│       │   ├── MainTabFeature.swift
│       │   └── MainTabView.swift
│       ├── Home/
│       │   ├── HomeFeature.swift
│       │   ├── HomeView.swift
│       │   └── Components/
│       │       ├── HeroSection.swift
│       │       ├── ContentSection.swift
│       │       └── ContinueWatchingRow.swift
│       ├── Search/
│       │   ├── SearchFeature.swift
│       │   ├── SearchView.swift
│       │   └── Components/
│       │       ├── SearchBar.swift
│       │       ├── SearchFilters.swift
│       │       └── SearchResultsGrid.swift
│       ├── ContentDetail/
│       │   ├── ContentDetailFeature.swift
│       │   ├── ContentDetailView.swift
│       │   └── Components/
│       │       ├── DetailHeader.swift
│       │       ├── EpisodeList.swift
│       │       ├── SeasonSelector.swift
│       │       └── CastSection.swift
│       ├── Player/
│       │   ├── PlayerFeature.swift
│       │   ├── PlayerView.swift
│       │   └── Components/
│       │       ├── PlayerControls.swift
│       │       ├── QualitySelector.swift
│       │       └── SubtitleSelector.swift
│       ├── Downloads/
│       │   ├── DownloadsFeature.swift
│       │   ├── DownloadsView.swift
│       │   └── Components/
│       │       ├── DownloadItem.swift
│       │       └── DownloadProgressBar.swift
│       ├── MySpace/
│       │   ├── MySpaceFeature.swift
│       │   ├── MySpaceView.swift
│       │   └── Components/
│       │       ├── ProfileHeader.swift
│       │       ├── WatchlistSection.swift
│       │       └── StatsSection.swift
│       └── Settings/
│           ├── SettingsFeature.swift
│           ├── SettingsView.swift
│           └── Components/
│               ├── SettingsRow.swift
│               ├── ThemeSelector.swift
│               └── ScraperSelector.swift
│
├── Shared/
│   ├── Extensions/
│   │   ├── Foundation/
│   │   │   ├── String+Extensions.swift
│   │   │   ├── Date+Extensions.swift
│   │   │   ├── URL+Extensions.swift
│   │   │   └── Array+Extensions.swift
│   │   ├── SwiftUI/
│   │   │   ├── View+Extensions.swift
│   │   │   ├── Color+Extensions.swift
│   │   │   ├── Image+Extensions.swift
│   │   │   └── Font+Extensions.swift
│   │   └── AVFoundation/
│   │       └── AVPlayer+Extensions.swift
│   ├── Utilities/
│   │   ├── Logging/
│   │   │   ├── Logger.swift
│   │   │   ├── LogLevel.swift
│   │   │   └── LogDestination.swift
│   │   ├── Formatters/
│   │   │   ├── DateFormatter+App.swift
│   │   │   ├── NumberFormatter+App.swift
│   │   │   └── DurationFormatter.swift
│   │   └── Helpers/
│   │       ├── ImageLoader.swift
│   │       ├── KeyboardManager.swift
│   │       └── HapticFeedback.swift
│   └── Protocols/
│       ├── Identifiable+App.swift
│       ├── Loadable.swift
│       └── Cacheable.swift
│
├── Resources/
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/
│   │   ├── Colors/
│   │   ├── Images/
│   │   └── Icons/
│   ├── Fonts/
│   ├── Localizable/
│   │   └── Localizable.xcstrings
│
├── Documentation/
│   ├── Architecture/
│   │   ├── Overview.md
│   │   ├── TCA_Implementation.md
│   │   ├── DependencyInjection.md
│   │   └── DataFlow.md
│   ├── API/
│   │   ├── TMDB_Integration.md
│   │   └── AniList_Integration.md
│   ├── Scrapers/
│   │   ├── Implementation_Guide.md
│   │   └── Adding_New_Scrapers.md
│   ├── Development/
│   │   ├── GettingStarted.md
│   │   ├── CodingStandards.md
│   │   └── Git_Workflow.md
│   └── README.md
│
├── Scripts/
│   ├── setup.sh
│   ├── code-quality.sh
│   └── update-dependencies.sh
│
├── Configurations/
│   ├── Debug.xcconfig
│   ├── Staging.xcconfig
│   ├── Release.xcconfig
│   └── Shared.xcconfig
│
├── fastlane/
│   ├── Fastfile
│   ├── Appfile
│   └── Matchfile
│
├── .gitignore
├── .swiftlint.yml
├── .swiftformat
├── CHANGELOG.md
└── README.md
