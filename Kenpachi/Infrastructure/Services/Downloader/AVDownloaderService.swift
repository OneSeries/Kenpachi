// AVDownloaderService.swift
// Service for downloading video content

import AVFoundation
import Foundation

/// Service for downloading video content with support for various formats
final class AVDownloaderService: NSObject {
  /// Shared singleton instance
  static let shared = AVDownloaderService()

  /// Active download tasks mapped by download ID
  private var activeTasks: [String: URLSessionDownloadTask] = [:]
  /// Active AVAssetDownloadTasks for HLS streams mapped by download ID
  private var activeAssetTasks: [String: AVAssetDownloadTask] = [:]
  /// Download progress callbacks mapped by download ID
  private var progressCallbacks: [String: (Double) -> Void] = [:]
  /// Download completion callbacks mapped by download ID
  private var completionCallbacks: [String: (Result<URL, Error>) -> Void] = [:]
  /// Download metadata mapped by download ID
  private var downloadMetadata: [String: Download] = [:]

  /// URL session for standard downloads
  private var _urlSession: URLSession?
  private var urlSession: URLSession {
    if let session = _urlSession {
      return session
    }
    let config = URLSessionConfiguration.background(withIdentifier: "com.kenpachi.downloads")
    config.isDiscretionary = false
    config.sessionSendsLaunchEvents = true
    let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    _urlSession = session
    return session
  }

  /// URL session for AVAssetDownloadTask (HLS/M3U8)
  private var _assetSession: AVAssetDownloadURLSession?
  private var assetSession: AVAssetDownloadURLSession {
    if let session = _assetSession {
      return session
    }
    let config = URLSessionConfiguration.background(withIdentifier: "com.kenpachi.asset.downloads")
    config.isDiscretionary = false
    config.sessionSendsLaunchEvents = true
    let session = AVAssetDownloadURLSession(
      configuration: config, assetDownloadDelegate: self, delegateQueue: nil)
    _assetSession = session
    return session
  }

  /// Private initializer for singleton
  private override init() {
    super.init()
    AppLogger.shared.log("AVDownloaderService initialized", level: .debug)
  }

  /// Starts a download for the given link
  /// - Parameters:
  ///   - downloadId: Unique identifier for the download
  ///   - link: Extracted link containing URL and metadata
  ///   - quality: Desired download quality
  ///   - download: Download entity with metadata for filename
  ///   - progress: Progress callback (0.0 to 1.0)
  ///   - completion: Completion callback with result
  func startDownload(
    downloadId: String,
    link: ExtractedLink,
    quality: DownloadQuality,
    download: Download,
    progress: @escaping (Double) -> Void,
    completion: @escaping (Result<URL, Error>) -> Void
  ) {
    // Store callbacks and metadata
    progressCallbacks[downloadId] = progress
    completionCallbacks[downloadId] = completion
    downloadMetadata[downloadId] = download

    // Check link type and start appropriate download
    if link.type == .m3u8 || link.type == .hls {
      // Use AVAssetDownloadTask for HLS streams
      startHLSDownload(downloadId: downloadId, link: link, quality: quality)
    } else {
      // Use standard URLSession download for direct links
      startDirectDownload(downloadId: downloadId, link: link)
    }

    AppLogger.shared.log("Download started: \(downloadId)", level: .info)
  }

  /// Starts a direct download using URLSession
  /// - Parameters:
  ///   - downloadId: Unique identifier for the download
  ///   - link: Extracted link containing URL
  private func startDirectDownload(downloadId: String, link: ExtractedLink) {
    guard let url = URL(string: link.url) else {
      completionCallbacks[downloadId]?(.failure(DownloadError.invalidURL))
      return
    }

    // Create request with headers
    var request = URLRequest(url: url)
    if let headers = link.headers {
      for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
      }
    }

    // Add referer if required
    if link.requiresReferer {
      request.setValue(url.absoluteString, forHTTPHeaderField: "Referer")
    }

    // Create download task
    let task = urlSession.downloadTask(with: request)
    activeTasks[downloadId] = task
    task.resume()
  }

  /// Starts an HLS download using AVAssetDownloadTask
  /// - Parameters:
  ///   - downloadId: Unique identifier for the download
  ///   - link: Extracted link containing M3U8 URL
  ///   - quality: Desired download quality
  private func startHLSDownload(downloadId: String, link: ExtractedLink, quality: DownloadQuality) {
    guard let url = URL(string: link.url) else {
      completionCallbacks[downloadId]?(.failure(DownloadError.invalidURL))
      return
    }

    // Create AVURLAsset
    let asset = AVURLAsset(url: url)

    // Get download directory
    guard let downloadDirectory = getDownloadDirectory() else {
      completionCallbacks[downloadId]?(.failure(DownloadError.fileSystemError))
      return
    }

    // Create download task
    let task = assetSession.makeAssetDownloadTask(
      asset: asset,
      assetTitle: downloadId,
      assetArtworkData: nil,
      options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: quality.bitrate]
    )

    activeAssetTasks[downloadId] = task
    task?.resume()
  }

  /// Pauses a download
  /// - Parameter downloadId: ID of download to pause
  func pauseDownload(downloadId: String) {
    if let task = activeTasks[downloadId] {
      task.suspend()
      AppLogger.shared.log("Download paused: \(downloadId)", level: .debug)
    } else if let task = activeAssetTasks[downloadId] {
      task.suspend()
      AppLogger.shared.log("Asset download paused: \(downloadId)", level: .debug)
    }
  }

  /// Resumes a paused download
  /// - Parameter downloadId: ID of download to resume
  func resumeDownload(downloadId: String) {
    if let task = activeTasks[downloadId] {
      task.resume()
      AppLogger.shared.log("Download resumed: \(downloadId)", level: .debug)
    } else if let task = activeAssetTasks[downloadId] {
      task.resume()
      AppLogger.shared.log("Asset download resumed: \(downloadId)", level: .debug)
    }
  }

  /// Cancels a download
  /// - Parameter downloadId: ID of download to cancel
  func cancelDownload(downloadId: String) {
    if let task = activeTasks[downloadId] {
      task.cancel()
      activeTasks.removeValue(forKey: downloadId)
      progressCallbacks.removeValue(forKey: downloadId)
      completionCallbacks.removeValue(forKey: downloadId)
      AppLogger.shared.log("Download cancelled: \(downloadId)", level: .debug)
    } else if let task = activeAssetTasks[downloadId] {
      task.cancel()
      activeAssetTasks.removeValue(forKey: downloadId)
      progressCallbacks.removeValue(forKey: downloadId)
      completionCallbacks.removeValue(forKey: downloadId)
      AppLogger.shared.log("Asset download cancelled: \(downloadId)", level: .debug)
    }
  }

  /// Gets the downloads directory (accessible in Files app)
  /// - Returns: URL to downloads directory
  private func getDownloadDirectory() -> URL? {
    let fileManager = FileManager.default

    // Use Documents directory which is accessible in Files app
    guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    else {
      return nil
    }

    // Create Downloads subdirectory
    let downloadsURL = documentsURL.appendingPathComponent("Downloads", isDirectory: true)

    // Create directory if it doesn't exist
    if !fileManager.fileExists(atPath: downloadsURL.path) {
      do {
        try fileManager.createDirectory(
          at: downloadsURL, withIntermediateDirectories: true, attributes: nil)

        // Exclude from iCloud backup to keep it local only
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = downloadsURL
        try mutableURL.setResourceValues(resourceValues)

        AppLogger.shared.log(
          "Downloads directory created at: \(downloadsURL.path)", level: .info)
      } catch {
        AppLogger.shared.log(
          "Failed to create downloads directory: \(error)", level: .error)
        return nil
      }
    }

    return downloadsURL
  }

  /// Generates a descriptive filename for the download
  /// - Parameters:
  ///   - downloadId: Download ID
  ///   - fileExtension: File extension
  /// - Returns: Formatted filename
  private func generateFileName(downloadId: String, fileExtension: String) -> String {
    guard let download = downloadMetadata[downloadId] else {
      return "\(UUID().uuidString).\(fileExtension)"
    }
    
    // Sanitize strings for filename
    func sanitize(_ string: String) -> String {
      let invalid = CharacterSet(charactersIn: ":/\\?%*|\"<>")
      return string.components(separatedBy: invalid).joined(separator: "_")
    }
    
    let contentTitle = sanitize(download.content.title)
    let quality = download.quality?.rawValue ?? "Unknown"
    let server = "Local"  // Since it's downloaded, it's local
    
    if let episode = download.episode {
      // TV Show: "Show Name - S01E01 - Episode Title - Source - Server - Quality.ext"
      let episodeId = episode.formattedEpisodeId
      let episodeName = sanitize(episode.name)
      return "\(contentTitle) - \(episodeId) - \(episodeName) - \(server) - \(quality).\(fileExtension)"
    } else {
      // Movie: "Movie Name - Source - Server - Quality.ext"
      return "\(contentTitle) - \(server) - \(quality).\(fileExtension)"
    }
  }
  
  /// Gets file extension from URL or MIME type
  /// - Parameters:
  ///   - url: Download URL
  ///   - mimeType: MIME type from response
  /// - Returns: File extension
  private func getFileExtension(from url: URL?, mimeType: String?) -> String {
    // Try to get extension from URL
    if let url = url, !url.pathExtension.isEmpty {
      return url.pathExtension
    }

    // Try to get extension from MIME type
    if let mimeType = mimeType {
      switch mimeType {
      case "video/mp4":
        return "mp4"
      case "video/x-matroska":
        return "mkv"
      case "video/webm":
        return "webm"
      case "video/quicktime":
        return "mov"
      case "video/x-msvideo":
        return "avi"
      case "video/x-flv":
        return "flv"
      case "application/x-mpegURL", "application/vnd.apple.mpegurl":
        return "m3u8"
      default:
        break
      }
    }

    // Default to mp4 if unable to determine
    return "mp4"
  }
}

// MARK: - URLSessionDownloadDelegate
extension AVDownloaderService: URLSessionDownloadDelegate {
  /// Called when download completes
  func urlSession(
    _ session: URLSession, downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    // Find download ID for this task
    guard let downloadId = activeTasks.first(where: { $0.value == downloadTask })?.key else {
      return
    }

    // Move file to downloads directory
    guard let downloadsURL = getDownloadDirectory() else {
      completionCallbacks[downloadId]?(.failure(DownloadError.fileSystemError))
      return
    }

    // Generate filename with metadata
    let fileExtension = getFileExtension(
      from: downloadTask.originalRequest?.url, mimeType: downloadTask.response?.mimeType)
    let fileName = generateFileName(
      downloadId: downloadId,
      fileExtension: fileExtension
    )

    let destinationURL = downloadsURL.appendingPathComponent(fileName)

    do {
      // Remove existing file if present
      if FileManager.default.fileExists(atPath: destinationURL.path) {
        try FileManager.default.removeItem(at: destinationURL)
      }

      // Move downloaded file
      try FileManager.default.moveItem(at: location, to: destinationURL)

      // Call completion callback
      completionCallbacks[downloadId]?(.success(destinationURL))

      // Cleanup
      activeTasks.removeValue(forKey: downloadId)
      progressCallbacks.removeValue(forKey: downloadId)
      completionCallbacks.removeValue(forKey: downloadId)

      AppLogger.shared.log("Download completed: \(downloadId)", level: .info)
    } catch {
      completionCallbacks[downloadId]?(.failure(error))
      AppLogger.shared.log("Download file move failed: \(error)", level: .error)
    }
  }

  /// Called periodically to report download progress
  func urlSession(
    _ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
  ) {
    // Find download ID for this task
    guard let downloadId = activeTasks.first(where: { $0.value == downloadTask })?.key else {
      return
    }

    // Calculate progress
    let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

    // Call progress callback
    progressCallbacks[downloadId]?(progress)
  }
}

// MARK: - AVAssetDownloadDelegate
extension AVDownloaderService: AVAssetDownloadDelegate {
  /// Called when asset download completes
  func urlSession(
    _ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    // Find download ID for this task
    guard let downloadId = activeAssetTasks.first(where: { $0.value == assetDownloadTask })?.key
    else {
      return
    }

    // HLS downloads are already in a playable format
    // No need to convert - just use the downloaded asset location
    AppLogger.shared.log("HLS download completed: \(location.path)", level: .info)

    // Call completion callback with the asset location
    completionCallbacks[downloadId]?(.success(location))

    // Cleanup
    activeAssetTasks.removeValue(forKey: downloadId)
    progressCallbacks.removeValue(forKey: downloadId)
    completionCallbacks.removeValue(forKey: downloadId)
  }

  /// Called periodically to report asset download progress
  func urlSession(
    _ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange,
    totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange
  ) {
    // Find download ID for this task
    guard let downloadId = activeAssetTasks.first(where: { $0.value == assetDownloadTask })?.key
    else {
      return
    }

    // Calculate progress based on time ranges
    var percentComplete = 0.0
    for value in loadedTimeRanges {
      let loadedTimeRange = value.timeRangeValue
      percentComplete +=
        CMTimeGetSeconds(loadedTimeRange.duration)
        / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
    }

    // Call progress callback
    progressCallbacks[downloadId]?(percentComplete)
  }
}

// MARK: - DownloadError
/// Errors that can occur during download
enum DownloadError: LocalizedError {
  case invalidURL
  case fileSystemError
  case conversionFailed
  case cancelled
  case networkError

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid download URL"
    case .fileSystemError:
      return "File system error occurred"
    case .conversionFailed:
      return "Failed to convert video format"
    case .cancelled:
      return "Download was cancelled"
    case .networkError:
      return "Network error occurred"
    }
  }
}
