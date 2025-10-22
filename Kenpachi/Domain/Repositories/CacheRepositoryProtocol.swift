// CacheRepositoryProtocol.swift
// Protocol defining cache repository interface
// Abstracts cache management operations

import Foundation

/// Cache type enumeration
enum CacheType: String {
  case images = "Images"
  case content = "Content"
  case api = "API"
  case downloads = "Downloads"
}

/// Protocol for cache management operations
protocol CacheManagerProtocol {
  /// Get total cache size in bytes
  func getCacheSize() async -> Int64
  
  /// Clear all cache and return cleared size
  func clearCache() async -> Int64
  
  /// Clear specific cache type
  func clearCache(type: CacheType) async -> Int64
}