// HeroCarouselSection.swift
// A view for the hero carousel on the home screen.

import SwiftUI

struct HeroCarouselSection: View {
  let items: [Content]
  let currentIndex: Int
  let watchlistStatus: [String: Bool]
  let onIndexChanged: (Int) -> Void
  let onItemTapped: (Content) -> Void
  let onPlayTapped: (Content) -> Void
  let onWatchlistTapped: (Content) -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      TabView(selection: .init(get: { currentIndex }, set: { onIndexChanged($0) })) {
        ForEach(items.indices, id: \.self) { index in
          let item = items[index]
          HeroCarouselItem(
            item: item,
            isInWatchlist: watchlistStatus[item.id] ?? false,
            onPlayTapped: { onPlayTapped(item) },
            onWatchlistTapped: { onWatchlistTapped(item) },
            onItemTapped: { onItemTapped(item) }
          )
          .tag(index)
          .accessibilityElement(children: .combine)
          .accessibilityLabel(item.title)
          .accessibilityHint("Double tap to see details")
        }
      }
      .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
      .frame(height: 500)

      // Custom page indicator dots (Hotstar style)
      HStack(spacing: .spacingXS + 2) {
        ForEach(items.indices, id: \.self) { index in
          Circle()
            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
            .frame(width: index == currentIndex ? 8 : 6, height: index == currentIndex ? 8 : 6)
            .animation(.standard, value: currentIndex)
        }
      }
      .padding(.bottom, .spacingM)
    }
    .frame(height: 500)
  }
}

struct HeroCarouselItem: View {
  let item: Content
  let isInWatchlist: Bool
  let onPlayTapped: () -> Void
  let onWatchlistTapped: () -> Void
  let onItemTapped: () -> Void

  var body: some View {
    Button(action: onItemTapped) {
      ZStack(alignment: .bottomLeading) {
        // Background image
        GeometryReader { geometry in
          AsyncImage(url: item.fullBackdropURL) { phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: 500)
                .clipped()
            case .failure:
              Color.surfaceBackground
                .frame(width: geometry.size.width, height: 500)
                .overlay(
                  Image(systemName: "photo")
                    .font(.displaySmall)
                    .foregroundColor(.textTertiary)
                )
            case .empty:
              Color.cardBackground
                .frame(width: geometry.size.width, height: 500)
                .overlay(
                  ProgressView()
                    .tint(.primaryBlue)
                )
            @unknown default:
              Color.cardBackground
                .frame(width: geometry.size.width, height: 500)
            }
          }
        }
        .frame(height: 500)

        // Multi-layer gradient overlay (Hotstar style)
        VStack(spacing: 0) {
          // Top fade
          LinearGradient(
            colors: [Color.black.opacity(0.6), Color.clear],
            startPoint: .top,
            endPoint: .bottom
          )
          .frame(height: 120)

          Spacer()

          // Bottom strong gradient
          LinearGradient(
            colors: [
              Color.clear,
              Color.black.opacity(0.4),
              Color.black.opacity(0.8),
              Color.black.opacity(0.95),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
          .frame(height: 280)
        }
        .frame(height: 500)

        // Content overlay
        VStack(alignment: .leading, spacing: .spacingS) {
          // Metadata row
          HStack(spacing: .spacingS) {
            // Content type badge
            HStack(spacing: .spacingXS) {
              Image(systemName: item.type.iconName)
                .font(.captionLarge)
                .fontWeight(.semibold)
              Text(item.type.displayName.uppercased())
                .font(.captionLarge)
                .fontWeight(.bold)
                .tracking(0.5)
            }
            .foregroundColor(.white)
            .padding(.horizontal, .spacingS + 2)
            .padding(.vertical, .spacingXS + 1)
            .background(Color.white.opacity(0.2))
            .cornerRadius(.radiusS)

            // Year
            if let year = item.releaseYear {
              Text(year)
                .font(.labelMedium)
                .foregroundColor(.white.opacity(0.8))
            }

            // Rating
            if let rating = item.formattedRating {
              HStack(spacing: .spacingXS / 2) {
                Image(systemName: "star.fill")
                  .font(.captionLarge)
                  .foregroundColor(.warning)
                Text(rating)
                  .font(.labelMedium)
                  .foregroundColor(.white.opacity(0.8))
              }
            }
          }
          .padding(.bottom, .spacingXS)

          // Title
          Text(item.title)
            .font(.displaySmall)
            .foregroundColor(.white)
            .lineLimit(2)
            .shadow(color: .black.opacity(0.3), radius: .spacingXS, x: 0, y: 2)

          // Overview
          if let overview = item.overview, !overview.isEmpty {
            Text(overview)
              .font(.bodyMedium)
              .foregroundColor(.white.opacity(0.85))
              .lineLimit(2)
              .shadow(color: .black.opacity(0.3), radius: .spacingXS / 2, x: 0, y: 1)
              .padding(.bottom, .spacingXS)
          }

          // Action buttons
          HStack(spacing: .spacingS + 2) {
            // Play button (Hotstar style)
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
              .padding(.horizontal, .spacingL + 4)
              .padding(.vertical, .spacingS + 4)
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
                .frame(width: 44, height: 44)
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
          .padding(.bottom, .spacingXXL + 2)
        }
        .padding(.horizontal, .spacingL - 4)
        .padding(.bottom, .spacingL - 4)
      }
    }
    .buttonStyle(PlainButtonStyle())
    .frame(maxWidth: .infinity)
  }
}
