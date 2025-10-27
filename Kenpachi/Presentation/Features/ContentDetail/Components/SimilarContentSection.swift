// SimilarContentSection.swift
// Component for displaying similar/recommended content
// Shows content recommendations in horizontal carousel

import SwiftUI

struct SimilarContentSection: View {
  /// Similar content items
  let content: [Content]
  /// Content tap callback
  let onContentTapped: (Content) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS) {
      /// Section title
      Text("content.more.title")
        .font(.headlineSmall)
        .foregroundColor(Color.textPrimary)

      /// Horizontal scrolling content list
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: .spacingS) {
          ForEach(content) { item in
            SimilarContentCard(
              content: item,
              onTapped: { onContentTapped(item) }
            )
          }
        }
      }
    }
  }
}

// MARK: - Similar Content Card
struct SimilarContentCard: View {
  /// Content to display
  let content: Content
  /// Tap callback
  let onTapped: () -> Void

  var body: some View {
    Button(action: onTapped) {
      VStack(alignment: .leading, spacing: .spacingS) {
        /// Poster image
        if let posterURL = content.fullPosterURL {
          AsyncImage(url: posterURL) { image in
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
          .frame(width: 120, height: 180)
          .cornerRadius(.radiusM)
        } else {
          /// Placeholder
          ZStack {
            Color.surfaceBackground
            Image(systemName: "film")
              .font(.title)
              .foregroundColor(.textTertiary)
          }
          .frame(width: 120, height: 180)
          .cornerRadius(.radiusM)
        }

        /// Title
        Text(content.title)
          .font(.captionLarge)
          .fontWeight(.medium)
          .foregroundColor(Color.textPrimary)
          .lineLimit(2)
          .frame(width: 120, alignment: .leading)

        /// Rating
        if let rating = content.formattedRating {
          HStack(spacing: .spacingXS) {
            Image(systemName: "star.fill")
              .font(.captionSmall)
              .foregroundColor(.warning)
            Text(rating)
              .font(.captionMedium)
              .foregroundColor(Color.textSecondary)
          }
        }
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}
