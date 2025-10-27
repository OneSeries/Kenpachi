// SearchResultsGrid.swift
// Component for displaying search results in a grid layout
// Shows content items with poster images and metadata

import SwiftUI

struct SearchResultsGrid: View {
  /// Search results to display
  let results: [Content]
  /// Content tap callback
  let onContentTapped: (Content) -> Void
  /// Reached bottom callback
  let onReachedBottom: () -> Void
  /// Whether loading next page
  let isLoadingNextPage: Bool

  /// Grid columns configuration
  private let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
  ]

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: .spacingM) {
        ForEach(Array(results.enumerated()), id: \.element.id) { index, content in
          ContentPosterCard(
            content: content,
            onTapped: { onContentTapped(content) }
          )
          .onAppear {
            /// Trigger pagination when reaching last 6 items
            if index == results.count - 6 {
              onReachedBottom()
            }
          }
        }

        /// Loading indicator for next page
        if isLoadingNextPage {
          HStack {
            Spacer()
            ProgressView()
              .tint(.primaryBlue)
              .padding(.spacingM)
            Spacer()
          }
          .gridCellColumns(3)
        }
      }
      .padding(.spacingM)
    }
  }
}

// MARK: - Content Poster Card
struct ContentPosterCard: View {
  /// Content to display
  let content: Content
  /// Tap callback
  let onTapped: () -> Void

  var body: some View {
    Button(action: onTapped) {
      VStack(alignment: .leading, spacing: 0) {
        /// Poster image with overlay gradient
        ZStack(alignment: .topLeading) {
          if let posterURL = content.fullPosterURL {
            AsyncImage(url: posterURL) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              ZStack {
                Color.gray.opacity(0.2)
                ProgressView()
                  .tint(.white)
              }
            }
            .frame(width: 140, height: 200)
            .clipped()
            .cornerRadius(8)
            .overlay(
              // Subtle gradient overlay for better text visibility
              LinearGradient(
                colors: [Color.black.opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .center
              )
              .cornerRadius(8)
            )
          } else {
            /// Placeholder
            ZStack {
              Color.gray.opacity(0.2)
              Image(systemName: "film")
                .font(.system(size: 30))
                .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 140, height: 200)
            .cornerRadius(8)
          }

          // Content type badge
          HStack(spacing: 4) {
            Image(systemName: content.type.iconName)
              .font(.system(size: 10, weight: .semibold))
            Text(content.type.displayName)
              .font(.system(size: 10, weight: .semibold))
          }
          .foregroundColor(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.black.opacity(0.7))
          .cornerRadius(4)
          .padding(8)
        }

        /// Title
        Text(content.title)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(.white)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
          .frame(width: 140, alignment: .leading)
          .padding(.top, 8)

        /// Metadata
        HStack(spacing: 6) {
          /// Year
          if let year = content.releaseYear {
            Text(year)
              .font(.system(size: 11))
              .foregroundColor(.white.opacity(0.6))
          }

          /// Rating
          if let rating = content.formattedRating {
            HStack(spacing: 2) {
              Image(systemName: "star.fill")
                .font(.captionSmall)
                .foregroundColor(.warning)
              Text(rating)
                .font(.captionSmall)
                .foregroundColor(.textSecondary)
            }
          }
        }
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}
