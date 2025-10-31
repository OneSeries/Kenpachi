// SearchView.swift
// SwiftUI view for search screen
// Provides search functionality with filters and results display

import ComposableArchitecture
import SwiftUI

struct SearchView: View {
  /// Store for TCA feature
  let store: StoreOf<SearchFeature>
  /// Focus state for search field
  @FocusState private var isSearchFocused: Bool

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        VStack(spacing: 0) {
          /// Search bar (Hotstar style - simplified)
          SearchBar(
            text: viewStore.binding(
              get: \.searchQuery,
              send: { .searchQueryChanged($0) }
            ),
            isFocused: $isSearchFocused
          )
          .padding(.horizontal, 16)
          .padding(.vertical, 12)

          /// Content area
          if viewStore.searchQuery.isEmpty {
            /// Empty state - show recent searches and popular content
            EmptySearchState(
              recentSearches: viewStore.recentSearches,
              trendingSearches: viewStore.trendingSearches,
              popularContent: viewStore.popularContent,
              onRecentSearchTapped: { viewStore.send(.recentSearchTapped($0)) },
              onClearRecentSearches: { viewStore.send(.clearRecentSearches) },
              onContentTapped: { viewStore.send(.searchResultTapped($0)) }
            )
          } else if viewStore.isSearching {
            /// Loading state
            LoadingView()
          } else if let errorMessage = viewStore.errorMessage {
            /// Error state
            ErrorView(
              message: errorMessage,
              retryAction: { viewStore.send(.performSearch(viewStore.searchQuery, page: 1)) }
            )
          } else if viewStore.searchResults.isEmpty {
            /// No results state
            NoResultsView(query: viewStore.searchQuery)
          } else {
            /// Results state
            SearchResultsGrid(
              results: viewStore.searchResults,
              onContentTapped: { viewStore.send(.searchResultTapped($0)) },
              onReachedBottom: { viewStore.send(.reachedBottom) },
              isLoadingNextPage: viewStore.isLoadingNextPage
            )
          }
        }
        .navigationTitle("search.title")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
          viewStore.send(.onAppear)
        }
        .sheet(
          isPresented: viewStore.binding(
            get: \.showFilters,
            send: { _ in .hideFilters }
          )
        ) {
          /// Filters sheet
          SearchFiltersView(
            selectedContentType: viewStore.binding(
              get: \.selectedContentType,
              send: { .contentTypeFilterSelected($0) }
            ),
            selectedGenre: viewStore.binding(
              get: \.selectedGenre,
              send: { .genreFilterSelected($0) }
            ),
            onApply: { viewStore.send(.applyFilters) },
            onClear: { viewStore.send(.clearFilters) }
          )
        }
      }
    }
  }
}

// MARK: - Search Bar (Hotstar Style - Simplified)
struct SearchBar: View {
  /// Search text binding
  @Binding var text: String
  /// Focus state binding
  var isFocused: FocusState<Bool>.Binding

  var body: some View {
    /// Search field (Hotstar style - full width)
    HStack(spacing: .spacingS + 2) {
      Image(systemName: "magnifyingglass")
        .font(.labelMedium)
        .foregroundColor(.textSecondary)

      TextField("Search movies, shows, sports...", text: $text)
        .focused(isFocused)
        .textFieldStyle(PlainTextFieldStyle())
        .foregroundColor(.textPrimary)
        .font(.bodyMedium)

      if !text.isEmpty {
        Button(action: { text = "" }) {
          Image(systemName: "xmark.circle.fill")
            .font(.labelMedium)
            .foregroundColor(.textSecondary)
        }
      }
    }
    .padding(.horizontal, .spacingM - 2)
    .padding(.vertical, .spacingS + 4)
    .background(Color.cardBackground)
    .cornerRadius(.radiusM)
  }
}

// MARK: - Active Filters View (Hotstar Style)
struct ActiveFiltersView: View {
  /// Selected content type
  let contentType: ContentType?
  /// Selected genre
  let genre: Genre?
  /// Clear filters action
  let onClearFilters: () -> Void

  var body: some View {
    HStack(spacing: .spacingS) {
      if let contentType = contentType {
        FilterChip(
          text: contentType.displayName,
          onRemove: onClearFilters
        )
      }

      if let genre = genre {
        FilterChip(
          text: genre.name,
          onRemove: onClearFilters
        )
      }

      Spacer()

      Button(action: onClearFilters) {
        Text("common.clear")
          .font(.labelMedium)
          .foregroundColor(.primaryBlue)
      }
    }
  }
}

// MARK: - Filter Chip (Hotstar Style)
struct FilterChip: View {
  /// Chip text
  let text: String
  /// Remove action
  let onRemove: () -> Void

  var body: some View {
    HStack(spacing: .spacingXS + 2) {
      Text(text)
        .font(.labelMedium)

      Button(action: onRemove) {
        Image(systemName: "xmark")
          .font(.captionLarge)
          .fontWeight(.semibold)
      }
    }
    .foregroundColor(.white)
    .padding(.horizontal, .spacingS + 4)
    .padding(.vertical, .spacingXS + 2)
    .background(Color.primaryBlue)
    .cornerRadius(.radiusL)
  }
}

// MARK: - Empty Search State (Hotstar Style)
struct EmptySearchState: View {
  /// Recent searches
  let recentSearches: [String]
  /// Trending searches
  let trendingSearches: [String]
  /// Popular content
  let popularContent: [Content]
  /// Recent search tap callback
  let onRecentSearchTapped: (String) -> Void
  /// Clear recent searches callback
  let onClearRecentSearches: () -> Void
  /// Content tap callback
  let onContentTapped: (Content) -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: .spacingL) {
        /// Recent searches (as pills)
        if !recentSearches.isEmpty {
          VStack(alignment: .leading, spacing: .spacingS + 4) {
            HStack {
              Text("search.recent.title")
                .font(.headlineSmall)
                .foregroundColor(.textPrimary)

              Spacer()

              Button(action: onClearRecentSearches) {
                Text("search.clear_all")
                  .font(.labelMedium)
                  .foregroundColor(.primaryBlue)
              }
            }

            FlowLayout(spacing: .spacingS) {
              ForEach(recentSearches, id: \.self) { query in
                Button(action: { onRecentSearchTapped(query) }) {
                  Text(query)
                    .font(.labelMedium)
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, .spacingM - 2)
                    .padding(.vertical, .spacingS)
                    .background(Color.cardBackground)
                    .cornerRadius(.radiusL)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
          }
        }
        
        /// Popular content with titles
        if !popularContent.isEmpty {
          VStack(alignment: .leading, spacing: .spacingS + 4) {
            Text("search.popular.title")
              .font(.headlineSmall)
              .foregroundColor(.textPrimary)

            LazyVGrid(
              columns: [
                GridItem(.flexible(), spacing: .spacingS + 4),
                GridItem(.flexible(), spacing: .spacingS + 4),
                GridItem(.flexible(), spacing: .spacingS + 4),
              ],
              spacing: .spacingM
            ) {
              ForEach(popularContent) { content in
                ContentPosterCard(
                  content: content,
                  onTapped: { onContentTapped(content) },
                  width: 110,
                  showTitle: true
                )
              }
            }
          }
        } else if recentSearches.isEmpty {
          /// Empty state when no popular content and no recent searches
          VStack(spacing: .spacingM) {
            Spacer()

            Image(systemName: "magnifyingglass")
              .font(.system(size: 60))
              .foregroundColor(.textTertiary)

            Text("search.empty.message")
              .font(.headlineSmall)
              .foregroundColor(.textSecondary)
              .multilineTextAlignment(.center)

            Spacer()
          }
          .frame(maxWidth: .infinity)
          .padding(.top, 100)
        }
      }
      .padding(.spacingM)
    }
  }
}

// MARK: - Flow Layout (for trending searches)
struct FlowLayout: Layout {
  /// Spacing between items
  var spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = FlowResult(
      in: proposal.replacingUnspecifiedDimensions().width,
      subviews: subviews,
      spacing: spacing
    )
    return result.size
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    let result = FlowResult(
      in: bounds.width,
      subviews: subviews,
      spacing: spacing
    )
    for (index, subview) in subviews.enumerated() {
      subview.place(
        at: CGPoint(
          x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y),
        proposal: .unspecified)
    }
  }

  struct FlowResult {
    var size: CGSize = .zero
    var positions: [CGPoint] = []

    init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
      var x: CGFloat = 0
      var y: CGFloat = 0
      var lineHeight: CGFloat = 0

      for subview in subviews {
        let size = subview.sizeThatFits(.unspecified)

        if x + size.width > maxWidth && x > 0 {
          x = 0
          y += lineHeight + spacing
          lineHeight = 0
        }

        positions.append(CGPoint(x: x, y: y))
        lineHeight = max(lineHeight, size.height)
        x += size.width + spacing
      }

      self.size = CGSize(width: maxWidth, height: y + lineHeight)
    }
  }
}
