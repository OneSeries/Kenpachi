// DownloadsView.swift
// Downloads management screen
// Clean, modern design with horizontal scrolling cards

import ComposableArchitecture
import SwiftUI

struct DownloadsView: View {
  let store: StoreOf<DownloadsFeature>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        ZStack {
          Color.appBackground.ignoresSafeArea()

          if viewStore.isLoading {
            LoadingView()
          } else if viewStore.downloads.isEmpty {
            EmptyDownloadsView()
          } else {
            ScrollView {
              VStack(alignment: .leading, spacing: .spacingM) {
                // Storage bar at top
                StorageBar(
                  used: viewStore.storageUsed,
                  available: viewStore.storageAvailable
                )
                .padding(.horizontal, .spacingM)
                .padding(.top, .spacingXS)

                // Compact downloads grid
                LazyVGrid(
                  columns: [
                    GridItem(.flexible(), spacing: .spacingS),
                    GridItem(.flexible(), spacing: .spacingS),
                    GridItem(.flexible(), spacing: .spacingS)
                  ],
                  spacing: .spacingM
                ) {
                  ForEach(viewStore.downloads) { download in
                    DownloadCard(
                      download: download,
                      onTap: { viewStore.send(.downloadTapped(download)) },
                      onDelete: { viewStore.send(.deleteDownloadTapped(download)) },
                      onPause: { viewStore.send(.pauseDownload(download.id)) },
                      onResume: { viewStore.send(.resumeDownload(download.id)) },
                      onCancel: { viewStore.send(.cancelDownload(download.id)) }
                    )
                  }
                }
                .padding(.horizontal, .spacingM)
              }
              .padding(.bottom, .spacingL)
            }
          }
        }
        .navigationTitle("downloads.title")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              viewStore.send(.storageInfoTapped)
            } label: {
              Image(systemName: "info.circle")
                .foregroundColor(.textSecondary)
            }
          }
        }
        .onAppear {
          viewStore.send(.onAppear)
        }
        .onDisappear {
          viewStore.send(.onDisappear)
        }
        .alert(
          "downloads.delete.title",
          isPresented: viewStore.binding(
            get: \.showDeleteConfirmation,
            send: { _ in .cancelDelete }
          )
        ) {
          Button("common.cancel", role: .cancel) {
            viewStore.send(.cancelDelete)
          }
          Button("downloads.delete.confirm", role: .destructive) {
            viewStore.send(.confirmDelete)
          }
        } message: {
          Text("downloads.delete.message")
        }
        .sheet(
          isPresented: viewStore.binding(
            get: \.showStorageInfo,
            send: { _ in .dismissStorageInfo }
          )
        ) {
          StorageInfoSheet(
            used: viewStore.storageUsed,
            available: viewStore.storageAvailable
          )
        }
        .fullScreenCover(
          isPresented: viewStore.binding(
            get: \.showPlayer,
            send: .dismissPlayer
          )
        ) {
          if let download = viewStore.downloadToPlay,
            let localFilePath = download.localFilePath
          {
            let localLink = ExtractedLink(
              url: localFilePath.absoluteString,
              quality: download.quality?.displayName,
              server: "Local File",
              type: .direct
            )

            PlayerView(
              store: Store(
                initialState: PlayerFeature.State(
                  content: download.content,
                  episode: download.episode,
                  streamingLinks: [localLink]
                )
              ) {
                PlayerFeature()
              }
            )
          }
        }
      }
    }
  }
}

// MARK: - Empty State
struct EmptyDownloadsView: View {
  var body: some View {
    VStack(spacing: .spacingL) {
      ZStack {
        Circle()
          .fill(Color.cardBackground)
          .frame(width: 120, height: 120)
        
        Image(systemName: "arrow.down.circle.fill")
          .font(.system(size: 60))
          .foregroundColor(.textTertiary)
      }

      VStack(spacing: .spacingS) {
        Text("downloads.empty.title")
          .font(.headlineLarge)
          .fontWeight(.semibold)
          .foregroundColor(.textPrimary)

        Text("downloads.empty.message")
          .font(.bodyMedium)
          .foregroundColor(.textSecondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, .spacingXXL)
      }
    }
  }
}

// MARK: - Storage Bar
struct StorageBar: View {
  let used: Int64
  let available: Int64

  private var usagePercentage: CGFloat {
    guard available > 0 else { return 0 }
    return CGFloat(used) / CGFloat(available)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS) {
      HStack {
        Text(formatBytes(used))
          .font(.captionLarge)
          .fontWeight(.medium)
          .foregroundColor(.textPrimary)
        
        Text("of \(formatBytes(available))")
          .font(.captionLarge)
          .foregroundColor(.textSecondary)
        
        Spacer()
        
        Text("\(Int(usagePercentage * 100))%")
          .font(.captionLarge)
          .fontWeight(.medium)
          .foregroundColor(.textPrimary)
      }
      
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          // Background
          RoundedRectangle(cornerRadius: 2)
            .fill(Color.cardBackground)
            .frame(height: 4)
          
          // Progress
          RoundedRectangle(cornerRadius: 2)
            .fill(
              LinearGradient(
                colors: [Color.primaryBlue, Color.primaryBlue.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(width: geometry.size.width * usagePercentage, height: 4)
        }
      }
      .frame(height: 4)
    }
  }

  private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
}

// MARK: - Download Card (Compact)
struct DownloadCard: View {
  let download: Download
  let onTap: () -> Void
  let onDelete: () -> Void
  let onPause: () -> Void
  let onResume: () -> Void
  let onCancel: () -> Void
  
  @State private var showMenu = false
  
  private var placeholderView: some View {
    ZStack {
      Color.cardBackground
        .aspectRatio(2/3, contentMode: .fill)
      
      VStack(spacing: 4) {
        Image(systemName: download.content.type == .movie ? "film.fill" : "tv.fill")
          .font(.headlineMedium)
          .foregroundColor(.textTertiary)
        
        Text(download.content.title)
          .font(.captionSmall)
          .foregroundColor(.textTertiary)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .padding(.horizontal, 4)
      }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Compact poster with overlay
      ZStack(alignment: .topTrailing) {
        Button(action: onTap) {
          ZStack(alignment: .center) {
            // Poster or placeholder
            if let posterURL = download.content.fullPosterURL {
              AsyncImage(url: posterURL) { phase in
                switch phase {
                case .success(let image):
                  image
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fill)
                case .failure:
                  // Failed to load - show placeholder
                  placeholderView
                case .empty:
                  // Loading - show placeholder
                  placeholderView
                @unknown default:
                  placeholderView
                }
              }
            } else {
              // No URL - show placeholder
              placeholderView
            }
            
            // State overlay
            if download.state == .downloading {
              ZStack {
                Color.black.opacity(0.6)
                
                VStack(spacing: 4) {
                  ProgressView(value: download.progress)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                  
                  Text("\(Int(download.progress * 100))%")
                    .font(.captionSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                }
              }
            } else if download.state == .completed {
              VStack {
                Spacer()
                HStack {
                  Spacer()
                  Image(systemName: "checkmark.circle.fill")
                    .font(.labelMedium)
                    .foregroundColor(.success)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding(4)
                }
              }
            } else if download.state == .paused {
              ZStack {
                Color.black.opacity(0.6)
                
                Image(systemName: "pause.circle.fill")
                  .font(.headlineMedium)
                  .foregroundColor(.white)
              }
            } else if download.state == .failed {
              ZStack {
                Color.black.opacity(0.6)
                
                Image(systemName: "exclamationmark.triangle.fill")
                  .font(.headlineMedium)
                  .foregroundColor(.error)
              }
            }
          }
          .clipShape(RoundedRectangle(cornerRadius: .radiusS))
        }
        .buttonStyle(PlainButtonStyle())
        
        // Compact menu button
        Button {
          showMenu = true
        } label: {
          Image(systemName: "ellipsis.circle.fill")
            .font(.labelMedium)
            .foregroundColor(.white)
            .padding(4)
            .background(Color.black.opacity(0.5))
            .clipShape(Circle())
        }
        .padding(4)
      }
      
      // Compact info section
      VStack(alignment: .leading, spacing: 2) {
        Text(download.content.title)
          .font(.captionLarge)
          .fontWeight(.semibold)
          .foregroundColor(.textPrimary)
          .lineLimit(1)
        
        if let episode = download.episode {
          Text(episode.formattedEpisodeId)
            .font(.captionSmall)
            .foregroundColor(.textSecondary)
            .lineLimit(1)
        }
        
        if let quality = download.quality {
          Text(quality.displayName)
            .font(.captionSmall)
            .foregroundColor(.textSecondary)
        }
      }
      .padding(.top, 6)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .confirmationDialog("", isPresented: $showMenu, titleVisibility: .hidden) {
      if download.state == .downloading {
        Button("downloads.action.pause") {
          onPause()
        }
        Button("downloads.action.cancel", role: .destructive) {
          onCancel()
        }
      } else if download.state == .paused {
        Button("downloads.action.resume") {
          onResume()
        }
        Button("downloads.action.cancel", role: .destructive) {
          onCancel()
        }
      } else if download.state == .completed {
        Button("downloads.action.play") {
          onTap()
        }
        Button("downloads.action.delete", role: .destructive) {
          onDelete()
        }
      } else if download.state == .failed {
        Button("downloads.action.retry") {
          onResume()
        }
        Button("downloads.action.delete", role: .destructive) {
          onDelete()
        }
      }
      
      Button("common.cancel", role: .cancel) {}
    }
  }
}

// MARK: - Storage Info Sheet
/// Storage information sheet showing used and available space
struct StorageInfoSheet: View {
  /// Used storage in bytes
  let used: Int64
  /// Available storage in bytes
  let available: Int64

  /// SwiftUI environment dismiss action
  @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction

  var body: some View {
    NavigationStack {
      VStack(spacing: .spacingL) {
        /// Storage visualization
        VStack(spacing: .spacingM) {
          ZStack {
            Circle()
              .stroke(Color.cardBackground, lineWidth: 20)
              .frame(width: 200, height: 200)

            Circle()
              .trim(from: 0, to: usagePercentage)
              .stroke(Color.primaryBlue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
              .frame(width: 200, height: 200)
              .rotationEffect(.degrees(-90))

            VStack(spacing: .spacingXS) {
              Text("\(Int(usagePercentage * 100))%")
                .font(.displayMedium)
                .foregroundColor(.textPrimary)
              Text("downloads.storage.used")
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
            }
          }

          VStack(spacing: .spacingS) {
            StorageRow(
              label: "downloads.storage.used",
              value: formatBytes(used),
              color: .primaryBlue
            )

            StorageRow(
              label: "downloads.storage.available",
              value: formatBytes(available - used),
              color: .success
            )

            Divider()

            StorageRow(
              label: "downloads.storage.total",
              value: formatBytes(available),
              color: .textPrimary
            )
          }
          .padding(.spacingM)
          .background(Color.cardBackground)
          .cornerRadius(.radiusL)
        }

        Spacer()
      }
      .padding(.spacingL)
      .background(Color.appBackground)
      .navigationTitle("downloads.storage.title")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("common.done") {
            dismiss()
          }
          .foregroundColor(.primaryBlue)
        }
      }
    }
  }

  private var usagePercentage: CGFloat {
    guard available > 0 else { return 0 }
    return CGFloat(used) / CGFloat(available)
  }

  private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
}

// MARK: - Storage Row
struct StorageRow: View {
  let label: String
  let value: String
  let color: Color

  var body: some View {
    HStack {
      Circle()
        .fill(color)
        .frame(width: 12, height: 12)

      Text(LocalizedStringKey(label))
        .font(.bodyMedium)
        .foregroundColor(.textPrimary)

      Spacer()

      Text(value)
        .font(.bodyMedium)
        .fontWeight(.semibold)
        .foregroundColor(.textPrimary)
    }
  }
}


