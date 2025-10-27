// SearchFilters.swift
// Component for search filters sheet
// Allows filtering by content type and genre

import SwiftUI

struct SearchFiltersView: View {
  /// Selected content type binding
  @Binding var selectedContentType: ContentType?
  /// Selected genre binding
  @Binding var selectedGenre: Genre?
  /// Apply filters callback
  let onApply: () -> Void
  /// Clear filters callback
  let onClear: () -> Void

  /// SwiftUI environment dismiss action
  @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction

  /// Available genres for filtering
  private let genres: [Genre] = [
    Genre.action, Genre.adventure, Genre.animation, Genre.comedy, Genre.crime,
    Genre.documentary, Genre.drama, Genre.family, Genre.fantasy, Genre.history,
    Genre.horror, Genre.music, Genre.mystery, Genre.romance, Genre.scienceFiction,
    Genre.thriller, Genre.war, Genre.western,
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: .spacingL) {
          /// Content Type Filter
          VStack(alignment: .leading, spacing: .spacingS) {
            Text("content.type.label")
              .font(.headlineMedium)
              .foregroundColor(.textPrimary)

            FlowLayout(spacing: .spacingS) {
              ForEach(ContentType.allCases) { type in
                FilterButton(
                  text: type.displayName,
                  icon: type.iconName,
                  isSelected: selectedContentType == type,
                  onTapped: {
                    if selectedContentType == type {
                      selectedContentType = nil
                    } else {
                      selectedContentType = type
                    }
                  }
                )
              }
            }
          }

          Divider()

          /// Genre Filter
          VStack(alignment: .leading, spacing: .spacingS) {
            Text("filters.genre.label")
              .font(.headlineMedium)
              .foregroundColor(.textPrimary)

            FlowLayout(spacing: .spacingS) {
              ForEach(genres) { genre in
                FilterButton(
                  text: genre.name,
                  isSelected: selectedGenre?.id == genre.id,
                  onTapped: {
                    if selectedGenre?.id == genre.id {
                      selectedGenre = nil
                    } else {
                      selectedGenre = genre
                    }
                  }
                )
              }
            }
          }
        }
        .padding(.spacingM)
      }
      .background(Color.appBackground)
      .navigationTitle("filters.title")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("filters.clear.button") {
            onClear()
          }
          .foregroundColor(.textSecondary)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("filters.apply.button") {
            onApply()
            dismiss()
          }
          .fontWeight(.semibold)
          .foregroundColor(.primaryBlue)
        }
      }
    }
  }
}

// MARK: - Filter Button
struct FilterButton: View {
  /// Button text
  let text: String
  /// Optional icon
  var icon: String? = nil
  /// Whether button is selected
  let isSelected: Bool
  /// Tap callback
  let onTapped: () -> Void

  var body: some View {
    Button(action: onTapped) {
      HStack(spacing: .spacingXS + 2) {
        if let icon = icon {
          Image(systemName: icon)
            .font(.labelSmall)
        }
        Text(text)
          .font(.labelMedium)
      }
      .padding(.horizontal, .spacingM)
      .padding(.vertical, .spacingS + 2)
      .background(
        isSelected
          ? Color.primaryBlue
          : Color.surfaceBackground
      )
      .foregroundColor(
        isSelected
          ? .white
          : .textPrimary
      )
      .cornerRadius(.radiusXL)
    }
    .buttonStyle(PlainButtonStyle())
  }
}
