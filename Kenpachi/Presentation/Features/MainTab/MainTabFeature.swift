// MainTabFeature.swift
// TCA feature for main tab navigation
// Manages tab selection and coordinates child features

import ComposableArchitecture
import Foundation

@Reducer
struct MainTabFeature {

  @ObservableState
  struct State: Equatable {
    /// Currently selected tab
    var selectedTab: Tab = .home
    /// Home feature state
    var home = HomeFeature.State()
    /// Search feature state
    var search = SearchFeature.State()
    /// Downloads feature state
    var downloads = DownloadsFeature.State()
    /// MySpace feature state
    var mySpace = MySpaceFeature.State()
    /// Content detail presentation state
    @Presents var contentDetail: ContentDetailFeature.State?

    /// Available tabs in the app
    enum Tab: String, CaseIterable, Identifiable {
      case home
      case search
      case downloads
      case mySpace

      var id: String { rawValue }

      /// Display name for the tab
      var displayName: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .downloads: return "Downloads"
        case .mySpace: return "MySpace"
        }
      }

      /// SF Symbol icon name for the tab
      var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .downloads: return "arrow.down.circle.fill"
        case .mySpace: return "person.fill"
        }
      }
    }
  }

  enum Action: Equatable {
    /// Tab selection changed
    case tabSelected(State.Tab)
    /// Home feature actions
    case home(HomeFeature.Action)
    /// Search feature actions
    case search(SearchFeature.Action)
    /// Downloads feature actions
    case downloads(DownloadsFeature.Action)
    /// MySpace feature actions
    case mySpace(MySpaceFeature.Action)
    /// Content detail presentation actions
    case contentDetail(PresentationAction<ContentDetailFeature.Action>)
    /// Navigate to content detail
    case navigateToContentDetail(String, ContentType?)
  }

  var body: some Reducer<State, Action> {
    // Scope the HomeFeature to handle its own logic
    Scope(state: \.home, action: \.home) {
      HomeFeature()
    }

    // Scope the SearchFeature to handle its own logic
    Scope(state: \.search, action: \.search) {
      SearchFeature()
    }

    // Scope the DownloadsFeature to handle its own logic
    Scope(state: \.downloads, action: \.downloads) {
      DownloadsFeature()
    }

    // Scope the MySpaceFeature to handle its own logic
    Scope(state: \.mySpace, action: \.mySpace) {
      MySpaceFeature()
    }

    Reduce { state, action in
      switch action {
      case .tabSelected(let tab):
        // Update selected tab
        state.selectedTab = tab
        return .none

      case .home(.contentTapped(let content)):
        // Navigate to content detail from home
        return .send(.navigateToContentDetail(content.id, content.type))

      case .home:
        // Handled by HomeFeature scope
        return .none

      case .search(.searchResultTapped(let content)):
        // Navigate to content detail from search
        return .send(.navigateToContentDetail(content.id, content.type))

      case .search:
        // Handled by SearchFeature scope
        return .none

      case .downloads(.downloadTapped(let download)):
        // Navigate to content detail from downloads
        return .send(.navigateToContentDetail(download.content.id, download.content.type))

      case .downloads:
        // Handled by DownloadsFeature scope
        return .none

      case .mySpace(.watchlistItemTapped(let content)),
        .mySpace(.historyItemTapped(let content)):
        // Navigate to content detail from MySpace
        return .send(.navigateToContentDetail(content.id, content.type))
      
      case .mySpace(.delegate(.settingsUpdated)):
        // Settings were updated, refresh home content
        return .send(.home(.refresh))

      case .mySpace:
        // Handled by MySpaceFeature scope
        return .none

      case .navigateToContentDetail(let contentId, let type):
        // Present content detail screen
        state.contentDetail = ContentDetailFeature.State(contentId: contentId, type: type)
        return .none

      case .contentDetail(.presented(.delegate(.navigateToContent(let contentId, let type)))):
        // Navigate to another content detail (replace current)
        state.contentDetail = ContentDetailFeature.State(contentId: contentId, type: type)
        return .none
        
      case .contentDetail(.presented(.delegate(.dismiss))):
        // Dismiss content detail
        state.contentDetail = nil
        return .none

      case .contentDetail:
        // Handled by ContentDetailFeature
        return .none
      }
    }
    .ifLet(\.$contentDetail, action: \.contentDetail) {
      ContentDetailFeature()
    }
  }
}
