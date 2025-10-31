// DownloadSelectionSheet.swift
// Sheet for selecting stream source for download
// Simplified flow: Show streams → Select stream → Download

import SwiftUI

/// Sheet view for selecting stream to download
struct DownloadSelectionSheet: View {
  /// Content to download
  let content: Content
  /// Available seasons (for TV shows)
  let seasons: [Season]?
  /// Pre-selected episode (if downloading from episode button)
  let selectedEpisode: Episode?
  /// Callback when download is requested
  let onDownload: (DownloadSelection) -> Void
  /// Callback when sheet should be dismissed
  let onDismiss: () -> Void

  /// Available streams
  @State private var availableStreams: [ExtractedLink] = []
  /// Selected stream
  @State private var selectedStream: ExtractedLink?
  /// Loading state
  @State private var isLoadingStreams = false
  /// Error message
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      ZStack {
        Color.appBackground.ignoresSafeArea()

        ScrollView {
          VStack(spacing: .spacingL) {
            // Content header
            ContentHeaderSection(content: content, episode: selectedEpisode)

            // Stream selection
            if isLoadingStreams {
              LoadingSection()
            } else if let errorMessage = errorMessage {
              ErrorSection(
                message: errorMessage,
                onRetry: {
                  loadStreams()
                })
            } else if !availableStreams.isEmpty {
              StreamSelectionSection(
                streams: availableStreams,
                selectedStream: $selectedStream
              )

              // Download button
              DownloadButton(
                isEnabled: selectedStream != nil,
                onTap: startDownload
              )
            }
          }
          .padding(.vertical, .spacingL)
        }
      }
      .navigationTitle("downloads.select.title")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("common.cancel") {
            onDismiss()
          }
          .foregroundColor(.primaryBlue)
        }
      }
      .onAppear {
        loadStreams()
      }
    }
  }

  /// Load available streams
  private func loadStreams() {
    isLoadingStreams = true
    errorMessage = nil

    Task {
      do {
        let contentRepository = ContentRepository()
        // Get episode ID for stream extraction
        let episodeId = selectedEpisode?.id
        let links = try await contentRepository.extractStreamingLinks(
          contentId: content.id,
          episodeId: episodeId
        )

        await MainActor.run {
          availableStreams = links
          selectedStream = links.first
          isLoadingStreams = false
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          isLoadingStreams = false
        }
      }
    }
  }

  /// Start download
  private func startDownload() {
    guard let stream = selectedStream else { return }

    // Use quality from stream if available, otherwise default to HD 720p
    let quality: DownloadQuality
    if let streamQuality = stream.quality {
      quality = parseQuality(from: streamQuality)
    } else {
      quality = .hd720
    }

    let selection = DownloadSelection(
      content: content,
      episode: selectedEpisode,
      quality: quality,
      stream: stream
    )
    onDownload(selection)
  }

  /// Parse quality from stream quality string
  private func parseQuality(from qualityString: String) -> DownloadQuality {
    if qualityString.contains("480") {
      return .sd480
    } else if qualityString.contains("720") {
      return .hd720
    } else if qualityString.contains("1080") {
      return .hd1080
    } else if qualityString.contains("4K") || qualityString.contains("2160") {
      return .uhd4k
    } else {
      return .hd720  // Default
    }
  }
}

// MARK: - Content Header Section
struct ContentHeaderSection: View {
  let content: Content
  let episode: Episode?

  var body: some View {
    HStack(spacing: .spacingM) {
      // Poster
      if let posterURL = content.fullPosterURL {
        AsyncImage(url: posterURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Color.cardBackground
        }
        .frame(width: 80, height: 120)
        .cornerRadius(.radiusM)
      }

      // Info
      VStack(alignment: .leading, spacing: .spacingXS) {
        Text(content.title)
          .font(.headlineSmall)
          .foregroundColor(.textPrimary)
          .lineLimit(2)

        // Show episode info if downloading an episode
        if let episode = episode {
          Text(episode.formattedEpisodeId)
            .font(.bodySmall)
            .foregroundColor(.textSecondary)

          Text(episode.name)
            .font(.captionLarge)
            .foregroundColor(.textTertiary)
            .lineLimit(1)
        } else {
          if let year = content.releaseYear {
            Text(year)
              .font(.bodySmall)
              .foregroundColor(.textSecondary)
          }

          if content.type == .movie {
            Text("Movie")
              .font(.bodySmall)
              .foregroundColor(.textSecondary)
          }
        }
      }

      Spacer()
    }
    .padding(.horizontal, .spacingL)
  }
}

// MARK: - Stream Selection Section
struct StreamSelectionSection: View {
  let streams: [ExtractedLink]
  @Binding var selectedStream: ExtractedLink?

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingM) {
      Text("downloads.select.stream")
        .font(.headlineMedium)
        .foregroundColor(.textPrimary)
        .padding(.horizontal, .spacingL)

      VStack(spacing: .spacingS) {
        ForEach(streams) { stream in
          StreamRow(
            stream: stream,
            isSelected: selectedStream?.id == stream.id,
            onSelect: { selectedStream = stream }
          )
        }
      }
      .padding(.horizontal, .spacingL)
    }
  }
}

// MARK: - Stream Row
struct StreamRow: View {
  let stream: ExtractedLink
  let isSelected: Bool
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      HStack {
        VStack(alignment: .leading, spacing: .spacingXS) {
          Text(stream.server)
            .font(.bodyMedium)
            .foregroundColor(.textPrimary)

          HStack(spacing: .spacingS) {
            if let quality = stream.quality {
              Text(quality)
                .font(.captionMedium)
                .foregroundColor(.textSecondary)
            }

            Text(stream.type.rawValue.uppercased())
              .font(.captionMedium)
              .foregroundColor(.textSecondary)
              .padding(.horizontal, .spacingXS)
              .padding(.vertical, .spacingXS / 2)
              .background(Color.primaryBlue.opacity(0.2))
              .cornerRadius(.radiusS / 2)
          }
        }

        Spacer()

        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.headlineSmall)
          .foregroundColor(isSelected ? .primaryBlue : .textTertiary)
      }
      .padding(.spacingM)
      .background(isSelected ? Color.primaryBlue.opacity(0.1) : Color.cardBackground)
      .cornerRadius(.radiusM)
      .overlay(
        RoundedRectangle(cornerRadius: .radiusM)
          .stroke(isSelected ? Color.primaryBlue : Color.clear, lineWidth: 2)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Download Button
struct DownloadButton: View {
  let isEnabled: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack {
        Image(systemName: "arrow.down.circle.fill")
        Text("downloads.start")
      }
      .font(.bodyMedium)
      .fontWeight(.semibold)
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 50)
      .background(isEnabled ? Color.primaryBlue : Color.textTertiary)
      .cornerRadius(.radiusM)
    }
    .disabled(!isEnabled)
    .padding(.horizontal, .spacingL)
    .padding(.top, .spacingM)
  }
}

// MARK: - Loading Section
struct LoadingSection: View {
  var body: some View {
    VStack(spacing: .spacingM) {
      ProgressView()
        .tint(.primaryBlue)
        .scaleEffect(1.5)

      Text("downloads.loading_streams")
        .font(.bodyMedium)
        .foregroundColor(.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.spacingXXL)
  }
}

// MARK: - Error Section
struct ErrorSection: View {
  let message: String
  let onRetry: () -> Void

  var body: some View {
    VStack(spacing: .spacingM) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundColor(.error)

      Text(message)
        .font(.bodyMedium)
        .foregroundColor(.textSecondary)
        .multilineTextAlignment(.center)

      Button(action: onRetry) {
        Text("common.retry")
          .font(.bodyMedium)
          .fontWeight(.semibold)
          .foregroundColor(.white)
          .padding(.horizontal, .spacingL)
          .padding(.vertical, .spacingS)
          .background(Color.primaryBlue)
          .cornerRadius(.radiusM)
      }
    }
    .padding(.horizontal, .spacingL)
    .padding(.vertical, .spacingXXL)
  }
}

// MARK: - Download Selection Model
/// Model representing a download selection
struct DownloadSelection: Equatable {
  let content: Content
  let episode: Episode?
  let quality: DownloadQuality
  let stream: ExtractedLink
}
