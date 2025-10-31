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
              /// Profile header (Hotstar style - no card background)
              ProfileHeaderView(
                profile: store.userProfile,
                onSettingsTapped: { store.send(.settingsTapped) }
              )
              .padding(.horizontal, .spacingM)
              .padding(.top, .spacingS)

              /// Statistics cards (Hotstar style - compact)
              StatisticsCardsView(
                watchTime: store.totalWatchTime,
                contentCount: store.contentWatched,
                favoriteGenres: store.favoriteGenres
              )
              .padding(.horizontal, .spacingM)

              /// Watchlist section (Hotstar style)
              if !store.watchlist.isEmpty {
                VStack(alignment: .leading, spacing: .spacingS + 4) {
                  HStack {
                    Text("myspace.watchlist.title")
                      .font(.headlineSmall)
                      .foregroundColor(.textPrimary)

                    Spacer()
                    
                    Text("\(store.watchlist.count)")
                      .font(.labelMedium)
                      .foregroundColor(.textSecondary)
                      .padding(.horizontal, .spacingS + 2)
                      .padding(.vertical, .spacingXS)
                      .background(Color.cardBackground)
                      .cornerRadius(.radiusS)
                  }
                  .padding(.horizontal, .spacingM)

                  ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: .spacingS + 4) {
                      ForEach(store.watchlist) { content in
                        ContentPosterCard(
                          content: content,
                          onTapped: { store.send(.watchlistItemTapped(content)) },
                          width: 110,
                          showTitle: true
                        )
                      }
                    }
                    .padding(.horizontal, .spacingM)
                  }
                }
              }

              /// Watch history section (Hotstar style)
              if !store.watchHistory.isEmpty {
                VStack(alignment: .leading, spacing: .spacingS + 4) {
                  HStack {
                    Text("myspace.history.title")
                      .font(.headlineSmall)
                      .foregroundColor(.textPrimary)

                    Spacer()

                    Button("myspace.history.clear") {
                      store.send(.clearWatchHistory)
                    }
                    .font(.labelMedium)
                    .foregroundColor(.primaryBlue)
                  }
                  .padding(.horizontal, .spacingM)

                  ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: .spacingS + 4) {
                      ForEach(store.watchHistory.prefix(10)) { content in
                        ContentPosterCard(
                          content: content,
                          onTapped: { store.send(.historyItemTapped(content)) },
                          width: 110,
                          showTitle: true
                        )
                      }
                    }
                    .padding(.horizontal, .spacingM)
                  }
                }
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
      .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Profile Header View (Hotstar Style)
struct ProfileHeaderView: View {
  let profile: UserProfile?
  let onSettingsTapped: () -> Void

  var body: some View {
    VStack(spacing: .spacingM) {
      HStack {
        /// Avatar
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [Color.primaryBlue.opacity(0.3), Color.primaryBlue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 70, height: 70)

          if let avatarURL = profile?.avatarURL {
            AsyncImage(url: avatarURL) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              Image(systemName: "person.fill")
                .font(.system(size: 32))
                .foregroundColor(.primaryBlue)
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())
          } else {
            Image(systemName: "person.fill")
              .font(.system(size: 32))
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

        /// Settings button (Hotstar style)
        Button(action: onSettingsTapped) {
          Image(systemName: "gearshape.fill")
            .font(.headlineMedium)
            .foregroundColor(.textPrimary)
            .frame(width: 44, height: 44)
            .background(Color.cardBackground)
            .cornerRadius(.radiusM)
        }
      }
    }
  }
}

// MARK: - Statistics Cards View (Hotstar Style - Compact)
struct StatisticsCardsView: View {
  let watchTime: TimeInterval
  let contentCount: Int
  let favoriteGenres: [String]

  var body: some View {
    HStack(spacing: .spacingS) {
      /// Watch time card
      CompactStatCard(
        icon: "clock.fill",
        value: formatWatchTime(watchTime),
        label: "myspace.stats.watch_time"
      )

      /// Content count card
      CompactStatCard(
        icon: "film.fill",
        value: "\(contentCount)",
        label: "myspace.stats.content_watched"
      )
      
      /// Favorite genre card
      if !favoriteGenres.isEmpty {
        CompactStatCard(
          icon: "star.fill",
          value: favoriteGenres.first ?? "",
          label: "myspace.stats.top_genre"
        )
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

// MARK: - Compact Stat Card (Hotstar Style)
struct CompactStatCard: View {
  let icon: String
  let value: String
  let label: String

  var body: some View {
    VStack(spacing: .spacingXS) {
      HStack(spacing: .spacingXS) {
        Image(systemName: icon)
          .font(.labelMedium)
          .foregroundColor(.primaryBlue)
        
        Text(value)
          .font(.headlineMedium)
          .foregroundColor(.textPrimary)
          .lineLimit(1)
      }

      Text(LocalizedStringKey(label))
        .font(.captionMedium)
        .foregroundColor(.textSecondary)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, .spacingS + 4)
    .padding(.horizontal, .spacingS)
    .background(Color.cardBackground)
    .cornerRadius(.radiusM)
  }
}





// MARK: - Empty MySpace View
struct EmptyMySpaceView: View {
  var body: some View {
    VStack(spacing: .spacingL) {
      Image(systemName: "person.crop.circle")
        .font(.system(size: 80))
        .foregroundColor(.textTertiary)

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
