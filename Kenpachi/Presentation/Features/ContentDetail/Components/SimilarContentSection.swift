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
    VStack(alignment: .leading, spacing: .spacingS + 4) {
      /// Section title (Hotstar style)
      Text("content.more_like_this")
        .font(.headlineSmall)
        .foregroundColor(.textPrimary)
        .padding(.horizontal, .spacingL - 4)

      /// Horizontal scrolling content list
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: .spacingS + 4) {
          ForEach(content) { item in
            ContentPosterCard(
              content: item,
              onTapped: { onContentTapped(item) },
              width: 110,
              showTitle: false
            )
          }
        }
        .padding(.horizontal, .spacingL - 4)
      }
    }
  }
}
