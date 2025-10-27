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
      HStack(spacing: 6) {
        ForEach(items.indices, id: \.self) { index in
          Circle()
            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
            .frame(width: index == currentIndex ? 8 : 6, height: index == currentIndex ? 8 : 6)
            .animation(.easeInOut(duration: 0.3), value: currentIndex)
        }
      }
      .padding(.bottom, 16)
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
              Color.gray.opacity(0.3)
                .frame(width: geometry.size.width, height: 500)
                .overlay(
                  Image(systemName: "photo")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.5))
                )
            case .empty:
              Color.gray.opacity(0.2)
                .frame(width: geometry.size.width, height: 500)
                .overlay(
                  ProgressView()
                    .tint(.white)
                )
            @unknown default:
              Color.gray.opacity(0.2)
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
              Color.black.opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
          .frame(height: 280)
        }
        .frame(height: 500)

        // Content overlay
        VStack(alignment: .leading, spacing: 8) {
          // Metadata row
          HStack(spacing: 8) {
            // Content type badge
            HStack(spacing: 4) {
              Image(systemName: item.type.iconName)
                .font(.system(size: 10, weight: .semibold))
              Text(item.type.displayName.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.2))
            .cornerRadius(4)
            
            // Year
            if let year = item.releaseYear {
              Text(year)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            }
            
            // Rating
            if let rating = item.formattedRating {
              HStack(spacing: 3) {
                Image(systemName: "star.fill")
                  .font(.system(size: 11))
                  .foregroundColor(.yellow)
                Text(rating)
                  .font(.system(size: 13, weight: .medium))
                  .foregroundColor(.white.opacity(0.8))
              }
            }
          }
          .padding(.bottom, 4)

          // Title
          Text(item.title)
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.white)
            .lineLimit(2)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

          // Overview
          if let overview = item.overview, !overview.isEmpty {
            Text(overview)
              .font(.system(size: 14))
              .foregroundColor(.white.opacity(0.85))
              .lineLimit(2)
              .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
              .padding(.bottom, 4)
          }

          // Action buttons
          HStack(spacing: 10) {
            // Play button (Hotstar style)
            Button(action: onPlayTapped) {
              HStack(spacing: 8) {
                Image(systemName: "play.fill")
                  .font(.system(size: 14, weight: .bold))
                Text("Watch Now")
                  .font(.system(size: 15, weight: .bold))
              }
              .foregroundColor(.black)
              .padding(.horizontal, 28)
              .padding(.vertical, 12)
              .background(Color.white)
              .cornerRadius(8)
            }

            // Watchlist button
            Button(action: onWatchlistTapped) {
              Image(systemName: isInWatchlist ? "checkmark" : "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
            }
            
            // Share button
            Button(action: {}) {
              Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
            }
          }
          .padding(.bottom, 50)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
      }
    }
    .buttonStyle(PlainButtonStyle())
    .frame(maxWidth: .infinity)
  }
}
