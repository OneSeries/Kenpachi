// ContentDetailFeature.swift
// This file defines the TCA feature for the content detail screen.
// It manages the state and logic for displaying detailed information about a specific content item,
// including its metadata, episodes, cast, and handling streaming link extraction.

import ComposableArchitecture // Imports the Composable Architecture library for state management.
import Foundation // Imports the Foundation framework for basic data types and functionality.

/// The `@Reducer` macro transforms the `ContentDetailFeature` struct into a reducer.
@Reducer
struct ContentDetailFeature {

  /// The `State` struct holds all the data necessary for the content detail screen to function.
  @ObservableState
  struct State: Equatable {
    /// The ID of the content to be displayed.
    let contentId: String
    /// The type of the content (e.g., movie, TV show).
    let type: ContentType?
    /// A boolean flag to indicate whether the content details are being loaded.
    var isLoading = false
    /// An optional string to hold an error message if loading fails.
    var errorMessage: String?
    /// The detailed `Content` object.
    var content: Content?
    /// The currently selected season for a TV show.
    var selectedSeason: Season?
    /// The currently selected episode for a TV show.
    var selectedEpisode: Episode?
    /// An array of `ExtractedLink` objects that hold the URLs for streaming content.
    var streamingLinks: [ExtractedLink] = []
    /// A boolean flag to indicate whether streaming links are being extracted.
    var isLoadingLinks = false
    /// A boolean flag to control the presentation of the player view.
    var showPlayer = false
    /// A boolean flag to indicate whether the content is in the user's watchlist.
    var isInWatchlist = false
    /// An array of `Content` objects that are similar or recommended.
    var similarContent: [Content] = []
    /// A boolean flag to control the auto-play of trailers.
    var autoPlayTrailer = true

    /// The initializer for the `State` struct.
      init(contentId: String, type: ContentType?) {
      self.contentId = contentId
      self.type = type
    }
  }

  /// The `Action` enum defines all the possible actions that can be performed on the `ContentDetailFeature`.
  enum Action: Equatable {
    /// This action is triggered when the detail view appears on the screen.
    case onAppear
    /// This action initiates the loading of content details.
    case loadContentDetails
    /// This action is dispatched when the content details have been successfully loaded.
    case contentDetailsLoaded(Content)
    /// This action is dispatched when content loading has failed.
    case loadingFailed(String)
    /// This action is triggered when a season is selected.
    case seasonSelected(Season)
    /// This action is triggered when an episode is selected.
    case episodeSelected(Episode)
    /// This action is triggered when the play button is tapped.
    case playTapped
    /// This action is triggered when the trailer play button is tapped.
    case trailerPlayTapped
    /// This action initiates the extraction of streaming links.
    case extractStreamingLinks
    /// This action is dispatched when streaming links have been successfully extracted.
    case streamingLinksExtracted([ExtractedLink])
    /// This action is dispatched when streaming link extraction has failed.
    case linkExtractionFailed(String)
    /// This action is triggered when the "Add to Watchlist" button is tapped.
    case addToWatchlistTapped
    /// This action is triggered when the "Remove from Watchlist" button is tapped.
    case removeFromWatchlistTapped
    /// This action is dispatched when the watchlist status has been loaded.
    case watchlistStatusLoaded(Bool)
    /// This action is dispatched when the watchlist status has been toggled.
    case watchlistToggled(Bool)
    /// This action is triggered when the share button is tapped.
    case shareTapped
    /// This action is triggered when the download button is tapped.
    case downloadTapped
    /// This action is triggered when a similar content item is tapped.
    case similarContentTapped(Content)
    /// This action is triggered when a cast member is tapped.
    case castMemberTapped(Cast)
    /// This action is triggered to dismiss the player view.
    case dismissPlayer
  }

  /// A dependency on `continuousClock` is used for time-based effects.
  @Dependency(\.continuousClock) var clock

  /// The `body` of the reducer defines how the state changes in response to actions.
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // If the content is already loaded, do nothing.
        guard state.content == nil else { return .none }
        // Otherwise, initiate the loading of content details.
        return .send(.loadContentDetails)

      case .loadContentDetails:
        // Set the loading state to true and clear any previous error messages.
        state.isLoading = true
        state.errorMessage = nil

        // Return a side effect to load the content details from the repository.
        return .run { [contentId = state.contentId, type = state.type] send in
          do {
            // Create an instance of the `ContentRepository`.
            let contentRepository = ContentRepository()

            // Fetch the content details from the repository.
            let content = try await contentRepository.fetchContentDetails(id: contentId, type: type)

            // Dispatch the `contentDetailsLoaded` action with the fetched content.
            await send(.contentDetailsLoaded(content))
          } catch {
            // If an error occurs, dispatch the `loadingFailed` action with the error description.
            await send(.loadingFailed(error.localizedDescription))
          }
        }

      case .contentDetailsLoaded(let content):
        // Set the loading state to false.
        state.isLoading = false
        // Update the state with the loaded content.
        state.content = content

        // If the content is a TV show, set the first season as the selected season.
        if content.type == .tvShow, let firstSeason = content.seasons?.first {
          state.selectedSeason = firstSeason
        }

        // Update the state with the similar content.
        state.similarContent = content.recommendations ?? []
        
        // Return a side effect to check if the content is in the user's watchlist.
        return .run { [contentId = state.contentId] send in
          do {
            let isInWatchlist = try await WatchlistManager.shared.isInWatchlist(contentId: contentId)
            await send(.watchlistStatusLoaded(isInWatchlist))
          } catch {
            // If an error occurs, log a warning message.
            AppLogger.shared.log("Failed to check watchlist status: \(error)", level: .warning)
          }
        }

      case .loadingFailed(let message):
        // Set the loading state to false and update the state with the error message.
        state.isLoading = false
        state.errorMessage = message
        return .none

      case .seasonSelected(let season):
        // Update the selected season in the state.
        state.selectedSeason = season
        // Clear the selected episode.
        state.selectedEpisode = nil
        return .none

      case .episodeSelected(let episode):
        // Update the selected episode in the state.
        state.selectedEpisode = episode
        // Set the loading state for streaming links to true.
        state.isLoadingLinks = true
        // Clear any previous error messages.
        state.errorMessage = nil
        // Initiate the extraction of streaming links.
        return .send(.extractStreamingLinks)

      case .playTapped:
        // Set the loading state for streaming links to true.
        state.isLoadingLinks = true
        // Clear any previous error messages.
        state.errorMessage = nil
        // Initiate the extraction of streaming links.
        return .send(.extractStreamingLinks)

      case .trailerPlayTapped:
        // This is a placeholder for playing the trailer.
        // TODO: Implement trailer playback
        return .none

      case .extractStreamingLinks:
        // Get the ID of the selected episode.
        var episodeId = state.selectedEpisode?.id

        // If no episode is selected for a TV show, use the first episode of the first season.
        if episodeId == nil || episodeId?.isEmpty == true {
          if state.content?.type == .tvShow,
            let firstSeason = state.content?.seasons?.first,
            let firstEpisode = firstSeason.episodes?.first
          {
            episodeId = firstEpisode.id
            // Update the selected episode and season in the state.
            state.selectedEpisode = firstEpisode
            state.selectedSeason = firstSeason
          }
        }

        // Return a side effect to extract the streaming links from the repository.
        return .run { [contentId = state.contentId, episodeId] send in
          do {
            // Create an instance of the `ContentRepository`.
            let contentRepository = ContentRepository()

            // Extract the streaming links from the repository.
            let links = try await contentRepository.extractStreamingLinks(
              contentId: contentId,
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
        // Set the loading state for streaming links to false.
        state.isLoadingLinks = false
        // Update the state with the extracted streaming links.
        state.streamingLinks = links
        // Set the flag to show the player to true.
        state.showPlayer = true
        return .none

      case .linkExtractionFailed(let message):
        // Set the loading state for streaming links to false.
        state.isLoadingLinks = false
        // Update the state with the error message.
        state.errorMessage = message
        return .none

      case .addToWatchlistTapped:
        // Optimistically update the UI to show the content in the watchlist.
        state.isInWatchlist = true
        
        // Return a side effect to add the content to the watchlist.
        return .run { [contentId = state.contentId] send in
          do {
            try await WatchlistManager.shared.addToWatchlist(contentId: contentId)
            await send(.watchlistToggled(true))
          } catch {
            AppLogger.shared.log("Failed to add to watchlist: \(error)", level: .error)
            await send(.watchlistToggled(false))
          }
        }

      case .removeFromWatchlistTapped:
        // Optimistically update the UI to remove the content from the watchlist.
        state.isInWatchlist = false
        
        // Return a side effect to remove the content from the watchlist.
        return .run { [contentId = state.contentId] send in
          do {
            try await WatchlistManager.shared.removeFromWatchlist(contentId: contentId)
            await send(.watchlistToggled(false))
          } catch {
            AppLogger.shared.log("Failed to remove from watchlist: \(error)", level: .error)
            await send(.watchlistToggled(true))
          }
        }
      
      case .watchlistStatusLoaded(let isInWatchlist):
        // Update the watchlist status in the state.
        state.isInWatchlist = isInWatchlist
        return .none
      
      case .watchlistToggled(let isInWatchlist):
        // Confirm the watchlist toggle by updating the state.
        state.isInWatchlist = isInWatchlist
        return .none

      case .shareTapped:
        // This is a placeholder for sharing the content.
        // TODO: Implement share functionality
        return .none

      case .downloadTapped:
        // This is a placeholder for downloading the content.
        // TODO: Implement download functionality
        return .none

      case .similarContentTapped(let content):
        // This is a placeholder for navigating to a similar content item.
        // TODO: Implement navigation
        return .none

      case .castMemberTapped(let cast):
        // This is a placeholder for showing cast member details.
        // TODO: Implement cast detail view
        return .none

      case .dismissPlayer:
        // Set the flag to show the player to false.
        state.showPlayer = false
        return .none
      }
    }
  }
}
