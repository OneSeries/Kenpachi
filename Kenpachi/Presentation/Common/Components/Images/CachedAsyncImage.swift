// CachedAsyncImage.swift
// Custom async image view with persistent caching
// Replaces SwiftUI's AsyncImage with better caching support

import SwiftUI

/// A view that asynchronously loads and displays an image with caching
/// Provides better caching than SwiftUI's AsyncImage, especially when switching sources
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    /// Image URL to load
    let url: URL?
    
    /// Content builder for successful image load
    let content: (Image) -> Content
    
    /// Placeholder builder for loading/error states
    let placeholder: () -> Placeholder
    
    /// Image cache instance
    private let imageCache = ImageCache.shared
    
    /// Current image state
    @State private var loadedImage: UIImage?
    
    /// Loading state
    @State private var isLoading = false
    
    /// Error state
    @State private var hasError = false
    
    /// Initializer with content and placeholder builders
    /// - Parameters:
    ///   - url: Image URL to load
    ///   - content: Builder for displaying the loaded image
    ///   - placeholder: Builder for loading/error placeholder
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let loadedImage = loadedImage {
                // Display loaded image
                content(Image(uiImage: loadedImage))
            } else {
                // Display placeholder
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    /// Load image from URL with caching
    private func loadImage() async {
        // Reset state
        loadedImage = nil
        hasError = false
        
        // Check if URL is valid
        guard let url = url else {
            hasError = true
            return
        }
        
        // Set loading state
        isLoading = true
        
        // Load image from cache or download
        if let image = await imageCache.loadImage(from: url) {
            loadedImage = image
            hasError = false
        } else {
            hasError = true
        }
        
        isLoading = false
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage where Content == Image, Placeholder == Color {
    /// Convenience initializer with default placeholder
    /// - Parameter url: Image URL to load
    init(url: URL?) {
        self.init(
            url: url,
            content: { image in
                image
                    .resizable()
            },
            placeholder: {
                Color.cardBackground
            }
        )
    }
}

extension CachedAsyncImage where Placeholder == AnyView {
    /// Convenience initializer with phase-based content
    /// - Parameters:
    ///   - url: Image URL to load
    ///   - content: Builder that receives AsyncImagePhase
    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = { image in
            content(.success(image))
        }
        self.placeholder = {
            AnyView(content(.empty))
        }
    }
}

// MARK: - Preview

#Preview("Cached Image") {
    VStack(spacing: 20) {
        // Example with custom content and placeholder
        CachedAsyncImage(
            url: URL(string: "https://image.tmdb.org/t/p/w500/example.jpg")
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 300)
                .clipped()
                .cornerRadius(12)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 200, height: 300)
                .cornerRadius(12)
                .overlay(
                    ProgressView()
                )
        }
        
        // Example with default placeholder
        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500/example.jpg"))
            .frame(width: 200, height: 300)
            .cornerRadius(12)
    }
    .padding()
    .background(Color.appBackground)
}
