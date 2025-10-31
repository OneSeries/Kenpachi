// ContentDetailView.swift
// This file defines the SwiftUI view for the content detail screen.
// It provides a comprehensive and immersive user interface for displaying content information,
// similar in style to the Disney+ application.

import ComposableArchitecture  // Imports the Composable Architecture library for state management.
import SwiftUI  // Imports the SwiftUI framework for building the user interface.

/// The `ContentDetailView` struct defines the main view for the content detail screen.
struct ContentDetailView: View {
  /// This property holds the TCA `Store` for the `ContentDetailFeature`.
  let store: StoreOf<ContentDetailFeature>

  /// The `body` of the view defines its content and layout.
  var body: some View {
    // The `WithViewStore` is used to observe the state of the store.
    WithViewStore(store, observe: { $0 }) { viewStore in
      // A `ZStack` is used to layer views on top of each other.
      ZStack {
        // If the content is loading, show a loading view.
        if viewStore.isLoading {
          LoadingView()
          // If there is an error message, show an error view.
        } else if let errorMessage = viewStore.errorMessage {
          ErrorView(
            message: errorMessage,
            retryAction: { viewStore.send(.loadContentDetails) }  // The retry button sends the `loadContentDetails` action.
          )
          // If the content is loaded, display the main content.
        } else if let content = viewStore.content {
          // A `GeometryReader` is used to get the size of the parent view.
          GeometryReader { geometry in
            // A `ScrollView` allows the content to be scrolled vertically.
            ScrollView {
              // A `VStack` arranges the content vertically.
              VStack(spacing: 0) {
                // The immersive header view displays the backdrop image and action buttons.
                ImmersiveHeaderView(
                  content: content,
                  geometry: geometry,
                  isInWatchlist: viewStore.isInWatchlist,
                  onPlayTapped: { viewStore.send(.playTapped) },
                  onTrailerTapped: { viewStore.send(.trailerPlayTapped) },
                  onWatchlistTapped: {
                    if viewStore.isInWatchlist {
                      viewStore.send(.removeFromWatchlistTapped)
                    } else {
                      viewStore.send(.addToWatchlistTapped)
                    }
                  },
                  onShareTapped: { viewStore.send(.shareTapped) },
                  onDownloadTapped: { viewStore.send(.downloadTapped) }
                )

                // Content sections (Hotstar style - tighter spacing)
                VStack(alignment: .leading, spacing: .spacingL) {
                  // Metadata section
                  ContentInfoSection(content: content)
                    .padding(.horizontal, .spacingL - 4)

                  // Overview section
                  if let overview = content.overview, !overview.isEmpty {
                    OverviewSection(overview: overview)
                      .padding(.horizontal, .spacingL - 4)
                  }

                  // Episodes section for TV shows
                  if content.type == .tvShow, let seasons = content.seasons, !seasons.isEmpty {
                    EpisodeListSection(
                      seasons: seasons,
                      selectedSeason: viewStore.selectedSeason,
                      selectedEpisode: viewStore.selectedEpisode,
                      onSeasonSelected: { viewStore.send(.seasonSelected($0)) },
                      onEpisodeSelected: { viewStore.send(.episodeSelected($0)) }
                    )
                  }

                  // Cast section
                  if let cast = content.cast, !cast.isEmpty {
                    CastSection(
                      cast: cast,
                      onCastTapped: { viewStore.send(.castMemberTapped($0)) }
                    )
                  }

                  // Similar content section
                  if let recommendations = content.recommendations, !recommendations.isEmpty {
                    SimilarContentSection(
                      content: recommendations,
                      onContentTapped: { viewStore.send(.similarContentTapped($0)) }
                    )
                  }
                }
                .padding(.top, .spacingL - 4)
                .padding(.bottom, .spacingXXL + 12)
              }
            }
            .scrollIndicators(.hidden)  // The scroll indicators are hidden.
          }
          .ignoresSafeArea(edges: .top)  // The view ignores the top safe area to create an immersive layout.
        }

        // If streaming links are being loaded, show a loading overlay.
        if viewStore.isLoadingLinks {
          ZStack {
            Color.overlay
              .ignoresSafeArea()

            VStack(spacing: .spacingL) {
              ProgressView()
                .scaleEffect(1.5)
                .tint(.primaryBlue)

              Text("player.extracting_links")
                .font(.bodyMedium)
                .foregroundColor(.white)
            }
          }
        }
      }
      .background(Color.appBackground)  // The background color of the view.
      .navigationBarTitleDisplayMode(.inline)  // The navigation bar title is displayed inline.
      .disabled(viewStore.isLoadingLinks)  // The view is disabled while loading links.
      .onAppear {
        viewStore.send(.onAppear)  // When the view appears, send the `onAppear` action.
      }
      .fullScreenCover(
        isPresented: viewStore.binding(
          get: \.showPlayer,
          send: .dismissPlayer
        )
      ) {
        // When `showPlayer` is true, present the `PlayerView` as a full-screen cover.
        if !viewStore.streamingLinks.isEmpty, let content = viewStore.content {
          PlayerView(
            store: Store(
              initialState: PlayerFeature.State(
                content: content,
                episode: viewStore.selectedEpisode,
                streamingLinks: viewStore.streamingLinks
              )
            ) {
              PlayerFeature()
            }
          )
        }
      }
    }
  }
}

// MARK: - Immersive Header View (Hotstar Style)
/// A private view for the immersive header, displaying the backdrop image and action buttons.
struct ImmersiveHeaderView: View {
  let content: Content  // The content to display.
  let geometry: GeometryProxy  // The geometry proxy for dynamic sizing.
  let isInWatchlist: Bool  // A boolean indicating if the content is in the watchlist.
  let onPlayTapped: () -> Void  // The action for the play button.
  let onTrailerTapped: () -> Void  // The action for the trailer button.
  let onWatchlistTapped: () -> Void  // The action for the watchlist button.
  let onShareTapped: () -> Void  // The action for the share button.
  let onDownloadTapped: () -> Void  // The action for the download button.

  var body: some View {
    ZStack(alignment: .bottom) {
      // Backdrop image with proper aspect ratio
      if let backdropURL = content.fullBackdropURL {
        AsyncImage(url: backdropURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Rectangle()
            .fill(Color.gray.opacity(0.15))
        }
        .frame(width: geometry.size.width, height: 450)
        .clipped()
      } else {
        Rectangle()
          .fill(Color.cardBackground)
          .frame(width: geometry.size.width, height: 450)
      }

      // Multi-layer gradient overlay (Hotstar style)
      VStack(spacing: 0) {
        LinearGradient(
          colors: [Color.black.opacity(0.5), .clear],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 120)

        Spacer()

        LinearGradient(
          colors: [
            .clear,
            Color.appBackground.opacity(0.5),
            Color.appBackground.opacity(0.9),
            Color.appBackground,
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 200)
      }
      .frame(height: 450)

      // Content overlay with title and buttons (Hotstar style)
      VStack(alignment: .leading, spacing: .spacingM) {
        // Title
        Text(content.title)
          .font(.displaySmall)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .lineLimit(2)
          .shadow(color: .black.opacity(0.3), radius: .spacingXS, x: 0, y: 2)
          .padding(.horizontal, .spacingL - 4)

        // Action buttons row (Hotstar style - horizontal)
        HStack(spacing: .spacingS + 4) {
          // Watch Now button (primary)
          Button(action: onPlayTapped) {
            HStack(spacing: .spacingS) {
              Image(systemName: "play.fill")
                .font(.labelMedium)
                .fontWeight(.bold)
              Text("content.watch_now")
                .font(.labelLarge)
                .fontWeight(.bold)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.white)
            .cornerRadius(.radiusM)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .overlay(
              RoundedRectangle(cornerRadius: .radiusM)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
          }

          // Watchlist button
          Button(action: onWatchlistTapped) {
            Image(systemName: isInWatchlist ? "checkmark" : "plus")
              .font(.headlineSmall)
              .fontWeight(.semibold)
              .foregroundColor(.white)
              .frame(width: 48, height: 48)
              .background(
                Color.black.opacity(0.5)
                  .overlay(Color.white.opacity(0.15))
              )
              .cornerRadius(.radiusM)
              .overlay(
                RoundedRectangle(cornerRadius: .radiusM)
                  .stroke(Color.white.opacity(0.3), lineWidth: 1)
              )
          }

          // Download button
          Button(action: onDownloadTapped) {
            Image(systemName: "arrow.down.circle")
              .font(.headlineSmall)
              .fontWeight(.semibold)
              .foregroundColor(.white)
              .frame(width: 48, height: 48)
              .background(
                Color.black.opacity(0.5)
                  .overlay(Color.white.opacity(0.15))
              )
              .cornerRadius(.radiusM)
              .overlay(
                RoundedRectangle(cornerRadius: .radiusM)
                  .stroke(Color.white.opacity(0.3), lineWidth: 1)
              )
          }
        }
        .padding(.horizontal, .spacingL - 4)
        .padding(.bottom, .spacingL)
      }
    }
    .frame(height: 450)
  }
}

// MARK: - Content Info Section (Hotstar Style)
/// A private view for displaying the content's metadata.
struct ContentInfoSection: View {
  let content: Content  // The content to display.

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS + 4) {
      // Metadata row (Hotstar style - compact)
      HStack(spacing: .spacingS) {
        if let year = content.releaseYear {
          Text(year)
            .font(.labelMedium)
            .foregroundColor(.textSecondary)
        }

        if let rating = content.formattedRating {
          HStack(spacing: .spacingXS / 2) {
            Image(systemName: "star.fill")
              .font(.captionLarge)
              .foregroundColor(.warning)
            Text(rating)
              .font(.labelMedium)
              .foregroundColor(.textSecondary)
          }
        }

        if let runtime = content.formattedRuntime {
          Text("•")
            .foregroundColor(.textTertiary)
          Text(runtime)
            .font(.labelMedium)
            .foregroundColor(.textSecondary)
        }

        if content.adult {
          Text("18+")
            .font(.captionLarge)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, .spacingXS + 2)
            .padding(.vertical, .spacingXS / 2)
            .background(Color.error)
            .cornerRadius(.radiusS / 2)
        }
      }

      // Genres (Hotstar style - pill badges)
      if let genres = content.genres, !genres.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: .spacingS) {
            ForEach(genres.prefix(5)) { genre in
              Text(genre.name)
                .font(.labelSmall)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, .spacingS + 4)
                .padding(.vertical, .spacingXS + 2)
                .background(Color.cardBackground)
                .cornerRadius(.radiusL)
            }
          }
        }
      }
    }
  }
}

// MARK: - Overview Section (Hotstar Style)
/// A private view for displaying the content's overview.
struct OverviewSection: View {
  let overview: String  // The overview text.
  @State private var isExpanded = false  // A state variable to control whether the full text is shown.

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS + 2) {
      Text("content.about")
        .font(.headlineSmall)
        .foregroundColor(.textPrimary)

      Text(overview)
        .font(.bodyMedium)
        .foregroundColor(.textSecondary)
        .lineSpacing(.spacingXS)
        .lineLimit(isExpanded ? nil : 3)
        .animation(.quick, value: isExpanded)

      // Show "More" button if text is long
      if overview.count > 150 {
        Button(action: {
          withAnimation(.standard) {
            isExpanded.toggle()
          }
        }) {
          Text(isExpanded ? "content.less" : "content.more")
            .font(.labelMedium)
            .fontWeight(.semibold)
            .foregroundColor(.primaryBlue)
        }
      }
    }
  }
}
