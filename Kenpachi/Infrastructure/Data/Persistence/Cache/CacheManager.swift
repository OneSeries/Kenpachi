// CacheManager.swift
// Centralized cache management for app performance
// Handles memory and disk caching with automatic cleanup

import Foundation

/// Cache manager for handling app-wide caching
/// Manages both memory and disk caches with size limits and expiration
@Observable
final class CacheManager {
    /// Shared singleton instance
    static let shared = CacheManager()
    
    /// Current memory cache size in bytes
    var currentMemorySize: Int = 0
    /// Current disk cache size in bytes
    var currentDiskSize: Int = 0
    /// Maximum memory cache size in bytes
    private var maxMemorySize: Int = AppConstants.Cache.maxMemorySize
    /// Maximum disk cache size in bytes
    private var maxDiskSize: Int = AppConstants.Cache.maxDiskSize
    
    /// File manager for disk operations
    private let fileManager = FileManager.default
    /// Cache directory URL
    private let cacheDirectory: URL
    /// Memory cache dictionary
    private var memoryCache: [String: CacheEntry] = [:]
    /// Serial queue for thread-safe cache operations
    private let cacheQueue = DispatchQueue(label: "com.kenpachi.cachemanager")
    
    /// Cache entry structure
    private struct CacheEntry {
        /// Cached data
        let data: Data
        /// Expiration date
        let expirationDate: Date
        /// Entry size in bytes
        let size: Int
    }
    
    /// Private initializer for singleton
    private init() {
        // Get caches directory URL
        let cachesDirectory = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!
        
        // Create app-specific cache directory
        cacheDirectory = cachesDirectory.appendingPathComponent("KenpachiCache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
        
        // Calculate initial cache sizes
        calculateCacheSizes()
        
        // Log initialization
        AppLogger.shared.log(
            "CacheManager initialized. Memory: \(formatBytes(currentMemorySize)), Disk: \(formatBytes(currentDiskSize))",
            level: .debug
        )
    }
    
    /// Configures cache manager with custom sizes
    /// - Parameters:
    ///   - maxMemorySize: Maximum memory cache size in bytes
    ///   - maxDiskSize: Maximum disk cache size in bytes
    func configure(maxMemorySize: Int, maxDiskSize: Int) {
        // Update maximum sizes
        self.maxMemorySize = maxMemorySize
        self.maxDiskSize = maxDiskSize
        
        // Log configuration
        AppLogger.shared.log(
            "CacheManager configured. Max Memory: \(formatBytes(maxMemorySize)), Max Disk: \(formatBytes(maxDiskSize))",
            level: .info
        )
        
        // Clean up if current sizes exceed new limits
        if currentMemorySize > maxMemorySize {
            cleanupMemoryCache()
        }
        if currentDiskSize > maxDiskSize {
            cleanupDiskCache()
        }
    }
    
    /// Stores data in memory cache
    /// - Parameters:
    ///   - data: Data to cache
    ///   - key: Cache key
    ///   - expirationTime: Time interval until expiration
    func cacheInMemory(data: Data, forKey key: String, expirationTime: TimeInterval = AppConstants.Cache.expirationTime) {
        // Perform cache operation on serial queue
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Create expiration date
            let expirationDate = Date().addingTimeInterval(expirationTime)
            
            // Create cache entry
            let entry = CacheEntry(
                data: data,
                expirationDate: expirationDate,
                size: data.count
            )
            
            // Store in memory cache
            self.memoryCache[key] = entry
            
            // Update memory size
            self.currentMemorySize += data.count
            
            // Clean up if exceeds limit
            if self.currentMemorySize > self.maxMemorySize {
                self.cleanupMemoryCache()
            }
            
            // Log cache
            AppLogger.shared.log(
                "Cached in memory: \(key) (\(self.formatBytes(data.count)))",
                level: .debug
            )
        }
    }
    
    /// Retrieves data from memory cache
    /// - Parameter key: Cache key
    /// - Returns: Cached data or nil if not found/expired
    func getFromMemory(forKey key: String) -> Data? {
        // Perform cache operation on serial queue
        return cacheQueue.sync { [weak self] in
            guard let self = self else { return nil }
            
            // Get cache entry
            guard let entry = self.memoryCache[key] else {
                return nil
            }
            
            // Check if expired
            if entry.expirationDate < Date() {
                // Remove expired entry
                self.memoryCache.removeValue(forKey: key)
                self.currentMemorySize -= entry.size
                
                // Log expiration
                AppLogger.shared.log(
                    "Memory cache expired: \(key)",
                    level: .debug
                )
                
                return nil
            }
            
            // Return cached data
            return entry.data
        }
    }
    
    /// Stores data in disk cache
    /// - Parameters:
    ///   - data: Data to cache
    ///   - key: Cache key
    func cacheToDisk(data: Data, forKey key: String) {
        // Perform cache operation on serial queue
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Create file URL for cache key
            let fileURL = self.cacheDirectory.appendingPathComponent(key.md5Hash)
            
            do {
                // Write data to disk
                try data.write(to: fileURL, options: .atomic)
                
                // Update disk size
                self.currentDiskSize += data.count
                
                // Clean up if exceeds limit
                if self.currentDiskSize > self.maxDiskSize {
                    self.cleanupDiskCache()
                }
                
                // Log cache
                AppLogger.shared.log(
                    "Cached to disk: \(key) (\(self.formatBytes(data.count)))",
                    level: .debug
                )
            } catch {
                // Log error
                AppLogger.shared.log(
                    "Failed to cache to disk: \(error.localizedDescription)",
                    level: .error
                )
            }
        }
    }
    
    /// Retrieves data from disk cache
    /// - Parameter key: Cache key
    /// - Returns: Cached data or nil if not found
    func getFromDisk(forKey key: String) -> Data? {
        // Create file URL for cache key
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        
        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            // Read data from disk
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            // Log error
            AppLogger.shared.log(
                "Failed to read from disk cache: \(error.localizedDescription)",
                level: .error
            )
            return nil
        }
    }
    
    /// Clears all caches (memory and disk)
    func clearAllCaches() {
        // Clear memory cache
        clearMemoryCache()
        
        // Clear disk cache
        clearDiskCache()
        
        // Log clear
        AppLogger.shared.log(
            "All caches cleared",
            level: .info
        )
    }
    
    /// Clears memory cache
    func clearMemoryCache() {
        // Perform on serial queue
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Remove all entries
            self.memoryCache.removeAll()
            
            // Reset size
            self.currentMemorySize = 0
            
            // Log clear
            AppLogger.shared.log(
                "Memory cache cleared",
                level: .debug
            )
        }
    }
    
    /// Clears disk cache
    func clearDiskCache() {
        // Perform on serial queue
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Get all files in cache directory
                let files = try self.fileManager.contentsOfDirectory(
                    at: self.cacheDirectory,
                    includingPropertiesForKeys: nil
                )
                
                // Delete each file
                for file in files {
                    try self.fileManager.removeItem(at: file)
                }
                
                // Reset size
                self.currentDiskSize = 0
                
                // Log clear
                AppLogger.shared.log(
                    "Disk cache cleared",
                    level: .debug
                )
            } catch {
                // Log error
                AppLogger.shared.log(
                    "Failed to clear disk cache: \(error.localizedDescription)",
                    level: .error
                )
            }
        }
    }
    
    /// Cleans up memory cache by removing oldest entries
    private func cleanupMemoryCache() {
        // Sort entries by expiration date
        let sortedEntries = memoryCache.sorted { $0.value.expirationDate < $1.value.expirationDate }
        
        // Remove entries until under limit
        for (key, entry) in sortedEntries {
            // Check if still over limit
            guard currentMemorySize > maxMemorySize else { break }
            
            // Remove entry
            memoryCache.removeValue(forKey: key)
            currentMemorySize -= entry.size
        }
        
        // Log cleanup
        AppLogger.shared.log(
            "Memory cache cleaned up. Current size: \(formatBytes(currentMemorySize))",
            level: .debug
        )
    }
    
    /// Cleans up disk cache by removing oldest files
    private func cleanupDiskCache() {
        do {
            // Get all files with attributes
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]
            )
            
            // Sort by creation date
            let sortedFiles = try files.sorted {
                let date1 = try $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date()
                let date2 = try $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date()
                return date1 < date2
            }
            
            // Remove files until under limit
            for file in sortedFiles {
                // Check if still over limit
                guard currentDiskSize > maxDiskSize else { break }
                
                // Get file size
                let fileSize = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                
                // Delete file
                try fileManager.removeItem(at: file)
                
                // Update size
                currentDiskSize -= fileSize
            }
            
            // Log cleanup
            AppLogger.shared.log(
                "Disk cache cleaned up. Current size: \(formatBytes(currentDiskSize))",
                level: .debug
            )
        } catch {
            // Log error
            AppLogger.shared.log(
                "Failed to cleanup disk cache: \(error.localizedDescription)",
                level: .error
            )
        }
    }
    
    /// Calculates current cache sizes
    private func calculateCacheSizes() {
        // Calculate memory size
        currentMemorySize = memoryCache.values.reduce(0) { $0 + $1.size }
        
        // Calculate disk size
        do {
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )
            
            currentDiskSize = try files.reduce(0) { total, file in
                let fileSize = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                return total + fileSize
            }
        } catch {
            currentDiskSize = 0
        }
    }
    
    /// Formats bytes to human-readable string
    /// - Parameter bytes: Number of bytes
    /// - Returns: Formatted string (e.g., "1.5 MB")
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - String Extension for MD5 Hash
extension String {
    /// Generates MD5 hash of string for cache key
    var md5Hash: String {
        // Simple hash implementation for cache keys
        // In production, use CryptoKit for proper hashing
        return self.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
    }
}
