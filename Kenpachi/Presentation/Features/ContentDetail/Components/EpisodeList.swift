// EpisodeList.swift
// Component for displaying TV show episodes with season selector
// Provides episode selection and playback functionality

import SwiftUI

struct EpisodeListSection: View {
  /// Available seasons
  let seasons: [Season]
  /// Currently selected season
  let selectedSeason: Season?
  /// Currently selected episode
  let selectedEpisode: Episode?
  /// Season selection callback
  let onSeasonSelected: (Season) -> Void
  /// Episode selection callback
  let onEpisodeSelected: (Episode) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS + 4) {
      /// Section title (Hotstar style)
      Text("content.episodes")
        .font(.headlineSmall)
        .foregroundColor(.textPrimary)
        .padding(.horizontal, .spacingL - 4)

      /// Season selector
      if seasons.count > 1 {
        SeasonSelector(
          seasons: seasons,
          selectedSeason: selectedSeason,
          onSeasonSelected: onSeasonSelected
        )
        .padding(.horizontal, .spacingL - 4)
      }

      /// Episode list
      if let season = selectedSeason, let episodes = season.episodes {
        VStack(spacing: .spacingS + 2) {
          ForEach(episodes) { episode in
            EpisodeCard(
              episode: episode,
              isSelected: selectedEpisode?.id == episode.id,
              onTapped: { onEpisodeSelected(episode) }
            )
          }
        }
        .padding(.horizontal, .spacingL - 4)
      }
    }
  }
}

// MARK: - Season Selector (Hotstar Style)
struct SeasonSelector: View {
  /// Available seasons
  let seasons: [Season]
  /// Currently selected season
  let selectedSeason: Season?
  /// Season selection callback
  let onSeasonSelected: (Season) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: .spacingS) {
        ForEach(seasons) { season in
          Button(action: { onSeasonSelected(season) }) {
            Text(season.formattedSeasonNumber)
              .font(.labelMedium)
              .padding(.horizontal, .spacingM)
              .padding(.vertical, .spacingS)
              .background(
                selectedSeason?.id == season.id
                  ? Color.primaryBlue
                  : Color.cardBackground
              )
              .foregroundColor(selectedSeason?.id == season.id ? .white : .textPrimary)
              .cornerRadius(.radiusL)
          }
        }
      }
    }
  }
}

// MARK: - Episode Card (Hotstar Style)
struct EpisodeCard: View {
  /// Episode to display
  let episode: Episode
  /// Whether episode is selected
  let isSelected: Bool
  /// Tap callback
  let onTapped: () -> Void

  var body: some View {
    Button(action: onTapped) {
      HStack(spacing: .spacingS + 4) {
        /// Episode thumbnail
        ZStack(alignment: .center) {
          if let stillURL = episode.fullStillURL {
            AsyncImage(url: stillURL) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              ZStack {
                Color.cardBackground
                ProgressView()
                  .tint(.textTertiary)
              }
            }
            .frame(width: 140, height: 80)
            .cornerRadius(.radiusM)
          } else {
            /// Placeholder
            ZStack {
              Color.cardBackground
              Image(systemName: "photo")
                .font(.headlineLarge)
                .foregroundColor(.textTertiary)
            }
            .frame(width: 140, height: 80)
            .cornerRadius(.radiusM)
          }

          /// Play overlay
          Image(systemName: "play.circle.fill")
            .font(.displaySmall)
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: .spacingXS)
        }

        /// Episode info
        VStack(alignment: .leading, spacing: .spacingXS + 2) {
          /// Episode number and title
          Text("\(episode.formattedEpisodeId) • \(episode.name)")
            .font(.bodyMedium)
            .foregroundColor(.textPrimary)
            .lineLimit(2)

          /// Runtime
          if let runtime = episode.formattedRuntime {
            Text(runtime)
              .font(.captionLarge)
              .foregroundColor(.textSecondary)
          }

          /// Overview
          if let overview = episode.overview, !overview.isEmpty {
            Text(overview)
              .font(.captionLarge)
              .foregroundColor(.textTertiary)
              .lineLimit(2)
          }
        }

        Spacer()
      }
      .padding(.spacingS + 4)
      .background(
        isSelected
          ? Color.primaryBlue.opacity(0.2)
          : Color.cardBackground
      )
      .cornerRadius(.radiusM)
    }
    .buttonStyle(PlainButtonStyle())
  }
}
