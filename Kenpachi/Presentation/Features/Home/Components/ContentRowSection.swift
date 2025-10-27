// ContentRowSection.swift
// A view for a horizontal row of content on the home screen.

import SwiftUI

struct ContentRowSection: View {
  let title: String
  let items: [Content]
  let onItemTapped: (Content) -> Void

  @State private var showAllContent = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      if !title.isEmpty {
        HStack {
          Text(title)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)

          Spacer()

          // "See All" button
          Button(action: {
            showAllContent = true
          }) {
            HStack(spacing: 4) {
              Text("See All")
                .font(.system(size: 14, weight: .medium))
              Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.7))
          }
        }
        .padding(.horizontal, 16)
      }

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          ForEach(items) { item in
            ContentPosterCard(
              content: item,
              onTapped: {
                onItemTapped(item)
              }
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(item.title)
            .accessibilityHint("Double tap to see details")
          }
        }
        .padding(.horizontal, 16)
      }
    }
    .padding(.vertical, 12)
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
    GridItem(.flexible(), spacing: 16),
    GridItem(.flexible(), spacing: 16),
    GridItem(.flexible(), spacing: 16),
  ]

  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground.ignoresSafeArea()

        ScrollView {
          LazyVGrid(columns: columns, spacing: 20) {
            ForEach(items) { item in
              ContentPosterCard(
                content: item,
                onTapped: {
                  onItemTapped(item)
                }
              )
            }
          }
          .padding(16)
        }
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: onDismiss) {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 24))
              .foregroundColor(.white.opacity(0.7))
          }
        }
      }
    }
  }
}
