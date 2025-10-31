// ContentRowSection.swift
// A view for a horizontal row of content on the home screen.

import SwiftUI

struct ContentRowSection: View {
  let title: String
  let items: [Content]
  let onItemTapped: (Content) -> Void

  @State private var showAllContent = false

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingM) {
      if !title.isEmpty {
        HStack {
          Text(title)
            .font(.headlineSmall)
            .foregroundColor(.textPrimary)

          Spacer()

          // "See All" button (Hotstar style)
          Button(action: {
            showAllContent = true
          }) {
            HStack(spacing: .spacingXS) {
              Text("content.see_all")
                .font(.labelMedium)
              Image(systemName: "chevron.right")
                .font(.captionLarge)
                .fontWeight(.semibold)
            }
            .foregroundColor(.textSecondary)
          }
        }
        .padding(.horizontal, .spacingM)
        .padding(.bottom, .spacingS)
      }

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: .spacingS + 4) {
          ForEach(items) { item in
            ContentPosterCard(
              content: item,
              onTapped: {
                onItemTapped(item)
              },
              width: 110,
              showTitle: true
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(item.title)
            .accessibilityHint("Double tap to see details")
          }
        }
        .padding(.horizontal, .spacingM)
      }
    }
    .padding(.vertical, .spacingS + 4)
    .sheet(isPresented: $showAllContent) {
      SeeAllContentView(
        title: title,
        items: items,
        onItemTapped: { content in
          showAllContent = false
          onItemTapped(content)
        },
        onDismiss: {
          showAllContent = false
        }
      )
    }
  }
}

// MARK: - See All Content View
struct SeeAllContentView: View {
  let title: String
  let items: [Content]
  let onItemTapped: (Content) -> Void
  let onDismiss: () -> Void

  private let columns = [
    GridItem(.flexible(), spacing: .spacingM),
    GridItem(.flexible(), spacing: .spacingM),
    GridItem(.flexible(), spacing: .spacingM),
  ]

  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground.ignoresSafeArea()

        ScrollView {
          LazyVGrid(columns: columns, spacing: .spacingM) {
            ForEach(items) { item in
              ContentPosterCard(
                content: item,
                onTapped: {
                  onItemTapped(item)
                },
                width: 110,
                showTitle: true
              )
            }
          }
          .padding(.spacingM)
        }
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: onDismiss) {
            Image(systemName: "xmark.circle.fill")
              .font(.headlineLarge)
              .foregroundColor(.textSecondary)
          }
        }
      }
    }
  }
}
