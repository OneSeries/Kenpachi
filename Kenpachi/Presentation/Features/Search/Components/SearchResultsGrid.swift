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


