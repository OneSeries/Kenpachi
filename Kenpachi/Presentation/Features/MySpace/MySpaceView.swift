// MySpaceView.swift
// User profile and activity screen
// Displays watchlist, watch history, and statistics

import ComposableArchitecture
import SwiftUI

struct MySpaceView: View {
  /// TCA store for MySpace feature
  @Bindable var store: StoreOf<MySpaceFeature>

  var body: some View {
    NavigationStack {
      ZStack {
        Color.appBackground.ignoresSafeArea()

        if store.isLoading {
          /// Loading state
          LoadingView()
        } else {
          ScrollView {
            VStack(spacing: .spacingL) {
              /// Profile header
              ProfileHeaderView(
                profile: store.userProfile,
                onSettingsTapped: { store.send(.settingsTapped) }
              )
              .padding(.horizontal, .spacingM)

              /// Statistics cards
              StatisticsCardsView(
                watchTime: store.totalWatchTime,
                contentCount: store.contentWatched,
                favoriteGenres: store.favoriteGenres
              )
              .padding(.horizontal, .spacingM)

              /// Watchlist section
              if !store.watchlist.isEmpty {
                VStack(alignment: .leading, spacing: .spacingXS) {
                  HStack {
                    Text("myspace.watchlist.title")
                      .font(.headlineMedium)
                      .foregroundColor(.textPrimary)
                      .padding(.horizontal, .spacingM)

                    Spacer()

                    // Show current scraper
                    Text(ScraperManager.shared.getActiveScraper()?.name ?? "")
                      .font(.captionLarge)
                      .foregroundColor(.textSecondary)
                      .padding(.horizontal, .spacingS)
                      .padding(.vertical, .spacingXS)
                      .background(Color.primaryBlue.opacity(0.1))
                      .cornerRadius(.radiusS)
                      .padding(.horizontal, .spacingM)
                  }

                  WatchlistSection(
                    items: store.watchlist,
                    onItemTapped: { content in
                      store.send(.watchlistItemTapped(content))
                    },
                    onRemove: { content in
                      store.send(.removeFromWatchlist(content.id))
                    }
                  )
                }
              }

              /// Watch history section
              if !store.watchHistory.isEmpty {
                WatchHistorySection(
                  items: store.watchHistory,
                  onItemTapped: { content in
                    store.send(.historyItemTapped(content))
                  },
                  onClearHistory: {
                    store.send(.clearWatchHistory)
                  }
                )
              }

              /// Empty state
              if store.watchlist.isEmpty && store.watchHistory.isEmpty {
                EmptyMySpaceView()
                  .padding(.top, .spacingXXL)
              }
            }
            .padding(.vertical, .spacingM)
          }
        }
      }
      .navigationTitle("myspace.title")
      .navigationBarTitleDisplayMode(.large)
      .onAppear {
        store.send(.onAppear)
      }
      .sheet(
        item: $store.scope(state: \.settings, action: \.settings)
      ) { settingsStore in
        SettingsView(store: settingsStore)
      }
    }
  }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
  let profile: UserProfile?
  let onSettingsTapped: () -> Void

  var body: some View {
    HStack(spacing: .spacingM) {
      /// Avatar
      ZStack {
        Circle()
          .fill(Color.primaryBlue.opacity(0.2))
          .frame(width: 80, height: 80)

        if let avatarURL = profile?.avatarURL {
          AsyncImage(url: avatarURL) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            Image(systemName: "person.fill")
              .font(.system(size: 40))
              .foregroundColor(.primaryBlue)
          }
          .frame(width: 80, height: 80)
          .clipShape(Circle())
        } else {
          Image(systemName: "person.fill")
            .font(.system(size: 40))
            .foregroundColor(.primaryBlue)
        }
      }

      /// Profile info
      VStack(alignment: .leading, spacing: .spacingXS) {
        Text(profile?.name ?? "User")
          .font(.headlineLarge)
          .foregroundColor(.textPrimary)

        if let email = profile?.email {
          Text(email)
            .font(.bodySmall)
            .foregroundColor(.textSecondary)
        }
      }

      Spacer()

      /// Settings button
      Button(action: onSettingsTapped) {
        Image(systemName: "gearshape.fill")
          .font(.title2)
          .foregroundColor(.textSecondary)
      }
    }
    .padding(.spacingM)
    .background(Color.cardBackground)
    .cornerRadius(.radiusL)
  }
}

// MARK: - Statistics Cards View
struct StatisticsCardsView: View {
  let watchTime: TimeInterval
  let contentCount: Int
  let favoriteGenres: [String]

  var body: some View {
    VStack(spacing: .spacingS) {
      HStack(spacing: .spacingS) {
        /// Watch time card
        StatCard(
          icon: "clock.fill",
          value: formatWatchTime(watchTime),
          label: "myspace.stats.watch_time"
        )

        /// Content count card
        StatCard(
          icon: "film.fill",
          value: "\(contentCount)",
          label: "myspace.stats.content_watched"
        )
      }

      /// Favorite genres card
      if !favoriteGenres.isEmpty {
        HStack(spacing: .spacingXS) {
          Image(systemName: "star.fill")
            .font(.labelMedium)
            .foregroundColor(.warning)

          Text("myspace.stats.favorite_genres")
            .font(.labelMedium)
            .foregroundColor(.textSecondary)

          Spacer()

          Text(favoriteGenres.prefix(3).joined(separator: ", "))
            .font(.bodySmall)
            .foregroundColor(.textPrimary)
            .lineLimit(1)
        }
        .padding(.spacingM)
        .background(Color.cardBackground)
        .cornerRadius(.radiusM)
      }
    }
  }

  private func formatWatchTime(_ time: TimeInterval) -> String {
    let hours = Int(time) / 3600
    if hours > 0 {
      return "\(hours)h"
    } else {
      let minutes = Int(time) / 60
      return "\(minutes)m"
    }
  }
}

// MARK: - Stat Card
struct StatCard: View {
  let icon: String
  let value: String
  let label: String

  var body: some View {
    VStack(spacing: .spacingS) {
      Image(systemName: icon)
        .font(.title)
        .foregroundColor(.primaryBlue)

      Text(value)
        .font(.headlineLarge)
        .foregroundColor(.textPrimary)

      Text(LocalizedStringKey(label))
        .font(.captionLarge)
        .foregroundColor(.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.spacingM)
    .background(Color.cardBackground)
    .cornerRadius(.radiusL)
  }
}

// MARK: - Watchlist Section
struct WatchlistSection: View {
  let items: [Content]
  let onItemTapped: (Content) -> Void
  let onRemove: (Content) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS) {
      /// Section header
      HStack {
        Text("myspace.watchlist.title")
          .font(.headlineMedium)
          .foregroundColor(.textPrimary)

        Spacer()

        Text("\(items.count)")
          .font(.labelMedium)
          .foregroundColor(.textSecondary)
      }
      .padding(.horizontal, .spacingM)

      /// Horizontal scroll
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: .spacingS) {
          ForEach(items) { content in
            WatchlistItemCard(
              content: content,
              onTap: { onItemTapped(content) },
              onRemove: { onRemove(content) }
            )
          }
        }
        .padding(.horizontal, .spacingM)
      }
    }
  }
}

// MARK: - Watchlist Item Card
struct WatchlistItemCard: View {
  let content: Content
  let onTap: () -> Void
  let onRemove: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: .spacingXS) {
        /// Poster
        ZStack(alignment: .topTrailing) {
          if let posterURL = content.fullPosterURL {
            AsyncImage(url: posterURL) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              Color.surfaceBackground
            }
            .frame(width: 120, height: 180)
            .cornerRadius(.radiusM)
          } else {
            Color.surfaceBackground
              .frame(width: 120, height: 180)
              .cornerRadius(.radiusM)
          }

          /// Remove button
          Button(action: onRemove) {
            Image(systemName: "xmark.circle.fill")
              .font(.title3)
              .foregroundColor(.white)
              .background(Color.black.opacity(0.5))
              .clipShape(Circle())
          }
          .padding(.spacingXS)
        }

        /// Title
        Text(content.title)
          .font(.captionLarge)
          .foregroundColor(.textPrimary)
          .lineLimit(2)
          .frame(width: 120, alignment: .leading)
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Watch History Section
struct WatchHistorySection: View {
  let items: [Content]
  let onItemTapped: (Content) -> Void
  let onClearHistory: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS) {
      /// Section header
      HStack {
        Text("myspace.history.title")
          .font(.headlineMedium)
          .foregroundColor(.textPrimary)

        Spacer()

        Button("myspace.history.clear") {
          onClearHistory()
        }
        .font(.labelMedium)
        .foregroundColor(.primaryBlue)
      }
      .padding(.horizontal, .spacingM)

      /// List
      LazyVStack(spacing: .spacingS) {
        ForEach(items.prefix(10)) { content in
          Button(action: { onItemTapped(content) }) {
            HStack(spacing: .spacingS) {
              /// Thumbnail
              if let posterURL = content.fullPosterURL {
                AsyncImage(url: posterURL) { image in
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                } placeholder: {
                  Color.surfaceBackground
                }
                .frame(width: 60, height: 90)
                .cornerRadius(.radiusS)
              } else {
                Color.surfaceBackground
                  .frame(width: 60, height: 90)
                  .cornerRadius(.radiusS)
              }

              /// Info
              VStack(alignment: .leading, spacing: .spacingXS) {
                Text(content.title)
                  .font(.bodyMedium)
                  .foregroundColor(.textPrimary)
                  .lineLimit(2)

                if let year = content.releaseYear {
                  Text(year)
                    .font(.captionLarge)
                    .foregroundColor(.textSecondary)
                }
              }

              Spacer()

              Image(systemName: "chevron.right")
                .font(.labelMedium)
                .foregroundColor(.textTertiary)
            }
            .padding(.spacingS)
            .background(Color.cardBackground)
            .cornerRadius(.radiusM)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(.horizontal, .spacingM)
    }
  }
}

// MARK: - Empty MySpace View
struct EmptyMySpaceView: View {
  var body: some View {
    VStack(spacing: .spacingL) {
      Image(systemName: "person.crop.circle")
        .font(.system(size: 80))
        .foregroundColor(.textSecondary)

      Text("myspace.empty.title")
        .font(.headlineLarge)
        .foregroundColor(.textPrimary)

      Text("myspace.empty.message")
        .font(.bodyMedium)
        .foregroundColor(.textSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, .spacingXXL)
    }
  }
}
