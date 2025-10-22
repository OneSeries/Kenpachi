// ContentRowSection.swift
// Horizontal scrolling content row with title
// Displays content cards in a carousel format

import SwiftUI

/// Content row section with title and horizontal scrolling cards
struct ContentRowSection: View {
    /// Section title localization key
    let title: String
    /// Array of content items to display
    let items: [Content]
    /// Callback when item is tapped
    let onItemTapped: (Content) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            // Section title
            Text(LocalizedStringKey(title))
                .font(.headlineMedium)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, .spacingM)
            
            // Horizontal scrolling content
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: .spacingS) {
                    ForEach(items) { content in
                        ContentCard(content: content)
                            .onTapGesture {
                                onItemTapped(content)
                            }
                    }
                }
                .padding(.horizontal, .spacingM)
            }
        }
    }
}

/// Individual content card with poster and info
private struct ContentCard: View {
    /// Content to display
    let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Poster image
            ZStack(alignment: .topTrailing) {
                if let posterURL = content.fullPosterURL {
                    AsyncImage(url: posterURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(AppConstants.UI.posterAspectRatio, contentMode: .fill)
                        case .failure, .empty:
                            placeholderView
                        @unknown default:
                            placeholderView
                        }
                    }
                } else {
                    placeholderView
                }
                
                // Rating badge
                if let rating = content.formattedRating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.captionSmall)
                        Text(rating)
                            .font(.labelSmall)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, .spacingXS + 2)
                    .padding(.vertical, .spacingXS)
                    .background(Color.appBackground.opacity(0.7))
                    .cornerRadius(.radiusS)
                    .padding(.spacingXS + 2)
                }
            }
            .frame(width: AppConstants.UI.cardWidth, height: AppConstants.UI.cardHeight)
            .cornerRadius(.radiusM)
            .clipped()
            
            // Title
            Text(content.title)
                .font(.bodySmall)
                .foregroundColor(.textPrimary)
                .lineLimit(2)
                .frame(width: AppConstants.UI.cardWidth, alignment: .leading)
        }
    }
    
    /// Placeholder view when poster is unavailable
    private var placeholderView: some View {
        Rectangle()
            .fill(Color.surfaceBackground)
            .overlay(
                Image(systemName: "film")
                    .font(.largeTitle)
                    .foregroundColor(Color.textTertiary)
            )
    }
}
