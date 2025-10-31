// DownloadsFeature.swift
// TCA feature for downloads management
// Handles download operations, progress tracking, and storage management

import ComposableArchitecture
import Foundation

@Reducer
struct DownloadsFeature {

  @ObservableState
  struct State: Equatable {
    /// List of downloads
    var downloads: [Download] = []
    /// Loading state
    var isLoading = false
    /// Error message
    var errorMessage: String?
    /// Total storage used
    var storageUsed: Int64 = 0
    /// Available storage
    var storageAvailable: Int64 = 0
    /// Show delete confirmation
    var showDeleteConfirmation = false
    /// Download to delete
    var downloadToDelete: Download?
    /// Show storage info
    var showStorageInfo = false
    /// Show player
    var showPlayer = false
    /// Download to play
    var downloadToPlay: Download?
  }

  enum Action: Equatable {
    /// View appeared
    case onAppear
    /// View disappeared
    case onDisappear
    /// Refresh downloads
    case refresh
    /// Auto refresh tick
    case autoRefreshTick
    /// Downloads loaded
    case downloadsLoaded([Download])
    /// Storage info updated
    case storageInfoUpdated(used: Int64, available: Int64)
    /// Download tapped
    case downloadTapped(Download)
    /// Dismiss player
    case dismissPlayer
    /// Delete download tapped
    case deleteDownloadTapped(Download)
    /// Confirm delete
    case confirmDelete
    /// Cancel delete
    case cancelDelete
    /// Download deleted
    case downloadDeleted(String)
    /// Pause download
    case pauseDownload(String)
    /// Resume download
    case resumeDownload(String)
    /// Cancel download
    case cancelDownload(String)
    /// Storage info tapped
    case storageInfoTapped
    /// Dismiss storage info
    case dismissStorageInfo
    /// Error occurred
    case errorOccurred(String)
  }

  @Dependency(\.continuousClock) var clock

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        /// Load downloads and start auto-refresh
        return .merge(
          .send(.refresh),
          .run { send in
            for await _ in clock.timer(interval: .seconds(5)) {
              await send(.autoRefreshTick)
            }
          }
          .cancellable(id: "autoRefresh")
        )

      case .onDisappear:
        /// Stop auto-refresh when view disappears
        return .cancel(id: "autoRefresh")

      case .autoRefreshTick:
        /// Auto-refresh downloads without showing loading state
        return .run { send in
          await MainActor.run {
            let manager = DownloadQueueManager.shared
            let allDownloads =
              manager.activeDownloads + manager.queuedDownloads + manager.completedDownloads
              + manager.failedDownloads
            send(.downloadsLoaded(allDownloads))

            /// Calculate storage
            let usedStorage = allDownloads.reduce(Int64(0)) { $0 + ($1.fileSize ?? 0) }
            let availableStorage = getAvailableStorage()
            send(.storageInfoUpdated(used: usedStorage, available: availableStorage))
          }
        }

        /// Helper function to get available storage
        func getAvailableStorage() -> Int64 {
          do {
            let fileURL = URL(fileURLWithPath: NSHomeDirectory())
            let values = try fileURL.resourceValues(forKeys: [
              .volumeAvailableCapacityForImportantUsageKey
            ])
            return Int64(values.volumeAvailableCapacityForImportantUsage ?? 0)
          } catch {
            return 0
          }
        }

      case .refresh:
        /// Refresh downloads list
        state.isLoading = true
        state.errorMessage = nil

        return .run { send in
          /// Fetch downloads from DownloadQueueManager
          await MainActor.run {
            let manager = DownloadQueueManager.shared
            let allDownloads =
              manager.activeDownloads + manager.queuedDownloads + manager.completedDownloads
              + manager.failedDownloads
            send(.downloadsLoaded(allDownloads))

            /// Calculate storage
            let usedStorage = allDownloads.reduce(Int64(0)) { $0 + ($1.fileSize ?? 0) }
            let availableStorage = getAvailableStorage()
            send(.storageInfoUpdated(used: usedStorage, available: availableStorage))
          }
        }

        /// Helper function to get available storage
        func getAvailableStorage() -> Int64 {
          do {
            let fileURL = URL(fileURLWithPath: NSHomeDirectory())
            let values = try fileURL.resourceValues(forKeys: [
              .volumeAvailableCapacityForImportantUsageKey
            ])
            return Int64(values.volumeAvailableCapacityForImportantUsage ?? 0)
          } catch {
            return 0
          }
        }

      case .downloadsLoaded(let downloads):
        /// Update downloads list
        state.isLoading = false
        state.downloads = downloads
        return .none

      case .storageInfoUpdated(let used, let available):
        /// Update storage info
        state.storageUsed = used
        state.storageAvailable = available
        return .none

      case .downloadTapped(let download):
        /// Handle download tap (play downloaded content)
        // Only play if download is completed
        guard download.state == .completed else { return .none }
        
        state.downloadToPlay = download
        state.showPlayer = true
        return .none
      
      case .dismissPlayer:
        /// Dismiss player
        state.showPlayer = false
        state.downloadToPlay = nil
        return .none

      case .deleteDownloadTapped(let download):
        /// Show delete confirmation
        state.downloadToDelete = download
        state.showDeleteConfirmation = true
        return .none

      case .confirmDelete:
        /// Delete download
        guard let download = state.downloadToDelete else { return .none }
        state.showDeleteConfirmation = false

        return .run { send in
          await MainActor.run {
            DownloadQueueManager.shared.deleteDownload(download.id)
          }
          await send(.downloadDeleted(download.id))
          await send(.refresh)
        }

      case .cancelDelete:
        /// Cancel delete
        state.showDeleteConfirmation = false
        state.downloadToDelete = nil
        return .none

      case .downloadDeleted:
        /// Download deleted successfully
        return .send(.refresh)

      case .pauseDownload(let id):
        /// Pause download
        return .run { send in
          await MainActor.run {
            DownloadQueueManager.shared.pauseDownload(id)
          }
          await send(.refresh)
        }

      case .resumeDownload(let id):
        /// Resume download
        return .run { send in
          await MainActor.run {
            DownloadQueueManager.shared.resumeDownload(id)
          }
          await send(.refresh)
        }

      case .cancelDownload(let id):
        /// Cancel download
        return .run { send in
          await MainActor.run {
            DownloadQueueManager.shared.cancelDownload(id)
          }
          await send(.refresh)
        }

      case .storageInfoTapped:
        /// Show storage info
        state.showStorageInfo = true
        return .none

      case .dismissStorageInfo:
        /// Dismiss storage info
        state.showStorageInfo = false
        return .none

      case .errorOccurred(let message):
        /// Handle error
        state.errorMessage = message
        state.isLoading = false
        return .none
      }
    }
  }
}
