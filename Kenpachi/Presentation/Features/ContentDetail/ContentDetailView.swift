// ContentDetailView.swift
// SwiftUI view for content detail screen
// Displays comprehensive content information with Disney+ style layout

import ComposableArchitecture
import SwiftUI

struct ContentDetailView: View {
  /// Store for TCA feature
  let store: StoreOf<ContentDetailFeature>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        if viewStore.isLoading {
          /// Loading state
          LoadingView()
        } else if let errorMessage = viewStore.errorMessage {
          /// Error state
          ErrorView(
            message: errorMessage,
            retryAction: { viewStore.send(.loadContentDetails) }
          )
        } else if let content = viewStore.content {
          /// Content loaded state - Immersive Disney+ style
          GeometryReader { geometry in
            ScrollView {
              VStack(spacing: 0) {
                /// Immersive header with backdrop
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

                /// Content sections
                VStack(alignment: .leading, spacing: .spacingXXL) {
                  /// Title and metadata
                  ContentInfoSection(content: content)
                    .padding(.horizontal, .spacingXL - 4)

                  /// Overview
                  if let overview = content.overview, !overview.isEmpty {
                    OverviewSection(overview: overview)
                      .padding(.horizontal, .spacingXL - 4)
                  }

                  /// Episodes (for TV shows)
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

                  /// Cast and crew
                  if let cast = content.cast, !cast.isEmpty {
                    CastSection(
                      cast: cast,
                      onCastTapped: { viewStore.send(.castMemberTapped($0)) }
                    )
                    .padding(.horizontal, .spacingXL - 4)
                  }

                  /// Similar content
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
            .scrollIndicators(.hidden)
          }
          .ignoresSafeArea(edges: .top)
        }
        
        /// Loading overlay when extracting links
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
      .background(Color.appBackground)
      .navigationBarTitleDisplayMode(.inline)
      .disabled(viewStore.isLoadingLinks)
      .onAppear {
        viewStore.send(.onAppear)
      }
      .fullScreenCover(
        isPresented: viewStore.binding(
          get: \.showPlayer,
          send: .dismissPlayer
        )
      ) {
        /// Player view
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
struct ImmersiveHeaderView: View {
  /// Content to display
  let content: Content
  /// Geometry proxy for dynamic sizing
  let geometry: GeometryProxy
  /// Whether content is in watchlist
  let isInWatchlist: Bool
  /// Play button action
  let onPlayTapped: () -> Void
  /// Trailer button action
  let onTrailerTapped: () -> Void
  /// Watchlist button action
  let onWatchlistTapped: () -> Void
  /// Share button action
  let onShareTapped: () -> Void
  /// Download button action
  let onDownloadTapped: () -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      /// Backdrop image with parallax effect
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

      /// Multi-layer gradient for depth
      VStack(spacing: 0) {
        /// Top fade
        LinearGradient(
          colors: [Color.appBackground.opacity(0.6), .clear],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 150)

        Spacer()

        /// Bottom fade with stronger gradient
        LinearGradient(
          colors: [.clear, Color.appBackground.opacity(0.7), Color.appBackground],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 250)
      }
      .frame(height: 500)

      /// Content overlay
      VStack(spacing: .spacingXL - 4) {
        /// Logo or title (if available)
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

        /// Action buttons
        VStack(spacing: .spacingM - 2) {
          /// Primary play button
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

          /// Secondary actions row
          HStack(spacing: .spacingM) {
            /// Watchlist button
            ActionButton(
              icon: isInWatchlist ? "checkmark" : "plus",
              title: isInWatchlist ? "Watchlist" : "Watchlist",
              action: onWatchlistTapped
            )

            /// Download button
            ActionButton(
              icon: "arrow.down.to.line",
              title: "Download",
              action: onDownloadTapped
            )

            /// Trailer button
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
struct ActionButton: View {
  /// Icon name
  let icon: String
  /// Button title
  let title: String
  /// Button action
  let action: () -> Void

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
struct ContentInfoSection: View {
  /// Content to display
  let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS) {
      /// Metadata row with better spacing
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

      /// Genres with improved styling
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

      /// Tagline if available
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
struct OverviewSection: View {
  /// Overview text
  let overview: String
  /// Whether to show full text
  @State private var isExpanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS) {
      Text("content.synopsis.title")
        .font(.headlineSmall)
        .foregroundColor(Color.textPrimary)

      Text(overview)
        .font(.bodyMedium)
        .foregroundColor(Color.textSecondary)
        .lineSpacing(.spacingXS)
        .lineLimit(isExpanded ? nil : 4)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)

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


