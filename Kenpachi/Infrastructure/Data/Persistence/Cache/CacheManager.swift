// CacheManager.swift
// Generic cache manager for in-memory and disk caching
// Provides thread-safe caching with expiration support

import Foundation

/// Generic cache manager with memory and disk persistence
actor CacheManager<Key: Hashable, Value: Codable> {
    /// In-memory cache storage
    private var memoryCache: [Key: CacheEntry<Value>] = [:]
    /// Cache directory URL
    private let cacheDirectory: URL
    /// Cache name for file organization
    private let cacheName: String
    /// Default expiration time in seconds
    private let defaultExpiration: TimeInterval
    /// Maximum memory cache size
    private let maxMemoryCacheSize: Int
    
    /// Cache entry with expiration
    private struct CacheEntry<T: Codable>: Codable {
        let value: T
        let expirationDate: Date
        
        var isExpired: Bool {
            Date() > expirationDate
        }
    }
    
    /// Initialize cache manager
    /// - Parameters:
    ///   - cacheName: Name for cache directory
    ///   - defaultExpiration: Default expiration time in seconds (default: 1 hour)
    ///   - maxMemoryCacheSize: Maximum number of items in memory cache (default: 100)
    init(
        cacheName: String,
        defaultExpiration: TimeInterval = 3600,
        maxMemoryCacheSize: Int = 100
    ) {
        self.cacheName = cacheName
        self.defaultExpiration = defaultExpiration
        self.maxMemoryCacheSize = maxMemoryCacheSize
        
        // Setup cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cacheDir.appendingPathComponent("Kenpachi/\(cacheName)")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }
    
    /// Store value in cache
    /// - Parameters:
    ///   - value: Value to cache
    ///   - key: Cache key
    ///   - expiration: Custom expiration time (optional)
    func set(_ value: Value, forKey key: Key, expiration: TimeInterval? = nil) async {
        let expirationTime = expiration ?? defaultExpiration
        let entry = CacheEntry(
            value: value,
            expirationDate: Date().addingTimeInterval(expirationTime)
        )
        
        // Store in memory cache
        memoryCache[key] = entry
        
        // Enforce memory cache size limit
        if memoryCache.count > maxMemoryCacheSize {
            await cleanupMemoryCache()
        }
        
        // Store on disk
        await saveToDisk(entry, forKey: key)
    }
    
    /// Retrieve value from cache
    /// - Parameter key: Cache key
    /// - Returns: Cached value if exists and not expired
    func get(forKey key: Key) async -> Value? {
        // Check memory cache first
        if let entry = memoryCache[key] {
            if entry.isExpired {
                memoryCache.removeValue(forKey: key)
                await removeFromDisk(forKey: key)
                return nil
            }
            return entry.value
        }
        
        // Check disk cache
        if let entry = await loadFromDisk(forKey: key) {
            if entry.isExpired {
                await removeFromDisk(forKey: key)
                return nil
            }
            // Restore to memory cache
            memoryCache[key] = entry
            return entry.value
        }
        
        return nil
    }
    
    /// Remove value from cache
    /// - Parameter key: Cache key
    func remove(forKey key: Key) async {
        memoryCache.removeValue(forKey: key)
        await removeFromDisk(forKey: key)
    }
    
    /// Clear all cached values
    func clearAll() async {
        memoryCache.removeAll()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }
    
    /// Remove expired entries from memory cache
    private func cleanupMemoryCache() async {
        let expiredKeys = memoryCache.filter { $0.value.isExpired }.map { $0.key }
        for key in expiredKeys {
            memoryCache.removeValue(forKey: key)
            await removeFromDisk(forKey: key)
        }
        
        // If still over limit, remove oldest entries
        if memoryCache.count > maxMemoryCacheSize {
            let keysToRemove = Array(memoryCache.keys.prefix(memoryCache.count - maxMemoryCacheSize))
            for key in keysToRemove {
                memoryCache.removeValue(forKey: key)
            }
        }
    }
    
    /// Save entry to disk
    private func saveToDisk(_ entry: CacheEntry<Value>, forKey key: Key) async {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.hashValue)")
        do {
            let data = try JSONEncoder().encode(entry)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save cache to disk: \(error)")
        }
    }
    
    /// Load entry from disk
    private func loadFromDisk(forKey key: Key) async -> CacheEntry<Value>? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.hashValue)")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let entry = try JSONDecoder().decode(CacheEntry<Value>.self, from: data)
            return entry
        } catch {
            print("Failed to load cache from disk: \(error)")
            return nil
        }
    }
    
    /// Remove entry from disk
    private func removeFromDisk(forKey key: Key) async {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.hashValue)")
        try? FileManager.default.removeItem(at: fileURL)
    }
}
