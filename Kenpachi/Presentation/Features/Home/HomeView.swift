// HomeView.swift
// This file defines the SwiftUI view for the home screen of the Kenpachi app.
// It is designed to replicate the look and feel of the Disney+ home screen,
// featuring a hero carousel and horizontally scrollable content rows.

import ComposableArchitecture  // Imports the Composable Architecture library for state management.
import SwiftUI  // Imports the SwiftUI framework for building the user interface.

/// The `HomeView` struct defines the main view for the home screen.
struct HomeView: View {
  /// This property holds the TCA `Store` for the `HomeFeature`.
  /// The store is the single source of truth for the view's state.
  let store: StoreOf<HomeFeature>

  /// The `body` of the view defines its content and layout.
  var body: some View {
    // A `ZStack` is used to layer views on top of each other.
    ZStack {
      // The background color of the view is set to the app's background color.
      Color.appBackground.ignoresSafeArea()

      // If the content is loading and there are no carousels to display, show a loading view.
      if store.isLoading && store.contentCarousels.isEmpty {
        LoadingView()
        // If there is an error message, show an error state view.
      } else if let errorMessage = store.errorMessage {
        ErrorStateView(message: errorMessage) {
          // The error view has a retry button that sends the `refresh` action.
          store.send(.refresh)
        }
        // Otherwise, if the content is loaded, display the main content.
      } else {
        // A `ScrollView` is used to allow the content to be scrolled vertically.
        ScrollView(.vertical, showsIndicators: false) {
          // A `VStack` is used to arrange the content vertically.
          VStack(spacing: .spacingL + 4) {
            // The view iterates over the `contentCarousels` array to create the content sections.
            ForEach(store.contentCarousels) { carousel in
              // If the carousel type is `.hero`, create a `HeroCarouselSection`.
              if carousel.type == .hero {
                HeroCarouselSection(
                  items: carousel.items,  // The items to display in the carousel.
                  currentIndex: store.currentHeroIndex,  // The index of the current item.
                  watchlistStatus: store.heroWatchlistStatus,  // The watchlist status of the items.
                  onIndexChanged: { index in
                    // When the index changes, send the `heroIndexChanged` action.
                    store.send(.heroIndexChanged(index))
                  },
                  onItemTapped: { content in
                    // When an item is tapped, send the `contentTapped` action.
                    store.send(.contentTapped(content))
                  },
                  onPlayTapped: { content in
                    // When the play button is tapped, send the `playTapped` action.
                    store.send(.playTapped(content))
                  },
                  onWatchlistTapped: { content in
                    // When the watchlist button is tapped, send the `watchlistTapped` action.
                    store.send(.watchlistTapped(content))
                  }
                )
                .padding(.bottom, .spacingXS)
                
                // Display "My Watchlist" section immediately after hero carousel
                if !store.watchlistItems.isEmpty {
                  VStack(alignment: .leading, spacing: .spacingM) {
                    HStack {
                      Text("myspace.watchlist.title")
                        .font(.headlineSmall)
                        .foregroundColor(.textPrimary)

                      Spacer()
                      
                      // Display a badge with the name of the active scraper.
                      Text(ScraperManager.shared.getActiveScraper()?.name ?? "")
                        .font(.captionLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, .spacingS)
                        .padding(.vertical, .spacingXS)
                        .background(Color.primaryBlue.opacity(0.7))
                        .cornerRadius(.radiusS)
                    }
                    .padding(.horizontal, .spacingM)
                    .padding(.bottom, .spacingS)

                    // Display the watchlist items in a `ContentRowSection`.
                    ContentRowSection(
                      title: "",
                      items: store.watchlistItems,
                      onItemTapped: { content in
                        store.send(.contentTapped(content))
                      }
                    )
                  }
                  .padding(.top, .spacingXS)
                }
                
                // Otherwise, create a `ContentRowSection`.
              } else {
                ContentRowSection(
                  title: carousel.title,  // The title of the content row.
                  items: carousel.items,  // The items to display in the row.
                  onItemTapped: { content in
                    // When an item is tapped, send the `contentTapped` action.
                    store.send(.contentTapped(content))
                  }
                )
              }
            }

            // A spacer to add some extra space at the bottom of the scroll view.
            Spacer(minLength: 60)
          }
        }
        .ignoresSafeArea(edges: .top)  // The scroll view ignores the top safe area to create an immersive layout.
      }
    }
    .onAppear {
      // When the view appears, send the `onAppear` action to the store.
      store.send(.onAppear)
    }
    .overlay {
      // If the app is currently extracting streaming links, show a loading overlay.
      if store.isLoadingPlay {
        ZStack {
          Color.overlay
            .ignoresSafeArea()

          VStack(spacing: .spacingM) {
            ProgressView()
              .scaleEffect(1.5)
              .tint(.primaryBlue)

            Text("player.loading")
              .font(.bodyMedium)
              .foregroundColor(.white)
          }
        }
      }
    }
    .fullScreenCover(
      isPresented: Binding(
        get: { store.showPlayer },
        set: { _ in store.send(.dismissPlayer) }
      )
    ) {
      // When `showPlayer` is true, present the `PlayerView` as a full-screen cover.
      if !store.streamingLinks.isEmpty, let content = store.contentToPlay {
        PlayerView(
          store: Store(
            initialState: PlayerFeature.State(
              content: content,
              episode: nil,
              streamingLinks: store.streamingLinks
            )
          ) {
            PlayerFeature()
          }
        )
      }
    }
  }
}

// MARK: - Error State View
/// A private view to display an error state with a retry button.
private struct ErrorStateView: View {
  let message: String  // The error message to display.
  let onRetry: () -> Void  // The action to perform when the retry button is tapped.

  var body: some View {
    VStack(spacing: .spacingL) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 60))
        .foregroundColor(.error)

      Text("error.title")
        .font(.headlineLarge)
        .foregroundColor(.textPrimary)

      Text(message)
        .font(.bodyMedium)
        .foregroundColor(.textSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, .spacingXXL)

      Button(action: onRetry) {
        Text("error.retry.button")
          .font(.labelLarge)
          .foregroundColor(.white)
          .padding(.horizontal, .spacingXXL)
          .padding(.vertical, .spacingS)
          .background(Color.primaryBlue)
          .cornerRadius(.radiusM)
      }
    }
  }
}
