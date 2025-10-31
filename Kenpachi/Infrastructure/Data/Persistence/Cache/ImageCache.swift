// ImageCache.swift
// Specialized cache for images with persistent storage
// Handles image downloading, caching, and retrieval with memory and disk caching

import Foundation
import SwiftUI

/// Image cache manager for efficient image loading and caching
/// Provides both memory and disk caching with automatic cleanup
@Observable
final class ImageCache {
    /// Shared singleton instance
    static let shared = ImageCache()
    
    /// Current image cache size in bytes
    var currentImageCacheSize: Int64 = 0
    
    /// Maximum image cache size in bytes (100 MB default)
    private let maxImageCacheSize: Int64 = 100 * 1024 * 1024
    
    /// File manager for disk operations
    private let fileManager = FileManager.default
    
    /// Image cache directory URL
    private let imageCacheDirectory: URL
    
    /// Memory cache for images (NSCache for automatic memory management)
    private let memoryCache = NSCache<NSString, UIImage>()
    
    /// Serial queue for thread-safe cache operations
    private let cacheQueue = DispatchQueue(label: "com.kenpachi.imagecache", qos: .userInitiated)
    
    /// URL session for downloading images
    private let urlSession: URLSession
    
    /// Active download tasks to prevent duplicate downloads
    private var activeDownloads: [URL: Task<UIImage?, Never>] = [:]
    
    /// Private initializer for singleton
    private init() {
        // Get caches directory URL
        let cachesDirectory = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!
        
        // Create image-specific cache directory
        imageCacheDirectory = cachesDirectory.appendingPathComponent("KenpachiImageCache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(
            at: imageCacheDirectory,
            withIntermediateDirectories: true
        )
        
        // Configure URL session with caching
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50 MB memory cache
            diskCapacity: 100 * 1024 * 1024   // 100 MB disk cache
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        urlSession = URLSession(configuration: configuration)
        
        // Configure memory cache
        memoryCache.countLimit = 100 // Maximum 100 images in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB memory limit
        
        // Calculate initial cache size
        calculateCacheSize()
        
        // Log initialization
        AppLogger.shared.log(
            "ImageCache initialized. Size: \(formatBytes(currentImageCacheSize))",
            level: .debug
        )
    }
    
    /// Load image from URL with caching
    /// - Parameter url: Image URL
    /// - Returns: UIImage if available, nil otherwise
    func loadImage(from url: URL) async -> UIImage? {
        // Create cache key from URL
        let cacheKey = url.absoluteString as NSString
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            AppLogger.shared.log("Image loaded from memory cache: \(url.lastPathComponent)", level: .debug)
            return cachedImage
        }
        
        // Check disk cache
        if let diskImage = await loadImageFromDisk(url: url) {
            // Store in memory cache for faster access
            memoryCache.setObject(diskImage, forKey: cacheKey)
            AppLogger.shared.log("Image loaded from disk cache: \(url.lastPathComponent)", level: .debug)
            return diskImage
        }
        
        // Check if download is already in progress
        if let existingTask = activeDownloads[url] {
            return await existingTask.value
        }
        
        // Download image
        let downloadTask = Task<UIImage?, Never> {
            await downloadImage(from: url)
        }
        
        activeDownloads[url] = downloadTask
        let image = await downloadTask.value
        activeDownloads.removeValue(forKey: url)
        
        return image
    }
    
    /// Download image from URL
    /// - Parameter url: Image URL
    /// - Returns: Downloaded UIImage or nil
    private func downloadImage(from url: URL) async -> UIImage? {
        do {
            // Download image data
            let (data, response) = try await urlSession.data(from: url)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                AppLogger.shared.log("Failed to download image: Invalid response", level: .error)
                return nil
            }
            
            // Create UIImage from data
            guard let image = UIImage(data: data) else {
                AppLogger.shared.log("Failed to create image from data", level: .error)
                return nil
            }
            
            // Cache image
            let cacheKey = url.absoluteString as NSString
            memoryCache.setObject(image, forKey: cacheKey)
            
            // Save to disk
            await saveImageToDisk(image: image, url: url)
            
            AppLogger.shared.log("Image downloaded and cached: \(url.lastPathComponent)", level: .debug)
            
            return image
        } catch {
            AppLogger.shared.log("Failed to download image: \(error.localizedDescription)", level: .error)
            return nil
        }
    }
    
    /// Load image from disk cache
    /// - Parameter url: Image URL
    /// - Returns: Cached UIImage or nil
    private func loadImageFromDisk(url: URL) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Create file path from URL
                let fileName = url.absoluteString.md5Hash
                let fileURL = self.imageCacheDirectory.appendingPathComponent(fileName)
                
                // Check if file exists
                guard self.fileManager.fileExists(atPath: fileURL.path) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Load image data
                guard let data = try? Data(contentsOf: fileURL),
                      let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: image)
            }
        }
    }
    
    /// Save image to disk cache
    /// - Parameters:
    ///   - image: UIImage to save
    ///   - url: Original image URL
    private func saveImageToDisk(image: UIImage, url: URL) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                // Convert image to data
                guard let data = image.jpegData(compressionQuality: 0.8) else {
                    continuation.resume()
                    return
                }
                
                // Create file path from URL
                let fileName = url.absoluteString.md5Hash
                let fileURL = self.imageCacheDirectory.appendingPathComponent(fileName)
                
                do {
                    // Write data to disk
                    try data.write(to: fileURL, options: .atomic)
                    
                    // Update cache size
                    self.currentImageCacheSize += Int64(data.count)
                    
                    // Clean up if exceeds limit
                    if self.currentImageCacheSize > self.maxImageCacheSize {
                        self.cleanupDiskCache()
                    }
                    
                    AppLogger.shared.log(
                        "Image saved to disk: \(url.lastPathComponent) (\(self.formatBytes(Int64(data.count))))",
                        level: .debug
                    )
                } catch {
                    AppLogger.shared.log(
                        "Failed to save image to disk: \(error.localizedDescription)",
                        level: .error
                    )
                }
                
                continuation.resume()
            }
        }
    }
    
    /// Clear all image caches (memory and disk)
    func clearAllImageCaches() {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Get all files in cache directory
                let files = try self.fileManager.contentsOfDirectory(
                    at: self.imageCacheDirectory,
                    includingPropertiesForKeys: nil
                )
                
                // Delete each file
                for file in files {
                    try self.fileManager.removeItem(at: file)
                }
                
                // Reset size
                self.currentImageCacheSize = 0
                
                // Log clear
                AppLogger.shared.log("Image cache cleared", level: .info)
            } catch {
                AppLogger.shared.log(
                    "Failed to clear image cache: \(error.localizedDescription)",
                    level: .error
                )
            }
        }
        
        // Also clear URLCache
        urlSession.configuration.urlCache?.removeAllCachedResponses()
    }
    
    /// Clean up disk cache by removing oldest files
    private func cleanupDiskCache() {
        do {
            // Get all files with attributes
            let files = try fileManager.contentsOfDirectory(
                at: imageCacheDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]
            )
            
            // Sort by creation date (oldest first)
            let sortedFiles = try files.sorted {
                let date1 = try $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date()
                let date2 = try $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date()
                return date1 < date2
            }
            
            // Remove files until under limit
            for file in sortedFiles {
                // Check if still over limit
                guard currentImageCacheSize > maxImageCacheSize else { break }
                
                // Get file size
                let fileSize = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                
                // Delete file
                try fileManager.removeItem(at: file)
                
                // Update size
                currentImageCacheSize -= Int64(fileSize)
            }
            
            AppLogger.shared.log(
                "Image cache cleaned up. Current size: \(formatBytes(currentImageCacheSize))",
                level: .debug
            )
        } catch {
            AppLogger.shared.log(
                "Failed to cleanup image cache: \(error.localizedDescription)",
                level: .error
            )
        }
    }
    
    /// Calculate current cache size
    private func calculateCacheSize() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let files = try self.fileManager.contentsOfDirectory(
                    at: self.imageCacheDirectory,
                    includingPropertiesForKeys: [.fileSizeKey]
                )
                
                self.currentImageCacheSize = try files.reduce(0) { total, file in
                    let fileSize = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    return total + Int64(fileSize)
                }
            } catch {
                self.currentImageCacheSize = 0
            }
        }
    }
    
    /// Get current cache size (thread-safe)
    func getCacheSize() -> Int64 {
        return currentImageCacheSize
    }
    
    /// Format bytes to human-readable string
    /// - Parameter bytes: Number of bytes
    /// - Returns: Formatted string (e.g., "1.5 MB")
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
