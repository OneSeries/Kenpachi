// ContentDetailFeature.swift
// TCA feature for content detail screen
// Manages content details, episodes, cast, and streaming link extraction

import ComposableArchitecture
import Foundation

@Reducer
struct ContentDetailFeature {

  @ObservableState
  struct State: Equatable {
    /// Content ID to display
    let contentId: String
    /// Content type
    let type: ContentType?
    /// Loading state for content details
    var isLoading = false
    /// Error message if loading fails
    var errorMessage: String?
    /// Content details
    var content: Content?
    /// Selected season (for TV shows)
    var selectedSeason: Season?
    /// Selected episode (for TV shows)
    var selectedEpisode: Episode?
    /// Extracted streaming links
    var streamingLinks: [ExtractedLink] = []
    /// Loading state for streaming links
    var isLoadingLinks = false
    /// Whether to show player
    var showPlayer = false
    /// Whether content is in watchlist
    var isInWatchlist = false
    /// Similar/recommended content
    var similarContent: [Content] = []
    /// Auto-play trailer
    var autoPlayTrailer = true

    /// Initializer
      init(contentId: String, type: ContentType?) {
      self.contentId = contentId
      self.type = type
    }
  }

  enum Action: Equatable {
    /// Triggered when detail view appears
    case onAppear
    /// Load content details
    case loadContentDetails
    /// Content details loaded successfully
    case contentDetailsLoaded(Content)
    /// Content loading failed
    case loadingFailed(String)
    /// Season selected
    case seasonSelected(Season)
    /// Episode selected
    case episodeSelected(Episode)
    /// Play button tapped
    case playTapped
    /// Trailer play tapped
    case trailerPlayTapped
    /// Extract streaming links
    case extractStreamingLinks
    /// Streaming links extracted
    case streamingLinksExtracted([ExtractedLink])
    /// Streaming link extraction failed
    case linkExtractionFailed(String)
    /// Add to watchlist tapped
    case addToWatchlistTapped
    /// Remove from watchlist tapped
    case removeFromWatchlistTapped
    /// Share button tapped
    case shareTapped
    /// Download button tapped
    case downloadTapped
    /// Similar content item tapped
    case similarContentTapped(Content)
    /// Cast member tapped
    case castMemberTapped(Cast)
    /// Dismiss player
    case dismissPlayer
  }

  @Dependency(\.continuousClock) var clock

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        /// Load content details when view appears
        guard state.content == nil else { return .none }
        return .send(.loadContentDetails)

      case .loadContentDetails:
        /// Set loading state and fetch content details
        state.isLoading = true
        state.errorMessage = nil

        return .run { [contentId = state.contentId, type = state.type] send in
          do {
            /// Create repository instance
            let contentRepository = ContentRepository()

            /// Fetch content details
            let content = try await contentRepository.fetchContentDetails(id: contentId, type: type)

            await send(.contentDetailsLoaded(content))
          } catch {
            await send(.loadingFailed(error.localizedDescription))
          }
        }

      case .contentDetailsLoaded(let content):
        /// Update state with loaded content
        state.isLoading = false
        state.content = content

        /// Set first season as selected for TV shows
        if content.type == .tvShow, let firstSeason = content.seasons?.first {
          state.selectedSeason = firstSeason
        }

        /// TODO: Load similar content
        /// TODO: Check if in watchlist

        return .none

      case .loadingFailed(let message):
        /// Handle loading failure
        state.isLoading = false
        state.errorMessage = message
        return .none

      case .seasonSelected(let season):
        /// Update selected season
        state.selectedSeason = season
        state.selectedEpisode = nil
        return .none

      case .episodeSelected(let episode):
        /// Update selected episode and start playing
        state.selectedEpisode = episode
        state.isLoadingLinks = true
        state.errorMessage = nil
        return .send(.extractStreamingLinks)

      case .playTapped:
        /// Extract streaming links and show player
        state.isLoadingLinks = true
        state.errorMessage = nil
        return .send(.extractStreamingLinks)

      case .trailerPlayTapped:
        /// Play trailer
        /// TODO: Implement trailer playback
        return .none

      case .extractStreamingLinks:
        /// Extract streaming links for selected content/episode
        /// If no episode is selected for TV shows, use first episode of first season
        var episodeId = state.selectedEpisode?.id

        if episodeId == nil || episodeId?.isEmpty == true {
          /// For TV shows, try to get first episode of first season
          if state.content?.type == .tvShow,
            let firstSeason = state.content?.seasons?.first,
            let firstEpisode = firstSeason.episodes?.first
          {
            episodeId = firstEpisode.id
            /// Update selected episode
            state.selectedEpisode = firstEpisode
            state.selectedSeason = firstSeason
          }
        }

        return .run { [contentId = state.contentId, episodeId] send in
          do {
            /// Create repository instance
            let contentRepository = ContentRepository()

            /// Extract streaming links
            let links = try await contentRepository.extractStreamingLinks(
              contentId: contentId,
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
        /// Update state with extracted links
        state.isLoadingLinks = false
        state.streamingLinks = links
        state.showPlayer = true
        return .none

      case .linkExtractionFailed(let message):
        /// Handle link extraction failure
        state.isLoadingLinks = false
        state.errorMessage = message
        return .none

      case .addToWatchlistTapped:
        /// Add content to watchlist
        state.isInWatchlist = true
        /// TODO: Persist to storage
        return .none

      case .removeFromWatchlistTapped:
        /// Remove content from watchlist
        state.isInWatchlist = false
        /// TODO: Remove from storage
        return .none

      case .shareTapped:
        /// Share content
        /// TODO: Implement share functionality
        return .none

      case .downloadTapped:
        /// Download content
        /// TODO: Implement download functionality
        return .none

      case .similarContentTapped(let content):
        /// Navigate to similar content detail
        /// TODO: Implement navigation
        return .none

      case .castMemberTapped(let cast):
        /// Show cast member details
        /// TODO: Implement cast detail view
        return .none

      case .dismissPlayer:
        /// Dismiss player
        state.showPlayer = false
        return .none
      }
    }
  }
}
