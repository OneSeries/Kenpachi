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
        VStack(alignment: .leading, spacing: .spacingM) {
            /// Section title
            Text("content.episodes.title")
                .font(.headlineSmall)
                .foregroundColor(Color.textPrimary)
            
            /// Season selector
            if seasons.count > 1 {
                SeasonSelector(
                    seasons: seasons,
                    selectedSeason: selectedSeason,
                    onSeasonSelected: onSeasonSelected
                )
            }
            
            /// Episode list
            if let season = selectedSeason, let episodes = season.episodes {
                VStack(spacing: .spacingS) {
                    ForEach(episodes) { episode in
                        EpisodeCard(
                            episode: episode,
                            isSelected: selectedEpisode?.id == episode.id,
                            onTapped: { onEpisodeSelected(episode) }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Season Selector
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
                            .font(.bodySmall)
                            .fontWeight(selectedSeason?.id == season.id ? .semibold : .regular)
                            .padding(.horizontal, .spacingM)
                            .padding(.vertical, .spacingS)
                            .background(
                                selectedSeason?.id == season.id
                                    ? Color.primaryBlue
                                    : Color.cardBackground
                            )
                            .foregroundColor(
                                selectedSeason?.id == season.id
                                    ? .white
                                    : Color.textPrimary
                            )
                            .cornerRadius(.radiusXL)
                    }
                }
            }
        }
    }
}

// MARK: - Episode Card
struct EpisodeCard: View {
    /// Episode to display
    let episode: Episode
    /// Whether episode is selected
    let isSelected: Bool
    /// Tap callback
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            HStack(spacing: .spacingS) {
                /// Episode thumbnail
                if let stillURL = episode.fullStillURL {
                    AsyncImage(url: stillURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            Color.surfaceBackground
                            ProgressView()
                                .tint(.primaryBlue)
                        }
                    }
                    .frame(width: 120, height: 68)
                    .cornerRadius(.radiusM)
                } else {
                    /// Placeholder
                    ZStack {
                        Color.surfaceBackground
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(Color.textTertiary)
                    }
                    .frame(width: 120, height: 68)
                    .cornerRadius(.radiusM)
                }
                
                /// Episode info
                VStack(alignment: .leading, spacing: .spacingXS) {
                    /// Episode number and title
                    Text("\(episode.formattedEpisodeId) - \(episode.name)")
                        .font(.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(2)
                    
                    /// Runtime and rating
                    HStack(spacing: .spacingS) {
                        if let runtime = episode.formattedRuntime {
                            Text(runtime)
                                .font(.captionLarge)
                                .foregroundColor(Color.textSecondary)
                        }
                        
                        if let rating = episode.formattedRating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.captionSmall)
                                    .foregroundColor(.warning)
                                Text(rating)
                                    .font(.captionLarge)
                            }
                            .foregroundColor(Color.textSecondary)
                        }
                    }
                    
                    /// Overview
                    if let overview = episode.overview {
                        Text(overview)
                            .font(.captionLarge)
                            .foregroundColor(Color.textTertiary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                /// Play icon
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? Color.primaryBlue : Color.textSecondary)
            }
            .padding(.spacingS)
            .background(
                isSelected
                    ? Color.primaryBlue.opacity(0.15)
                    : Color.cardBackground
            )
            .cornerRadius(.spacingS)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
