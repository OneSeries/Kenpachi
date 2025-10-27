// ContentDetailView.swift
// This file defines the SwiftUI view for the content detail screen.
// It provides a comprehensive and immersive user interface for displaying content information,
// similar in style to the Disney+ application.

import ComposableArchitecture // Imports the Composable Architecture library for state management.
import SwiftUI // Imports the SwiftUI framework for building the user interface.

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
            retryAction: { viewStore.send(.loadContentDetails) } // The retry button sends the `loadContentDetails` action.
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

                // This `VStack` contains the sections with content information.
                VStack(alignment: .leading, spacing: .spacingXXL) {
                  // The `ContentInfoSection` displays the title and metadata.
                  ContentInfoSection(content: content)
                    .padding(.horizontal, .spacingXL - 4)

                  // If there is an overview, display the `OverviewSection`.
                  if let overview = content.overview, !overview.isEmpty {
                    OverviewSection(overview: overview)
                      .padding(.horizontal, .spacingXL - 4)
                  }

                  // If the content is a TV show, display the `EpisodeListSection`.
                  if content.type == .tvShow, let seasons = content.seasons, !seasons.isEmpty {
                    EpisodeListSection(
                      seasons: seasons,
                      selectedSeason: viewStore.selectedSeason,
                      selectedEpisode: viewStore.selectedEpisode,
                      onSeasonSelected: { viewStore.send(.seasonSelected($0)) },
                      onEpisodeSelected: { viewStore.send(.episodeSelected($0)) }
                    )
                    .padding(.horizontal, .spacingXL - 4)
                  }

                  // If there is cast information, display the `CastSection`.
                  if let cast = content.cast, !cast.isEmpty {
                    CastSection(
                      cast: cast,
                      onCastTapped: { viewStore.send(.castMemberTapped($0)) }
                    )
                    .padding(.horizontal, .spacingXL - 4)
                  }

                  // If there are recommendations, display the `SimilarContentSection`.
                  if let recommendations = content.recommendations, !recommendations.isEmpty {
                    SimilarContentSection(
                      content: recommendations,
                      onContentTapped: { viewStore.send(.similarContentTapped($0)) }
                    )
                    .padding(.horizontal, .spacingXL - 4)
                  }
                }
                .padding(.top, .spacingL)
                .padding(.bottom, 60)
              }
            }
            .scrollIndicators(.hidden) // The scroll indicators are hidden.
          }
          .ignoresSafeArea(edges: .top) // The view ignores the top safe area to create an immersive layout.
        }
        
        // If streaming links are being loaded, show a loading overlay.
        if viewStore.isLoadingLinks {
          ZStack {
            Color.black.opacity(0.6)
              .ignoresSafeArea()
            
            VStack(spacing: .spacingL) {
              ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
              
              Text("Extracting streaming links...")
                .font(.bodyMedium)
                .foregroundColor(.white)
            }
          }
        }
      }
      .background(Color.appBackground) // The background color of the view.
      .navigationBarTitleDisplayMode(.inline) // The navigation bar title is displayed inline.
      .disabled(viewStore.isLoadingLinks) // The view is disabled while loading links.
      .onAppear {
        viewStore.send(.onAppear) // When the view appears, send the `onAppear` action.
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

// MARK: - Immersive Header View
/// A private view for the immersive header, displaying the backdrop image and action buttons.
struct ImmersiveHeaderView: View {
  let content: Content // The content to display.
  let geometry: GeometryProxy // The geometry proxy for dynamic sizing.
  let isInWatchlist: Bool // A boolean indicating if the content is in the watchlist.
  let onPlayTapped: () -> Void // The action for the play button.
  let onTrailerTapped: () -> Void // The action for the trailer button.
  let onWatchlistTapped: () -> Void // The action for the watchlist button.
  let onShareTapped: () -> Void // The action for the share button.
  let onDownloadTapped: () -> Void // The action for the download button.

  var body: some View {
    ZStack(alignment: .bottom) {
      // If a backdrop URL is available, display the backdrop image.
      if let backdropURL = content.fullBackdropURL {
        AsyncImage(url: backdropURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Rectangle()
            .fill(Color.gray.opacity(0.2))
        }
        .frame(width: geometry.size.width, height: 500)
        .clipped()
      } else {
        Rectangle()
          .fill(Color.gray.opacity(0.2))
          .frame(width: geometry.size.width, height: 500)
      }

      // A multi-layer gradient to create a depth effect.
      VStack(spacing: 0) {
        // A gradient at the top to fade into the background.
        LinearGradient(
          colors: [Color.appBackground.opacity(0.6), .clear],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 150)

        Spacer()

        // A stronger gradient at the bottom to blend with the content.
        LinearGradient(
          colors: [.clear, Color.appBackground.opacity(0.7), Color.appBackground],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 250)
      }
      .frame(height: 500)

      // An overlay containing the content logo and action buttons.
      VStack(spacing: .spacingXL - 4) {
        // If a poster URL is available, display the poster image as a logo.
        if let posterURL = content.fullPosterURL {
          AsyncImage(url: posterURL) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
          } placeholder: {
            EmptyView()
          }
          .frame(width: 200, height: 120)
          .shadow(color: Color.appBackground.opacity(0.5), radius: 10, x: 0, y: 5)
        }

        // A `VStack` for the action buttons.
        VStack(spacing: .spacingM - 2) {
          // The primary play button.
          Button(action: onPlayTapped) {
            HStack(spacing: .spacingS + 2) {
              Image(systemName: "play.fill")
                .font(.labelLarge)
              Text("content.play.button")
                .font(.labelLarge)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.primaryBlue)
            .foregroundColor(.white)
            .cornerRadius(.radiusM)
          }
          .padding(.horizontal, .spacingXL - 4)

          // A row of secondary action buttons.
          HStack(spacing: .spacingM) {
            // The watchlist button.
            ActionButton(
              icon: isInWatchlist ? "checkmark" : "plus",
              title: isInWatchlist ? "Watchlist" : "Watchlist",
              action: onWatchlistTapped
            )

            // The download button.
            ActionButton(
              icon: "arrow.down.to.line",
              title: "Download",
              action: onDownloadTapped
            )

            // The trailer button, only shown if a trailer URL is available.
            if content.trailerUrl != nil {
              ActionButton(
                icon: "play.rectangle",
                title: "Trailer",
                action: onTrailerTapped
              )
            }
          }
          .padding(.horizontal, .spacingXL - 4)
        }
      }
      .padding(.bottom, .spacingL)
    }
    .frame(height: 500)
  }
}

// MARK: - Action Button
/// A private view for the secondary action buttons.
struct ActionButton: View {
  let icon: String // The name of the icon for the button.
  let title: String // The title of the button.
  let action: () -> Void // The action to perform when the button is tapped.

  var body: some View {
    Button(action: action) {
      VStack(spacing: .spacingXS + 2) {
        Image(systemName: icon)
          .font(.title3)
        Text(title)
          .font(.labelSmall)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 70)
      .background(Color.cardBackground)
      .foregroundColor(Color.textPrimary)
      .cornerRadius(.radiusM + 2)
    }
  }
}

// MARK: - Content Info Section
/// A private view for displaying the content's metadata.
struct ContentInfoSection: View {
  let content: Content // The content to display.

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS) {
      // A row of metadata with improved spacing.
      HStack(spacing: .spacingS) {
        if let year = content.releaseYear {
          Text(year)
            .foregroundColor(Color.textSecondary)
        }

        if let rating = content.formattedRating {
          HStack(spacing: .spacingXS) {
            Image(systemName: "star.fill")
              .font(.captionLarge)
              .foregroundColor(.warning)
            Text(rating)
              .foregroundColor(Color.textSecondary)
          }
        }

        if let runtime = content.formattedRuntime {
          Text("content.separator")
            .foregroundColor(Color.textSecondary)
          Text(runtime)
            .foregroundColor(Color.textSecondary)
        }

        if content.adult {
          Text("content.adult.label")
            .font(.captionMedium.bold())
            .padding(.horizontal, .spacingS)
            .padding(.vertical, 3)
            .background(Color.error)
            .foregroundColor(.white)
            .cornerRadius(.radiusS)
        }
      }
      .font(.labelMedium)

      // If genres are available, display them in a horizontally scrollable view.
      if let genres = content.genres, !genres.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: .spacingS + 2) {
            ForEach(genres) { genre in
              Text(genre.name)
                .font(.bodySmall)
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, .spacingM - 2)
                .padding(.vertical, 7)
                .background(Color.cardBackground)
                .cornerRadius(.radiusXL)
            }
          }
        }
      }

      // If a tagline is available, display it.
      if let tagline = content.tagline, !tagline.isEmpty {
        Text(tagline)
          .font(.bodyMedium)
          .foregroundColor(Color.textSecondary)
          .italic()
      }
    }
  }
}

// MARK: - Overview Section
/// A private view for displaying the content's overview.
struct OverviewSection: View {
  let overview: String // The overview text.
  @State private var isExpanded = false // A state variable to control whether the full text is shown.

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS) {
      Text("content.synopsis.title")
        .font(.headlineSmall)
        .foregroundColor(Color.textPrimary)

      Text(overview)
        .font(.bodyMedium)
        .foregroundColor(Color.textSecondary)
        .lineSpacing(.spacingXS)
        .lineLimit(isExpanded ? nil : 4) // The text is limited to 4 lines by default.
        .animation(.easeInOut(duration: 0.3), value: isExpanded)

      // If the overview is long, show a "Read More" button.
      if overview.count > 200 {
        Button(action: {
          withAnimation {
            isExpanded.toggle()
          }
        }) {
          HStack(spacing: .spacingXS) {
            Text(isExpanded ? "content.read_less.button" : "content.read_more.button")
              .font(.labelMedium)
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
              .font(.labelSmall)
          }
          .foregroundColor(Color.primaryBlue)
        }
      }
    }
  }
}
