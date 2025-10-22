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
        GridItem(.flexible())
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
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(.radiusM)
                } else {
                    /// Placeholder
                    ZStack {
                        Color.surfaceBackground
                        Image(systemName: "film")
                            .font(.system(size: 30))
                            .foregroundColor(.textTertiary)
                    }
                    .frame(height: 160)
                    .cornerRadius(.radiusM)
                }
                
                /// Title
                Text(content.title)
                    .font(.captionLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                /// Metadata
                HStack(spacing: .spacingXS) {
                    /// Content type icon
                    Image(systemName: content.type.iconName)
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)
                    
                    /// Year
                    if let year = content.releaseYear {
                        Text(year)
                            .font(.captionSmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
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
