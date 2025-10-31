// ContentPosterCard.swift
// Reusable content poster card component
// Disney+ Hotstar style with proper aspect ratios and hover effects

import SwiftUI

/// A card component for displaying content posters in a Disney+ Hotstar style
/// Supports both portrait (2:3) and landscape (16:9) aspect ratios
struct ContentPosterCard: View {
  /// The content to display
  let content: Content
  /// Callback when card is tapped
  let onTapped: () -> Void
  /// Card width (optional, defaults to 110 for portrait - Hotstar style)
  var width: CGFloat = 110
  /// Whether to use landscape aspect ratio (16:9) instead of portrait (2:3)
  var useLandscapeRatio: Bool = false
  /// Whether to show title below the card (Hotstar style)
  var showTitle: Bool = true

  /// Computed height based on aspect ratio
  private var height: CGFloat {
    useLandscapeRatio ? width * 9 / 16 : width * 3 / 2
  }

  var body: some View {
    Button(action: onTapped) {
      VStack(alignment: .leading, spacing: 8) {
        ZStack(alignment: .topLeading) {
          /// Poster image with rounded corners (Hotstar style) - Using cached image loader
          CachedAsyncImage(
            url: useLandscapeRatio ? content.fullBackdropURL : content.fullPosterURL
          ) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: width, height: height)
              .clipped()
              .cornerRadius(.radiusM)
          } placeholder: {
            /// Loading placeholder with shimmer
            Rectangle()
              .fill(Color.cardBackground)
              .frame(width: width, height: height)
              .cornerRadius(.radiusM)
              .overlay(
                ProgressView()
                  .tint(.textTertiary)
              )
          }

          /// Content type badge (top-left corner - Hotstar style)
          HStack(spacing: .spacingXS / 2) {
            Image(systemName: content.type.iconName)
              .font(.captionSmall)
            Text(content.type.displayName.uppercased())
              .font(.captionSmall)
              .fontWeight(.bold)
              .tracking(0.3)
          }
          .foregroundColor(.white)
          .padding(.horizontal, .spacingXS + 2)
          .padding(.vertical, .spacingXS / 2)
          .background(Color.overlay)
          .cornerRadius(.radiusS / 2)
          .padding(.spacingXS + 2)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

          /// Premium badge for special content (top-right corner - Hotstar style)
          if content.adult || content.rating == "Premium" {
            HStack(spacing: .spacingXS / 2) {
              Image(systemName: "crown.fill")
                .font(.captionSmall)
              Text("content.vip")
                .font(.captionSmall)
                .fontWeight(.bold)
                .tracking(0.5)
            }
            .foregroundColor(.black)
            .padding(.horizontal, .spacingXS + 2)
            .padding(.vertical, .spacingXS / 2)
            .background(
              LinearGradient(
                colors: [Color.warning, Color.orange],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .cornerRadius(.radiusS / 2)
            .padding(.spacingXS + 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
          }
        }
        .frame(width: width, height: height)

        /// Title below card (Hotstar style) - Fixed height for alignment
        if showTitle {
          Text(content.title)
            .font(.labelMedium)
            .foregroundColor(.textPrimary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(width: width, height: 36, alignment: .topLeading)
        }
      }
      .frame(alignment: .top)
    }
    .buttonStyle(ContentCardButtonStyle())
  }
}

/// Custom button style for content cards with scale animation
struct ContentCardButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(.quick, value: configuration.isPressed)
  }
}

/// Preview provider for ContentPosterCard
#Preview("Portrait Card") {
  ContentPosterCard(
    content: Content.preview,
    onTapped: {},
    width: 120
  )
  .padding()
  .background(Color.appBackground)
}

#Preview("Landscape Card") {
  ContentPosterCard(
    content: Content.preview,
    onTapped: {},
    width: 200,
    useLandscapeRatio: true
  )
  .padding()
  .background(Color.appBackground)
}
