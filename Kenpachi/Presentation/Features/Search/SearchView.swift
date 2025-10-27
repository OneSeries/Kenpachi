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
          /// Search bar
          SearchBar(
            text: viewStore.binding(
              get: \.searchQuery,
              send: { .searchQueryChanged($0) }
            ),
            isFocused: $isSearchFocused,
            onFiltersTapped: { viewStore.send(.showFiltersTapped) }
          )
          .padding(.horizontal, .spacingM)
          .padding(.vertical, .spacingS)

          /// Active filters display
          if viewStore.selectedContentType != nil || viewStore.selectedGenre != nil {
            ActiveFiltersView(
              contentType: viewStore.selectedContentType,
              genre: viewStore.selectedGenre,
              onClearFilters: { viewStore.send(.clearFilters) }
            )
            .padding(.horizontal, .spacingM)
            .padding(.bottom, .spacingS)
          }

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

// MARK: - Search Bar
struct SearchBar: View {
  /// Search text binding
  @Binding var text: String
  /// Focus state binding
  var isFocused: FocusState<Bool>.Binding
  /// Filters button action
  let onFiltersTapped: () -> Void

  var body: some View {
    HStack(spacing: .spacingS) {
      /// Search field
      HStack(spacing: .spacingS) {
        Image(systemName: "magnifyingglass")
          .foregroundColor(Color.textSecondary)

        TextField("search.placeholder", text: $text)
          .focused(isFocused)
          .textFieldStyle(PlainTextFieldStyle())
          .foregroundColor(Color.textPrimary)

        if !text.isEmpty {
          Button(action: { text = "" }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(Color.textSecondary)
          }
        }
      }
      .padding(.horizontal, .spacingS)
      .padding(.vertical, .spacingS + 2)
      .background(Color.surfaceBackground)
      .cornerRadius(.radiusM + 2)

      /// Filters button
      Button(action: onFiltersTapped) {
        Image(systemName: "line.3.horizontal.decrease.circle")
          .font(.title2)
          .foregroundColor(Color.primaryBlue)
      }
    }
  }
}

// MARK: - Active Filters View
struct ActiveFiltersView: View {
  /// Selected content type
  let contentType: ContentType?
  /// Selected genre
  let genre: Genre?
  /// Clear filters action
  let onClearFilters: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Text("filters.label")
        .font(.captionLarge)
        .foregroundColor(Color.textSecondary)

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
        Text("search.clear.button")
          .font(.captionLarge)
          .foregroundColor(Color.primaryBlue)
      }
    }
  }
}

// MARK: - Filter Chip
struct FilterChip: View {
  /// Chip text
  let text: String
  /// Remove action
  let onRemove: () -> Void

  var body: some View {
    HStack(spacing: .spacingXS) {
      Text(text)
        .font(.captionLarge)

      Button(action: onRemove) {
        Image(systemName: "xmark")
          .font(.captionSmall)
      }
    }
    .padding(.horizontal, .spacingS + 2)
    .padding(.vertical, .spacingXS + 2)
    .background(Color.primaryBlue.opacity(0.15))
    .foregroundColor(Color.primaryBlue)
    .cornerRadius(.spacingM)
  }
}

// MARK: - Empty Search State
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
        /// Recent searches
        if !recentSearches.isEmpty {
          VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
              Text("search.recent.title")
                .font(.headlineSmall)
                .foregroundColor(Color.textPrimary)

              Spacer()

              Button(action: onClearRecentSearches) {
                Text("search.clear.button")
                  .font(.bodySmall)
                  .foregroundColor(Color.primaryBlue)
              }
            }

            ForEach(recentSearches, id: \.self) { query in
              Button(action: { onRecentSearchTapped(query) }) {
                HStack {
                  Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(Color.textSecondary)
                  Text(query)
                    .foregroundColor(Color.textPrimary)
                  Spacer()
                  Image(systemName: "arrow.up.left")
                    .foregroundColor(Color.textSecondary)
                }
                .padding(.vertical, .spacingS)
              }
              .buttonStyle(PlainButtonStyle())
            }
          }
        }

        /// Trending searches
        if !trendingSearches.isEmpty {
          VStack(alignment: .leading, spacing: .spacingS) {
            Text("search.trending.title")
              .font(.headlineSmall)
              .foregroundColor(Color.textPrimary)

            FlowLayout(spacing: .spacingS) {
              ForEach(trendingSearches, id: \.self) { query in
                Button(action: { onRecentSearchTapped(query) }) {
                  Text(query)
                    .font(.bodySmall)
                    .foregroundColor(Color.textPrimary)
                    .padding(.horizontal, .spacingM)
                    .padding(.vertical, .spacingS)
                    .background(Color.cardBackground)
                    .cornerRadius(.radiusXL)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
          }
        }

        /// Popular content
        if !popularContent.isEmpty {
          VStack(alignment: .leading, spacing: .spacingS) {
            Text("search.popular.title")
              .font(.headlineSmall)
              .foregroundColor(Color.textPrimary)

            LazyVGrid(
              columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
              ],
              spacing: .spacingM
            ) {
              ForEach(popularContent) { content in
                ContentPosterCard(
                  content: content,
                  onTapped: { onContentTapped(content) }
                )
              }
            }
          }
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
