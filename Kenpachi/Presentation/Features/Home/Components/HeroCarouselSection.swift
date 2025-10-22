// HeroCarouselSection.swift
// Hero carousel component for featured content
// Auto-playing paginated carousel with smooth transitions

import SwiftUI

/// Hero carousel section displaying featured content
struct HeroCarouselSection: View {
    /// Array of content items to display
    let items: [Content]
    /// Current carousel index
    let currentIndex: Int
    /// Callback when index changes
    let onIndexChanged: (Int) -> Void
    /// Callback when item is tapped
    let onItemTapped: (Content) -> Void
    /// Callback when play is tapped
    let onPlayTapped: ((Content) -> Void)?
    /// Callback when watchlist is tapped
    let onWatchlistTapped: ((Content) -> Void)?
    
    init(
        items: [Content],
        currentIndex: Int,
        onIndexChanged: @escaping (Int) -> Void,
        onItemTapped: @escaping (Content) -> Void,
        onPlayTapped: ((Content) -> Void)? = nil,
        onWatchlistTapped: ((Content) -> Void)? = nil
    ) {
        self.items = items
        self.currentIndex = currentIndex
        self.onIndexChanged = onIndexChanged
        self.onItemTapped = onItemTapped
        self.onPlayTapped = onPlayTapped
        self.onWatchlistTapped = onWatchlistTapped
    }
    
    var body: some View {
        TabView(selection: Binding(
            get: { currentIndex },
            set: { onIndexChanged($0) }
        )) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, content in
                HeroCard(
                    content: content,
                    onPlayTapped: { onPlayTapped?(content) },
                    onWatchlistTapped: { onWatchlistTapped?(content) }
                )
                .tag(index)
                .onTapGesture {
                    onItemTapped(content)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: AppConstants.UI.heroCarouselHeight)
    }
}

/// Individual hero card with backdrop and gradient overlay - Disney Plus style
private struct HeroCard: View {
    /// Content to display
    let content: Content
    /// Play button action
    let onPlayTapped: () -> Void
    /// Watchlist button action
    let onWatchlistTapped: () -> Void
    
    @State private var isLoadingPlay = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Backdrop image with proper aspect ratio
                if let backdropURL = content.fullBackdropURL {
                    AsyncImage(url: backdropURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        case .failure, .empty:
                            placeholderView
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        @unknown default:
                            placeholderView
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                } else {
                    placeholderView
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                // Multi-layer gradient overlay (Disney Plus style)
                VStack(spacing: 0) {
                    // Top fade
                    LinearGradient(
                        colors: [Color.black.opacity(0.4), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    
                    Spacer()
                    
                    // Bottom fade with stronger gradient
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.6), Color.black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                }
                
                // Content info overlay
                VStack(alignment: .leading, spacing: 12) {
                    // Logo or title
                    Text(content.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    
                    // Metadata row
                    HStack(spacing: 12) {
                        if let rating = content.formattedRating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(rating)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        if let year = content.releaseYear {
                            Text(year)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Text(content.type.displayName.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    // Overview
                    if let overview = content.overview {
                        Text(overview)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(3)
                            .lineSpacing(4)
                    }
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        // Play button
                        Button {
                            isLoadingPlay = true
                            onPlayTapped()
                        } label: {
                            HStack(spacing: 8) {
                                if isLoadingPlay {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "play.fill")
                                        .font(.body.weight(.semibold))
                                }
                                Text("Play")
                                    .font(.headline)
                            }
                            .foregroundColor(.black)
                            .frame(minWidth: 120)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                        }
                        .disabled(isLoadingPlay)
                        
                        // Watchlist button
                        Button {
                            onWatchlistTapped()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.body.weight(.semibold))
                                Text("Watchlist")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    /// Placeholder view when image is unavailable
    private var placeholderView: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}
