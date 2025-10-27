// HomeFeature.swift
// This file defines the TCA (The Composable Architecture) feature for the home screen.
// It manages the state and logic for loading and displaying content carousels,
// including the hero carousel and various content sections.

import ComposableArchitecture // Imports the Composable Architecture library for state management.
import Foundation // Imports the Foundation framework for basic data types and functionality.

/// The `@Reducer` macro transforms the `HomeFeature` struct into a reducer,
/// which is responsible for handling actions and mutating the state.
@Reducer
struct HomeFeature {

  /// The `State` struct holds all the data necessary for the home screen to function.
  /// It is marked as `@ObservableState` to allow SwiftUI views to observe changes to its properties.
  @ObservableState
  struct State: Equatable {
    /// A boolean flag to indicate whether the initial content is being loaded.
    var isLoading = false
    /// An optional string to hold an error message if content loading fails.
    var errorMessage: String?
    /// An array of `ContentCarousel` objects that represent the rows of content on the home screen.
    var contentCarousels: [ContentCarousel] = []
    /// An array of `Content` objects that the user has added to their watchlist.
    var watchlistItems: [Content] = []
    /// The index of the currently displayed item in the hero carousel.
    var currentHeroIndex = 0
    /// A boolean flag to indicate whether a play action is in progress (e.g., extracting streaming links).
    var isLoadingPlay = false
    /// An array of `ExtractedLink` objects that hold the URLs for streaming content.
    var streamingLinks: [ExtractedLink] = []
    /// The `Content` object that is intended to be played.
    var contentToPlay: Content?
    /// A boolean flag to control the presentation of the player view.
    var showPlayer = false
    /// A dictionary to store the watchlist status for each item in the hero carousel.
    var heroWatchlistStatus: [String: Bool] = [:]
  }

  /// The `Action` enum defines all the possible actions that can be performed on the `HomeFeature`.
  /// These actions are sent to the store to trigger state changes and side effects.
  enum Action: Equatable {
    /// This action is triggered when the home view appears on the screen.
    case onAppear
    /// This action initiates the loading of all content for the home screen.
    case loadContent
    /// This action is dispatched when the home content has been successfully loaded.
    case contentLoaded([ContentCarousel])
    /// This action is dispatched when content loading has failed.
    case loadingFailed(String)
    /// This action is triggered when the index of the hero carousel changes.
    case heroIndexChanged(Int)
    /// This action is triggered when a content item is tapped.
    case contentTapped(Content)
    /// This action is triggered when the play button is tapped on a content item.
    case playTapped(Content)
    /// This action initiates the extraction of streaming links for a content item.
    case extractStreamingLinks(Content)
    /// This action is dispatched when streaming links have been successfully extracted.
    case streamingLinksExtracted([ExtractedLink])
    /// This action is dispatched when link extraction has failed.
    case linkExtractionFailed(String)
    /// This action is triggered when the watchlist button is tapped on a content item.
    case watchlistTapped(Content)
    /// This action is dispatched when the user's watchlist has been loaded.
    case watchlistLoaded([Content])
    /// This action is dispatched when the watchlist status for a hero item has been loaded.
    case heroWatchlistStatusLoaded(String, Bool)
    /// This action is dispatched when the watchlist status for a content item has been toggled.
    case watchlistToggled(String, Bool)
    /// This action is triggered to dismiss the player view.
    case dismissPlayer
    /// This action is triggered to refresh the content on the home screen.
    case refresh
  }

  /// A dependency on `continuousClock` is used for time-based effects, such as debouncing.
  @Dependency(\.continuousClock) var clock

  /// The `body` of the reducer defines how the state changes in response to actions.
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // If the content carousels are already populated, do nothing.
        guard state.contentCarousels.isEmpty else { return .none }
        // Otherwise, initiate the loading of content.
        return .send(.loadContent)

      case .loadContent:
        // Set the loading state to true.
        state.isLoading = true
        // Clear any previous error messages.
        state.errorMessage = nil
        // Clear the existing content to force a refresh.
        state.contentCarousels = []

        // Return a side effect to load the content from the repository.
        return .run { send in
          do {
            // Create an instance of the `ContentRepository`.
            let contentRepository = ContentRepository()

            // Fetch the home content using the repository.
            let carousels = try await contentRepository.fetchHomeContent()

            // Dispatch the `contentLoaded` action with the fetched carousels.
            await send(.contentLoaded(carousels))
          } catch {
            // If an error occurs, dispatch the `loadingFailed` action with the error description.
            await send(.loadingFailed(error.localizedDescription))
          }
        }

      case .contentLoaded(let carousels):
        // Set the loading state to false.
        state.isLoading = false
        // Update the state with the loaded content carousels.
        state.contentCarousels = carousels

        // Return a side effect to load the user's watchlist.
        return .run { send in
          do {
            // Fetch the watchlist from the `WatchlistManager`.
            let watchlist = try await WatchlistManager.shared.fetchWatchlist()
            // Dispatch the `watchlistLoaded` action with the fetched watchlist.
            await send(.watchlistLoaded(watchlist))

            // Get the items from the hero carousel.
            let heroItems = carousels.first(where: { $0.type == .hero })?.items ?? []
            // For each hero item, check if it is in the user's watchlist.
            for item in heroItems {
              let isInWatchlist = try await WatchlistManager.shared.isInWatchlist(
                contentId: item.id)
              // Dispatch the `heroWatchlistStatusLoaded` action with the result.
              await send(.heroWatchlistStatusLoaded(item.id, isInWatchlist))
            }
          } catch {
            // If an error occurs, log a warning message.
            AppLogger.shared.log("Failed to load watchlist: \(error)", level: .warning)
          }
        }

      case .loadingFailed(let message):
        // Set the loading state to false.
        state.isLoading = false
        // Update the state with the error message.
        state.errorMessage = message
        return .none

      case .heroIndexChanged(let index):
        // Update the current hero index in the state.
        state.currentHeroIndex = index
        return .none

      case .contentTapped(let content):
        // This is a placeholder for handling content taps, which should navigate to a detail screen.
        // TODO: Implement navigation to detail screen
        return .none

      case .playTapped(let content):
        // Set the loading state for the play action to true.
        state.isLoadingPlay = true
        // Store the content that is intended to be played.
        state.contentToPlay = content
        // Initiate the extraction of streaming links.
        return .send(.extractStreamingLinks(content))

      case .extractStreamingLinks(let content):
        // Return a side effect to extract the streaming links from the repository.
        return .run { send in
          do {
            // Create an instance of the `ContentRepository`.
            let contentRepository = ContentRepository()

            // If the content is a TV show, get the first episode of the first season.
            var episodeId: String?
            if content.type == .tvShow,
              let firstSeason = content.seasons?.first,
              let firstEpisode = firstSeason.episodes?.first
            {
              episodeId = firstEpisode.id
            }

            // Extract the streaming links from the repository.
            let links = try await contentRepository.extractStreamingLinks(
              contentId: content.id,
              seasonId: content.seasons?.first?.id,
              episodeId: episodeId
            )

            // If no links are found, dispatch the `linkExtractionFailed` action.
            guard !links.isEmpty else {
              await send(.linkExtractionFailed("No streaming links found"))
              return
            }

            // If links are found, dispatch the `streamingLinksExtracted` action.
            await send(.streamingLinksExtracted(links))
          } catch {
            // If an error occurs, dispatch the `linkExtractionFailed` action with the error description.
            await send(.linkExtractionFailed(error.localizedDescription))
          }
        }

      case .streamingLinksExtracted(let links):
        // Set the loading state for the play action to false.
        state.isLoadingPlay = false
        // Update the state with the extracted streaming links.
        state.streamingLinks = links
        // Set the flag to show the player to true.
        state.showPlayer = true
        return .none

      case .linkExtractionFailed(let message):
        // Set the loading state for the play action to false.
        state.isLoadingPlay = false
        // Update the state with the error message.
        state.errorMessage = message
        return .none

      case .watchlistTapped(let content):
        // Get the current watchlist status for the content item.
        let currentStatus = state.heroWatchlistStatus[content.id] ?? false
        // Determine the new watchlist status.
        let newStatus = !currentStatus

        // Optimistically update the UI with the new status.
        state.heroWatchlistStatus[content.id] = newStatus

        // Return a side effect to toggle the watchlist status in the `WatchlistManager`.
        return .run { send in
          do {
            // Toggle the watchlist status.
            let finalStatus = try await WatchlistManager.shared.toggleWatchlist(
              contentId: content.id)
            // Dispatch the `watchlistToggled` action with the final status.
            await send(.watchlistToggled(content.id, finalStatus))

            // Reload the watchlist to update the watchlist section.
            let watchlist = try await WatchlistManager.shared.fetchWatchlist()
            await send(.watchlistLoaded(watchlist))
          } catch {
            // If an error occurs, log an error message.
            AppLogger.shared.log("Failed to toggle watchlist: \(error)", level: .error)
            // Revert the UI to the original status.
            await send(.watchlistToggled(content.id, currentStatus))
          }
        }

      case .watchlistLoaded(let watchlist):
        // Update the state with the loaded watchlist items.
        state.watchlistItems = watchlist
        return .none

      case .heroWatchlistStatusLoaded(let contentId, let isInWatchlist):
        // Update the watchlist status for the hero item in the state.
        state.heroWatchlistStatus[contentId] = isInWatchlist
        return .none

      case .watchlistToggled(let contentId, let isInWatchlist):
        // Confirm the watchlist toggle by updating the state.
        state.heroWatchlistStatus[contentId] = isInWatchlist
        return .none

      case .dismissPlayer:
        // Set the flag to show the player to false.
        state.showPlayer = false
        // Clear the streaming links.
        state.streamingLinks = []
        // Clear the content to play.
        state.contentToPlay = nil
        return .none

      case .refresh:
        // Clear the watchlist items and hero watchlist status.
        state.watchlistItems = []
        state.heroWatchlistStatus = [:]
        // Initiate the loading of all content.
        return .send(.loadContent)
      }
    }
  }
}
