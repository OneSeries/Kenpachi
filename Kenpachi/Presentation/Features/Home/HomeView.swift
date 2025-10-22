// HomeView.swift
// Disney+ style home screen with hero carousel and content rows
// Displays featured content and browsable categories

import ComposableArchitecture
import SwiftUI

struct HomeView: View {
  /// TCA store for home feature
  let store: StoreOf<HomeFeature>

  var body: some View {
    ZStack {
      // Background color
      Color.appBackground.ignoresSafeArea()

      if store.isLoading && store.contentCarousels.isEmpty {
        // Loading state
        LoadingView()
      } else if let errorMessage = store.errorMessage {
        // Error state
        ErrorStateView(message: errorMessage) {
          store.send(.refresh)
        }
      } else {
        // Content loaded
        ScrollView(.vertical, showsIndicators: false) {
          VStack(spacing: 0) {
            // Dynamic content sections based on carousels
            ForEach(store.contentCarousels) { carousel in
              if carousel.type == .hero {
                // Hero carousel section
                HeroCarouselSection(
                  items: carousel.items,
                  currentIndex: store.currentHeroIndex,
                  onIndexChanged: { index in
                    store.send(.heroIndexChanged(index))
                  },
                  onItemTapped: { content in
                    store.send(.contentTapped(content))
                  },
                  onPlayTapped: { content in
                    store.send(.playTapped(content))
                  },
                  onWatchlistTapped: { content in
                    store.send(.watchlistTapped(content))
                  }
                )
              } else {
                // Regular content row section
                ContentRowSection(
                  title: carousel.title,
                  items: carousel.items,
                  onItemTapped: { content in
                    store.send(.contentTapped(content))
                  }
                )

              }
            }
            .padding(.top, 24)
            .padding(.bottom, 40)
          }
        }
        .ignoresSafeArea(edges: .top)
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
    .overlay {
      // Loading overlay when extracting links
      if store.isLoadingPlay {
        ZStack {
          Color.black.opacity(0.6)
            .ignoresSafeArea()

          VStack(spacing: 16) {
            ProgressView()
              .scaleEffect(1.5)
              .tint(.white)

            Text("Loading video...")
              .font(.subheadline)
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
      // Player view
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
/// Error state view with retry button
private struct ErrorStateView: View {
  let message: String
  let onRetry: () -> Void

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
