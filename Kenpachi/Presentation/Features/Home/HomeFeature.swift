// HomeFeature.swift
// TCA feature for home screen with content carousels
// Manages content loading, hero carousel, and content sections

import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {

  @ObservableState
  struct State: Equatable {
    /// Loading state for initial content
    var isLoading = false
    /// Error message if loading fails
    var errorMessage: String?
    /// Array of content carousels
    var contentCarousels: [ContentCarousel] = []
    /// Current hero carousel index
    var currentHeroIndex = 0
    /// Loading state for play action
    var isLoadingPlay = false
    /// Streaming links for playback
    var streamingLinks: [ExtractedLink] = []
    /// Content to play
    var contentToPlay: Content?
    /// Show player
    var showPlayer = false
  }

  enum Action: Equatable {
    /// Triggered when home view appears
    case onAppear
    /// Load all home content
    case loadContent
    /// Content loaded successfully
    case contentLoaded([ContentCarousel])
    /// Content loading failed
    case loadingFailed(String)
    /// Hero carousel index changed
    case heroIndexChanged(Int)
    /// Content item tapped
    case contentTapped(Content)
    /// Play button tapped
    case playTapped(Content)
    /// Extract streaming links
    case extractStreamingLinks(Content)
    /// Streaming links extracted
    case streamingLinksExtracted([ExtractedLink])
    /// Link extraction failed
    case linkExtractionFailed(String)
    /// Watchlist button tapped
    case watchlistTapped(Content)
    /// Dismiss player
    case dismissPlayer
    /// Refresh content
    case refresh
  }

  @Dependency(\.continuousClock) var clock

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Load content if not already loaded
        guard state.contentCarousels.isEmpty else { return .none }
        return .send(.loadContent)

      case .loadContent:
        // Set loading state
        state.isLoading = true
        state.errorMessage = nil
        // Clear existing content to force refresh
        state.contentCarousels = []

        // Load content from APIs/scrapers
        return .run { send in
          do {
            // Create repository instance
            let contentRepository = ContentRepository()

            // Fetch home content using the new method
            let carousels = try await contentRepository.fetchHomeContent()

            await send(.contentLoaded(carousels))
          } catch {
            await send(.loadingFailed(error.localizedDescription))
          }
        }

      case .contentLoaded(let carousels):
        // Update state with loaded content
        state.isLoading = false
        state.contentCarousels = carousels
        return .none

      case .loadingFailed(let message):
        // Handle loading failure
        state.isLoading = false
        state.errorMessage = message
        return .none

      case .heroIndexChanged(let index):
        // Update hero carousel index
        state.currentHeroIndex = index
        return .none

      case .contentTapped(let content):
        // Handle content tap (navigate to detail)
        // TODO: Implement navigation to detail screen
        return .none

      case .playTapped(let content):
        // Start extracting streaming links
        state.isLoadingPlay = true
        state.contentToPlay = content
        return .send(.extractStreamingLinks(content))

      case .extractStreamingLinks(let content):
        // Extract streaming links for playback
        return .run { send in
          do {
            let contentRepository = ContentRepository()

            // For TV shows, get first episode of first season
            var episodeId: String?
            if content.type == .tvShow,
              let firstSeason = content.seasons?.first,
              let firstEpisode = firstSeason.episodes?.first
            {
              episodeId = firstEpisode.id
            }

            let links = try await contentRepository.extractStreamingLinks(
              contentId: content.id,
              seasonId: content.seasons?.first?.id,
              episodeId: episodeId
            )

            guard !links.isEmpty else {
              await send(.linkExtractionFailed("No streaming links found"))
              return
            }

            await send(.streamingLinksExtracted(links))
          } catch {
            await send(.linkExtractionFailed(error.localizedDescription))
          }
        }

      case .streamingLinksExtracted(let links):
        // Links extracted successfully, show player
        state.isLoadingPlay = false
        state.streamingLinks = links
        state.showPlayer = true
        return .none

      case .linkExtractionFailed(let message):
        // Handle extraction failure
        state.isLoadingPlay = false
        state.errorMessage = message
        return .none

      case .watchlistTapped(let content):
        // Add to watchlist
        // TODO: Implement watchlist functionality
        return .none

      case .dismissPlayer:
        // Dismiss player
        state.showPlayer = false
        state.streamingLinks = []
        state.contentToPlay = nil
        return .none

      case .refresh:
        // Refresh all content
        return .send(.loadContent)
      }
    }
  }
}
