// DownloadsView.swift
// Downloads management screen
// Displays downloaded content with progress tracking and storage info

import ComposableArchitecture
import SwiftUI

struct DownloadsView: View {
  /// TCA store for downloads feature
  let store: StoreOf<DownloadsFeature>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        ZStack {
          Color.appBackground.ignoresSafeArea()

          if viewStore.isLoading {
            /// Loading state
            LoadingView()
          } else if viewStore.downloads.isEmpty {
            /// Empty state
            EmptyDownloadsView()
          } else {
            /// Downloads list
            ScrollView {
              VStack(spacing: .spacingM) {
                /// Storage info card
                StorageInfoCard(
                  used: viewStore.storageUsed,
                  available: viewStore.storageAvailable,
                  onTap: { viewStore.send(.storageInfoTapped) }
                )
                .padding(.horizontal, .spacingM)

                /// Downloads list
                LazyVStack(spacing: .spacingS) {
                  ForEach(viewStore.downloads) { download in
                    DownloadItemCard(
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
              .padding(.vertical, .spacingM)
            }
          }
        }
        .navigationTitle("downloads.title")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              viewStore.send(.refresh)
            } label: {
              Image(systemName: "arrow.clockwise")
                .foregroundColor(.primaryBlue)
            }
          }
        }
        .onAppear {
          viewStore.send(.onAppear)
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
      }
    }
  }
}

// MARK: - Empty Downloads View
struct EmptyDownloadsView: View {
  var body: some View {
    VStack(spacing: .spacingL) {
      Image(systemName: "arrow.down.circle")
        .font(.system(size: 80))
        .foregroundColor(.textSecondary)

      Text("downloads.empty.title")
        .font(.headlineLarge)
        .foregroundColor(.textPrimary)

      Text("downloads.empty.message")
        .font(.bodyMedium)
        .foregroundColor(.textSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, .spacingXXL)
    }
  }
}

// MARK: - Storage Info Card
struct StorageInfoCard: View {
  let used: Int64
  let available: Int64
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: .spacingM) {
        Image(systemName: "internaldrive")
          .font(.title)
          .foregroundColor(.primaryBlue)

        VStack(alignment: .leading, spacing: .spacingXS) {
          Text("downloads.storage.title")
            .font(.labelLarge)
            .foregroundColor(.textPrimary)

          HStack(spacing: .spacingXS) {
            Text(formatBytes(used))
              .font(.bodySmall)
              .foregroundColor(.textSecondary)
            Text("downloads.storage.of")
              .font(.bodySmall)
              .foregroundColor(.textTertiary)
            Text(formatBytes(available))
              .font(.bodySmall)
              .foregroundColor(.textSecondary)
          }
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.labelMedium)
          .foregroundColor(.textTertiary)
      }
      .padding(.spacingM)
      .background(Color.cardBackground)
      .cornerRadius(.radiusL)
    }
    .buttonStyle(PlainButtonStyle())
  }

  private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
}

// MARK: - Download Item Card
struct DownloadItemCard: View {
  let download: Download
  let onTap: () -> Void
  let onDelete: () -> Void
  let onPause: () -> Void
  let onResume: () -> Void
  let onCancel: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: .spacingS) {
        /// Thumbnail
        if let posterURL = download.content.fullPosterURL {
          AsyncImage(url: posterURL) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            Color.surfaceBackground
          }
          .frame(width: 80, height: 120)
          .cornerRadius(.radiusM)
        } else {
          Color.surfaceBackground
            .frame(width: 80, height: 120)
            .cornerRadius(.radiusM)
        }

        /// Info
        VStack(alignment: .leading, spacing: .spacingXS) {
          Text(download.content.title)
            .font(.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(.textPrimary)
            .lineLimit(2)

          if let episode = download.episode {
            Text(episode.formattedEpisodeId)
              .font(.captionLarge)
              .foregroundColor(.textSecondary)
          }

          /// Download state
          switch download.state {
          case .downloading:
            VStack(alignment: .leading, spacing: .spacingXS) {
              ProgressView(value: download.progress)
                .tint(.primaryBlue)

              HStack {
                Text("\(Int(download.progress * 100))%")
                  .font(.captionMedium)
                  .foregroundColor(.textSecondary)

                Spacer()

                if let quality = download.quality {
                  Text(quality.displayName)
                    .font(.captionMedium)
                    .foregroundColor(.textTertiary)
                }
              }
            }

          case .completed:
            HStack(spacing: .spacingXS) {
              Image(systemName: "checkmark.circle.fill")
                .font(.captionMedium)
                .foregroundColor(.success)
              Text("downloads.state.completed")
                .font(.captionLarge)
                .foregroundColor(.success)

              Spacer()

              if let quality = download.quality {
                Text(quality.displayName)
                  .font(.captionMedium)
                  .foregroundColor(.textTertiary)
              }
            }

          case .paused:
            HStack(spacing: .spacingXS) {
              Image(systemName: "pause.circle.fill")
                .font(.captionMedium)
                .foregroundColor(.warning)
              Text("downloads.state.paused")
                .font(.captionLarge)
                .foregroundColor(.warning)
            }

          case .failed:
            HStack(spacing: .spacingXS) {
              Image(systemName: "exclamationmark.circle.fill")
                .font(.captionMedium)
                .foregroundColor(.error)
              Text("downloads.state.failed")
                .font(.captionLarge)
                .foregroundColor(.error)
            }

          case .pending:
            HStack(spacing: .spacingXS) {
              Image(systemName: "clock.fill")
                .font(.captionMedium)
                .foregroundColor(.textSecondary)
              Text("downloads.state.pending")
                .font(.captionLarge)
                .foregroundColor(.textSecondary)
            }
          }
        }

        Spacer()

        /// Actions
        Menu {
          if download.state == .downloading {
            Button {
              onPause()
            } label: {
              Label("downloads.action.pause", systemImage: "pause.fill")
            }

            Button(role: .destructive) {
              onCancel()
            } label: {
              Label("downloads.action.cancel", systemImage: "xmark")
            }
          } else if download.state == .paused {
            Button {
              onResume()
            } label: {
              Label("downloads.action.resume", systemImage: "play.fill")
            }

            Button(role: .destructive) {
              onCancel()
            } label: {
              Label("downloads.action.cancel", systemImage: "xmark")
            }
          } else if download.state == .completed {
            Button(role: .destructive) {
              onDelete()
            } label: {
              Label("downloads.action.delete", systemImage: "trash")
            }
          } else if download.state == .failed {
            Button {
              onResume()
            } label: {
              Label("downloads.action.retry", systemImage: "arrow.clockwise")
            }

            Button(role: .destructive) {
              onDelete()
            } label: {
              Label("downloads.action.delete", systemImage: "trash")
            }
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.title3)
            .foregroundColor(.textSecondary)
            .padding(.spacingS)
        }
      }
      .padding(.spacingS)
      .background(Color.cardBackground)
      .cornerRadius(.radiusL)
    }
    .buttonStyle(PlainButtonStyle())
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
              .stroke(Color.surfaceBackground, lineWidth: 20)
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
