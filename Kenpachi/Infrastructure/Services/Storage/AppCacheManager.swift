// AppCacheManager.swift
// Application-level cache manager
// Provides cache management for the entire app

import Foundation

/// Application cache manager conforming to protocol
final class AppCacheManager: CacheManagerProtocol {
  /// Shared singleton instance
  static let shared = AppCacheManager()

  /// File manager instance
  private let fileManager = FileManager.default

  /// Cache directory URL
  private lazy var cacheDirectory: URL = {
    let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    return cacheDir.appendingPathComponent("Kenpachi")
  }()

  /// Private initializer for singleton
  private init() {}

  /// Get total cache size in bytes
  func getCacheSize() async -> Int64 {
    var totalSize: Int64 = 0

    guard let enumerator = fileManager.enumerator(
      at: cacheDirectory,
      includingPropertiesForKeys: [.fileSizeKey],
      options: [.skipsHiddenFiles]
    ) else {
      return 0
    }

    for case let fileURL as URL in enumerator {
      guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
        let fileSize = resourceValues.fileSize
      else {
        continue
      }
      totalSize += Int64(fileSize)
    }

    return totalSize
  }

  /// Clear all cache and return cleared size
  func clearCache() async -> Int64 {
    let sizeBeforeClear = await getCacheSize()

    do {
      /// Remove cache directory
      if fileManager.fileExists(atPath: cacheDirectory.path) {
        try fileManager.removeItem(at: cacheDirectory)
      }

      /// Recreate cache directory
      try fileManager.createDirectory(
        at: cacheDirectory,
        withIntermediateDirectories: true,
        attributes: nil
      )

      /// Clear URLCache
      URLCache.shared.removeAllCachedResponses()

      return sizeBeforeClear
    } catch {
      print("Error clearing cache: \(error)")
      return 0
    }
  }

  /// Clear specific cache type
  func clearCache(type: CacheType) async -> Int64 {
    let typeDirectory = cacheDirectory.appendingPathComponent(type.rawValue)
    var clearedSize: Int64 = 0

    guard let enumerator = fileManager.enumerator(
      at: typeDirectory,
      includingPropertiesForKeys: [.fileSizeKey],
      options: [.skipsHiddenFiles]
    ) else {
      return 0
    }

    /// Calculate size before clearing
    for case let fileURL as URL in enumerator {
      guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
        let fileSize = resourceValues.fileSize
      else {
        continue
      }
      clearedSize += Int64(fileSize)
    }

    /// Remove directory
    do {
      if fileManager.fileExists(atPath: typeDirectory.path) {
        try fileManager.removeItem(at: typeDirectory)
      }
      /// Recreate directory
      try fileManager.createDirectory(
        at: typeDirectory,
        withIntermediateDirectories: true,
        attributes: nil
      )
    } catch {
      print("Error clearing \(type.rawValue) cache: \(error)")
      return 0
    }

    return clearedSize
  }
}
