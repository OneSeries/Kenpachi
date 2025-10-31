// SearchFiltersView.swift
// Filter sheet for search functionality
// Allows users to filter content by type and genre

import SwiftUI

/// Search filters sheet view
struct SearchFiltersView: View {
  /// Selected content type binding
  @Binding var selectedContentType: ContentType?
  /// Selected genre binding
  @Binding var selectedGenre: Genre?
  /// Apply filters callback
  let onApply: () -> Void
  /// Clear filters callback
  let onClear: () -> Void
  
  /// Environment dismiss action
  @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
  
  var body: some View {
    NavigationStack {
      ZStack {
        Color.appBackground.ignoresSafeArea()
        
        ScrollView {
          VStack(alignment: .leading, spacing: .spacingL) {
            /// Content Type Filter
            VStack(alignment: .leading, spacing: .spacingS) {
              Text("filters.content_type.title")
                .font(.headlineSmall)
                .foregroundColor(.textPrimary)
              
              LazyVGrid(
                columns: [
                  GridItem(.flexible()),
                  GridItem(.flexible()),
                ],
                spacing: .spacingS
              ) {
                ForEach(ContentType.allCases, id: \.self) { type in
                  FilterButton(
                    title: type.displayName,
                    icon: type.iconName,
                    isSelected: selectedContentType == type
                  ) {
                    if selectedContentType == type {
                      selectedContentType = nil
                    } else {
                      selectedContentType = type
                    }
                  }
                }
              }
            }
            
            Divider()
              .background(Color.separator)
            
            /// Genre Filter
            VStack(alignment: .leading, spacing: .spacingS) {
              Text("filters.genre.title")
                .font(.headlineSmall)
                .foregroundColor(.textPrimary)
              
              /// Common genres
              let commonGenres = Genre.commonGenres
              
              LazyVGrid(
                columns: [
                  GridItem(.flexible()),
                  GridItem(.flexible()),
                ],
                spacing: .spacingS
              ) {
                ForEach(commonGenres, id: \.id) { genre in
                  FilterButton(
                    title: genre.name,
                    icon: nil,
                    isSelected: selectedGenre?.id == genre.id
                  ) {
                    if selectedGenre?.id == genre.id {
                      selectedGenre = nil
                    } else {
                      selectedGenre = genre
                    }
                  }
                }
              }
            }
          }
          .padding(.spacingM)
        }
      }
      .navigationTitle("filters.title")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("common.cancel") {
            dismiss()
          }
          .foregroundColor(.primaryBlue)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("filters.clear") {
            onClear()
          }
          .foregroundColor(.error)
          .disabled(selectedContentType == nil && selectedGenre == nil)
        }
      }
      .safeAreaInset(edge: .bottom) {
        /// Apply button
        Button(action: {
          onApply()
          dismiss()
        }) {
          Text("filters.apply")
            .font(.labelLarge)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacingM)
            .background(Color.primaryBlue)
            .cornerRadius(.radiusM)
        }
        .padding(.spacingM)
        .background(Color.appBackground)
      }
    }
  }
}

// MARK: - Filter Button
/// Reusable filter button component
struct FilterButton: View {
  /// Button title
  let title: String
  /// Optional icon name
  let icon: String?
  /// Whether button is selected
  let isSelected: Bool
  /// Tap action
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack(spacing: .spacingS) {
        if let icon = icon {
          Image(systemName: icon)
            .font(.labelMedium)
        }
        
        Text(title)
          .font(.bodyMedium)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, .spacingM)
      .padding(.horizontal, .spacingS)
      .background(
        isSelected
          ? Color.primaryBlue
          : Color.cardBackground
      )
      .foregroundColor(
        isSelected
          ? .white
          : .textPrimary
      )
      .cornerRadius(.radiusM)
      .overlay(
        RoundedRectangle(cornerRadius: .radiusM)
          .stroke(
            isSelected
              ? Color.primaryBlue
              : Color.border,
            lineWidth: isSelected ? 2 : 1
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Genre Extension
extension Genre {
  /// Common genres for filtering
  static let commonGenres: [Genre] = [
    Genre(id: 28, name: "Action"),
    Genre(id: 12, name: "Adventure"),
    Genre(id: 16, name: "Animation"),
    Genre(id: 35, name: "Comedy"),
    Genre(id: 80, name: "Crime"),
    Genre(id: 99, name: "Documentary"),
    Genre(id: 18, name: "Drama"),
    Genre(id: 10751, name: "Family"),
    Genre(id: 14, name: "Fantasy"),
    Genre(id: 36, name: "History"),
    Genre(id: 27, name: "Horror"),
    Genre(id: 10402, name: "Music"),
    Genre(id: 9648, name: "Mystery"),
    Genre(id: 10749, name: "Romance"),
    Genre(id: 878, name: "Sci-Fi"),
    Genre(id: 53, name: "Thriller"),
  ]
}
