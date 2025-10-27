// MySpaceFeature.swift
// TCA feature for MySpace/Profile screen
// Manages user profile, watchlist, and app settings

import ComposableArchitecture
import Foundation

@Reducer
struct MySpaceFeature {

  @ObservableState
  struct State: Equatable {
    /// User profile
    var userProfile: UserProfile?
    /// Watchlist items
    var watchlist: [Content] = []
    /// Watch history
    var watchHistory: [Content] = []
    /// Loading state
    var isLoading = false
    /// Error message
    var errorMessage: String?
    /// Show settings
    @Presents var settings: SettingsFeature.State?
    /// Statistics
    var totalWatchTime: TimeInterval = 0
    var contentWatched: Int = 0
    var favoriteGenres: [String] = []
  }

  enum Action: Equatable {
    /// View appeared
    case onAppear
    /// Refresh data
    case refresh
    /// Profile loaded
    case profileLoaded(UserProfile)
    /// Watchlist loaded
    case watchlistLoaded([Content])
    /// Watch history loaded
    case watchHistoryLoaded([Content])
    /// Statistics loaded
    case statisticsLoaded(watchTime: TimeInterval, contentCount: Int, genres: [String])
    /// Watchlist item tapped
    case watchlistItemTapped(Content)
    /// History item tapped
    case historyItemTapped(Content)
    /// Settings tapped
    case settingsTapped
    /// Settings actions
    case settings(PresentationAction<SettingsFeature.Action>)
    /// Remove from watchlist
    case removeFromWatchlist(String)
    /// Clear watch history
    case clearWatchHistory
    /// Error occurred
    case errorOccurred(String)
    /// Delegate actions
    case delegate(Delegate)

    enum Delegate: Equatable {
      case settingsUpdated
    }
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        /// Load profile data
        return .send(.refresh)

      case .refresh:
        /// Refresh all data
        state.isLoading = true
        state.errorMessage = nil

        return .run { send in
          do {
            /// Fetch user profile
            let profile =
              try await UserRepository.shared.fetchUserProfile()
              ?? UserProfile(
                id: "user-1",
                name: "User",
                email: nil,
                avatarURL: nil
              )
            await send(.profileLoaded(profile))

            /// Fetch watchlist
            let watchlist = try await WatchlistManager.shared.fetchWatchlist()
            await send(.watchlistLoaded(watchlist))

            /// Fetch watch history
            let history = try await WatchHistoryManager.shared.fetchWatchHistory()
            await send(.watchHistoryLoaded(history))

            /// Fetch statistics
            let stats = try await UserRepository.shared.getUserStatistics()
            await send(
              .statisticsLoaded(
                watchTime: stats.watchTime,
                contentCount: stats.contentCount,
                genres: stats.favoriteGenres
              ))
          } catch {
            await send(.errorOccurred(error.localizedDescription))
          }
        }

      case .profileLoaded(let profile):
        /// Update profile
        state.userProfile = profile
        state.isLoading = false
        return .none

      case .watchlistLoaded(let watchlist):
        /// Update watchlist
        state.watchlist = watchlist
        return .none

      case .watchHistoryLoaded(let history):
        /// Update watch history
        state.watchHistory = history
        return .none

      case .statisticsLoaded(let watchTime, let contentCount, let genres):
        /// Update statistics
        state.totalWatchTime = watchTime
        state.contentWatched = contentCount
        state.favoriteGenres = genres
        return .none

      case .watchlistItemTapped:
        /// Navigate to content detail
        return .none

      case .historyItemTapped:
        /// Navigate to content detail
        return .none

      case .settingsTapped:
        /// Show settings
        state.settings = SettingsFeature.State()
        return .none

      case .settings(.presented(.delegate(.settingsUpdated))):
        /// Settings were updated, refresh watchlist as scraper may have changed
        return .merge(
          .send(.refresh),
          .send(.delegate(.settingsUpdated))
        )

      case .settings:
        /// Handle settings actions
        return .none

      case .removeFromWatchlist(let contentId):
        /// Remove from watchlist
        state.watchlist.removeAll { $0.id == contentId }

        return .run { send in
          do {
            try await WatchlistManager.shared.removeFromWatchlist(contentId: contentId)
          } catch {
            await send(.errorOccurred(error.localizedDescription))
          }
        }

      case .clearWatchHistory:
        /// Clear watch history
        state.watchHistory = []

        return .run { send in
          do {
            try await UserRepository.shared.clearWatchHistory()
          } catch {
            await send(.errorOccurred(error.localizedDescription))
          }
        }

      case .errorOccurred(let message):
        /// Handle error
        state.errorMessage = message
        state.isLoading = false
        return .none

      case .delegate:
        /// Delegate actions handled by parent
        return .none
      }
    }
    .ifLet(\.$settings, action: \.settings) {
      SettingsFeature()
    }
  }
}
