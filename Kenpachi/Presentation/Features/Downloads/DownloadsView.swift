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
            /// Downloads list (Hotstar style)
            ScrollView {
              VStack(spacing: .spacingS) {
                /// Storage info card (compact)
                StorageInfoCard(
                  used: viewStore.storageUsed,
                  available: viewStore.storageAvailable,
                  onTap: { viewStore.send(.storageInfoTapped) }
                )
                .padding(.horizontal, .spacingM)
                .padding(.top, .spacingS)

                /// Section header
                HStack {
                  Text("downloads.list.title")
                    .font(.headlineSmall)
                    .foregroundColor(.textPrimary)

                  Spacer()

                  Text("\(viewStore.downloads.count)")
                    .font(.labelMedium)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, .spacingS + 2)
                    .padding(.vertical, .spacingXS)
                    .background(Color.cardBackground)
                    .cornerRadius(.radiusS)
                }
                .padding(.horizontal, .spacingM)
                .padding(.top, .spacingM)

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
              .padding(.bottom, .spacingM)
            }
          }
        }
        .navigationTitle("downloads.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              viewStore.send(.refresh)
            } label: {
              Image(systemName: "arrow.clockwise")
                .font(.labelLarge)
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
        .foregroundColor(.textTertiary)

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

// MARK: - Storage Info Card (Hotstar Style - Compact)
struct StorageInfoCard: View {
  let used: Int64
  let available: Int64
  let onTap: () -> Void

  private var usagePercentage: CGFloat {
    guard available > 0 else { return 0 }
    return CGFloat(used) / CGFloat(available)
  }

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: .spacingS + 4) {
        /// Circular progress indicator
        ZStack {
          Circle()
            .stroke(Color.cardBackground.opacity(0.3), lineWidth: 4)
            .frame(width: 50, height: 50)

          Circle()
            .trim(from: 0, to: usagePercentage)
            .stroke(Color.primaryBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 50, height: 50)
            .rotationEffect(.degrees(-90))

          Image(systemName: "internaldrive.fill")
            .font(.labelLarge)
            .foregroundColor(.primaryBlue)
        }

        VStack(alignment: .leading, spacing: .spacingXS / 2) {
          Text("downloads.storage.title")
            .font(.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(.textPrimary)

          HStack(spacing: .spacingXS) {
            Text(formatBytes(used))
              .font(.captionLarge)
              .foregroundColor(.textSecondary)
            Text("•")
              .font(.captionLarge)
              .foregroundColor(.textTertiary)
            Text("\(Int(usagePercentage * 100))% used")
              .font(.captionLarge)
              .foregroundColor(.textSecondary)
          }
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.captionMedium)
          .foregroundColor(.textTertiary)
      }
      .padding(.horizontal, .spacingM)
      .padding(.vertical, .spacingS + 4)
      .background(Color.cardBackground)
      .cornerRadius(.radiusM)
    }
    .buttonStyle(PlainButtonStyle())
  }

  private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
}

// MARK: - Download Item Card (Hotstar Style - Compact)
struct DownloadItemCard: View {
  let download: Download
  let onTap: () -> Void
  let onDelete: () -> Void
  let onPause: () -> Void
  let onResume: () -> Void
  let onCancel: () -> Void

  var body: some View {
    HStack(spacing: .spacingS + 4) {
      /// Thumbnail with overlay icon
      ZStack(alignment: .center) {
        if let posterURL = download.content.fullPosterURL {
          AsyncImage(url: posterURL) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            Color.cardBackground
          }
          .frame(width: 100, height: 140)
          .cornerRadius(.radiusM)
        } else {
          Color.cardBackground
            .frame(width: 100, height: 140)
            .cornerRadius(.radiusM)
        }

        /// State overlay icon
        if download.state == .completed {
          Circle()
            .fill(Color.success.opacity(0.9))
            .frame(width: 36, height: 36)
            .overlay(
              Image(systemName: "checkmark")
                .font(.labelMedium)
                .fontWeight(.bold)
                .foregroundColor(.white)
            )
        } else if download.state == .downloading {
          Circle()
            .fill(Color.black.opacity(0.7))
            .frame(width: 36, height: 36)
            .overlay(
              Text("\(Int(download.progress * 100))%")
                .font(.captionMedium)
                .fontWeight(.bold)
                .foregroundColor(.white)
            )
        }
      }
      .onTapGesture {
        onTap()
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

        Spacer()

        /// Download state (compact)
        HStack(spacing: .spacingXS) {
          switch download.state {
          case .downloading:
            ProgressView(value: download.progress)
              .tint(.primaryBlue)
              .frame(maxWidth: .infinity)

          case .completed:
            if let quality = download.quality {
              Text(quality.displayName)
                .font(.captionMedium)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, .spacingXS + 2)
                .padding(.vertical, .spacingXS / 2)
                .background(Color.success.opacity(0.15))
                .cornerRadius(.radiusS)
            }

          case .paused:
            Image(systemName: "pause.circle.fill")
              .font(.captionLarge)
              .foregroundColor(.warning)
            Text("downloads.state.paused")
              .font(.captionLarge)
              .foregroundColor(.warning)

          case .failed:
            Image(systemName: "exclamationmark.circle.fill")
              .font(.captionLarge)
              .foregroundColor(.error)
            Text("downloads.state.failed")
              .font(.captionLarge)
              .foregroundColor(.error)

          case .pending:
            Image(systemName: "clock.fill")
              .font(.captionLarge)
              .foregroundColor(.textSecondary)
            Text("downloads.state.pending")
              .font(.captionLarge)
              .foregroundColor(.textSecondary)
          }

          Spacer()
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      /// Actions menu (compact)
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
          Button {
            onTap()
          } label: {
            Label("downloads.action.play", systemImage: "play.fill")
          }

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
        Image(systemName: "ellipsis.circle")
          .font(.headlineSmall)
          .foregroundColor(.textSecondary)
      }
    }
    .padding(.spacingS + 4)
    .background(Color.cardBackground)
    .cornerRadius(.radiusM)
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
